extends RefCounted
## Desenha um camaleão fofo só com formas (sem imagem): corpo redondo, olhos
## grandes de pálpebra caída, cauda em espiral e a mão apontando para onde ele mira.
## Inspirado no desenho em arte/referencia_camaleao.jpg.
## Tudo é desenhado virado para a direita e espelhado quando ele olha para a esquerda.

const CONTORNO := Color(0.08, 0.07, 0.1)
const LARGURA := 2.0
## Tamanho do desenho dentro do jogo (1.0 = umas 50 px de altura).
const ESCALA_JOGO := 1.2


## item: o nó que está desenhando (dentro do _draw dele).
## base: posição e escala do camaleão dentro do item.
## mira: direção para onde ele olha e aponta a mão.
## passo: fase da animação de andar (0 = parado).
static func desenhar(item: CanvasItem, base: Transform2D, cor: Color, mira: Vector2,
		olhando_direita: bool, passo: float) -> void:
	var lado := 1.0 if olhando_direita else -1.0
	var escuro := cor.darkened(0.3)
	var claro := cor.lightened(0.4)
	var mira_local := Vector2(mira.x * lado, mira.y).normalized()
	if mira_local == Vector2.ZERO:
		mira_local = Vector2.RIGHT

	# Sombra no chão: não pula junto quando ele anda.
	item.draw_set_transform_matrix(base)
	item.draw_colored_polygon(_elipse(Vector2(0, 21), Vector2(17, 5)), Color(0, 0, 0, 0.25))

	var pulo := -absf(sin(passo)) * 2.5
	var corpo := base * Transform2D(0.0, Vector2(lado, 1.0), 0.0, Vector2(0, pulo))
	item.draw_set_transform_matrix(corpo)

	_cauda(item, cor)
	_forma(item, _elipse(Vector2(-5, 19), Vector2(6, 3.5)), escuro) # pé de trás
	_forma(item, _elipse(Vector2(0, 5), Vector2(12, 14)), cor) # corpo
	item.draw_colored_polygon(_elipse(Vector2(4, 9), Vector2(6.5, 8.5)), claro) # barriga
	for i in 3: # listras nas costas
		item.draw_arc(Vector2(-3.0 + i, -2.0 + i * 6.0), 5.0, PI * 0.75, PI * 1.25, 6, escuro, 1.5, true)
	_forma(item, _elipse(Vector2(7, 19), Vector2(7, 3.5)), cor) # pé da frente

	# Crista atrás da cabeça (a cabeça cobre a parte de baixo dela).
	_forma(item, PackedVector2Array([
		Vector2(-8, -16), Vector2(-4, -24), Vector2(3, -25.5), Vector2(7, -21),
	]), escuro)
	_forma(item, _elipse(Vector2(5, -12), Vector2(13, 11)), cor) # cabeça
	_forma(item, _elipse(Vector2(16, -6.5), Vector2(6, 4.5)), cor) # beiço
	item.draw_polyline(PackedVector2Array([
		Vector2(9, -5), Vector2(13, -4), Vector2(18, -5.5), Vector2(21.5, -7),
	]), CONTORNO, 1.5, true) # sorriso

	_olho(item, Vector2(16, -15.5), 4.5, cor, mira_local) # olho de longe
	_olho(item, Vector2(5, -14), 6.5, cor, mira_local) # olho de perto

	# Braço e mão.
	var ombro := Vector2(3, 3)
	var mao := ombro + mira_local * 11.0
	item.draw_line(ombro, mao, CONTORNO, 6.5, true)
	item.draw_line(ombro, mao, cor, 3.5, true)
	item.draw_circle(mao, 4.2, CONTORNO)
	item.draw_circle(mao, 3.0, cor)

	item.draw_set_transform_matrix(Transform2D.IDENTITY)


## Onde sai a língua (o canto da boca), em relação ao centro do camaleão.
static func boca(olhando_direita: bool) -> Vector2:
	return Vector2(19.0 if olhando_direita else -19.0, -6.0) * ESCALA_JOGO


static func _cauda(item: CanvasItem, cor: Color) -> void:
	# Um "tubo" de bolinhas que vai afinando enquanto enrola.
	var centro := Vector2(-19, 9)
	var pontos: Array = []
	var quantidade := 60
	for i in quantidade:
		var t := float(i) / (quantidade - 1)
		var angulo := 0.43 + t * 1.25 * TAU
		var raio_espiral := lerpf(13.0, 3.5, t)
		pontos.append([centro + Vector2.from_angle(angulo) * raio_espiral, lerpf(3.2, 1.6, t)])
	for p in pontos:
		item.draw_circle(p[0], p[1] + 1.1, CONTORNO)
	for p in pontos:
		item.draw_circle(p[0], p[1], cor)


static func _olho(item: CanvasItem, centro: Vector2, raio: float, cor: Color, mira: Vector2) -> void:
	item.draw_circle(centro, raio, Color.WHITE)
	var pupila := centro + mira * raio * 0.32 + Vector2(0, raio * 0.15)
	item.draw_circle(pupila, raio * 0.48, CONTORNO)
	item.draw_circle(pupila + Vector2(-raio * 0.15, -raio * 0.18), raio * 0.14, Color.WHITE)
	# Pálpebra caída: cobre o topo do olho com a cor da pele.
	var palpebra := PackedVector2Array()
	for i in 9:
		palpebra.append(centro + Vector2.from_angle(lerpf(PI + 0.25, TAU - 0.25, i / 8.0)) * raio)
	item.draw_colored_polygon(palpebra, cor)
	item.draw_line(palpebra[0], palpebra[8], CONTORNO, 1.5, true)
	item.draw_arc(centro, raio, 0.0, TAU, 20, CONTORNO, LARGURA, true)


static func _forma(item: CanvasItem, pontos: PackedVector2Array, cor: Color) -> void:
	item.draw_colored_polygon(pontos, cor)
	var fechado := pontos.duplicate()
	fechado.append(pontos[0])
	item.draw_polyline(fechado, CONTORNO, LARGURA, true)


static func _elipse(centro: Vector2, raio: Vector2, lados := 20) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for i in lados:
		var angulo := TAU * i / lados
		pontos.append(centro + Vector2(cos(angulo) * raio.x, sin(angulo) * raio.y))
	return pontos
