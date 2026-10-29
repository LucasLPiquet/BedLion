extends Node2D
## Uma pegada de camaleão com o pé sujo de cocô de pombo. Some sozinha depois
## de DURACAO segundos. Desenhada apontando para a direita (+x); quem cria
## gira ela para o lado em que o camaleão andava.

const DURACAO := 3.0
const COR := Color(0.36, 0.33, 0.2, 0.8)

var _tempo := 0.0


func _ready() -> void:
	z_index = -2 # no chão, por baixo dos camaleões e dos upgrades


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	modulate.a = 1.0 - _tempo / DURACAO # vai apagando


func _draw() -> void:
	# Sola redonda e três dedinhos em leque para a frente.
	draw_circle(Vector2.ZERO, 3.5, COR)
	for angulo in [-0.6, 0.0, 0.6]:
		var dedo := Vector2.from_angle(angulo) * 6.0
		draw_line(Vector2.ZERO, dedo, COR, 2.0, true)
		draw_circle(dedo, 1.8, COR)
