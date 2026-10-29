extends CharacterBody2D
## Um camaleão controlado por um jogador (teclado ou controle) ou por um bot.
## Dois ataques:
## - Língua (só visível): sai reta da boca, vai até o alcance e volta. Se pegar
##   outro camaleão, puxa ele até a boca. A língua sozinha não mata: é para trazer
##   o outro para perto e dar o golpe. Enquanto ela está fora, quem lançou fica
##   parado. Apertar de novo solta, e a língua fica RECARGA_SOLTAR segundos sem
##   poder ser usada. Quem foi pego pode se soltar com a língua ou com o golpe,
##   mas só depois de TEMPO_ATE_SE_SOLTAR.
## - Golpe: curto, na frente dele; mata. Funciona visível e invisível, mas
##   golpear faz ele aparecer de novo, então não dá para ficar batendo escondido.
## Invisível: segura o botão por TEMPO_PARA_SUMIR segundos para sumir para todos
## (inclusive para o próprio jogador). Se tiver um upgrade de língua, ele cai no chão.
## Pés sujos: quem pisa em cocô de pombo (coco_pombo.gd) deixa pegadas por um
## tempo, mesmo invisível.

signal morreu(camaleao)

const Linguas := preload("res://scripts/linguas.gd")
const LinguaNoChao := preload("res://scripts/lingua_no_chao.gd")
const EfeitoGolpe := preload("res://scripts/efeito_golpe.gd")
const EfeitoMorte := preload("res://scripts/efeito_morte.gd")
const Pegada := preload("res://scripts/pegada.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

const VELOCIDADE := 300.0
const RAIO := 18.0
## Distância máxima entre os centros dos dois camaleões para o golpe matar.
## Cada camaleão tem raio 18, então 95 deixa uns 60 px de folga entre eles.
const ALCANCE_GOLPE := 95.0
## Abertura do golpe para cada lado da direção em que ele olha (1.5 rad = uns 85°).
const ANGULO_GOLPE := 1.5
## Quem estiver mais perto que isso (centro a centro) é acertado de qualquer lado.
const DISTANCIA_COLADO := 50.0
const RECARGA_GOLPE := 0.5
## Espera da língua depois de voltar sozinha (errou ou terminou de puxar).
const RECARGA_LINGUA := 0.3
## Espera da língua quando ela é solta antes da hora: por quem lançou, por quem
## foi pego ou porque alguém cortou.
const RECARGA_SOLTAR := 1.0
## Quem é puxado só consegue se soltar depois de tantos segundos.
const TEMPO_ATE_SE_SOLTAR := 0.25
## A puxada termina quando os dois ficam a esta distância (centro a centro).
## É menos que ALCANCE_GOLPE, então dá para golpear logo em seguida.
const DISTANCIA_FIM_PUXADA := 42.0
## Tamanho da ponta da língua para pegar alguém (maior = mais fácil acertar).
const RAIO_PONTA := 16.0
## Se um terceiro camaleão passar por cima da língua esticada, ela é cortada.
const LINGUA_PODE_SER_CORTADA := true
## Quanto tempo segurar o botão de invisível para sumir (soltar antes cancela).
const TEMPO_PARA_SUMIR := 1.0
## Depois de aparecer, quanto esperar para poder começar a sumir de novo.
const RECARGA_INVISIBILIDADE := 0.5
## Com os pés sujos, deixa uma pegada a cada tantos pixels andados.
const DISTANCIA_ENTRE_PEGADAS := 24.0

var controle := "teclado1" # prefixo das ações em controles.gd
var bot := "" # "" = jogador de verdade; "parado" ou "andando" = bot de teste
var cor := Color.WHITE
var mundo: Node # onde efeitos e upgrades largados são criados

var direcao := Vector2.RIGHT
var lingua := Linguas.BASICA # tipo em linguas.gd
var invisivel := false
var vivo := true
var puxado_por: Node = null # quem está puxando este camaleão com a língua

var _recarga_golpe := 0.0
var _recarga_lingua := 0.0
var _recarga_invisibilidade := 0.0
var _carga_invisivel := 0.0 # segundos segurando o botão para sumir
var _olhando_direita := true
var _passo := 0.0 # animação de andar
var _tempo_pes_sujos := 0.0 # segundos que ainda vai deixar pegadas
var _andado_desde_pegada := 0.0
var _pe_esquerdo := true # as pegadas alternam um lado e o outro

# Língua lançada por este camaleão.
var _estado_lingua := "" # "" = na boca; "indo", "voltando" ou "puxando"
var _ponta := Vector2.ZERO # posição da ponta, no mundo
var _percorrido := 0.0
var _dados_lingua: Dictionary = {} # números da língua no momento em que saiu
var _preso: Node = null # quem a língua pegou
var _tempo_puxando := 0.0
var _desenho_lingua: Node2D # desenha a língua por cima de todos os camaleões

# Quando é este camaleão que está sendo puxado.
var _velocidade_puxada := 0.0
var _tempo_puxado := 0.0

# Decisão atual do bot (ele repensa algumas vezes por segundo).
var _bot_tempo := 0.0
var _bot_mover := Vector2.ZERO
var _bot_mirar := Vector2.ZERO
var _bot_golpear := false
var _bot_lingua := false


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
	_desenho_lingua = Node2D.new()
	_desenho_lingua.z_index = 1
	_desenho_lingua.draw.connect(_desenhar_lingua)
	add_child(_desenho_lingua)


func _physics_process(delta: float) -> void:
	if not vivo:
		return
	_recarga_golpe -= delta
	_recarga_lingua -= delta
	_recarga_invisibilidade -= delta

	var entrada := Vector2.ZERO
	var quer_golpear := false
	var quer_lingua := false
	var apertou_invisivel := false
	var segurando_invisivel := false
	if bot != "":
		_pensar_bot(delta)
		entrada = _bot_mover
		quer_golpear = _bot_golpear
		quer_lingua = _bot_lingua
		_bot_golpear = false
		_bot_lingua = false
	else:
		entrada = Input.get_vector(
			controle + "_esquerda", controle + "_direita", controle + "_cima", controle + "_baixo"
		)
		quer_golpear = Input.is_action_just_pressed(controle + "_golpe")
		quer_lingua = Input.is_action_just_pressed(controle + "_lingua")
		apertou_invisivel = Input.is_action_just_pressed(controle + "_invisivel")
		segurando_invisivel = Input.is_action_pressed(controle + "_invisivel")

	if _sendo_puxado():
		_ser_arrastado(delta, quer_golpear or quer_lingua, quer_golpear)
		return

	if _estado_lingua != "":
		# Com a língua fora fica parado; apertar a língua de novo solta.
		entrada = Vector2.ZERO
		quer_golpear = false
		if quer_lingua:
			soltar_lingua(RECARGA_SOLTAR)
			quer_lingua = false
	else:
		if entrada != Vector2.ZERO:
			direcao = entrada.normalized()
		if _bot_mirar != Vector2.ZERO:
			direcao = _bot_mirar
	if absf(direcao.x) > 0.1:
		_olhando_direita = direcao.x > 0.0
	velocity = entrada * VELOCIDADE
	move_and_slide()
	_passo = _passo + delta * 14.0 if entrada != Vector2.ZERO else 0.0
	_deixar_pegadas(delta)

	_controlar_invisibilidade(delta, apertou_invisivel, segurando_invisivel)
	if quer_golpear:
		_golpear()
	if quer_lingua:
		_lancar_lingua()
	_mover_lingua(delta)
	queue_redraw()
	_desenho_lingua.queue_redraw()


## Invisível: um toque no botão faz aparecer na hora.
## Visível: precisa segurar o botão; a carga só começa com um aperto novo,
## então segurar depois de aparecer não faz sumir de novo sozinho.
## Com a língua fora não dá para começar a sumir.
func _controlar_invisibilidade(delta: float, apertou: bool, segurando: bool) -> void:
	if invisivel:
		if apertou:
			_aparecer()
		return
	var carregando := segurando and _estado_lingua == "" and _recarga_invisibilidade <= 0.0 \
		and (apertou or _carga_invisivel > 0.0)
	_carga_invisivel = _carga_invisivel + delta if carregando else 0.0
	if _carga_invisivel >= TEMPO_PARA_SUMIR:
		_sumir()
	# Vai ficando transparente enquanto carrega: os outros veem que ele vai sumir.
	modulate.a = lerpf(1.0, 0.45, _carga_invisivel / TEMPO_PARA_SUMIR)


func _sumir() -> void:
	_carga_invisivel = 0.0
	invisivel = true
	visible = false
	if lingua != Linguas.BASICA:
		_largar_upgrade()
		lingua = Linguas.BASICA


func _aparecer() -> void:
	invisivel = false
	visible = true
	modulate.a = 1.0
	_recarga_invisibilidade = RECARGA_INVISIBILIDADE


# --- Língua -----------------------------------------------------------------

func _boca() -> Vector2:
	return position + Desenho.boca(_olhando_direita)


func _lancar_lingua() -> void:
	if invisivel or _estado_lingua != "" or _recarga_lingua > 0.0:
		return
	_dados_lingua = Linguas.TIPOS[lingua]
	_estado_lingua = "indo"
	_ponta = _boca()
	_percorrido = 0.0
	_carga_invisivel = 0.0


func _mover_lingua(delta: float) -> void:
	match _estado_lingua:
		"indo":
			var passo: float = _dados_lingua["velocidade"] * delta
			var nova := _ponta + direcao * passo
			# Confere a parede a partir do corpo (e não da boca): colado numa
			# parede, a boca já fica dentro dela e a língua passaria direto.
			var batida := _parede_entre(position, nova)
			if not batida.is_empty():
				nova = batida["position"] # a ponta para na parede
			var pego := _camaleao_no_caminho(_ponta, nova)
			_ponta = nova
			_percorrido += passo
			if pego:
				_comecar_puxada(pego)
			elif not batida.is_empty() or _percorrido >= _dados_lingua["alcance"]:
				_estado_lingua = "voltando"
		"voltando":
			var passo: float = _dados_lingua["velocidade"] * delta
			var boca := _boca()
			if _ponta.distance_to(boca) <= passo:
				soltar_lingua(RECARGA_LINGUA)
			else:
				_ponta = _ponta.move_toward(boca, passo)
		"puxando":
			if not (is_instance_valid(_preso) and _preso.vivo):
				soltar_lingua(RECARGA_LINGUA)
				return
			_ponta = _preso.position
			_tempo_puxando += delta
			# Chegou perto (ou ficou preso numa quina por tempo demais): acabou a puxada.
			if position.distance_to(_preso.position) <= DISTANCIA_FIM_PUXADA \
					or _tempo_puxando >= _dados_lingua["tempo_puxada"] + 0.4:
				soltar_lingua(RECARGA_LINGUA)
			elif LINGUA_PODE_SER_CORTADA and _alguem_cortou():
				soltar_lingua(RECARGA_SOLTAR)
			elif _bate_em_parede(position, _preso.position):
				# Uma parede ficou no meio (ele foi arrastado por uma quina): solta.
				soltar_lingua(RECARGA_LINGUA)


## Onde a linha de "de" até "ate" bate numa parede ({} se não bate).
## O resultado tem "position" = o ponto da batida.
func _parede_entre(de: Vector2, ate: Vector2) -> Dictionary:
	var consulta := PhysicsRayQueryParameters2D.create(de, ate, 1) # 1 = paredes
	consulta.hit_from_inside = true # começando dentro da parede também conta
	return get_world_2d().direct_space_state.intersect_ray(consulta)


func _bate_em_parede(de: Vector2, ate: Vector2) -> bool:
	return not _parede_entre(de, ate).is_empty()


## Primeiro camaleão (que não seja ele e não esteja sendo puxado) que a ponta
## encosta indo de "de" até "ate". Pega invisíveis também, e eles aparecem.
## Não pega quem está atrás de uma parede.
func _camaleao_no_caminho(de: Vector2, ate: Vector2) -> Node:
	var melhor: Node = null
	var melhor_distancia := INF
	for outro in get_tree().get_nodes_in_group("camaleoes"):
		if outro == self or not outro.vivo or outro._sendo_puxado():
			continue
		var perto := Geometry2D.get_closest_point_to_segment(outro.position, de, ate)
		if perto.distance_to(outro.position) <= RAIO + RAIO_PONTA \
				and not _bate_em_parede(position, outro.position):
			var distancia := de.distance_to(perto)
			if distancia < melhor_distancia:
				melhor = outro
				melhor_distancia = distancia
	return melhor


func _comecar_puxada(alvo: Node) -> void:
	_estado_lingua = "puxando"
	_preso = alvo
	_tempo_puxando = 0.0
	# Velocidade para chegar em tempo_puxada segundos, seja de longe ou de perto.
	var falta := maxf(position.distance_to(alvo.position) - DISTANCIA_FIM_PUXADA, 10.0)
	alvo.ser_puxado(self, falta / _dados_lingua["tempo_puxada"])


## Um terceiro camaleão encostando na língua esticada corta ela.
func _alguem_cortou() -> bool:
	var boca := _boca()
	for outro in get_tree().get_nodes_in_group("camaleoes"):
		if outro == self or outro == _preso or not outro.vivo:
			continue
		var perto := Geometry2D.get_closest_point_to_segment(outro.position, boca, _preso.position)
		if perto.distance_to(outro.position) <= RAIO:
			return true
	return false


## Recolhe a língua na hora (soltando quem estiver preso nela).
func soltar_lingua(recarga: float) -> void:
	if _estado_lingua == "":
		return
	if is_instance_valid(_preso) and _preso.puxado_por == self:
		_preso.puxado_por = null
	_preso = null
	_estado_lingua = ""
	_recarga_lingua = recarga
	_desenho_lingua.queue_redraw()


## Chamado pela língua de outro camaleão quando ela pega este.
func ser_puxado(quem: Node, velocidade: float) -> void:
	soltar_lingua(RECARGA_SOLTAR) # se a língua dele estava fora, ela solta
	if invisivel:
		_aparecer()
	_carga_invisivel = 0.0
	modulate.a = 1.0
	puxado_por = quem
	_velocidade_puxada = velocidade
	_tempo_puxado = 0.0


func _sendo_puxado() -> bool:
	if puxado_por != null and not (is_instance_valid(puxado_por) and puxado_por.vivo):
		puxado_por = null
	return puxado_por != null


## Enquanto é puxado: vai em direção a quem puxou, sem poder andar.
## Depois de TEMPO_ATE_SE_SOLTAR, apertar língua ou golpe solta (o golpe também bate).
func _ser_arrastado(delta: float, tentou_soltar: bool, golpeou: bool) -> void:
	_tempo_puxado += delta
	# Fica virado para quem puxa, então o golpe ao se soltar vai na direção dele.
	var para_quem_puxa := position.direction_to(puxado_por.position)
	if para_quem_puxa != Vector2.ZERO:
		direcao = para_quem_puxa
	if absf(direcao.x) > 0.1:
		_olhando_direita = direcao.x > 0.0
	velocity = para_quem_puxa * _velocidade_puxada
	move_and_slide()
	_passo = 0.0
	if tentou_soltar and _tempo_puxado >= TEMPO_ATE_SE_SOLTAR:
		puxado_por.soltar_lingua(RECARGA_SOLTAR)
		if golpeou:
			_golpear()
	queue_redraw()


func _desenhar_lingua() -> void:
	if _estado_lingua == "":
		return
	var cor_ponta: Color = Linguas.ROSA if lingua == Linguas.BASICA else Linguas.TIPOS[lingua]["cor"]
	Linguas.desenhar(_desenho_lingua, Desenho.boca(_olhando_direita), to_local(_ponta), cor_ponta)


# --- Golpe ------------------------------------------------------------------

func _golpear() -> void:
	if _recarga_golpe > 0.0:
		return
	_recarga_golpe = RECARGA_GOLPE
	# Bater tira da invisibilidade: ele aparece para dar o golpe.
	if invisivel:
		_aparecer()
	var acertou := false
	for outro in get_tree().get_nodes_in_group("camaleoes"):
		if outro == self or not outro.vivo:
			continue
		var para_outro: Vector2 = outro.position - position
		var distancia := para_outro.length()
		var na_frente := absf(direcao.angle_to(para_outro)) <= ANGULO_GOLPE
		if distancia > ALCANCE_GOLPE or (distancia > DISTANCIA_COLADO and not na_frente):
			continue
		if not _bate_em_parede(position, outro.position): # não bate através de parede
			outro.morrer()
			acertou = true
	var efeito := EfeitoGolpe.new()
	efeito.position = position
	efeito.direcao = direcao
	efeito.alcance = ALCANCE_GOLPE
	efeito.abertura = ANGULO_GOLPE
	efeito.acertou = acertou
	mundo.add_child(efeito)


# --- Pés sujos (cocô de pombo) ----------------------------------------------

## Chamado pelo cocô de pombo quando este camaleão pisa nele (ou leva na cabeça).
func sujar_pes(segundos: float) -> void:
	_tempo_pes_sujos = maxf(_tempo_pes_sujos, segundos)


## Com os pés sujos, vai largando pegadas no chão enquanto anda. Elas são
## criadas no mundo (não dentro do camaleão), então aparecem mesmo invisível.
func _deixar_pegadas(delta: float) -> void:
	if _tempo_pes_sujos <= 0.0:
		return
	_tempo_pes_sujos -= delta
	var andou := get_real_velocity().length() * delta
	if andou <= 0.0:
		return
	_andado_desde_pegada += andou
	if _andado_desde_pegada < DISTANCIA_ENTRE_PEGADAS:
		return
	_andado_desde_pegada = 0.0
	_pe_esquerdo = not _pe_esquerdo
	var andando := get_real_velocity().normalized()
	var lado := andando.orthogonal() * (6.0 if _pe_esquerdo else -6.0)
	var pegada := Pegada.new()
	pegada.position = position + Vector2(0, 22) + lado # nos pés
	pegada.rotation = andando.angle()
	mundo.add_child(pegada)


# --- Upgrades de língua -----------------------------------------------------

## Chamado pelo upgrade no chão. Só dá para pegar estando visível e com a língua básica.
func pegar_upgrade(no_chao: Node) -> bool:
	if not vivo or invisivel or lingua != Linguas.BASICA:
		return false
	lingua = no_chao.tipo
	return true


func _largar_upgrade() -> void:
	var no_chao := LinguaNoChao.new()
	no_chao.tipo = lingua
	no_chao.position = position
	mundo.add_child(no_chao)


func morrer() -> void:
	if not vivo:
		return
	soltar_lingua(RECARGA_LINGUA)
	if _sendo_puxado():
		puxado_por.soltar_lingua(RECARGA_LINGUA)
	vivo = false
	var efeito := EfeitoMorte.new()
	efeito.position = position
	efeito.cor = cor
	mundo.add_child.call_deferred(efeito)
	morreu.emit(self)
	queue_free()


# --- Bot de teste -----------------------------------------------------------
# Bem simples: anda até o inimigo visível mais perto, joga a língua quando ele
# está no alcance e golpeia quando está perto. Se for pego, tenta se soltar.

func _pensar_bot(delta: float) -> void:
	_bot_tempo -= delta
	if _bot_tempo > 0.0:
		return
	_bot_tempo = randf_range(0.2, 0.4)
	_bot_mirar = Vector2.ZERO
	if bot == "parado":
		_bot_mover = Vector2.ZERO
		return
	if _sendo_puxado():
		_bot_golpear = randf() < 0.5
		return

	var travado := _bot_mover != Vector2.ZERO and get_real_velocity().length() < VELOCIDADE * 0.3
	var alvo := _mais_perto(_inimigos_visiveis())
	if alvo:
		var para_alvo := alvo.position - position
		var distancia := para_alvo.length()
		_bot_mirar = para_alvo.normalized().rotated(randf_range(-0.15, 0.15))
		if distancia < ALCANCE_GOLPE * 0.9:
			_bot_mover = Vector2.ZERO
			_bot_golpear = true
		else:
			_bot_mover = para_alvo.normalized()
			var alcance: float = Linguas.TIPOS[lingua]["alcance"]
			_bot_lingua = _estado_lingua == "" and distancia < alcance and randf() < 0.4
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
	Desenho.desenhar(self, Transform2D(0.0, escala, 0.0, Vector2.ZERO), cor, direcao, _olhando_direita, _passo)
	if _tempo_pes_sujos > 0.0:
		# Manchinhas de cocô nos pés.
		for x in [-6.0, 8.0]:
			draw_circle(Vector2(x, 23), 3.5, Pegada.COR)
	if lingua != Linguas.BASICA:
		# Bolinha em cima da cabeça com a cor do upgrade de língua.
		var cor_upgrade: Color = Linguas.TIPOS[lingua]["cor"]
		draw_circle(Vector2(0, -42), 6.0, Linguas.CONTORNO)
		draw_circle(Vector2(0, -42), 4.5, cor_upgrade)
	if _carga_invisivel > 0.0:
		# Anel que vai se completando enquanto o botão de invisível é segurado.
		var t := _carga_invisivel / TEMPO_PARA_SUMIR
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(0, 0, 0, 0.3), 5.0, true)
		draw_arc(Vector2.ZERO, 34.0, -PI / 2.0, -PI / 2.0 + TAU * t, 32, Color.WHITE, 3.0, true)
