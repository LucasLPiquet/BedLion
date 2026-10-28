extends Area2D
## Projétil das armas. Some ao bater em parede e mata o camaleão que acertar.

const RAIO := 4.0

var direcao := Vector2.RIGHT
var velocidade := 480.0
var dono: Node
var alcance := INF
var _percorrido := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # paredes e camaleões
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)
	body_entered.connect(_ao_atingir)
	z_index = 1


func _physics_process(delta: float) -> void:
	position += direcao * velocidade * delta
	_percorrido += velocidade * delta
	if _percorrido >= alcance:
		queue_free()


func _ao_atingir(corpo: Node) -> void:
	if corpo == dono:
		return
	if corpo.has_method("morrer"):
		corpo.morrer()
	queue_free()


func _draw() -> void:
	# Rastro curto atrás da bala e um brilho em volta.
	draw_line(Vector2.ZERO, -direcao * 14.0, Color(1.0, 0.85, 0.3, 0.5), RAIO * 1.5)
	draw_circle(Vector2.ZERO, RAIO * 1.8, Color(1.0, 0.9, 0.4, 0.3))
	draw_circle(Vector2.ZERO, RAIO, Color(1.0, 0.97, 0.7))
