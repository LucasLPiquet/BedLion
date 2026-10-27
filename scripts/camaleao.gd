extends CharacterBody2D
## Um camaleão controlado por um jogador.
## Visível: anda e atira com a arma (se tiver uma).
## Invisível: some para todos (inclusive para o próprio jogador), solta a arma
## no chão e só consegue matar de perto.

signal morreu(camaleao)

const Bala := preload("res://scripts/bala.gd")
const ArmaNoChao := preload("res://scripts/arma_no_chao.gd")

const VELOCIDADE := 260.0
const RAIO := 18.0
const ALCANCE_GOLPE := 50.0
const RECARGA_TIRO := 0.35
const RECARGA_GOLPE := 0.4
const RECARGA_INVISIBILIDADE := 0.5

var prefixo := "p1"
var cor := Color.WHITE
var mundo: Node # onde balas e armas soltas são criadas

var direcao := Vector2.RIGHT
var tem_arma := true
var invisivel := false
var vivo := true

var _recarga_tiro := 0.0
var _recarga_golpe := 0.0
var _recarga_invisibilidade := 0.0


func _ready() -> void:
	collision_layer = 2 # camaleões
	collision_mask = 1 # só colidem com paredes (atravessam outros camaleões)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)
	add_to_group("camaleoes")


func _physics_process(delta: float) -> void:
	if not vivo:
		return
	_recarga_tiro -= delta
	_recarga_golpe -= delta
	_recarga_invisibilidade -= delta

	var entrada := Input.get_vector(
		prefixo + "_esquerda", prefixo + "_direita", prefixo + "_cima", prefixo + "_baixo"
	)
	if entrada != Vector2.ZERO:
		direcao = entrada.normalized()
	velocity = entrada * VELOCIDADE
	move_and_slide()

	if Input.is_action_just_pressed(prefixo + "_invisivel"):
		_alternar_invisibilidade()
	if Input.is_action_just_pressed(prefixo + "_atacar"):
		_atacar()
	queue_redraw()


func _alternar_invisibilidade() -> void:
	if _recarga_invisibilidade > 0.0:
		return
	_recarga_invisibilidade = RECARGA_INVISIBILIDADE
	invisivel = not invisivel
	visible = not invisivel
	if invisivel and tem_arma:
		tem_arma = false
		var arma := ArmaNoChao.new()
		arma.position = position
		mundo.add_child(arma)


func _atacar() -> void:
	if invisivel:
		_golpear()
	elif tem_arma:
		_atirar()


func _atirar() -> void:
	if _recarga_tiro > 0.0:
		return
	_recarga_tiro = RECARGA_TIRO
	var bala := Bala.new()
	bala.dono = self
	bala.direcao = direcao
	bala.position = position + direcao * (RAIO + 6.0)
	mundo.add_child(bala)


func _golpear() -> void:
	if _recarga_golpe > 0.0:
		return
	_recarga_golpe = RECARGA_GOLPE
	for outro in get_tree().get_nodes_in_group("camaleoes"):
		if outro != self and outro.vivo and position.distance_to(outro.position) <= ALCANCE_GOLPE:
			outro.morrer()


## Chamado pela arma no chão. Só dá para pegar estando visível e desarmado.
func pegar_arma() -> bool:
	if not vivo or invisivel or tem_arma:
		return false
	tem_arma = true
	return true


func morrer() -> void:
	if not vivo:
		return
	vivo = false
	morreu.emit(self)
	queue_free()


func _draw() -> void:
	# Placeholder: corpo, olho apontando para a direção e cano da arma.
	draw_circle(Vector2.ZERO, RAIO, cor)
	draw_arc(Vector2.ZERO, RAIO, 0.0, TAU, 24, cor.darkened(0.4), 2.0)
	draw_circle(direcao * (RAIO * 0.5), 5.0, Color.WHITE)
	draw_circle(direcao * (RAIO * 0.6), 2.5, Color.BLACK)
	if tem_arma:
		draw_line(direcao * RAIO * 0.6, direcao * (RAIO + 12.0), Color(0.2, 0.2, 0.2), 6.0)
