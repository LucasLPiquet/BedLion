extends Node2D
## Brilhinhos que piscam na água, para ela parecer viva. É só enfeite: o
## desenho parado da água fica em cenario.gd e quem afunda é conferido em camaleao.gd.

const Mapas := preload("res://scripts/mapas.gd")

## Quantos brilhos por pedaço de água (a cada tantos pixels quadrados).
const AREA_POR_BRILHO := 6000.0

var mapa: Dictionary = {}
var tamanho := Vector2(1600, 900)
var espessura := 40.0
var _brilhos: Array = [] # cada um: [posição, fase, tamanho]
var _tempo := 0.0


func _ready() -> void:
	z_index = -9 # por cima do chão (cenario.gd), por baixo de todo o resto
	# Longe da cerca, para o brilho não aparecer por cima das folhas.
	var dentro := Rect2(Vector2.ONE * (espessura + 30.0), tamanho - Vector2.ONE * (espessura + 30.0) * 2.0)
	for agua in mapa.get("agua", []):
		var retangulo: Rect2 = agua
		for i in int(retangulo.get_area() / AREA_POR_BRILHO):
			var ponto := Vector2(randf_range(retangulo.position.x, retangulo.end.x),
				randf_range(retangulo.position.y, retangulo.end.y))
			if dentro.has_point(ponto) and Mapas.na_agua(mapa, ponto, 16.0) and not _perto_de_ponte(ponto):
				_brilhos.append([ponto, randf() * TAU, randf_range(4.0, 8.0)])
	set_process(not _brilhos.is_empty())


func _perto_de_ponte(ponto: Vector2) -> bool:
	for ponte in mapa.get("pontes", []):
		var retangulo: Rect2 = ponte
		if retangulo.grow(16.0).has_point(ponto):
			return true
	return false


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()


func _draw() -> void:
	for brilho in _brilhos:
		var ponto: Vector2 = brilho[0]
		var fase: float = brilho[1]
		var largura: float = brilho[2]
		# Cada brilho acende e apaga devagar, cada um no seu tempo.
		var forca := maxf(0.0, sin(_tempo * 1.6 + fase))
		if forca <= 0.05:
			continue
		var balanco := Vector2(sin(_tempo * 0.8 + fase) * 3.0, 0)
		draw_line(ponto + balanco - Vector2(largura, 0), ponto + balanco + Vector2(largura, 0),
			Color(1, 1, 1, 0.45 * forca), 2.0, true)
