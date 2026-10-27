extends Area2D
## Arma largada no chão. Qualquer camaleão visível e desarmado que passar por cima pega.

const RAIO := 14.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # camaleões
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)


func _physics_process(_delta: float) -> void:
	# Checa toda frame (e não só ao entrar) para quem ficar visível em cima da arma.
	for corpo in get_overlapping_bodies():
		if corpo.has_method("pegar_arma") and corpo.pegar_arma():
			queue_free()
			return


func _draw() -> void:
	draw_circle(Vector2.ZERO, RAIO, Color(1.0, 1.0, 1.0, 0.15))
	draw_rect(Rect2(-10.0, -3.0, 20.0, 6.0), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-10.0, -3.0, 5.0, 10.0), Color(0.2, 0.2, 0.2))
