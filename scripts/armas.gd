extends RefCounted
## Tipos de arma. Para criar ou ajustar uma arma, basta mexer neste dicionário.
## nivel: arma de nível maior substitui a de nível menor ao passar por cima.
## municao: -1 é infinita; quando acaba, o camaleão fica desarmado.
## alcance: distância máxima de cada bala (INF = até bater em algo).

const TIPOS := {
	"pistola": {
		"nivel": 1, "recarga": 0.35, "balas": 1, "espalhamento": 0.0,
		"alcance": INF, "municao": -1, "cor": Color(0.25, 0.25, 0.28),
	},
	"espingarda": {
		"nivel": 2, "recarga": 0.6, "balas": 5, "espalhamento": 0.5,
		"alcance": 380.0, "municao": 6, "cor": Color(0.85, 0.2, 0.25),
	},
}

const CONTORNO := Color(0.08, 0.07, 0.1)
const MADEIRA := Color(0.55, 0.35, 0.2)


## Desenha a arma apontando para a direita, com o cabo na origem (onde fica a mão).
## base: posição, rotação e escala da arma dentro de quem está desenhando.
static func desenhar(item: CanvasItem, tipo: String, base: Transform2D) -> void:
	item.draw_set_transform_matrix(base)
	var cor: Color = TIPOS[tipo]["cor"]
	var pecas: Array = []
	if tipo == "espingarda":
		pecas = [
			[Rect2(-9.0, -2.0, 9.0, 6.0), MADEIRA], # coronha
			[Rect2(-1.0, -3.5, 9.0, 7.0), cor], # corpo
			[Rect2(-1.0, 0.0, 4.0, 7.0), MADEIRA], # cabo
			[Rect2(7.0, -3.0, 15.0, 3.0), cor.darkened(0.3)], # cano de cima
			[Rect2(7.0, 0.0, 15.0, 3.0), cor.darkened(0.3)], # cano de baixo
		]
	else:
		pecas = [
			[Rect2(-2.0, -3.0, 14.0, 6.0), cor], # cano
			[Rect2(-2.0, 0.0, 5.0, 8.0), cor.darkened(0.2)], # cabo
		]
	# Primeiro todos os contornos, depois as cores: as peças parecem uma só.
	for peca in pecas:
		var retangulo: Rect2 = peca[0]
		item.draw_rect(retangulo.grow(1.5), CONTORNO)
	for peca in pecas:
		item.draw_rect(peca[0], peca[1])
	# Brilho em cima do cano.
	var cano: Rect2 = pecas[0][0] if tipo == "pistola" else pecas[3][0]
	item.draw_line(cano.position + Vector2(1.0, 1.0), Vector2(cano.end.x - 1.0, cano.position.y + 1.0), Color(1, 1, 1, 0.35), 1.0)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)
