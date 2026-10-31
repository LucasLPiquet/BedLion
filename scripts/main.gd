extends Node2D
## Monta a arena, escolhe quem joga (teclados, controles e bots) e controla
## rodadas, placar e partida. Ganha a partida quem fizer PONTOS_PARA_VENCER.
## A cada rodada o mapa muda (sorteado entre os de mapas.gd, sem repetir o anterior).

const Camaleao := preload("res://scripts/camaleao.gd")
const LinguaNoChao := preload("res://scripts/lingua_no_chao.gd")
const Linguas := preload("res://scripts/linguas.gd")
const Cenario := preload("res://scripts/cenario.gd")
const Placar := preload("res://scripts/placar.gd")
const CocoPombo := preload("res://scripts/coco_pombo.gd")
const Mapas := preload("res://scripts/mapas.gd")
const Agua := preload("res://scripts/agua.gd")

## Tamanho da arena (em pixels do jogo). A janela continua do mesmo tamanho:
## o jogo é esticado para caber nela (veja _ready). Era 1280 x 720.
## Se mudar, ajuste também as posições dos mapas (mapas.gd).
const TAMANHO := Vector2(1600, 900)
const ESPESSURA_PAREDE := 40.0

## Pontos para ganhar a partida (cada rodada vale 1 ponto para quem sobrar vivo).
const PONTOS_PARA_VENCER := 5
const PAUSA_FIM_RODADA := 2.0 # segundos mostrando quem ganhou a rodada
const PAUSA_FIM_PARTIDA := 4.0

## Teclados que entram no jogo (tire um daqui se quiser jogar só com um).
const TECLADOS := ["teclado1", "teclado2"]
const MAX_JOGADORES := 4
## Modos dos bots de teste, trocados com F1: completam até MAX_JOGADORES.
const MODOS_BOT := ["", "parado", "andando"]
const NOMES_MODO_BOT := ["sem bots", "bots parados", "bots andando"]

## Quanto tempo o nome do mapa fica na tela no começo da rodada.
const TEMPO_NOME_MAPA := 1.8

## Upgrades de língua (sorteados entre os de linguas.gd) aparecem de tempos em tempos,
## num dos "pontos_upgrade" do mapa (sorteado a cada vez, sem repetir um ocupado).
const INTERVALO_UPGRADE := 10.0 # segundos entre uma aparição e outra
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
var _indice_mapa := -1 # qual dos Mapas.MAPAS está em jogo
var _mapa: Dictionary = {}
var _arena: Node2D # desenho e paredes do mapa atual (trocado a cada rodada)
var _modo_bot := 0
var _rodada: Node2D
var _numero_rodada := 0
var _vivos: Array = []
var _rodada_acabou := false
var _placar: Placar
var _rotulo_mensagem: Label
var _rotulo_mapa: Label
var _rotulo_ajuda: Label


func _ready() -> void:
	# A tela mostra a arena inteira (TAMANHO), seja qual for o tamanho da janela.
	get_window().content_scale_size = Vector2i(TAMANHO)
	_montar_hud()
	Input.joy_connection_changed.connect(_ao_mudar_controles)
	_nova_partida()


func _unhandled_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla and tecla.pressed and not tecla.echo and tecla.keycode == KEY_F1:
		_modo_bot = (_modo_bot + 1) % MODOS_BOT.size()
		_nova_partida()


func _ao_mudar_controles(_aparelho: int, _conectado: bool) -> void:
	# Um controle entrou ou saiu: monta os jogadores de novo e recomeça.
	_nova_partida()


## Sorteia o mapa da rodada: qualquer um, menos o que acabou de ser jogado.
func _trocar_mapa() -> void:
	var opcoes: Array = []
	for i in Mapas.MAPAS.size():
		if i != _indice_mapa:
			opcoes.append(i)
	if opcoes.is_empty(): # só existe um mapa
		opcoes.append(0)
	_indice_mapa = opcoes.pick_random()
	_mapa = Mapas.MAPAS[_indice_mapa]
	_montar_arena()


## Apaga o mapa anterior e monta o atual: desenho, brilho da água e paredes.
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


func _criar_rotulo(posicao: Vector2, tamanho_fonte: int, contorno: int) -> Label:
	var rotulo := Label.new()
	rotulo.position = posicao
	rotulo.size = Vector2(TAMANHO.x, tamanho_fonte * 2)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", tamanho_fonte)
	rotulo.add_theme_constant_override("outline_size", contorno)
	rotulo.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.1))
	return rotulo


## Quem joga: primeiro os teclados, depois cada controle conectado, e os bots
## (se ligados com F1) completam até MAX_JOGADORES.
func _escolher_jogadores() -> void:
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

	var partes := PackedStringArray()
	for jogador in _jogadores:
		var como: String = Controles.descricao(jogador["controle"])
		if jogador["bot"] != "":
			como = "bot " + jogador["bot"]
		partes.append("%s: %s" % [jogador["nome"], como])
	partes.append("F1: %s" % NOMES_MODO_BOT[_modo_bot])
	_rotulo_ajuda.text = "(golpe / invisível / língua)    " + "    |    ".join(partes)


func _nova_partida() -> void:
	_escolher_jogadores()
	placar.clear()
	for jogador in _jogadores:
		placar.append(0)
	_numero_rodada = 0
	_nova_rodada()


func _nova_rodada() -> void:
	if _rodada:
		_rodada.queue_free()
	_rodada = Node2D.new()
	_rodada.y_sort_enabled = true # quem está mais embaixo aparece na frente
	add_child(_rodada)
	_trocar_mapa()
	_numero_rodada += 1
	_rodada_acabou = false
	_vivos.clear()
	_atualizar_placar()
	_mostrar_mensagem("Rodada %d" % _numero_rodada, 1.2)
	_mostrar_texto(_rotulo_mapa, _mapa["nome"], TEMPO_NOME_MAPA)

	for posicao in _mapa["upgrades_no_inicio"]:
		_criar_upgrade(posicao)

	var relogio := Timer.new()
	relogio.wait_time = INTERVALO_UPGRADE
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
	_vivos.erase(camaleao)
	if _rodada_acabou or _vivos.size() > 1:
		return
	_rodada_acabou = true
	var rodada_que_acabou := _numero_rodada
	var partida_acabou := false
	if _vivos.size() == 1:
		var vencedor: int = _vivos[0].get_meta("indice")
		placar[vencedor] += 1
		var nome: String = _jogadores[vencedor]["nome"]
		if placar[vencedor] >= PONTOS_PARA_VENCER:
			partida_acabou = true
			_mostrar_mensagem("%s venceu a partida!" % nome, PAUSA_FIM_PARTIDA)
		else:
			_mostrar_mensagem("%s ganhou a rodada!" % nome, PAUSA_FIM_RODADA)
	else:
		_mostrar_mensagem("Empate!", PAUSA_FIM_RODADA)
	_atualizar_placar()

	await get_tree().create_timer(PAUSA_FIM_PARTIDA if partida_acabou else PAUSA_FIM_RODADA).timeout
	# Se no meio da espera a partida recomeçou (F1 ou controle novo), não faz nada.
	if rodada_que_acabou != _numero_rodada or not _rodada_acabou:
		return
	if partida_acabou:
		_nova_partida()
	else:
		_nova_rodada()


func _mostrar_mensagem(texto: String, duracao: float) -> void:
	_mostrar_texto(_rotulo_mensagem, texto, duracao)


## Mostra o texto no rótulo e apaga depois de "duracao" segundos (se ninguém trocou antes).
func _mostrar_texto(rotulo: Label, texto: String, duracao: float) -> void:
	rotulo.text = texto
	var tempo := get_tree().create_timer(duracao)
	tempo.timeout.connect(func() -> void:
		if rotulo.text == texto:
			rotulo.text = ""
	)


func _atualizar_placar() -> void:
	_placar.atualizar(_jogadores, placar, PONTOS_PARA_VENCER)
