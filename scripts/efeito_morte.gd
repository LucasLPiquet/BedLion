extends Node2D
## "Puf" de fumaça na cor do camaleão quando ele morre.

const DURACAO := 0.45

var cor := Color.WHITE
var _tempo := 0.0
var _bolinhas: Array = [] # [direção, tamanho]


func _ready() -> void:
	z_index = 1
	for i in 8:
		_bolinhas.append([Vector2.from_angle(TAU * i / 8.0 + randf_range(-0.3, 0.3)), randf_range(6.0, 10.0)])


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _tempo / DURACAO
	for bolinha in _bolinhas:
		var centro: Vector2 = bolinha[0] * lerpf(6.0, 34.0, t)
		var tamanho: float = bolinha[1] * (1.0 - t * 0.7)
		draw_circle(centro, tamanho, Color(cor.lightened(0.3), 1.0 - t))
	draw_circle(Vector2.ZERO, 14.0 * (1.0 - t), Color(1, 1, 1, 0.8 * (1.0 - t)))
