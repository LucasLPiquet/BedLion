extends Node2D
## Manchas de sol no chão ("luz" em mapas.gd). Dentro delas, quem está invisível
## continua sem corpo, mas a sombra aparece no chão. Os camaleões visíveis já
## desenham a própria sombra (desenho_camaleao.gd).

const Mapas := preload("res://scripts/mapas.gd")

const COR_SOL := Color(1.0, 0.95, 0.7)
## Sombra do invisível: mesmo lugar e tamanho da sombra do desenho do camaleão.
const POSICAO_SOMBRA := Vector2(0, 25)
const TAMANHO_SOMBRA := Vector2(20, 6)
const FORCA_SOMBRA := 0.32
## Quanto tempo a sombra leva para aparecer ou sumir quando ele entra ou sai do sol.
const TEMPO_TRANSICAO := 0.15

var mapa: Dictionary = {}
var _sombras: Dictionary = {} # camaleão -> força atual da sombra (0 a 1)
var _poeira: Array = [] # [posição, fase, velocidade] grãozinhos brilhando no sol
var _tempo := 0.0


func _ready() -> void:
	z_index = -8 # por cima do chão e da água, por baixo dos camaleões
	for item in mapa.get("luz", []):
		var retangulo: Rect2 = item
		for i in int(retangulo.get_area() / 7000.0) + 2:
			_poeira.append([Vector2(randf_range(retangulo.position.x, retangulo.end.x),
				randf_range(retangulo.position.y, retangulo.end.y)), randf() * TAU, randf_range(4.0, 10.0)])
	set_process(not mapa.get("luz", []).is_empty())


func _process(delta: float) -> void:
	_tempo += delta
	var vistos: Dictionary = {}
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if not camaleao.vivo:
			continue
		vistos[camaleao] = true
		var quer := 1.0 if camaleao.invisivel and Mapas.na_luz(mapa, camaleao.position + POSICAO_SOMBRA) else 0.0
		_sombras[camaleao] = move_toward(_sombras.get(camaleao, 0.0), quer, delta / TEMPO_TRANSICAO)
	for camaleao in _sombras.keys():
		if not vistos.has(camaleao):
			_sombras.erase(camaleao)
	queue_redraw()


func _draw() -> void:
	# Sol: retângulos de cantos redondos uns dentro dos outros, para a borda ficar macia.
	for item in mapa.get("luz", []):
		var retangulo: Rect2 = item
		for passo in 4:
			var forma := retangulo.grow(-passo * 10.0)
			if forma.size.x <= 0.0 or forma.size.y <= 0.0:
				break
			var estilo := StyleBoxFlat.new()
			estilo.bg_color = Color(COR_SOL, 0.13)
			estilo.set_corner_radius_all(int(minf(forma.size.x, forma.size.y) / 3.0))
			estilo.corner_detail = 12
			estilo.anti_aliasing = true
			estilo.draw(get_canvas_item(), forma)
	# Poeirinha brilhando, subindo devagar.
	for grao in _poeira:
		var fase: float = grao[1]
		var brilho := maxf(0.0, sin(_tempo * 1.3 + fase))
		if brilho > 0.05:
			var ponto: Vector2 = grao[0] + Vector2(sin(_tempo * 0.6 + fase) * 6.0, -fmod(_tempo * grao[2] + fase * 10.0, 30.0))
			draw_circle(ponto, 1.6, Color(1, 1, 0.9, 0.5 * brilho))
	# Sombras dos invisíveis que estão no sol.
	for camaleao in _sombras:
		var forca: float = _sombras[camaleao]
		if forca <= 0.0 or not is_instance_valid(camaleao):
			continue
		draw_set_transform(camaleao.position + POSICAO_SOMBRA, 0.0, Vector2(1.0, TAMANHO_SOMBRA.y / TAMANHO_SOMBRA.x))
		draw_circle(Vector2.ZERO, TAMANHO_SOMBRA.x, Color(0, 0, 0, FORCA_SOMBRA * forca))
		draw_set_transform(Vector2.ZERO)
