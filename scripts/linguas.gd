extends RefCounted
## Línguas e poderes. Todo camaleão começa com a "basica"; os outros são poderes
## que aparecem no mapa numa bolha (lingua_no_chao.gd). Só dá para ter um por vez,
## e ficar invisível larga o poder no chão (menos a "muda", que é gasta ao sumir).
## Para criar ou ajustar um poder, basta mexer neste dicionário.
## alcance: até onde a ponta vai (px) antes de voltar.
## velocidade: pixels por segundo da ponta, na ida e na volta.
## tempo_puxada: segundos para trazer quem foi pego até a boca (menor = puxa mais forte).
## cor: cor do poder (bolha no chão, bolinha em cima do camaleão e ponta da língua).
## nome: como o poder é chamado (aparece rapidinho em cima de quem pega).
##
## Poderes (o que cada um faz está em camaleao.gd, grude.gd e casca.gd):
## - gancho: se a língua bater numa parede, ela gruda lá e puxa VOCÊ até a
##   parede, voando por cima de qualquer coisa, até da água. Se a língua for
##   solta no meio do caminho em cima da água, você afunda.
## - grude: quando a língua erra, a ponta deixa uma bola de grude no chão.
##   Quem pisar (até invisível) fica preso e aparece. Quem soltou não gruda.
## - muda: um toque no botão de invisível troca de pele na hora: você some sem
##   precisar segurar, e a pele velha fica parada no lugar, igualzinha a você.
## - olho: os olhos de camaleão giram para todo lado. Quem estiver invisível
##   perto de você treme no ar e dá para ver o vulto. O círculo em volta mostra até onde.

const BASICA := "basica"

const TIPOS := {
	"basica": {
		"nome": "Língua", "alcance": 330.0, "velocidade": 1100.0, "tempo_puxada": 0.5,
		"cor": Color(0.95, 0.4, 0.55),
	},
	"gancho": {
		"nome": "Gancho", "alcance": 480.0, "velocidade": 1400.0, "tempo_puxada": 0.5,
		"cor": Color(0.95, 0.55, 0.15),
		"velocidade_voo": 950.0, # px/s voando até a parede
	},
	"grude": {
		"nome": "Grude", "alcance": 360.0, "velocidade": 1100.0, "tempo_puxada": 0.5,
		"cor": Color(0.55, 0.85, 0.2),
		"max_grudes": 2, # bolas de grude de um mesmo camaleão no chão ao mesmo tempo
	},
	"muda": {
		"nome": "Muda de pele", "alcance": 330.0, "velocidade": 1100.0, "tempo_puxada": 0.5,
		"cor": Color(0.93, 0.9, 0.78),
	},
	"olho": {
		"nome": "Olho de camaleão", "alcance": 330.0, "velocidade": 1100.0, "tempo_puxada": 0.5,
		"cor": Color(0.3, 0.85, 0.95),
		"raio_olho": 200.0, # até onde ele enxerga quem está invisível
	},
	# Os upgrades antigos continuam aqui: para voltar com eles, coloque
	# "longa" ou "rapida" na lista UPGRADES lá embaixo.
	"longa": {
		"nome": "Língua longa", "alcance": 520.0, "velocidade": 1250.0, "tempo_puxada": 0.5,
		"cor": Color(0.6, 0.4, 0.95),
	},
	"rapida": {
		"nome": "Língua rápida", "alcance": 330.0, "velocidade": 1800.0, "tempo_puxada": 0.3,
		"cor": Color(1.0, 0.8, 0.2),
	},
}
## Poderes que podem aparecer no mapa (um é sorteado a cada vez).
const UPGRADES := ["gancho", "grude", "muda", "olho"]

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
