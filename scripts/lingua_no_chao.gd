extends Area2D
## Upgrade de língua no chão (tipos em linguas.gd). Um camaleão visível pega
## se estiver com a língua básica. Ao ficar invisível ele larga o upgrade aqui.
## Também dá para puxar de longe com a língua (camaleao.gd): enquanto está preso
## nela, ninguém pega passando por cima. Se cair na água, afunda e some.

const Linguas := preload("res://scripts/linguas.gd")

const RAIO := 14.0
const TEMPO_AFUNDAR := 0.6

var tipo := "longa"
var na_lingua := false # sendo trazido pela língua de alguém
var _tempo := 0.0
var _afundando := -1.0 # >= 0: segundos afundando


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # camaleões
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)
	add_to_group("upgrades_no_chao")
	z_index = -1 # fica por baixo dos camaleões


func _physics_process(delta: float) -> void:
	_tempo += delta
	queue_redraw() # flutua devagar e brilha
	z_index = 1 if na_lingua else -1 # na língua, fica por cima de todo mundo
	if _afundando >= 0.0:
		_afundando += delta
		scale = Vector2.ONE * maxf(1.0 - _afundando / TEMPO_AFUNDAR, 0.0)
		modulate.a = scale.x
		if _afundando >= TEMPO_AFUNDAR:
			queue_free()
		return
	if na_lingua:
		return
	# Checa toda frame (e não só ao entrar) para quem ficar visível em cima dele.
	for corpo in get_overlapping_bodies():
		if corpo.has_method("pegar_upgrade") and corpo.pegar_upgrade(self):
			queue_free()
			return


## Caiu na água (solto da língua em cima de um lago ou rio): encolhe e some.
func afundar() -> void:
	if _afundando < 0.0:
		_afundando = 0.0
		remove_from_group("upgrades_no_chao")


func _draw() -> void:
	var cor: Color = Linguas.TIPOS[tipo]["cor"]
	var pulso := 0.5 + 0.5 * sin(_tempo * 6.0)
	draw_circle(Vector2.ZERO, RAIO + 6.0 * pulso, Color(cor, 0.3))
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, RAIO, Color(0, 0, 0, 0.25)) # sombra
	draw_set_transform(Vector2(0, sin(_tempo * 3.0) * 2.0 - 4.0))
	# Bolha com uma línguinha dentro: a longa é mais comprida, a rápida tem riscos de velocidade.
	draw_circle(Vector2.ZERO, RAIO, Linguas.CONTORNO)
	draw_circle(Vector2.ZERO, RAIO - 1.5, cor.lightened(0.5))
	if tipo == "longa":
		Linguas.desenhar(self, Vector2(-8, 6), Vector2(7, -6), cor, 3.0)
	else:
		Linguas.desenhar(self, Vector2(-4, 4), Vector2(5, -3), cor, 3.0)
		for i in 2:
			var y: float = -3.0 + i * 5.0
			draw_line(Vector2(-10, y), Vector2(-6, y), Linguas.CONTORNO, 1.5, true)
