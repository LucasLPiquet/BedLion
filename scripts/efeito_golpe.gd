extends Node2D
## Anel rápido do golpe corpo a corpo, do tamanho do alcance. Fica no mundo
## (não no camaleão), então aparece mesmo quando quem golpeou está invisível.

const DURACAO := 0.2

var alcance := 75.0
var acertou := false
var _tempo := 0.0


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _tempo / DURACAO
	var cor := Color(1.0, 0.3, 0.3) if acertou else Color(1.0, 1.0, 1.0)
	cor.a = 0.8 * (1.0 - t)
	draw_arc(Vector2.ZERO, alcance * lerpf(0.5, 1.0, t), 0.0, TAU, 32, cor, 3.0)
