extends Node2D
## Ondinha na água: dois anéis achatados que crescem e somem. Aparece quando
## alguém (até invisível) anda numa poça, fica parado nela ou anda numa ponte.

const DURACAO := 0.9
const COR := Color(0.92, 0.97, 1.0)

var tamanho := 1.0 # 1 = ondinha de quem anda; menor para quem está parado
var _tempo := 0.0


func _ready() -> void:
	z_index = -3 # na água, por baixo das pegadas e dos camaleões


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _tempo / DURACAO
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	for atraso in [0.0, 0.3]:
		var u := t - atraso
		if u <= 0.0:
			continue
		var raio := lerpf(4.0, 24.0, u) * tamanho
		draw_arc(Vector2.ZERO, raio, 0.0, TAU, 24, Color(COR, 0.7 * (1.0 - u)), 2.0, true)
	draw_set_transform(Vector2.ZERO)
