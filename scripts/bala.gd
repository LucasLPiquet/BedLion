extends Area2D
## Projétil da arma inicial. Some ao bater em parede e mata o camaleão que acertar.

const VELOCIDADE := 700.0
const RAIO := 4.0

var direcao := Vector2.RIGHT
var dono: Node


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # paredes e camaleões
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)
	body_entered.connect(_ao_atingir)


func _physics_process(delta: float) -> void:
	position += direcao * VELOCIDADE * delta


func _ao_atingir(corpo: Node) -> void:
	if corpo == dono:
		return
	if corpo.has_method("morrer"):
		corpo.morrer()
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RAIO, Color(1.0, 0.95, 0.5))
