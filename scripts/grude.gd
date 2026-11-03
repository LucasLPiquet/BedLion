extends Node2D
## Bola de grude que a língua com o poder "grude" deixa no chão quando erra.
## Quem pisar nela (visível ou invisível) fica preso por TEMPO_PRESO segundos e,
## se estava invisível, aparece. Quem soltou o grude não gruda nele.
## A bola some depois de DURACAO segundos ou quando pega alguém.

const DURACAO := 12.0
const TEMPO_PRESO := 1.2
## Só começa a pegar depois disso (para não grudar quem está bem em cima na hora).
const TEMPO_ARMAR := 0.3
## Distância (do centro do camaleão ao centro do grude) para contar como pisada.
const RAIO_PISAR := 28.0

const VERDE := Color(0.55, 0.85, 0.2)
const CONTORNO := Color(0.08, 0.07, 0.1)

var dono: Node = null # quem soltou (não gruda nele)
var _tempo := 0.0
var _formato: Array = [] # bolinhas da poça, sorteadas uma vez


func _ready() -> void:
	z_index = -1 # no chão, por baixo dos camaleões
	add_to_group("grudes")
	for i in 5:
		var angulo := TAU * i / 5.0 + randf_range(-0.3, 0.3)
		_formato.append([Vector2.from_angle(angulo) * Vector2(1.0, 0.6) * randf_range(8.0, 12.0), randf_range(4.0, 6.0)])


func _physics_process(delta: float) -> void:
	_tempo += delta
	queue_redraw()
	if _tempo >= DURACAO:
		queue_free()
		return
	if _tempo < TEMPO_ARMAR:
		return
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if camaleao == dono or not camaleao.vivo:
			continue
		if position.distance_to(camaleao.position + Vector2(0, 12)) <= RAIO_PISAR \
				and camaleao.grudar(TEMPO_PRESO):
			queue_free()
			return


func _draw() -> void:
	var alfa := clampf(DURACAO - _tempo, 0.0, 1.0) # vai sumindo no último segundo
	var cair := minf(_tempo / 0.15, 1.0) # "ploft" quando cai
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6) * lerpf(0.4, 1.0, cair))
	for bolinha in _formato:
		draw_circle(bolinha[0], bolinha[1] + 1.5, Color(CONTORNO, 0.8 * alfa))
	draw_circle(Vector2.ZERO, 13.0, Color(CONTORNO, 0.8 * alfa))
	for bolinha in _formato:
		draw_circle(bolinha[0], bolinha[1], Color(VERDE.darkened(0.15), 0.85 * alfa))
	draw_circle(Vector2.ZERO, 11.5, Color(VERDE.darkened(0.15), 0.85 * alfa))
	# Bolhinha que estufa e brilho: dá para ver que é mole e grudento.
	var bolha := 2.5 + 1.5 * sin(_tempo * 4.0)
	draw_circle(Vector2(4, -2), bolha, Color(VERDE.lightened(0.3), alfa))
	draw_circle(Vector2(-4, -4), 2.5, Color(1, 1, 1, 0.6 * alfa))
	draw_set_transform(Vector2.ZERO)
