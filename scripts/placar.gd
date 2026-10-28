extends Control
## Placar no topo da tela: para cada jogador, um camaleãozinho na cor dele,
## o nome e uma bolinha por ponto (preenchida quando ele já ganhou aquele ponto).

const Desenho := preload("res://scripts/desenho_camaleao.gd")

var jogadores: Array = [] # cada um: {"nome": String, "cor": Color}
var pontos: Array = []
var meta := 5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func atualizar(novos_jogadores: Array, novos_pontos: Array, nova_meta: int) -> void:
	jogadores = novos_jogadores
	pontos = novos_pontos
	meta = nova_meta
	queue_redraw()


func _draw() -> void:
	if jogadores.is_empty():
		return
	var largura_item := 120.0 + meta * 16.0
	var total := largura_item * jogadores.size()
	var inicio := (size.x - total) / 2.0

	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.05, 0.08, 0.05, 0.6)
	fundo.set_corner_radius_all(14)
	fundo.draw(get_canvas_item(), Rect2(inicio - 8.0, 2.0, total + 8.0, 44.0))

	var fonte := ThemeDB.fallback_font
	for i in jogadores.size():
		var jogador: Dictionary = jogadores[i]
		var cor: Color = jogador["cor"]
		var x := inicio + i * largura_item
		Desenho.desenhar(self, Transform2D(0.0, Vector2(0.55, 0.55), 0.0, Vector2(x + 22.0, 26.0)),
			cor, Vector2.RIGHT, true, 0.0)
		draw_string(fonte, Vector2(x + 42.0, 30.0), jogador["nome"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		for p in meta:
			var centro := Vector2(x + 112.0 + p * 16.0, 24.0)
			draw_circle(centro, 6.5, Color(0, 0, 0, 0.6))
			draw_circle(centro, 5.0, cor if p < pontos[i] else Color(1, 1, 1, 0.15))
