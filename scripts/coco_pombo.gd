extends Node2D
## Cocô de pombo que cai do céu. Primeiro aparece só uma sombra no chão (o aviso),
## que vai escurecendo durante TEMPO_AVISO segundos; aí o cocô cai e faz "splat".
## Quem levar ele na cabeça ou pisar nele depois fica com os pés sujos e deixa
## pegadas por TEMPO_PEGADAS segundos, mesmo invisível. Ele fica TEMPO_NO_CHAO
## segundos no chão e some. Quem cria os cocôs (e de quanto em quanto tempo) é o main.gd.

const TEMPO_AVISO := 1.0
const TEMPO_NO_CHAO := 15.0
const TEMPO_PEGADAS := 6.0
## Distância (do centro do camaleão ao centro do cocô) para contar como pisada.
const RAIO_PISAR := 24.0
const ALTURA_QUEDA := 260.0 # de onde o cocô vem caindo, só no desenho

const BRANCO := Color(0.97, 0.96, 0.9)
const MIOLO := Color(0.42, 0.42, 0.25)
const CONTORNO := Color(0.08, 0.07, 0.1)

var _tempo := 0.0
var _formato: Array = [] # bolinhas do "splat", sorteadas uma vez


func _ready() -> void:
	z_index = -1 # no chão, por baixo dos camaleões
	add_to_group("cocos")
	for i in 6:
		var angulo := TAU * i / 6.0 + randf_range(-0.3, 0.3)
		_formato.append([Vector2.from_angle(angulo) * randf_range(7.0, 12.0), randf_range(4.0, 6.5)])


func _physics_process(delta: float) -> void:
	_tempo += delta
	queue_redraw()
	if _tempo < TEMPO_AVISO:
		return
	if _tempo >= TEMPO_AVISO + TEMPO_NO_CHAO:
		queue_free()
		return
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if camaleao.vivo and position.distance_to(camaleao.position) <= RAIO_PISAR:
			camaleao.sujar_pes(TEMPO_PEGADAS)


func _draw() -> void:
	if _tempo < TEMPO_AVISO:
		_desenhar_aviso(_tempo / TEMPO_AVISO)
		return
	# No último segundo vai sumindo.
	var resta := TEMPO_AVISO + TEMPO_NO_CHAO - _tempo
	var alfa := clampf(resta, 0.0, 1.0)
	# "Splat": achata logo que cai e volta ao normal.
	var no_chao := _tempo - TEMPO_AVISO
	var esticada := 1.0 + 0.5 * maxf(0.0, 1.0 - no_chao * 6.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(esticada, 1.0 / esticada))
	for bolinha in _formato:
		draw_circle(bolinha[0], bolinha[1] + 1.5, Color(CONTORNO, alfa))
	draw_circle(Vector2.ZERO, 11.0, Color(CONTORNO, alfa))
	for bolinha in _formato:
		draw_circle(bolinha[0], bolinha[1], Color(BRANCO, alfa))
	draw_circle(Vector2.ZERO, 9.5, Color(BRANCO, alfa))
	# Miolo escuro e um brilho, como cocô de pombo de verdade.
	draw_circle(Vector2(1, 1), 4.5, Color(MIOLO, alfa))
	draw_circle(Vector2(-3, -3), 2.0, Color(1, 1, 1, 0.8 * alfa))
	draw_set_transform(Vector2.ZERO)


## Sombra crescendo no chão e, no fim do aviso, o cocô despencando.
func _desenhar_aviso(t: float) -> void:
	var raio := lerpf(6.0, 16.0, t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, raio, Color(0, 0, 0, lerpf(0.1, 0.45, t)))
	draw_set_transform(Vector2.ZERO)
	if t > 0.6:
		var queda := (t - 0.6) / 0.4 # 0 = lá em cima, 1 = no chão
		var altura := ALTURA_QUEDA * (1.0 - queda * queda)
		var gota := Vector2(0, -altura)
		draw_circle(gota, 6.5, CONTORNO)
		draw_circle(gota, 5.0, BRANCO)
		draw_circle(gota + Vector2(1, 1), 2.0, MIOLO)
