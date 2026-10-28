extends CharacterBody2D
## Um camaleão controlado por um jogador.
## Visível: anda e atira com a arma (se tiver uma).
## Invisível: some para todos (inclusive para o próprio jogador), solta a arma
## no chão e o ataque vira um golpe que mata quem estiver perto.

signal morreu(camaleao)

const Bala := preload("res://scripts/bala.gd")
const ArmaNoChao := preload("res://scripts/arma_no_chao.gd")
const Armas := preload("res://scripts/armas.gd")
const EfeitoGolpe := preload("res://scripts/efeito_golpe.gd")

const VELOCIDADE := 260.0
const RAIO := 18.0
## Distância máxima entre os centros dos dois camaleões para o golpe matar.
## Cada camaleão tem raio 18, então 75 deixa uns 40 px de folga entre eles.
const ALCANCE_GOLPE := 75.0
const RECARGA_GOLPE := 0.4
const RECARGA_INVISIBILIDADE := 0.5

var prefixo := "p1"
var cor := Color.WHITE
var mundo: Node # onde balas e armas soltas são criadas

var direcao := Vector2.RIGHT
var arma := "pistola" # "" = desarmado; tipos em armas.gd
var municao := -1 # -1 = infinita
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
	if invisivel and arma != "":
		_largar_arma(arma, municao)
		arma = ""


func _atacar() -> void:
	if invisivel:
		_golpear()
	elif arma != "":
		_atirar()


func _atirar() -> void:
	if _recarga_tiro > 0.0:
		return
	var dados: Dictionary = Armas.TIPOS[arma]
	_recarga_tiro = dados["recarga"]
	var quantidade: int = dados["balas"]
	var espalhamento: float = dados["espalhamento"]
	for i in quantidade:
		# Distribui as balas igualmente dentro do leque (uma só sai reta).
		var angulo := 0.0
		if quantidade > 1:
			angulo = lerpf(-espalhamento / 2.0, espalhamento / 2.0, float(i) / (quantidade - 1))
		var bala := Bala.new()
		bala.dono = self
		bala.direcao = direcao.rotated(angulo)
		bala.alcance = dados["alcance"]
		bala.position = position + direcao * (RAIO + 6.0)
		mundo.add_child(bala)
	if municao > 0:
		municao -= 1
		if municao == 0:
			arma = ""


func _golpear() -> void:
	if _recarga_golpe > 0.0:
		return
	_recarga_golpe = RECARGA_GOLPE
	var acertou := false
	for outro in get_tree().get_nodes_in_group("camaleoes"):
		if outro != self and outro.vivo and position.distance_to(outro.position) <= ALCANCE_GOLPE:
			outro.morrer()
			acertou = true
	# O anel aparece para todos: golpear entrega por um instante onde você está.
	var efeito := EfeitoGolpe.new()
	efeito.position = position
	efeito.alcance = ALCANCE_GOLPE
	efeito.acertou = acertou
	mundo.add_child(efeito)


## Chamado pela arma no chão. Só dá para pegar estando visível, e só se estiver
## desarmado ou se a arma do chão for melhor (aí a atual fica no chão).
func pegar_arma(no_chao: Node) -> bool:
	if not vivo or invisivel:
		return false
	if arma != "" and Armas.TIPOS[no_chao.tipo]["nivel"] <= Armas.TIPOS[arma]["nivel"]:
		return false
	if arma != "":
		_largar_arma.call_deferred(arma, municao)
	arma = no_chao.tipo
	municao = no_chao.municao
	return true


func _largar_arma(tipo: String, restante: int) -> void:
	var no_chao := ArmaNoChao.new()
	no_chao.tipo = tipo
	no_chao.municao = restante
	no_chao.position = position
	mundo.add_child(no_chao)


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
	if arma != "":
		var dados: Dictionary = Armas.TIPOS[arma]
		var comprimento := 16.0 if arma == "espingarda" else 12.0
		draw_line(direcao * RAIO * 0.6, direcao * (RAIO + comprimento), dados["cor"], 6.0)
