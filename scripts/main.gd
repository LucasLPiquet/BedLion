class_name Main
extends Node2D
## Monta a arena e controla rodadas, placar e partida. Quem joga vem do lobby
## (Partida.jogadores, ver lobby.gd); se a arena for aberta direto (F6 no editor),
## entram os teclados e controles conectados, e F1 liga bots de teste. Ganha a partida quem fizer PONTOS_PARA_VENCER.
## A cada rodada o mapa muda: os mapas de mapas.gd são embaralhados e saem um
## por vez, então todos aparecem antes de algum repetir. F2 pula para o próximo mapa.

const Camaleao := preload("res://scripts/camaleao.gd")
const LinguaNoChao := preload("res://scripts/lingua_no_chao.gd")
const Linguas := preload("res://scripts/linguas.gd")
const Cenario := preload("res://scripts/cenario.gd")
const Placar := preload("res://scripts/placar.gd")
const CocoPombo := preload("res://scripts/coco_pombo.gd")
const Mapas := preload("res://scripts/mapas.gd")
const Agua := preload("res://scripts/agua.gd")
const GramaAlta := preload("res://scripts/grama_alta.gd")
const Luz := preload("res://scripts/luz.gd")
const Pistas := preload("res://scripts/pistas.gd")
const Ui := preload("res://scripts/ui.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

## Tamanho da arena (em pixels do jogo). A janela continua do mesmo tamanho:
## o jogo é esticado para caber nela (veja _ready). Era 1280 x 720.
## Se mudar, ajuste também as posições dos mapas (mapas.gd).
const TAMANHO := Vector2(1600, 900)
const ESPESSURA_PAREDE := 40.0

## Pontos para ganhar a partida (cada rodada vale 1 ponto para quem sobrar vivo).
const PONTOS_PARA_VENCER := 5
const PAUSA_FIM_RODADA := 2.0 # segundos mostrando quem ganhou a rodada
const PAUSA_FIM_PARTIDA := 4.0

## Tremor suave de tela na morte (kill) de um jogador ou bot.
const FORCA_TREMOR := 4.5
const DURACAO_TREMOR := 0.22

## Teclados que entram no jogo (tire um daqui se quiser jogar só com um).
const TECLADOS := ["teclado1", "teclado2"]
const MAX_JOGADORES := 4
## Modos dos bots de teste (só abrindo a arena direto), trocados com F1:
## completam até MAX_JOGADORES. As dificuldades estão em bot.gd.
const MODOS_BOT := ["", "parado", "facil", "medio", "dificil"]
const NOMES_MODO_BOT := ["sem bots", "bots parados", "bots fáceis", "bots médios", "bots difíceis"]

## Quanto tempo o nome do mapa fica na tela no começo da rodada.
const TEMPO_NOME_MAPA := 1.8

## Upgrades de língua (sorteados entre os de linguas.gd) aparecem num dos "pontos_upgrade"
## do mapa (sorteado a cada vez, sem repetir um ocupado). A rodada começa sem nenhum:
## cada número abaixo é quantos segundos depois do começo da rodada um aparece.
## Depois do último não aparece mais nenhum naquela rodada.
const TEMPOS_UPGRADE: Array[float] = [5.0, 10.0]
const MAX_UPGRADES := 2 # quantos podem estar no chão ao mesmo tempo

## Cocô de pombo (coco_pombo.gd) cai num lugar sorteado de tempos em tempos.
const INTERVALO_COCO := 4.0 # segundos entre um cocô e outro
const MAX_COCOS := 4 # quantos podem estar no mapa ao mesmo tempo

## Visual de cada vaga de jogador, na ordem em que entram. Onde cada um
## começa depende do mapa ("inicios" em mapas.gd).
const VAGAS := [
	{"nome": "Verde", "cor": Color(0.45, 0.82, 0.35)},
	{"nome": "Laranja", "cor": Color(0.98, 0.6, 0.25)},
	{"nome": "Azul", "cor": Color(0.35, 0.65, 0.98)},
	{"nome": "Rosa", "cor": Color(0.95, 0.5, 0.78)},
]

var placar: Array = []
var _jogadores: Array = [] # cada um: {"nome", "cor", "controle", "bot"}
var _veio_do_lobby := false # quem joga foi escolhido no lobby (aí F1 e controles novos não mudam nada)
var _indice_mapa := -1 # qual dos Mapas.MAPAS está em jogo
var _proximos_mapas: Array = [] # índices que ainda vão sair nesta volta (embaralhados)
var _mapa: Dictionary = {}
var _arena: Node2D # desenho e paredes do mapa atual (trocado a cada rodada)
var _modo_bot := 0
var _rodada: Node2D
var _numero_rodada := 0
var _vivos: Array = []
var _rodada_acabou := false
var _verificando_fim_rodada := false
var _partida_acabou := false
var _placar: Placar
var _rotulo_mensagem: Label
var _rotulo_mapa: Label
var _rotulo_ajuda: Label
var _camera: Camera2D
var _tempo_tremor := 0.0
var _menu_pausa: Control
var _botao_pausa_continuar: Button
var _tela_fim_partida: Control
var _rotulo_vencedor: Label
var _desenho_vencedor: Node2D
var _container_placar_final: VBoxContainer
var _botao_fim_reiniciar: Button
var _indice_vencedor := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	_camera.position = Vector2.ZERO
	add_child(_camera)
	_veio_do_lobby = not Partida.jogadores.is_empty()
	_montar_hud()
	if not Input.joy_connection_changed.is_connected(_ao_mudar_controles):
		Input.joy_connection_changed.connect(_ao_mudar_controles)
	_nova_partida()


func _process(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _tempo_tremor > 0.0:
		_tempo_tremor = maxf(0.0, _tempo_tremor - delta)
		var t := _tempo_tremor / DURACAO_TREMOR
		_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * (FORCA_TREMOR * t * t)
	elif is_instance_valid(_camera) and _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO


## Deslocamento rápido e suave da câmera ao ocorrer uma morte (kill).
func tremer_tela(duracao := DURACAO_TREMOR) -> void:
	_tempo_tremor = duracao


func _abrir_pausa() -> void:
	if _partida_acabou or (_menu_pausa and _menu_pausa.visible) or (_tela_fim_partida and _tela_fim_partida.visible):
		return
	if get_tree():
		get_tree().paused = true
	if _menu_pausa:
		_menu_pausa.visible = true
	if _botao_pausa_continuar:
		_botao_pausa_continuar.grab_focus.call_deferred()


func _fechar_pausa() -> void:
	if not _menu_pausa or not _menu_pausa.visible:
		return
	_menu_pausa.visible = false
	if get_tree():
		get_tree().paused = false


func alternar_pausa() -> void:
	if _menu_pausa and _menu_pausa.visible:
		_fechar_pausa()
	else:
		_abrir_pausa()


func _unhandled_input(evento: InputEvent) -> void:
	var e_pausa := false
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		if tecla.pressed and not tecla.echo and (tecla.keycode == KEY_ESCAPE or tecla.keycode == KEY_P):
			e_pausa = true
	elif evento is InputEventJoypadButton:
		var btn := evento as InputEventJoypadButton
		if btn.pressed and btn.button_index == JOY_BUTTON_START:
			e_pausa = true
	elif get_tree().paused and evento.is_action_pressed("ui_cancel"):
		e_pausa = true

	if e_pausa:
		if not _partida_acabou:
			alternar_pausa()
			get_viewport().set_input_as_handled()
			return

	if get_tree().paused:
		return

	var tecla := evento as InputEventKey
	if not (tecla and tecla.pressed and not tecla.echo):
		return
	if tecla.keycode == KEY_F1 and not _veio_do_lobby:
		_modo_bot = (_modo_bot + 1) % MODOS_BOT.size()
		_nova_partida()
	elif tecla.keycode == KEY_F2 and not _veio_do_lobby:
		# Pula para o próximo mapa apenas em teste direto e enquanto a partida não terminou.
		if not _partida_acabou:
			_nova_rodada()


func _ao_mudar_controles(_aparelho: int, _conectado: bool) -> void:
	# Um controle entrou ou saiu: monta os jogadores de novo e recomeça
	# (só sem lobby; com lobby, quem joga já foi escolhido lá).
	if not _veio_do_lobby:
		_nova_partida()


## Escolhe o mapa da rodada. Os mapas saem de uma "sacola" embaralhada: só
## quando todos já foram jogados ela é enchida e embaralhada de novo. Assim todo
## mapa aparece a cada volta e o mesmo nunca sai duas vezes seguidas.
func _trocar_mapa() -> void:
	if _proximos_mapas.is_empty():
		for i in Mapas.MAPAS.size():
			_proximos_mapas.append(i)
		_proximos_mapas.shuffle()
		# Não começar a volta nova com o mapa que acabou de ser jogado.
		if _proximos_mapas.size() > 1 and _proximos_mapas[0] == _indice_mapa:
			_proximos_mapas.push_back(_proximos_mapas.pop_front())
	_indice_mapa = _proximos_mapas.pop_front()
	_mapa = Mapas.MAPAS[_indice_mapa]
	_montar_arena()


## Apaga o mapa anterior e monta o atual: desenho, brilho da água, sol,
## capim alto e paredes.
func _montar_arena() -> void:
	if _arena:
		remove_child(_arena) # tira as paredes antigas na hora
		_arena.queue_free()
	_arena = Node2D.new()
	add_child(_arena)
	move_child(_arena, 0)

	var cenario := Cenario.new()
	cenario.tamanho = TAMANHO
	cenario.espessura = ESPESSURA_PAREDE
	cenario.mapa = _mapa
	_arena.add_child(cenario)

	var agua := Agua.new()
	agua.mapa = _mapa
	agua.tamanho = TAMANHO
	agua.espessura = ESPESSURA_PAREDE
	_arena.add_child(agua)

	# Sol (mostra a sombra de quem está invisível) e capim alto (se mexe quando alguém passa).
	var luz := Luz.new()
	luz.mapa = _mapa
	_arena.add_child(luz)
	var grama := GramaAlta.new()
	grama.mapa = _mapa
	_arena.add_child(grama)

	var e := ESPESSURA_PAREDE
	_criar_parede(Rect2(0, 0, TAMANHO.x, e))
	_criar_parede(Rect2(0, TAMANHO.y - e, TAMANHO.x, e))
	_criar_parede(Rect2(0, 0, e, TAMANHO.y))
	_criar_parede(Rect2(TAMANHO.x - e, 0, e, TAMANHO.y))
	for retangulo in _mapa["paredes"]:
		_criar_parede(retangulo)


## Só a colisão; o desenho das paredes fica em cenario.gd.
func _criar_parede(retangulo: Rect2) -> void:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 1
	corpo.position = retangulo.get_center()
	var forma := CollisionShape2D.new()
	var caixa := RectangleShape2D.new()
	caixa.size = retangulo.size
	forma.shape = caixa
	corpo.add_child(forma)
	_arena.add_child(corpo)


func _montar_hud() -> void:
	var hud := CanvasLayer.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

	_placar = Placar.new()
	_placar.size = Vector2(TAMANHO.x, 50)
	hud.add_child(_placar)

	_rotulo_mensagem = _criar_rotulo(Vector2(0, TAMANHO.y / 2.0 - 60), 48, 12)
	hud.add_child(_rotulo_mensagem)

	_rotulo_mapa = _criar_rotulo(Vector2(0, TAMANHO.y / 2.0 + 4), 30, 9)
	_rotulo_mapa.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	hud.add_child(_rotulo_mapa)

	_rotulo_ajuda = _criar_rotulo(Vector2(0, TAMANHO.y - 32), 16, 5)
	hud.add_child(_rotulo_ajuda)

	_montar_menu_pausa(hud)
	_montar_tela_fim_partida(hud)


func _montar_tela_fim_partida(hud: CanvasLayer) -> void:
	_tela_fim_partida = Control.new()
	_tela_fim_partida.process_mode = Node.PROCESS_MODE_ALWAYS
	_tela_fim_partida.visible = false
	hud.add_child(_tela_fim_partida)

	var cortina := ColorRect.new()
	cortina.size = TAMANHO
	cortina.color = Color(0.02, 0.05, 0.02, 0.8)
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	_tela_fim_partida.add_child(cortina)

	var larg_painel := 580.0
	var alt_painel := 620.0
	var pos_painel := Vector2((TAMANHO.x - larg_painel) / 2.0, (TAMANHO.y - alt_painel) / 2.0)
	var painel := Ui.painel(Rect2(pos_painel, Vector2(larg_painel, alt_painel)), Ui.AMARELO)
	painel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tela_fim_partida.add_child(painel)

	var titulo := Ui.rotulo("VITÓRIA!", 48, Vector2(pos_painel.x, pos_painel.y + 24), larg_painel)
	titulo.add_theme_color_override("font_color", Ui.AMARELO)
	_tela_fim_partida.add_child(titulo)

	_rotulo_vencedor = Ui.rotulo("", 28, Vector2(pos_painel.x, pos_painel.y + 80), larg_painel)
	_tela_fim_partida.add_child(_rotulo_vencedor)

	_desenho_vencedor = Node2D.new()
	_desenho_vencedor.position = Vector2(pos_painel.x + larg_painel / 2.0, pos_painel.y + 195.0)
	_desenho_vencedor.draw.connect(_desenhar_vencedor)
	_tela_fim_partida.add_child(_desenho_vencedor)

	_container_placar_final = VBoxContainer.new()
	_container_placar_final.add_theme_constant_override("separation", 6)
	_container_placar_final.position = Vector2(pos_painel.x + 40.0, pos_painel.y + 265.0)
	_container_placar_final.custom_minimum_size = Vector2(500, 120)
	_tela_fim_partida.add_child(_container_placar_final)

	var coluna_botoes := VBoxContainer.new()
	coluna_botoes.add_theme_constant_override("separation", 14)
	coluna_botoes.position = Vector2(pos_painel.x + (larg_painel - 360.0) / 2.0, pos_painel.y + 440.0)
	_tela_fim_partida.add_child(coluna_botoes)

	_botao_fim_reiniciar = Ui.botao("Jogar Novamente", Vector2(360, 64), 30)
	_botao_fim_reiniciar.pressed.connect(func() -> void:
		_ocultar_fim_partida()
		_nova_partida()
	)
	coluna_botoes.add_child(_botao_fim_reiniciar)

	if _veio_do_lobby:
		var botao_lobby := Ui.botao("Voltar ao Lobby", Vector2(360, 56), 26)
		botao_lobby.pressed.connect(func() -> void:
			_ocultar_fim_partida()
			Partida.ir_para(Partida.CENA_LOBBY)
		)
		coluna_botoes.add_child(botao_lobby)

	var botao_menu := Ui.botao("Menu Principal", Vector2(360, 56) if _veio_do_lobby else Vector2(360, 64), 26)
	botao_menu.pressed.connect(func() -> void:
		_ocultar_fim_partida()
		Partida.ir_para(Partida.CENA_MENU)
	)
	coluna_botoes.add_child(botao_menu)


func _desenhar_vencedor() -> void:
	if _indice_vencedor < 0 or _indice_vencedor >= _jogadores.size():
		return
	var cor: Color = _jogadores[_indice_vencedor]["cor"]
	_desenho_vencedor.draw_set_transform(Vector2.ZERO)
	Desenho.desenhar(_desenho_vencedor, Transform2D(0.0, Vector2.ONE * 3.6, 0.0, Vector2.ZERO),
		cor, Vector2.RIGHT, true, 0.0)
	_desenho_vencedor.draw_set_transform(Vector2.ZERO)


func _exibir_fim_partida(vencedor: int) -> void:
	_indice_vencedor = vencedor
	var dados: Dictionary = _jogadores[vencedor]
	var nome: String = dados["nome"]
	var cor: Color = dados["cor"]
	if dados.get("bot", "") != "":
		_rotulo_vencedor.text = "%s (Bot) venceu a partida!" % nome
	else:
		_rotulo_vencedor.text = "%s venceu a partida!" % nome
	_rotulo_vencedor.add_theme_color_override("font_color", cor.lightened(0.25))

	for filho in _container_placar_final.get_children():
		filho.queue_free()

	for i in _jogadores.size():
		var j: Dictionary = _jogadores[i]
		var eh_vencedor := (i == vencedor)
		var texto := "%s: %d pontos" % [j["nome"], placar[i]]
		if str(j.get("bot", "")) != "":
			texto += " (bot)"
		if eh_vencedor:
			texto += "  ★ VENCEDOR ★"
		var rotulo_j := Ui.rotulo(texto, 20 if not eh_vencedor else 22, Vector2.ZERO, 500)
		rotulo_j.add_theme_color_override("font_color", j["cor"] if not eh_vencedor else Ui.AMARELO)
		_container_placar_final.add_child(rotulo_j)

	_tela_fim_partida.visible = true
	_desenho_vencedor.queue_redraw()
	_botao_fim_reiniciar.grab_focus.call_deferred()


func _ocultar_fim_partida() -> void:
	if _tela_fim_partida:
		_tela_fim_partida.visible = false


func _montar_menu_pausa(hud: CanvasLayer) -> void:
	_menu_pausa = Control.new()
	_menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_pausa.visible = false
	hud.add_child(_menu_pausa)

	var cortina := ColorRect.new()
	cortina.size = TAMANHO
	cortina.color = Color(0.02, 0.05, 0.02, 0.72)
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_pausa.add_child(cortina)

	var larg_painel := 460.0
	var alt_painel := 430.0
	var pos_painel := Vector2((TAMANHO.x - larg_painel) / 2.0, (TAMANHO.y - alt_painel) / 2.0)
	var painel := Ui.painel(Rect2(pos_painel, Vector2(larg_painel, alt_painel)), Ui.AMARELO)
	painel.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_pausa.add_child(painel)

	var titulo := Ui.rotulo("Jogo Pausado", 44, Vector2(pos_painel.x, pos_painel.y + 36), larg_painel)
	titulo.add_theme_color_override("font_color", Ui.AMARELO)
	_menu_pausa.add_child(titulo)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	coluna.position = Vector2(pos_painel.x + (larg_painel - 340.0) / 2.0, pos_painel.y + 120.0)
	_menu_pausa.add_child(coluna)

	_botao_pausa_continuar = Ui.botao("Continuar", Vector2(340, 68), 30)
	_botao_pausa_continuar.pressed.connect(_fechar_pausa)
	coluna.add_child(_botao_pausa_continuar)

	var botao_reiniciar := Ui.botao("Reiniciar Rodada", Vector2(340, 68), 28)
	botao_reiniciar.pressed.connect(func() -> void:
		_fechar_pausa()
		_nova_rodada()
	)
	coluna.add_child(botao_reiniciar)

	var botao_sair := Ui.botao("Sair para o Menu", Vector2(340, 68), 28)
	botao_sair.pressed.connect(func() -> void:
		_fechar_pausa()
		Partida.ir_para(Partida.CENA_MENU)
	)
	coluna.add_child(botao_sair)


func _criar_rotulo(posicao: Vector2, tamanho_fonte: int, contorno: int) -> Label:
	var rotulo := Label.new()
	rotulo.position = posicao
	rotulo.size = Vector2(TAMANHO.x, tamanho_fonte * 2)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", tamanho_fonte)
	rotulo.add_theme_constant_override("outline_size", contorno)
	rotulo.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.1))
	return rotulo


## Quem joga: o que foi escolhido no lobby. Sem lobby, primeiro os teclados,
## depois cada controle conectado, e os bots (se ligados com F1) completam até MAX_JOGADORES.
func _escolher_jogadores() -> void:
	if _veio_do_lobby:
		_jogadores = Partida.jogadores.duplicate(true)
		_escrever_ajuda()
		return
	var controles: Array = TECLADOS.duplicate()
	for pad in Input.get_connected_joypads():
		if pad < Controles.MAX_PADS:
			controles.append("pad%d" % pad)
	controles = controles.slice(0, MAX_JOGADORES)

	var modo: String = MODOS_BOT[_modo_bot]
	var quantidade := controles.size()
	if modo != "":
		quantidade = MAX_JOGADORES
	quantidade = maxi(quantidade, 2) # com uma pessoa só, entra um bot parado

	_jogadores.clear()
	for i in quantidade:
		var jogador: Dictionary = VAGAS[i].duplicate()
		if i < controles.size():
			jogador["controle"] = controles[i]
			jogador["bot"] = ""
		else:
			jogador["controle"] = ""
			jogador["bot"] = modo if modo != "" else "parado"
		_jogadores.append(jogador)
	_escrever_ajuda()


func _escrever_ajuda() -> void:
	var partes := PackedStringArray()
	for jogador in _jogadores:
		var como: String = Controles.descricao(jogador["controle"])
		var bot: String = jogador["bot"]
		if bot != "":
			como = "bot " + Partida.NOMES_DIFICULDADE.get(bot, bot).to_lower()
		partes.append("%s: %s" % [jogador["nome"], como])
	if not _veio_do_lobby:
		partes.append("F1: %s" % NOMES_MODO_BOT[_modo_bot])
		partes.append("F2: próximo mapa")
	partes.append("Esc: pausa")
	_rotulo_ajuda.text = "(golpe / invisível / língua)    " + "    |    ".join(partes)


func _nova_partida() -> void:
	_fechar_pausa()
	_ocultar_fim_partida()
	_escolher_jogadores()
	placar.clear()
	for jogador in _jogadores:
		placar.append(0)
	_numero_rodada = 0
	_partida_acabou = false
	_nova_rodada()


func _nova_rodada() -> void:
	_fechar_pausa()
	if _rodada:
		remove_child(_rodada)
		_rodada.queue_free()
	_rodada = Node2D.new()
	_rodada.y_sort_enabled = true # quem está mais embaixo aparece na frente
	add_child(_rodada)
	_trocar_mapa()
	var pistas := Pistas.new() # ondinhas e pegadas molhadas (pistas.gd)
	pistas.mapa = _mapa
	_rodada.add_child(pistas)
	_numero_rodada += 1
	_rodada_acabou = false
	_verificando_fim_rodada = false
	_vivos.clear()
	_atualizar_placar()
	_mostrar_mensagem("Rodada %d" % _numero_rodada, 1.2)
	_mostrar_texto(_rotulo_mapa, _mapa["nome"], TEMPO_NOME_MAPA)

	for tempo in TEMPOS_UPGRADE:
		var relogio := Timer.new()
		relogio.wait_time = tempo
		relogio.one_shot = true
		relogio.autostart = true
		relogio.timeout.connect(_spawnar_upgrade)
		_rodada.add_child(relogio)

	var relogio_coco := Timer.new()
	relogio_coco.wait_time = INTERVALO_COCO
	relogio_coco.autostart = true
	relogio_coco.timeout.connect(_spawnar_coco)
	_rodada.add_child(relogio_coco)

	for i in _jogadores.size():
		var dados: Dictionary = _jogadores[i]
		var inicio: Vector2 = _mapa["inicios"][i]
		var camaleao := Camaleao.new()
		camaleao.controle = dados["controle"]
		camaleao.bot = dados["bot"]
		camaleao.cor = dados["cor"]
		camaleao.position = inicio
		camaleao.direcao = Vector2.RIGHT if inicio.x < TAMANHO.x / 2.0 else Vector2.LEFT
		camaleao.mundo = _rodada
		camaleao.mapa = _mapa
		camaleao.set_meta("indice", i)
		camaleao.morreu.connect(_ao_morrer)
		_rodada.add_child(camaleao)
		_vivos.append(camaleao)


func _spawnar_upgrade() -> void:
	if _rodada_acabou:
		return
	var no_chao: Array = []
	for filho in _rodada.get_children():
		if filho is LinguaNoChao:
			no_chao.append(filho)
	if no_chao.size() >= MAX_UPGRADES:
		return
	var livres: Array = []
	for ponto in _mapa["pontos_upgrade"]:
		var ocupado := false
		for existente in no_chao:
			if existente.position.distance_to(ponto) < 40.0:
				ocupado = true
		if not ocupado:
			livres.append(ponto)
	if livres.is_empty():
		return
	_criar_upgrade(livres.pick_random())


## Sorteia um lugar livre no chão (longe das paredes, dos blocos e da água) e solta um cocô lá.
func _spawnar_coco() -> void:
	if _rodada_acabou or get_tree().get_nodes_in_group("cocos").size() >= MAX_COCOS:
		return
	var margem := ESPESSURA_PAREDE + 30.0
	for _tentativa in 20:
		var ponto := Vector2(randf_range(margem, TAMANHO.x - margem), randf_range(margem, TAMANHO.y - margem))
		if Mapas.lugar_livre(_mapa, ponto, 30.0):
			var coco := CocoPombo.new()
			coco.position = ponto
			_rodada.add_child(coco)
			return


func _criar_upgrade(posicao: Vector2) -> void:
	var upgrade := LinguaNoChao.new()
	upgrade.tipo = Linguas.UPGRADES.pick_random()
	upgrade.position = posicao
	_rodada.add_child(upgrade)


func _ao_morrer(camaleao: Node) -> void:
	tremer_tela()
	_vivos.erase(camaleao)
	if _rodada_acabou or _verificando_fim_rodada or _vivos.size() > 1:
		return
	# Só decide no fim do quadro de física: quem morrer no mesmo quadro (golpes
	# trocados ou dois caindo na água juntos) também conta, e aí dá empate.
	# Sem isso, a ordem dos nós na árvore escolheria o vencedor.
	_verificando_fim_rodada = true
	_encerrar_rodada.call_deferred(_numero_rodada)


func _encerrar_rodada(rodada: int) -> void:
	if not is_inside_tree() or rodada != _numero_rodada or _rodada_acabou:
		return
	_verificando_fim_rodada = false
	_rodada_acabou = true
	var rodada_que_acabou := _numero_rodada
	var partida_acabou := false
	if _vivos.size() == 1:
		var vencedor: int = _vivos[0].get_meta("indice")
		placar[vencedor] += 1
		var nome: String = _jogadores[vencedor]["nome"]
		if placar[vencedor] >= PONTOS_PARA_VENCER:
			_partida_acabou = true
			_mostrar_mensagem("%s venceu a partida!" % nome, PAUSA_FIM_PARTIDA)
			_atualizar_placar()
			await _criar_temporizador(1.5).timeout
			if not is_inside_tree() or rodada_que_acabou != _numero_rodada:
				return
			_exibir_fim_partida(vencedor)
			return
		else:
			_mostrar_mensagem("%s ganhou a rodada!" % nome, PAUSA_FIM_RODADA)
	else:
		_mostrar_mensagem("Empate!", PAUSA_FIM_RODADA)
	_atualizar_placar()

	await _criar_temporizador(PAUSA_FIM_RODADA).timeout
	# Se no meio da espera a partida recomeçou (F1 ou controle novo) ou saiu da cena, não faz nada.
	if not is_inside_tree() or rodada_que_acabou != _numero_rodada or not _rodada_acabou:
		return
	_nova_rodada()


func _mostrar_mensagem(texto: String, duracao: float) -> void:
	_mostrar_texto(_rotulo_mensagem, texto, duracao)


## Mostra o texto no rótulo e apaga depois de "duracao" segundos (se ninguém trocou antes).
func _mostrar_texto(rotulo: Label, texto: String, duracao: float) -> void:
	if not is_instance_valid(rotulo):
		return
	rotulo.text = texto
	var tempo := _criar_temporizador(duracao)
	tempo.timeout.connect(func() -> void:
		if is_instance_valid(rotulo) and rotulo.text == texto:
			rotulo.text = ""
	)


func _criar_temporizador(duracao: float) -> Timer:
	var relogio := Timer.new()
	relogio.wait_time = duracao
	relogio.one_shot = true
	relogio.autostart = true
	add_child(relogio)
	relogio.timeout.connect(relogio.queue_free)
	return relogio


func _atualizar_placar() -> void:
	_placar.atualizar(_jogadores, placar, PONTOS_PARA_VENCER)
