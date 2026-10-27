extends Node2D
## Monta a arena, cria os dois camaleões e controla rodadas e placar.

const Camaleao := preload("res://scripts/camaleao.gd")
const ArmaNoChao := preload("res://scripts/arma_no_chao.gd")

const TAMANHO := Vector2(1280, 720)
const ESPESSURA_PAREDE := 32.0
const COR_CHAO := Color(0.17, 0.2, 0.17)
const COR_PAREDE := Color(0.35, 0.3, 0.25)

const OBSTACULOS := [
	Rect2(380, 150, 60, 160),
	Rect2(840, 410, 60, 160),
	Rect2(560, 110, 160, 40),
	Rect2(560, 570, 160, 40),
]
## Armas extras espalhadas pelo mapa no começo de cada rodada.
const ARMAS_EXTRAS := [Vector2(640, 360)]

const JOGADORES := [
	{"prefixo": "p1", "nome": "Verde", "cor": Color(0.35, 0.85, 0.4), "inicio": Vector2(160, 360)},
	{"prefixo": "p2", "nome": "Laranja", "cor": Color(0.95, 0.55, 0.2), "inicio": Vector2(1120, 360)},
]

var placar := [0, 0]
var _rodada: Node2D
var _vivos: Array = []
var _rodada_acabou := false
var _rotulo_placar: Label
var _rotulo_mensagem: Label


func _ready() -> void:
	_montar_arena()
	_montar_hud()
	_nova_rodada()


func _montar_arena() -> void:
	var chao := ColorRect.new()
	chao.color = COR_CHAO
	chao.size = TAMANHO
	chao.z_index = -10
	add_child(chao)

	var e := ESPESSURA_PAREDE
	_criar_parede(Rect2(0, 0, TAMANHO.x, e))
	_criar_parede(Rect2(0, TAMANHO.y - e, TAMANHO.x, e))
	_criar_parede(Rect2(0, 0, e, TAMANHO.y))
	_criar_parede(Rect2(TAMANHO.x - e, 0, e, TAMANHO.y))
	for retangulo in OBSTACULOS:
		_criar_parede(retangulo)


func _criar_parede(retangulo: Rect2) -> void:
	var corpo := StaticBody2D.new()
	corpo.collision_layer = 1
	corpo.position = retangulo.get_center()
	var forma := CollisionShape2D.new()
	var caixa := RectangleShape2D.new()
	caixa.size = retangulo.size
	forma.shape = caixa
	corpo.add_child(forma)
	var visual := ColorRect.new()
	visual.color = COR_PAREDE
	visual.size = retangulo.size
	visual.position = -retangulo.size / 2.0
	corpo.add_child(visual)
	add_child(corpo)


func _montar_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	_rotulo_placar = Label.new()
	_rotulo_placar.position = Vector2(0, 4)
	_rotulo_placar.size = Vector2(TAMANHO.x, 24)
	_rotulo_placar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_rotulo_placar)

	_rotulo_mensagem = Label.new()
	_rotulo_mensagem.position = Vector2(0, TAMANHO.y / 2.0 - 40)
	_rotulo_mensagem.size = Vector2(TAMANHO.x, 40)
	_rotulo_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_mensagem.add_theme_font_size_override("font_size", 32)
	hud.add_child(_rotulo_mensagem)

	var ajuda := Label.new()
	ajuda.position = Vector2(0, TAMANHO.y - 28)
	ajuda.size = Vector2(TAMANHO.x, 24)
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ajuda.add_theme_font_size_override("font_size", 12)
	ajuda.text = "Verde: WASD, F ataca, G invisível    |    Laranja: setas, . ataca, , invisível"
	hud.add_child(ajuda)


func _nova_rodada() -> void:
	if _rodada:
		_rodada.queue_free()
	_rodada = Node2D.new()
	add_child(_rodada)
	_rodada_acabou = false
	_vivos.clear()
	_rotulo_mensagem.text = ""
	_atualizar_placar()

	for posicao in ARMAS_EXTRAS:
		var arma := ArmaNoChao.new()
		arma.position = posicao
		_rodada.add_child(arma)

	for i in JOGADORES.size():
		var dados: Dictionary = JOGADORES[i]
		var camaleao := Camaleao.new()
		camaleao.prefixo = dados["prefixo"]
		camaleao.cor = dados["cor"]
		camaleao.position = dados["inicio"]
		camaleao.direcao = Vector2.RIGHT if dados["inicio"].x < TAMANHO.x / 2.0 else Vector2.LEFT
		camaleao.mundo = _rodada
		camaleao.set_meta("indice", i)
		camaleao.morreu.connect(_ao_morrer)
		_rodada.add_child(camaleao)
		_vivos.append(camaleao)


func _ao_morrer(camaleao: Node) -> void:
	_vivos.erase(camaleao)
	if _rodada_acabou or _vivos.size() > 1:
		return
	_rodada_acabou = true
	if _vivos.size() == 1:
		var vencedor: int = _vivos[0].get_meta("indice")
		placar[vencedor] += 1
		_rotulo_mensagem.text = "%s venceu a rodada!" % JOGADORES[vencedor]["nome"]
	else:
		_rotulo_mensagem.text = "Empate!"
	_atualizar_placar()
	await get_tree().create_timer(2.0).timeout
	_nova_rodada()


func _atualizar_placar() -> void:
	_rotulo_placar.text = "%s %d  x  %d %s" % [
		JOGADORES[0]["nome"], placar[0], placar[1], JOGADORES[1]["nome"]
	]
