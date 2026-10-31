extends Node2D
## Desenha o mapa: chão de ladrilhos com musgo, cerca viva em volta, blocos de
## pedra, água com pontes e enfeites (tufos de grama, flores, pedrinhas). É só
## visual: as colisões das paredes são criadas em main.gd e quem afunda na água
## é conferido em camaleao.gd. Tudo sorteado com a semente do mapa (mapas.gd),
## então cada mapa fica sempre igual.

const Mapas := preload("res://scripts/mapas.gd")

const LADRILHO := 64.0
const COR_CHAO_A := Color(0.80, 0.71, 0.53)
const COR_CHAO_B := Color(0.76, 0.67, 0.50)
const COR_REJUNTE := Color(0.63, 0.54, 0.40)
const COR_GRAMA := Color(0.47, 0.63, 0.30)
const COR_CERCA := Color(0.20, 0.45, 0.22)
const COR_PEDRA := Color(0.62, 0.60, 0.56)
const COR_CONTORNO := Color(0.12, 0.1, 0.1)
const ALTURA_PEDRA := 12.0 # faixa mais escura embaixo que dá ideia de altura
const CORES_FLORES := [Color(1.0, 0.95, 0.85), Color(1.0, 0.85, 0.3), Color(0.95, 0.5, 0.6), Color(0.7, 0.6, 1.0)]
const COR_BEIRADA := Color(0.58, 0.50, 0.33) # terra molhada em volta da água
const COR_AGUA_FUNDA := Color(0.16, 0.42, 0.62)
const COR_AGUA := Color(0.25, 0.58, 0.78)
const COR_AGUA_RASA := Color(0.38, 0.70, 0.85)
const COR_FOLHA_LAGO := Color(0.35, 0.62, 0.28)
const COR_MADEIRA := Color(0.62, 0.42, 0.24)
const LARGURA_BEIRADA := 10.0

var tamanho := Vector2(1280, 720)
var espessura := 32.0
var mapa: Dictionary = {} # um dos mapas de mapas.gd
var obstaculos: Array = [] # Rect2 dos blocos do meio (vêm do mapa)
var aguas: Array = [] # Rect2 dos lagos e rios
var pontes: Array = [] # Rect2 das pontes


func _ready() -> void:
	z_index = -10
	obstaculos = mapa.get("paredes", [])
	aguas = mapa.get("agua", [])
	pontes = mapa.get("pontes", [])


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = mapa.get("semente", 7)
	_desenhar_chao(rng)
	_desenhar_musgo(rng)
	_desenhar_agua(rng)
	_desenhar_enfeites(rng)
	for ponte in pontes:
		_desenhar_ponte(ponte)
	for retangulo in obstaculos:
		_desenhar_bloco(retangulo, rng)
	_desenhar_cerca(rng)


func _desenhar_chao(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(Vector2.ZERO, tamanho), COR_REJUNTE)
	for coluna in ceili(tamanho.x / LADRILHO):
		for linha in ceili(tamanho.y / LADRILHO):
			var cor: Color = COR_CHAO_A if (coluna + linha) % 2 == 0 else COR_CHAO_B
			cor = cor.lightened(rng.randf_range(-0.04, 0.04))
			var ladrilho := Rect2(coluna * LADRILHO + 1.5, linha * LADRILHO + 1.5, LADRILHO - 3.0, LADRILHO - 3.0)
			draw_rect(ladrilho, cor)
			draw_line(ladrilho.position, Vector2(ladrilho.end.x, ladrilho.position.y), cor.lightened(0.08), 2.0)
			if rng.randf() < 0.15: # rachadura
				var inicio := ladrilho.position + Vector2(rng.randf_range(8, 56), rng.randf_range(8, 56))
				var meio := inicio + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12))
				var fim := meio + Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10))
				draw_polyline(PackedVector2Array([inicio, meio, fim]), COR_REJUNTE, 1.5, true)


func _desenhar_musgo(rng: RandomNumberGenerator) -> void:
	# Manchas de grama: grupos de bolinhas verdes, mais comuns perto da cerca.
	var centros: Array = []
	for i in int(14 * _proporcao_area()):
		centros.append(Vector2(rng.randf_range(0, tamanho.x), rng.randf_range(0, tamanho.y)))
	for x in range(0, int(tamanho.x), 90):
		centros.append(Vector2(x + rng.randf_range(0, 40), espessura + 6))
		centros.append(Vector2(x + rng.randf_range(0, 40), tamanho.y - espessura - 6))
	for y in range(0, int(tamanho.y), 90):
		centros.append(Vector2(espessura + 6, y + rng.randf_range(0, 40)))
		centros.append(Vector2(tamanho.x - espessura - 6, y + rng.randf_range(0, 40)))
	for centro in centros:
		for i in rng.randi_range(4, 8):
			var deslocamento := Vector2(rng.randf_range(-30, 30), rng.randf_range(-18, 18))
			var cor := COR_GRAMA.lightened(rng.randf_range(-0.06, 0.06))
			draw_circle(centro + deslocamento, rng.randf_range(10, 22), Color(cor, 0.8))


func _desenhar_enfeites(rng: RandomNumberGenerator) -> void:
	var colocados := 0
	var tentativas := 0
	var total := int(90 * _proporcao_area())
	while colocados < total and tentativas < 2000:
		tentativas += 1
		var ponto := Vector2(rng.randf_range(espessura + 10, tamanho.x - espessura - 10),
			rng.randf_range(espessura + 10, tamanho.y - espessura - 10))
		if _dentro_de_obstaculo(ponto, 12.0) or not Mapas.lugar_livre(mapa, ponto, LARGURA_BEIRADA + 4.0):
			continue
		colocados += 1
		var sorteio := rng.randf()
		if sorteio < 0.45:
			_tufo(ponto, rng)
		elif sorteio < 0.75:
			_flor(ponto, rng)
		else:
			_pedrinha(ponto, rng)


func _tufo(ponto: Vector2, rng: RandomNumberGenerator) -> void:
	var cor := COR_GRAMA.darkened(rng.randf_range(0.15, 0.35))
	for i in 3:
		var base := ponto + Vector2((i - 1) * 3.0, 0)
		var ponta := base + Vector2((i - 1) * 4.0 + rng.randf_range(-1.5, 1.5), -rng.randf_range(6, 11))
		draw_line(base, ponta, cor, 2.0, true)


func _flor(ponto: Vector2, rng: RandomNumberGenerator) -> void:
	var cor: Color = CORES_FLORES[rng.randi() % CORES_FLORES.size()]
	var giro := rng.randf() * TAU
	for i in 5:
		draw_circle(ponto + Vector2.from_angle(giro + TAU * i / 5.0) * 3.5, 2.6, cor)
	draw_circle(ponto, 2.0, Color(0.95, 0.7, 0.2))


func _pedrinha(ponto: Vector2, rng: RandomNumberGenerator) -> void:
	var raio := Vector2(rng.randf_range(3, 6), rng.randf_range(2, 4))
	draw_set_transform(ponto, 0.0, raio / raio.x)
	draw_circle(Vector2(0, 1.5), raio.x, Color(0, 0, 0, 0.15))
	draw_circle(Vector2.ZERO, raio.x, COR_PEDRA.darkened(rng.randf_range(0.0, 0.25)))
	draw_circle(Vector2(-raio.x * 0.3, -raio.x * 0.3), raio.x * 0.35, Color(1, 1, 1, 0.3))
	draw_set_transform(Vector2.ZERO)


## Lagos e rios: beirada de terra, borda funda, água e uma parte mais rasa no
## meio, com folhas de vitória-régia e ondinhas. Cada camada é desenhada para
## todos os pedaços de água antes da próxima, então pedaços que se encostam
## viram uma água só. O brilho que se mexe fica em agua.gd.
func _desenhar_agua(rng: RandomNumberGenerator) -> void:
	for camada in [[LARGURA_BEIRADA, COR_BEIRADA], [0.0, COR_AGUA_FUNDA], [-8.0, COR_AGUA], [-26.0, COR_AGUA_RASA]]:
		for agua in aguas:
			_forma_arredondada(agua, camada[0], camada[1])
	for agua in aguas:
		var retangulo: Rect2 = agua
		# Ondinhas paradas (arquinhos claros).
		for i in int(retangulo.get_area() / 9000.0) + 2:
			var ponto := _ponto_na_agua(retangulo, rng, 24.0)
			if ponto != Vector2.INF:
				draw_arc(ponto, rng.randf_range(7, 12), PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.25), 2.0, true)
		# Folhas de vitória-régia: um círculo verde com um "corte" em fatia.
		for i in int(retangulo.get_area() / 30000.0) + 1:
			var ponto := _ponto_na_agua(retangulo, rng, 30.0)
			if ponto == Vector2.INF:
				continue
			var raio := rng.randf_range(9, 14)
			var giro := rng.randf() * TAU
			draw_circle(ponto, raio + 1.5, COR_FOLHA_LAGO.darkened(0.45))
			draw_circle(ponto, raio, COR_FOLHA_LAGO.lightened(rng.randf_range(-0.05, 0.1)))
			var corte := PackedVector2Array([ponto, ponto + Vector2.from_angle(giro - 0.35) * (raio + 2.0),
				ponto + Vector2.from_angle(giro + 0.35) * (raio + 2.0)])
			draw_colored_polygon(corte, COR_AGUA)
			if rng.randf() < 0.4: # florzinha
				draw_circle(ponto + Vector2.from_angle(giro + PI) * raio * 0.4, 3.5, Color(1.0, 0.75, 0.85))
				draw_circle(ponto + Vector2.from_angle(giro + PI) * raio * 0.4, 1.5, Color(1.0, 0.9, 0.4))


## Um ponto sorteado dentro do pedaço de água, longe da beirada ("folga" px),
## fora das pontes e fora da cerca. Vector2.INF se não achar.
func _ponto_na_agua(retangulo: Rect2, rng: RandomNumberGenerator, folga: float) -> Vector2:
	var dentro := Rect2(Vector2.ONE * (espessura + 30.0), tamanho - Vector2.ONE * (espessura + 30.0) * 2.0)
	for _tentativa in 30:
		var ponto := Vector2(rng.randf_range(retangulo.position.x, retangulo.end.x),
			rng.randf_range(retangulo.position.y, retangulo.end.y))
		if dentro.has_point(ponto) and Mapas.dentro_arredondado(retangulo, ponto, folga) \
				and Mapas.na_agua(mapa, ponto) and not _perto_de_ponte(ponto, 20.0):
			return ponto
	return Vector2.INF


func _perto_de_ponte(ponto: Vector2, folga: float) -> bool:
	for ponte in pontes:
		var retangulo: Rect2 = ponte
		if retangulo.grow(folga).has_point(ponto):
			return true
	return false


## Retângulo de cantos bem redondos (mesmo formato que mapas.gd usa para a água),
## aumentado (crescer > 0) ou diminuído (crescer < 0).
func _forma_arredondada(retangulo: Rect2, crescer: float, cor: Color) -> void:
	var forma := retangulo.grow(crescer)
	if forma.size.x <= 0.0 or forma.size.y <= 0.0:
		return
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(int(Mapas.curva(forma)))
	estilo.corner_detail = 16
	estilo.anti_aliasing = true
	estilo.draw(get_canvas_item(), forma)


## Ponte de tábuas. As tábuas ficam atravessadas no sentido de quem anda nela.
func _desenhar_ponte(retangulo: Rect2) -> void:
	var deitada := retangulo.size.x >= retangulo.size.y # anda-se na horizontal
	# Sombra na água.
	draw_rect(Rect2(retangulo.position + Vector2(5, 8), retangulo.size), Color(0, 0, 0, 0.25))
	# Postes nos quatro cantos.
	for canto in [retangulo.position, Vector2(retangulo.end.x, retangulo.position.y),
			Vector2(retangulo.position.x, retangulo.end.y), retangulo.end]:
		draw_circle(canto, 8.0, COR_CONTORNO)
		draw_circle(canto, 6.0, COR_MADEIRA.darkened(0.35))
	_caixa_reta(retangulo, COR_MADEIRA, 2)
	# Tábuas.
	var largura_tabua := 18.0
	if deitada:
		var x := retangulo.position.x + largura_tabua
		while x < retangulo.end.x - 4.0:
			draw_line(Vector2(x, retangulo.position.y + 2), Vector2(x, retangulo.end.y - 2), COR_MADEIRA.darkened(0.3), 2.0)
			x += largura_tabua
	else:
		var y := retangulo.position.y + largura_tabua
		while y < retangulo.end.y - 4.0:
			draw_line(Vector2(retangulo.position.x + 2, y), Vector2(retangulo.end.x - 2, y), COR_MADEIRA.darkened(0.3), 2.0)
			y += largura_tabua
	# Corrimãos (faixas mais escuras nas laterais compridas).
	var grossura := 7.0
	var lados: Array = []
	if deitada:
		lados = [Rect2(retangulo.position, Vector2(retangulo.size.x, grossura)),
			Rect2(retangulo.position.x, retangulo.end.y - grossura, retangulo.size.x, grossura)]
	else:
		lados = [Rect2(retangulo.position, Vector2(grossura, retangulo.size.y)),
			Rect2(retangulo.end.x - grossura, retangulo.position.y, grossura, retangulo.size.y)]
	for lado in lados:
		_caixa_reta(lado, COR_MADEIRA.darkened(0.25), 2)


func _caixa_reta(retangulo: Rect2, cor: Color, borda: int) -> void:
	draw_rect(retangulo, cor)
	draw_rect(retangulo, COR_CONTORNO, false, borda)


func _desenhar_bloco(retangulo: Rect2, rng: RandomNumberGenerator) -> void:
	# Sombra no chão.
	_caixa(Rect2(retangulo.position + Vector2(6, 8), retangulo.size), Color(0, 0, 0, 0.22), 0)
	# Lateral (mais escura) e topo (mais claro), os dois com contorno.
	_caixa(retangulo, COR_PEDRA.darkened(0.35), 2)
	var topo := Rect2(retangulo.position, retangulo.size - Vector2(0, ALTURA_PEDRA))
	_caixa(topo, COR_PEDRA, 2)
	# Juntas das pedras no topo, como um muro de tijolos.
	var linha_cor := COR_PEDRA.darkened(0.2)
	var altura_fiada := 20.0
	var fiada := 0
	var y := topo.position.y + altura_fiada
	while y < topo.end.y - 4.0:
		draw_line(Vector2(topo.position.x + 3, y), Vector2(topo.end.x - 3, y), linha_cor, 1.5)
		fiada += 1
		y += altura_fiada
	for f in fiada + 1:
		var y0 := topo.position.y + f * altura_fiada
		var y1 := minf(y0 + altura_fiada, topo.end.y)
		var x := topo.position.x + (14.0 if f % 2 == 0 else 28.0)
		while x < topo.end.x - 6.0:
			draw_line(Vector2(x, y0 + 2), Vector2(x, y1 - 2), linha_cor, 1.5)
			x += 28.0
	# Musgo escorrendo nos cantos de cima.
	for i in rng.randi_range(3, 6):
		var canto := retangulo.position + Vector2(rng.randf_range(0, retangulo.size.x), rng.randf_range(0, 8))
		draw_circle(canto, rng.randf_range(4, 8), Color(COR_GRAMA.darkened(0.1), 0.9))


func _desenhar_cerca(rng: RandomNumberGenerator) -> void:
	var e := espessura
	var faixas := [
		Rect2(0, 0, tamanho.x, e), Rect2(0, tamanho.y - e, tamanho.x, e),
		Rect2(0, 0, e, tamanho.y), Rect2(tamanho.x - e, 0, e, tamanho.y),
	]
	for faixa in faixas:
		draw_rect(faixa, COR_CERCA.darkened(0.3))
	# Folhagem: bolinhas ao longo da borda de dentro. Primeiro os contornos,
	# depois as cores, para virar uma moita só.
	var folhas: Array = []
	for x in range(0, int(tamanho.x) + 20, 20):
		folhas.append(Vector2(x, e - 6 + rng.randf_range(-3, 3)))
		folhas.append(Vector2(x, tamanho.y - e + 6 + rng.randf_range(-3, 3)))
	for y in range(0, int(tamanho.y) + 20, 20):
		folhas.append(Vector2(e - 6 + rng.randf_range(-3, 3), y))
		folhas.append(Vector2(tamanho.x - e + 6 + rng.randf_range(-3, 3), y))
	var raios: Array = []
	for folha in folhas:
		raios.append(rng.randf_range(11, 15))
	for i in folhas.size():
		draw_circle(folhas[i], raios[i] + 2.0, COR_CONTORNO)
	for i in folhas.size():
		draw_circle(folhas[i], raios[i], COR_CERCA.lightened(rng.randf_range(-0.05, 0.08)))
	for i in folhas.size():
		draw_circle(folhas[i] + Vector2(-3, -4), raios[i] * 0.45, Color(1, 1, 1, 0.12))
		if rng.randf() < 0.08: # frutinha
			draw_circle(folhas[i] + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)), 2.5, Color(0.9, 0.25, 0.3))


func _caixa(retangulo: Rect2, cor: Color, borda: int) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(8)
	estilo.set_border_width_all(borda)
	estilo.border_color = COR_CONTORNO
	estilo.anti_aliasing = true
	estilo.draw(get_canvas_item(), retangulo)


## Quantas vezes a arena é maior que a original (1280 x 720), para espalhar
## a mesma quantidade de enfeites por pedaço de chão.
func _proporcao_area() -> float:
	return tamanho.x * tamanho.y / (1280.0 * 720.0)


func _dentro_de_obstaculo(ponto: Vector2, folga: float) -> bool:
	for item in obstaculos:
		var retangulo: Rect2 = item
		if retangulo.grow(folga).has_point(ponto):
			return true
	return false
