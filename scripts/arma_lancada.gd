extends Area2D
## Arma jogada como bumerangue (armas com modo "arremesso" em armas.gd).
## Vai girando até o alcance e volta para quem jogou. Mata quem acertar no
## caminho. Se bater numa parede, ou se o dono não puder pegar de volta
## (invisível, morto ou já com outra arma), cai no chão para qualquer um pegar.

const ArmaNoChao := preload("res://scripts/arma_no_chao.gd")
const Armas := preload("res://scripts/armas.gd")

const RAIO := 10.0
## Distância do dono em que ele pega a arma de volta.
const DISTANCIA_PEGAR := 26.0
const GIRO := 18.0 # voltas por segundo, em radianos

var tipo := "pistola"
var municao := -1
var dono: Node
var direcao := Vector2.RIGHT
var _velocidade := 480.0
var _alcance := 320.0
var _percorrido := 0.0
var _voltando := false
var _caiu := false
var _angulo := 0.0


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
	_velocidade = Armas.TIPOS[tipo]["velocidade"]
	_alcance = Armas.TIPOS[tipo]["alcance"]


func _physics_process(delta: float) -> void:
	if _caiu:
		return
	_angulo += GIRO * delta
	if _voltando:
		if not _dono_pode_pegar():
			_cair()
			return
		if position.distance_to(dono.position) <= DISTANCIA_PEGAR:
			dono.receber_arma_de_volta(tipo, municao)
			queue_free()
			return
		direcao = position.direction_to(dono.position)
	else:
		_percorrido += _velocidade * delta
		if _percorrido >= _alcance:
			_voltando = true
	position += direcao * _velocidade * delta
	queue_redraw()


func _dono_pode_pegar() -> bool:
	return is_instance_valid(dono) and dono.vivo and not dono.invisivel and dono.arma == ""


func _ao_atingir(corpo: Node) -> void:
	if _caiu or corpo == dono:
		return
	if corpo.has_method("morrer"):
		corpo.morrer() # continua voando, como um bumerangue
	else:
		# Parede: recua um pouco para não cair dentro dela.
		position -= direcao * 16.0
		_cair()


func _cair() -> void:
	_caiu = true
	var no_chao := ArmaNoChao.new()
	no_chao.tipo = tipo
	no_chao.municao = municao
	no_chao.position = position
	# Adiar: não dá para criar áreas de colisão no meio de um aviso de colisão.
	get_parent().add_child.call_deferred(no_chao)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RAIO + 4.0, Color(1.0, 1.0, 1.0, 0.15))
	Armas.desenhar(self, tipo, Transform2D(_angulo, Vector2(1.2, 1.2), 0.0, Vector2.ZERO).translated_local(Vector2(-6, 0)))
