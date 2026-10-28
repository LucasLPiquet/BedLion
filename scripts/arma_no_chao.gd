extends Area2D
## Arma largada no chão. Um camaleão visível pega se estiver desarmado
## ou se ela for melhor que a que ele tem (aí a dele fica no chão no lugar).

const Armas := preload("res://scripts/armas.gd")

const RAIO := 14.0

var tipo := "pistola"
var municao := -1 # -1 = munição cheia do tipo
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # camaleões
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)
	add_to_group("armas_no_chao")
	z_index = -1 # fica por baixo dos camaleões
	if municao < 0:
		municao = Armas.TIPOS[tipo]["municao"]


func _physics_process(delta: float) -> void:
	_tempo += delta
	queue_redraw() # flutua devagar; as melhores também brilham
	# Checa toda frame (e não só ao entrar) para quem ficar visível em cima da arma.
	for corpo in get_overlapping_bodies():
		if corpo.has_method("pegar_arma") and corpo.pegar_arma(self):
			queue_free()
			return


func _draw() -> void:
	var dados: Dictionary = Armas.TIPOS[tipo]
	var cor: Color = dados["cor"]
	if dados["nivel"] > 1:
		var pulso := 0.5 + 0.5 * sin(_tempo * 6.0)
		draw_circle(Vector2.ZERO, RAIO + 6.0 * pulso, Color(cor, 0.3))
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, RAIO, Color(0, 0, 0, 0.25)) # sombra
	var flutua := sin(_tempo * 3.0) * 2.0
	Armas.desenhar(self, tipo, Transform2D(-0.3, Vector2(1.2, 1.2), 0.0, Vector2(-6, -2 + flutua)))
