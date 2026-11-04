extends RefCounted
## Caminhos pelo mapa para os bots (bot.gd). O chão vira uma grade de
## quadradinhos; os que caem em parede (com folga do corpo do camaleão), na
## cerca ou na água ficam bloqueados (pontes não). Com isso o bot acha o
## caminho em volta de uma parede ou de um rio, em vez de ficar empurrando a
## parede de um lado para o outro.
## A grade de cada mapa é montada uma vez só e fica guardada.

const Mapas := preload("res://scripts/mapas.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

const TAMANHO_ARENA := Vector2(1600, 900)
const CERCA := 40.0
const CELULA := 30.0
## Folga em volta das paredes: o raio do camaleão (18) e mais um pouco.
const FOLGA_PAREDE := 22.0
## Folga em volta da água (além da beirada que já não afunda).
const FOLGA_AGUA := 10.0
## Os pés (o ponto que afunda) ficam um pouco abaixo do centro.
const PES := Desenho.PES

static var _grades: Dictionary = {} # nome do mapa -> AStarGrid2D


static func grade(mapa: Dictionary) -> AStarGrid2D:
	var nome: String = mapa.get("nome", "")
	if _grades.has(nome):
		return _grades[nome]
	var colunas := ceili(TAMANHO_ARENA.x / CELULA)
	var linhas := ceili(TAMANHO_ARENA.y / CELULA)
	var nova := AStarGrid2D.new()
	nova.region = Rect2i(0, 0, colunas, linhas)
	nova.cell_size = Vector2(CELULA, CELULA)
	nova.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nova.update()
	for x in colunas:
		for y in linhas:
			var celula := Vector2i(x, y)
			if bloqueado(mapa, centro(celula)):
				nova.set_point_solid(celula, true)
	_grades[nome] = nova
	return nova


## Um camaleão com o centro aqui bate em parede/cerca ou cai na água?
static func bloqueado(mapa: Dictionary, ponto: Vector2) -> bool:
	var margem := CERCA + FOLGA_PAREDE
	if ponto.x < margem or ponto.y < margem or ponto.x > TAMANHO_ARENA.x - margem \
			or ponto.y > TAMANHO_ARENA.y - margem:
		return true
	for item in mapa.get("paredes", []):
		var parede: Rect2 = item
		if parede.grow(FOLGA_PAREDE).has_point(ponto):
			return true
	return Mapas.na_agua(mapa, ponto + PES, -FOLGA_AGUA)


static func celula_de(ponto: Vector2) -> Vector2i:
	return Vector2i(floori(ponto.x / CELULA), floori(ponto.y / CELULA))


static func centro(celula: Vector2i) -> Vector2:
	return (Vector2(celula) + Vector2(0.5, 0.5)) * CELULA


## A célula livre mais perto deste ponto (procura em volta, de perto para longe).
static func celula_livre(mapa: Dictionary, ponto: Vector2) -> Vector2i:
	var g := grade(mapa)
	var base := celula_de(ponto)
	var melhor := Vector2i(-1, -1)
	var melhor_distancia := INF
	for raio in 5:
		for dx in range(-raio, raio + 1):
			for dy in range(-raio, raio + 1):
				if maxi(absi(dx), absi(dy)) != raio:
					continue
				var celula := base + Vector2i(dx, dy)
				if not g.is_in_boundsv(celula) or g.is_point_solid(celula):
					continue
				var distancia := centro(celula).distance_to(ponto)
				if distancia < melhor_distancia:
					melhor = celula
					melhor_distancia = distancia
		if melhor.x >= 0:
			return melhor
	return melhor


## Pontos (no mundo) do caminho de "de" até "ate", sem o ponto de partida.
## Vazio se não tem caminho.
static func caminho(mapa: Dictionary, de: Vector2, ate: Vector2) -> Array[Vector2]:
	var pontos: Array[Vector2] = []
	var g := grade(mapa)
	var inicio := celula_livre(mapa, de)
	var fim := celula_livre(mapa, ate)
	if inicio.x < 0 or fim.x < 0:
		return pontos
	var celulas: Array[Vector2i] = g.get_id_path(inicio, fim)
	for i in range(1, celulas.size()):
		pontos.append(centro(celulas[i]))
	if not pontos.is_empty() and not bloqueado(mapa, ate):
		pontos[pontos.size() - 1] = ate # o último é o destino de verdade
	return pontos
