extends RefCounted
## Lista de mapas. A cada rodada o jogo sorteia um deles (nunca o mesmo da
## rodada anterior). Para criar um mapa novo, copie um dos blocos { ... } abaixo,
## mude o nome e as posições, e pronto: ele já entra no sorteio.
##
## A arena tem 1600 x 900 pixels. A cerca viva em volta ocupa 40 px de cada lado,
## então o chão vai de x = 40 até 1560 e de y = 40 até 860.
## Rect2(x, y, largura, altura): x e y são o canto de cima à esquerda.
##
## Cada mapa tem:
## - "nome": aparece na tela no começo da rodada.
## - "paredes": blocos de pedra (ninguém passa, nem a língua).
## - "agua": lagos e rios. Quem cair na água afunda e morre. A língua passa por
##   cima. Os cantos são arredondados sozinhos (um retângulo fino vira um rio com
##   pontas redondas; um quadrado vira um lago redondo). Dá para juntar vários
##   retângulos para fazer um lago com formato diferente.
## - "pontes": tábuas por cima da água; dá para andar nelas sem cair.
## - "inicios": onde cada jogador começa (Verde, Laranja, Azul, Rosa), nessa ordem.
## - "upgrades_no_inicio": upgrades de língua que já estão no chão quando a rodada começa.
## - "pontos_upgrade": lugares onde os upgrades de língua podem aparecer depois.
## - "semente": muda o sorteio dos enfeites (flores, grama) do desenho do mapa.
##
## Os cocôs de pombo caem em lugares sorteados, sempre fora das paredes e da água.

const MAPAS := [
	{
		"nome": "Jardim",
		"semente": 7,
		"paredes": [
			Rect2(475, 188, 75, 200),
			Rect2(1050, 512, 75, 200),
			Rect2(700, 138, 200, 50),
			Rect2(700, 712, 200, 50),
		],
		"agua": [],
		"pontes": [],
		"inicios": [Vector2(212, 262), Vector2(1388, 638), Vector2(1388, 262), Vector2(212, 638)],
		"upgrades_no_inicio": [Vector2(800, 450)],
		"pontos_upgrade": [
			Vector2(250, 162), Vector2(1350, 162), Vector2(250, 738), Vector2(1350, 738),
			Vector2(800, 300), Vector2(800, 600), Vector2(625, 588), Vector2(975, 312),
		],
	},
	{
		"nome": "Labirinto",
		"semente": 21,
		"paredes": [
			# Muros saindo da cerca.
			Rect2(330, 20, 50, 200), Rect2(1220, 680, 50, 200),
			Rect2(20, 425, 190, 50), Rect2(1390, 425, 190, 50),
			Rect2(330, 680, 50, 200), Rect2(1220, 20, 50, 200),
			# Cantos em "L".
			Rect2(520, 190, 200, 50), Rect2(520, 190, 50, 170),
			Rect2(880, 660, 200, 50), Rect2(1030, 540, 50, 170),
			Rect2(880, 190, 200, 50), Rect2(1030, 190, 50, 170),
			Rect2(520, 660, 200, 50), Rect2(520, 540, 50, 170),
			# Cruz no meio.
			Rect2(775, 360, 50, 180), Rect2(700, 425, 200, 50),
			# Blocos soltos.
			Rect2(230, 590, 50, 50), Rect2(1320, 260, 50, 50),
		],
		"agua": [],
		"pontes": [],
		"inicios": [Vector2(140, 140), Vector2(1460, 760), Vector2(1460, 140), Vector2(140, 760)],
		"upgrades_no_inicio": [Vector2(645, 450), Vector2(955, 450)],
		"pontos_upgrade": [
			Vector2(800, 110), Vector2(800, 790), Vector2(450, 450), Vector2(1150, 450),
			Vector2(640, 300), Vector2(960, 600), Vector2(960, 300), Vector2(640, 600),
		],
	},
	{
		"nome": "Lago",
		"semente": 33,
		"paredes": [
			Rect2(250, 190, 70, 70), Rect2(1280, 640, 70, 70),
			Rect2(1280, 190, 70, 70), Rect2(250, 640, 70, 70),
			Rect2(770, 70, 60, 60), Rect2(770, 770, 60, 60),
		],
		# Um lago grande e oval no meio.
		"agua": [
			Rect2(500, 230, 600, 440),
		],
		# Uma ponte de um lado ao outro, no meio do lago.
		"pontes": [
			Rect2(470, 410, 660, 80),
		],
		"inicios": [Vector2(140, 140), Vector2(1460, 760), Vector2(1460, 140), Vector2(140, 760)],
		"upgrades_no_inicio": [Vector2(800, 450)],
		"pontos_upgrade": [
			Vector2(400, 450), Vector2(1200, 450), Vector2(800, 160), Vector2(800, 740),
			Vector2(400, 120), Vector2(1200, 780), Vector2(1200, 120), Vector2(400, 780),
		],
	},
	{
		"nome": "Rios",
		"semente": 45,
		"paredes": [
			Rect2(760, 240, 80, 80), Rect2(760, 580, 80, 80),
			Rect2(240, 425, 120, 50), Rect2(1240, 425, 120, 50),
		],
		# Dois rios de cima a baixo (passam por baixo da cerca).
		"agua": [
			Rect2(470, -60, 90, 1020),
			Rect2(1040, -60, 90, 1020),
		],
		"pontes": [
			Rect2(445, 170, 140, 90), Rect2(445, 640, 140, 90),
			Rect2(1015, 170, 140, 90), Rect2(1015, 640, 140, 90),
		],
		"inicios": [Vector2(180, 180), Vector2(1420, 720), Vector2(1420, 180), Vector2(180, 720)],
		"upgrades_no_inicio": [Vector2(800, 450)],
		"pontos_upgrade": [
			Vector2(800, 120), Vector2(800, 780), Vector2(660, 450), Vector2(940, 450),
			Vector2(300, 300), Vector2(1300, 600), Vector2(1300, 300), Vector2(300, 600),
		],
	},
	{
		"nome": "Ruínas",
		"semente": 58,
		"paredes": [
			Rect2(560, 150, 180, 50), Rect2(860, 700, 180, 50),
			Rect2(860, 150, 180, 50), Rect2(560, 700, 180, 50),
			Rect2(240, 140, 50, 150), Rect2(1310, 610, 50, 150),
			Rect2(1310, 140, 50, 150), Rect2(240, 610, 50, 150),
			Rect2(770, 330, 60, 60), Rect2(770, 510, 60, 60),
		],
		# Dois laguinhos redondos, um de cada lado.
		"agua": [
			Rect2(370, 340, 220, 220),
			Rect2(1010, 340, 220, 220),
		],
		"pontes": [],
		"inicios": [Vector2(130, 450), Vector2(1470, 450), Vector2(800, 110), Vector2(800, 790)],
		"upgrades_no_inicio": [Vector2(800, 450)],
		"pontos_upgrade": [
			Vector2(480, 260), Vector2(1120, 640), Vector2(1120, 260), Vector2(480, 640),
			Vector2(650, 450), Vector2(950, 450), Vector2(140, 140), Vector2(1460, 760),
		],
	},
]

## O camaleão afunda quando este ponto (um pouco abaixo do centro, perto dos pés)
## entra na água. Fica um pouquinho de margem na beirada, para não morrer só de encostar.
const PES := Vector2(0, 12)
const MARGEM_BEIRADA := 6.0


## Raio dos cantos de um pedaço de água: metade do lado menor (fica bem redondo).
static func curva(retangulo: Rect2) -> float:
	return minf(retangulo.size.x, retangulo.size.y) / 2.0


## O ponto está dentro deste retângulo de cantos arredondados (encolhido por "folga")?
static func dentro_arredondado(retangulo: Rect2, ponto: Vector2, folga := 0.0) -> bool:
	var raio := curva(retangulo)
	var miolo := retangulo.grow(-raio)
	var mais_perto := ponto.clamp(miolo.position, miolo.end)
	return ponto.distance_to(mais_perto) <= raio - folga


## O ponto está na água (e não em cima de uma ponte)?
static func na_agua(mapa: Dictionary, ponto: Vector2, folga := 0.0) -> bool:
	for ponte in mapa.get("pontes", []):
		var retangulo: Rect2 = ponte
		if retangulo.has_point(ponto):
			return false
	for agua in mapa.get("agua", []):
		if dentro_arredondado(agua, ponto, folga):
			return true
	return false


## Um camaleão nesta posição cai na água?
static func afunda(mapa: Dictionary, posicao: Vector2) -> bool:
	return na_agua(mapa, posicao + PES, MARGEM_BEIRADA)


## O ponto está longe ("distancia" px) das paredes e da água? Serve para
## escolher onde soltar cocô de pombo.
static func lugar_livre(mapa: Dictionary, ponto: Vector2, distancia: float) -> bool:
	for parede in mapa.get("paredes", []):
		var retangulo: Rect2 = parede
		if retangulo.grow(distancia).has_point(ponto):
			return false
	for agua in mapa.get("agua", []):
		if dentro_arredondado(agua, ponto, -distancia):
			return false
	return true
