extends RefCounted
## Tipos de língua. Todo camaleão começa com a "basica"; as outras são upgrades
## que aparecem no mapa. Para criar ou ajustar uma língua, basta mexer neste dicionário.
## alcance: até onde a ponta vai (px) antes de voltar.
## velocidade: pixels por segundo da ponta, na ida e na volta.
## tempo_puxada: segundos para trazer quem foi pego até a boca (menor = puxa mais forte).
## cor: cor do upgrade (bolha no chão, bolinha em cima do camaleão e ponta da língua).

const BASICA := "basica"

const TIPOS := {
	"basica": {
		"alcance": 330.0, "velocidade": 1100.0, "tempo_puxada": 0.5,
		"cor": Color(0.95, 0.4, 0.55),
	},
	"longa": {
		"alcance": 520.0, "velocidade": 1250.0, "tempo_puxada": 0.5,
		"cor": Color(0.6, 0.4, 0.95),
	},
	"rapida": {
		"alcance": 330.0, "velocidade": 1800.0, "tempo_puxada": 0.3,
		"cor": Color(1.0, 0.8, 0.2),
	},
}
## Upgrades que podem aparecer no mapa (um é sorteado a cada vez).
const UPGRADES := ["longa", "rapida"]

const ROSA := Color(0.95, 0.45, 0.6)
const CONTORNO := Color(0.08, 0.07, 0.1)


## Desenha a língua saindo de "de" até "ate": linha rosa com ponta redonda.
## cor_ponta: a cor do upgrade (ou rosa na básica).
static func desenhar(item: CanvasItem, de: Vector2, ate: Vector2, cor_ponta: Color, largura := 8.0) -> void:
	var raio_ponta := largura * 1.1
	# Primeiro o contorno, depois a cor por cima: parece uma peça só.
	item.draw_line(de, ate, CONTORNO, largura + 3.0, true)
	item.draw_circle(de, (largura + 3.0) / 2.0, CONTORNO)
	item.draw_circle(ate, raio_ponta + 1.5, CONTORNO)
	item.draw_line(de, ate, ROSA, largura, true)
	item.draw_circle(de, largura / 2.0, ROSA)
	item.draw_circle(ate, raio_ponta, cor_ponta)
	# Brilho na ponta.
	item.draw_circle(ate + Vector2(-raio_ponta, -raio_ponta) * 0.35, raio_ponta * 0.3, Color(1, 1, 1, 0.6))
