extends Node2D
## Monta a arena, escolhe quem joga (teclados, controles e bots) e controla
## rodadas, placar e partida. Ganha a partida quem fizer PONTOS_PARA_VENCER.

const Camaleao := preload("res://scripts/camaleao.gd")
const LinguaNoChao := preload("res://scripts/lingua_no_chao.gd")
const Linguas := preload("res://scripts/linguas.gd")
const Cenario := preload("res://scripts/cenario.gd")
const Placar := preload("res://scripts/placar.gd")
const CocoPombo := preload("res://scripts/coco_pombo.gd")

## Tamanho da arena (em pixels do jogo). A janela continua do mesmo tamanho:
## o jogo é esticado para caber nela (veja _ready). Era 1280 x 720.
## Se mudar, ajuste também as posições abaixo (obstáculos, upgrades e início).
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

const OBSTACULOS := [
	Rect2(475, 188, 75, 200),
	Rect2(1050, 512, 75, 200),
	Rect2(700, 138, 200, 50),
	Rect2(700, 712, 200, 50),
]
## Upgrades de língua que já estão no mapa no começo de cada rodada.
const UPGRADES_NO_INICIO := [Vector2(800, 450)]

## Upgrades de língua (sorteados entre os de linguas.gd) aparecem de tempos em tempos.
const INTERVALO_UPGRADE := 10.0 # segundos entre uma aparição e outra
const MAX_UPGRADES := 2 # quantos podem estar no chão ao mesmo tempo
## Lugares onde eles podem aparecer (sorteado a cada vez, sem repetir um ocupado).
const PONTOS_UPGRADE := [
	Vector2(250, 162), Vector2(1350, 162), Vector2(250, 738), Vector2(1350, 738),
	Vector2(800, 300), Vector2(800, 600), Vector2(625, 588), Vector2(975, 312),
]

## Cocô de pombo (coco_pombo.gd) cai num lugar sorteado de tempos em tempos.
const INTERVALO_COCO := 4.0 # segundos entre um cocô e outro
const MAX_COCOS := 4 # quantos podem estar no mapa ao mesmo tempo

## Visual de cada vaga de jogador, na ordem em que entram.
const VAGAS := [
	{"nome": "Verde", "cor": Color(0.45, 0.82, 0.35), "inicio": Vector2(212, 262)},
	{"nome": "Laranja", "cor": Color(0.98, 0.6, 0.25), "inicio": Vector2(1388, 638)},
	{"nome": "Azul", "cor": Color(0.35, 0.65, 0.98), "inicio": Vector2(1388, 262)},
	{"nome": "Rosa", "cor": Color(0.95, 0.5, 0.78), "inicio": Vector2(212, 638)},
]

var placar: Array = []
var _jogadores: Array = [] # cada um: {"nome", "cor", "inicio", "controle", "bot"}
var _modo_bot := 0
var _rodada: Node2D
var _numero_rodada := 0
var _vivos: Array = []
var _rodada_acabou := false
var _placar: Placar
var _rotulo_mensagem: Label
var _rotulo_ajuda: Label


func _ready() -> void:
	# A tela mostra a arena inteira (TAMANHO), seja qual for o tamanho da janela.
	get_window().content_scale_size = Vector2i(TAMANHO)
	_montar_arena()
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


func _montar_arena() -> void:
	var cenario := Cenario.new()
	cenario.tamanho = TAMANHO
	cenario.espessura = ESPESSURA_PAREDE
	cenario.obstaculos = OBSTACULOS
	add_child(cenario)

	var e := ESPESSURA_PAREDE
	_criar_parede(Rect2(0, 0, TAMANHO.x, e))
	_criar_parede(Rect2(0, TAMANHO.y - e, TAMANHO.x, e))
	_criar_parede(Rect2(0, 0, e, TAMANHO.y))
	_criar_parede(Rect2(TAMANHO.x - e, 0, e, TAMANHO.y))
	for retangulo in OBSTACULOS:
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
	add_child(corpo)


func _montar_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	_placar = Placar.new()
	_placar.size = Vector2(TAMANHO.x, 50)
	hud.add_child(_placar)

	_rotulo_mensagem = _criar_rotulo(Vector2(0, TAMANHO.y / 2.0 - 60), 48, 12)
	hud.add_child(_rotulo_mensagem)

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
	_numero_rodada += 1
	_rodada_acabou = false
	_vivos.clear()
	_atualizar_placar()
	_mostrar_mensagem("Rodada %d" % _numero_rodada, 1.2)

	for posicao in UPGRADES_NO_INICIO:
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
		var inicio: Vector2 = dados["inicio"]
		var camaleao := Camaleao.new()
		camaleao.controle = dados["controle"]
		camaleao.bot = dados["bot"]
		camaleao.cor = dados["cor"]
		camaleao.position = inicio
		camaleao.direcao = Vector2.RIGHT if inicio.x < TAMANHO.x / 2.0 else Vector2.LEFT
		camaleao.mundo = _rodada
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
	for ponto in PONTOS_UPGRADE:
		var ocupado := false
		for existente in no_chao:
			if existente.position.distance_to(ponto) < 40.0:
				ocupado = true
		if not ocupado:
			livres.append(ponto)
	if livres.is_empty():
		return
	_criar_upgrade(livres.pick_random())


## Sorteia um lugar livre no chão (longe das paredes e dos blocos) e solta um cocô lá.
func _spawnar_coco() -> void:
	if _rodada_acabou or get_tree().get_nodes_in_group("cocos").size() >= MAX_COCOS:
		return
	var margem := ESPESSURA_PAREDE + 30.0
	for _tentativa in 20:
		var ponto := Vector2(randf_range(margem, TAMANHO.x - margem), randf_range(margem, TAMANHO.y - margem))
		var livre := true
		for retangulo in OBSTACULOS:
			if retangulo.grow(30.0).has_point(ponto):
				livre = false
		if livre:
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
	_rotulo_mensagem.text = texto
	var tempo := get_tree().create_timer(duracao)
	tempo.timeout.connect(func() -> void:
		if _rotulo_mensagem.text == texto:
			_rotulo_mensagem.text = ""
	)


func _atualizar_placar() -> void:
	_placar.atualizar(_jogadores, placar, PONTOS_PARA_VENCER)
