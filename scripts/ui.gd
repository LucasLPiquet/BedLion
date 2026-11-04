extends RefCounted
## Peças das telas fora da arena (menu, lobby e configurações): fundo com o
## mapa Jardim escurecido, rótulos com contorno e botões no mesmo estilo.
## Tudo montado por código, como a arena.

const Cenario := preload("res://scripts/cenario.gd")
const Mapas := preload("res://scripts/mapas.gd")

const TAMANHO := Vector2(1600, 900)
const CONTORNO := Color(0.08, 0.07, 0.1)
const AMARELO := Color(1.0, 0.92, 0.6)
const COR_BOTAO := Color(0.16, 0.3, 0.14)
const COR_BOTAO_FOCO := Color(0.33, 0.58, 0.24)
const COR_PAINEL := Color(0.06, 0.1, 0.06, 0.78)


## Põe o mapa Jardim de fundo (só o desenho) com uma película escura por cima.
static func fundo(pai: Node) -> void:
	var cenario := Cenario.new()
	cenario.tamanho = TAMANHO
	cenario.espessura = 40.0
	cenario.mapa = Mapas.MAPAS[0]
	pai.add_child(cenario)
	var pelicula := ColorRect.new()
	pelicula.color = Color(0.02, 0.05, 0.02, 0.55)
	pelicula.size = TAMANHO
	pelicula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(pelicula)


static func rotulo(texto: String, tamanho_fonte: int, posicao: Vector2, largura := TAMANHO.x) -> Label:
	var novo := Label.new()
	novo.text = texto
	novo.position = posicao
	novo.size = Vector2(largura, tamanho_fonte * 1.6)
	novo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	novo.add_theme_font_size_override("font_size", tamanho_fonte)
	novo.add_theme_constant_override("outline_size", maxi(4, tamanho_fonte / 5))
	novo.add_theme_color_override("font_outline_color", CONTORNO)
	novo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return novo


static func botao(texto: String, tamanho: Vector2, tamanho_fonte := 34) -> Button:
	var novo := Button.new()
	novo.text = texto
	novo.custom_minimum_size = tamanho
	novo.size = tamanho
	novo.add_theme_font_size_override("font_size", tamanho_fonte)
	novo.add_theme_constant_override("outline_size", 6)
	novo.add_theme_color_override("font_outline_color", CONTORNO)
	novo.add_theme_stylebox_override("normal", _estilo(COR_BOTAO, Color(0, 0, 0, 0.6)))
	novo.add_theme_stylebox_override("hover", _estilo(COR_BOTAO_FOCO, Color(0, 0, 0, 0.6)))
	novo.add_theme_stylebox_override("pressed", _estilo(COR_BOTAO_FOCO.darkened(0.2), Color(0, 0, 0, 0.6)))
	novo.add_theme_stylebox_override("focus", _estilo(COR_BOTAO_FOCO, AMARELO))
	novo.add_theme_stylebox_override("disabled", _estilo(Color(0.2, 0.2, 0.2, 0.6), Color(0, 0, 0, 0.4)))
	return novo


static func painel(retangulo: Rect2, cor_borda := Color(0, 0, 0, 0.6)) -> Panel:
	var novo := Panel.new()
	novo.position = retangulo.position
	novo.size = retangulo.size
	novo.add_theme_stylebox_override("panel", _estilo(COR_PAINEL, cor_borda))
	novo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return novo


static func _estilo(cor: Color, borda: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)
	estilo.content_margin_left = 16.0
	estilo.content_margin_right = 16.0
	return estilo
