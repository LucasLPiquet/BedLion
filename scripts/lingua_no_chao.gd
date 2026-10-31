extends Area2D
## Poder no chão (tipos em linguas.gd). Um camaleão visível pega se estiver
## com a língua básica. Ao ficar invisível ele larga o poder aqui.

const Linguas := preload("res://scripts/linguas.gd")

const RAIO := 14.0

var tipo := "longa"
var _tempo := 0.0


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
	# Checa toda frame (e não só ao entrar) para quem ficar visível em cima dele.
	for corpo in get_overlapping_bodies():
		if corpo.has_method("pegar_upgrade") and corpo.pegar_upgrade(self):
			queue_free()
			return


func _draw() -> void:
	var cor: Color = Linguas.TIPOS[tipo]["cor"]
	var pulso := 0.5 + 0.5 * sin(_tempo * 6.0)
	draw_circle(Vector2.ZERO, RAIO + 6.0 * pulso, Color(cor, 0.3))
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, RAIO, Color(0, 0, 0, 0.25)) # sombra
	draw_set_transform(Vector2(0, sin(_tempo * 3.0) * 2.0 - 4.0))
	# Bolha com um desenhinho do poder dentro.
	draw_circle(Vector2.ZERO, RAIO, Linguas.CONTORNO)
	draw_circle(Vector2.ZERO, RAIO - 1.5, cor.lightened(0.5))
	_desenhar_icone(cor)


func _desenhar_icone(cor: Color) -> void:
	var escuro := Linguas.CONTORNO
	match tipo:
		"gancho":
			# Língua com a ponta virada em gancho.
			Linguas.desenhar(self, Vector2(-8, 6), Vector2(4, -4), cor, 3.0)
			draw_arc(Vector2(6, -2), 4.0, PI, TAU + 0.6, 8, escuro, 2.0, true)
		"grude":
			# Gota de grude escorrendo.
			draw_circle(Vector2(0, 1), 6.5, escuro)
			draw_circle(Vector2(0, 1), 5.0, cor)
			draw_circle(Vector2(3, 7), 2.5, cor)
			draw_circle(Vector2(-2, -1), 1.6, Color(1, 1, 1, 0.8))
		"muda":
			# Contorno tracejado de um camaleão (a pele vazia).
			for i in 8:
				var angulo := TAU * i / 8.0
				draw_arc(Vector2.ZERO, 7.5, angulo, angulo + 0.45, 3, escuro, 1.8, true)
			draw_circle(Vector2(3, -2), 2.0, escuro)
		"olho":
			# Olho de camaleão: bolota com a pupila olhando para os lados.
			draw_circle(Vector2.ZERO, 7.5, escuro)
			draw_circle(Vector2.ZERO, 6.0, Color.WHITE)
			draw_circle(Vector2(cos(_tempo * 2.0) * 2.5, 0), 3.0, escuro)
		"longa":
			Linguas.desenhar(self, Vector2(-8, 6), Vector2(7, -6), cor, 3.0)
		_:
			Linguas.desenhar(self, Vector2(-4, 4), Vector2(5, -3), cor, 3.0)
			for i in 2:
				var y: float = -3.0 + i * 5.0
				draw_line(Vector2(-10, y), Vector2(-6, y), Linguas.CONTORNO, 1.5, true)
