extends Node2D
## Pele velha que fica para trás quando um camaleão com o poder "muda" some.
## É igualzinha ao camaleão, parada no lugar. Uma língua ou um golpe estoura a
## pele num "puf" branco (aí todo mundo sabe que era só a pele). Depois de
## DURACAO segundos ela murcha sozinha.

const Desenho := preload("res://scripts/desenho_camaleao.gd")
const EfeitoMorte := preload("res://scripts/efeito_morte.gd")

const DURACAO := 8.0
const TEMPO_MURCHAR := 0.6 # no fim ela vai murchando e ficando transparente
## Tamanho para a língua e o golpe acertarem (igual ao de um camaleão).
const RAIO := 18.0
const COR_PUF := Color(0.95, 0.93, 0.85)

var cor := Color.WHITE
var direcao := Vector2.RIGHT
var olhando_direita := true
var _tempo := 0.0


func _ready() -> void:
	add_to_group("cascas")


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	if _tempo >= DURACAO - TEMPO_MURCHAR:
		queue_redraw()


## Chamado pela língua ou pelo golpe de alguém.
func estourar() -> void:
	if is_queued_for_deletion():
		return
	var puf := EfeitoMorte.new()
	puf.cor = COR_PUF
	puf.position = position
	get_parent().add_child.call_deferred(puf)
	queue_free()


func _draw() -> void:
	var murcha := clampf((_tempo - (DURACAO - TEMPO_MURCHAR)) / TEMPO_MURCHAR, 0.0, 1.0)
	modulate.a = 1.0 - murcha
	var escala := Vector2(1.0 + murcha * 0.3, 1.0 - murcha * 0.6) * Desenho.ESCALA_JOGO
	var base := Transform2D(0.0, escala, 0.0, Vector2(0, murcha * 12.0))
	Desenho.desenhar(self, base, cor, direcao, olhando_direita, 0.0)
