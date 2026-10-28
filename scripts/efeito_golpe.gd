extends Node2D
## Risco rápido do golpe corpo a corpo: um arco na frente do camaleão, do
## tamanho do alcance e da abertura do golpe. Vermelho quando acerta alguém.

const DURACAO := 0.15

var direcao := Vector2.RIGHT
var alcance := 70.0
var abertura := 1.3 # radianos para cada lado da direção
var acertou := false
var _tempo := 0.0


func _ready() -> void:
	z_index = 1


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _tempo / DURACAO
	var cor := Color(1.0, 0.3, 0.3) if acertou else Color(1.0, 1.0, 1.0)
	cor.a = 0.9 * (1.0 - t)
	var centro := direcao.angle()
	# O risco "varre" de um lado para o outro enquanto some.
	var inicio := centro - abertura
	var fim := lerpf(centro - abertura * 0.3, centro + abertura, minf(t * 2.0, 1.0))
	draw_arc(Vector2.ZERO, alcance * 0.8, inicio, fim, 16, cor, 6.0, true)
	draw_arc(Vector2.ZERO, alcance * 0.55, inicio, fim, 16, Color(cor, cor.a * 0.5), 3.0, true)
