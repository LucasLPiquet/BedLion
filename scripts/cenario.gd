extends Node2D
## Desenha o mapa: chão de ladrilhos com musgo, cerca viva em volta, blocos de
## pedra e enfeites (tufos de grama, flores, pedrinhas). É só visual: as
## colisões das paredes são criadas em main.gd. Tudo sorteado com uma semente
## fixa, então o mapa fica sempre igual.

const LADRILHO := 64.0
const SEMENTE := 7
const COR_CHAO_A := Color(0.80, 0.71, 0.53)
const COR_CHAO_B := Color(0.76, 0.67, 0.50)
const COR_REJUNTE := Color(0.63, 0.54, 0.40)
const COR_GRAMA := Color(0.47, 0.63, 0.30)
const COR_CERCA := Color(0.20, 0.45, 0.22)
const COR_PEDRA := Color(0.62, 0.60, 0.56)
const COR_CONTORNO := Color(0.12, 0.1, 0.1)
const ALTURA_PEDRA := 12.0 # faixa mais escura embaixo que dá ideia de altura
const CORES_FLORES := [Color(1.0, 0.95, 0.85), Color(1.0, 0.85, 0.3), Color(0.95, 0.5, 0.6), Color(0.7, 0.6, 1.0)]

var tamanho := Vector2(1280, 720)
var espessura := 32.0
var obstaculos: Array = [] # Rect2 dos blocos do meio


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE
	_desenhar_chao(rng)
	_desenhar_musgo(rng)
	_desenhar_enfeites(rng)
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
		if _dentro_de_obstaculo(ponto, 12.0):
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
