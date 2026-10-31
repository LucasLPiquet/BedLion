extends Node2D
## Texto curto que sobe e some (o nome do poder quando alguém pega).

const DURACAO := 1.1

var texto := ""
var cor := Color.WHITE
var _tempo := 0.0


func _ready() -> void:
	z_index = 2


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _tempo / DURACAO
	var fonte := ThemeDB.fallback_font
	var tamanho := 18
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var onde := Vector2(-largura / 2.0, -58.0 - t * 22.0)
	var alfa := 1.0 - maxf(0.0, t - 0.6) / 0.4
	draw_string_outline(fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 5, Color(0.08, 0.07, 0.1, alfa))
	draw_string(fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, Color(cor, alfa))
