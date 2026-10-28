extends CharacterBody2D
## Um camaleão controlado por um jogador (teclado ou controle) ou por um bot.
## Visível: anda e atira com a arma (se tiver uma).
## Invisível: some para todos (inclusive para o próprio jogador), solta a arma
## no chão e o ataque vira um golpe que mata quem estiver perto.

signal morreu(camaleao)

const Bala := preload("res://scripts/bala.gd")
const ArmaNoChao := preload("res://scripts/arma_no_chao.gd")
const Armas := preload("res://scripts/armas.gd")
const EfeitoGolpe := preload("res://scripts/efeito_golpe.gd")
const EfeitoMorte := preload("res://scripts/efeito_morte.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

const VELOCIDADE := 260.0
const RAIO := 18.0
## Distância máxima entre os centros dos dois camaleões para o golpe matar.
## Cada camaleão tem raio 18, então 75 deixa uns 40 px de folga entre eles.
const ALCANCE_GOLPE := 75.0
const RECARGA_GOLPE := 0.4
const RECARGA_INVISIBILIDADE := 0.5

var controle := "teclado1" # prefixo das ações em controles.gd
var bot := "" # "" = jogador de verdade; "parado" ou "andando" = bot de teste
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
var _olhando_direita := true
var _passo := 0.0 # animação de andar

# Decisão atual do bot (ele repensa algumas vezes por segundo).
var _bot_tempo := 0.0
var _bot_mover := Vector2.ZERO
var _bot_mirar := Vector2.ZERO
var _bot_atirar := false


func _ready() -> void:
	collision_layer = 2 # camaleões
	collision_mask = 1 # só colidem com paredes (atravessam outros camaleões)
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = RAIO
	forma.shape = circulo
	add_child(forma)
	add_to_group("camaleoes")
	_olhando_direita = direcao.x >= 0.0


func _physics_process(delta: float) -> void:
	if not vivo:
		return
	_recarga_tiro -= delta
	_recarga_golpe -= delta
	_recarga_invisibilidade -= delta

	var entrada := Vector2.ZERO
	var quer_atacar := false
	var quer_invisivel := false
	if bot != "":
		_pensar_bot(delta)
		entrada = _bot_mover
		quer_atacar = _bot_atirar
		_bot_atirar = false
	else:
		entrada = Input.get_vector(
			controle + "_esquerda", controle + "_direita", controle + "_cima", controle + "_baixo"
		)
		quer_atacar = Input.is_action_just_pressed(controle + "_atacar")
		quer_invisivel = Input.is_action_just_pressed(controle + "_invisivel")

	if entrada != Vector2.ZERO:
		direcao = entrada.normalized()
	if _bot_mirar != Vector2.ZERO:
		direcao = _bot_mirar
	if absf(direcao.x) > 0.1:
		_olhando_direita = direcao.x > 0.0
	velocity = entrada * VELOCIDADE
	move_and_slide()
	_passo = _passo + delta * 14.0 if entrada != Vector2.ZERO else 0.0

	if quer_invisivel:
		_alternar_invisibilidade()
	if quer_atacar:
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
		bala.position = position + Desenho.ponta_da_arma(direcao, _olhando_direita)
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
	var efeito := EfeitoMorte.new()
	efeito.position = position
	efeito.cor = cor
	mundo.add_child.call_deferred(efeito)
	morreu.emit(self)
	queue_free()


# --- Bot de teste -----------------------------------------------------------
# Bem simples: pega uma arma se estiver desarmado, chega a uma distância média
# do inimigo visível mais perto, anda de lado e atira com um pouco de erro.

func _pensar_bot(delta: float) -> void:
	_bot_tempo -= delta
	if _bot_tempo > 0.0:
		return
	_bot_tempo = randf_range(0.2, 0.4)
	_bot_mirar = Vector2.ZERO
	if bot == "parado":
		_bot_mover = Vector2.ZERO
		return

	var travado := _bot_mover != Vector2.ZERO and get_real_velocity().length() < VELOCIDADE * 0.3
	var alvo := _mais_perto(_inimigos_visiveis())
	if arma == "":
		var arma_perto := _mais_perto(get_tree().get_nodes_in_group("armas_no_chao"))
		if arma_perto:
			_bot_mover = position.direction_to(arma_perto.position)
		else:
			_bot_mover = Vector2.from_angle(randf() * TAU)
	elif alvo:
		var para_alvo := alvo.position - position
		var distancia := para_alvo.length()
		if distancia > 280.0:
			_bot_mover = para_alvo.normalized()
		elif distancia < 150.0:
			_bot_mover = -para_alvo.normalized()
		else:
			_bot_mover = para_alvo.normalized().orthogonal() * (1.0 if randf() < 0.5 else -1.0)
		_bot_mirar = para_alvo.normalized().rotated(randf_range(-0.25, 0.25))
		_bot_atirar = distancia < 500.0 and randf() < 0.5
	else:
		_bot_mover = Vector2.from_angle(randf() * TAU)
	if travado:
		_bot_mover = Vector2.from_angle(randf() * TAU)


func _inimigos_visiveis() -> Array:
	var lista: Array = []
	for outro in get_tree().get_nodes_in_group("camaleoes"):
		if outro != self and outro.vivo and not outro.invisivel:
			lista.append(outro)
	return lista


func _mais_perto(nos: Array) -> Node2D:
	var melhor: Node2D = null
	for no in nos:
		if melhor == null or position.distance_to(no.position) < position.distance_to(melhor.position):
			melhor = no
	return melhor


func _draw() -> void:
	var escala := Vector2.ONE * Desenho.ESCALA_JOGO
	Desenho.desenhar(self, Transform2D(0.0, escala, 0.0, Vector2.ZERO), cor, direcao, _olhando_direita, arma, _passo)
