class_name Bot
extends RefCounted
## Cérebro de um bot. Ele joga com os mesmos botões de um jogador: a cada frame
## devolve o que estaria "apertando" (direcional, golpe, língua e invisível) e
## o camaleão (camaleao.gd) faz o resto, com as mesmas regras de todo mundo.
## Assim ele mira andando para o lado do alvo, precisa segurar o invisível por
## 1 s para sumir, não usa a língua invisível, larga o poder ao sumir etc.
##
## Ele também não trapaceia: só sabe onde está um invisível pelas pistas que
## qualquer jogador veria na tela (sombra no sol, capim mexendo, ondinha na poça
## ou na ponte, pegada de pé sujo, vulto do poder "olho"), ou porque viu ele
## sumir ali. E só às vezes nota a pista, dependendo da dificuldade.
##
## O que a dificuldade muda (números em NIVEIS):
## - reacao: de quanto em quanto tempo ele repensa, quanto demora para golpear
##   quem chegou perto e para tentar se soltar de uma língua.
## - erro_mira / prever: quanto a língua sai torta e o quanto ele adianta a
##   mira para onde o alvo está andando.
## - agressividade: vontade de ir para cima e de jogar a língua (baixo = fica
##   longe, foge de quem chega perto).
## - poderes: vontade de buscar as bolhas e de usar cada poder direito (gancho
##   para fugir ou chegar, muda de pele quando está em perigo, olho para caçar).
## - invisibilidade: vontade de sumir para caçar no corpo a corpo.
## - deteccao: chance de notar cada pista de um invisível (e de não cair na
##   pele velha do poder "muda").
## - cuidado: invisível, evita passar pelo sol, pelo capim e pelas poças.
## - esquiva: chance de sair da frente de uma língua vindo na direção dele.
## - memoria: por quantos segundos ele lembra onde viu um invisível.

const Mapas := preload("res://scripts/mapas.gd")
const Linguas := preload("res://scripts/linguas.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")
const Caminhos := preload("res://scripts/caminhos.gd")

const NIVEIS := {
	"facil": {
		"reacao": 0.55, "erro_mira": 0.3, "prever": 0.0, "agressividade": 0.35,
		"poderes": 0.25, "invisibilidade": 0.12, "deteccao": 0.15, "cuidado": 0.0,
		"esquiva": 0.05, "memoria": 1.5,
	},
	"medio": {
		"reacao": 0.32, "erro_mira": 0.14, "prever": 0.5, "agressividade": 0.6,
		"poderes": 0.6, "invisibilidade": 0.35, "deteccao": 0.45, "cuidado": 0.45,
		"esquiva": 0.35, "memoria": 3.0,
	},
	"dificil": {
		"reacao": 0.16, "erro_mira": 0.05, "prever": 1.0, "agressividade": 0.85,
		"poderes": 0.95, "invisibilidade": 0.6, "deteccao": 0.85, "cuidado": 0.9,
		"esquiva": 0.7, "memoria": 5.0,
	},
}

## Pés do camaleão (onde pisa no capim, na poça, no grude).
const PES := Desenho.PES
## Distância que ele tenta manter quando não quer briga (fora do alcance da língua).
const DISTANCIA_SEGURA := 420.0
## Quanto à frente ele confere parede e água antes de andar.
const OLHAR_A_FRENTE := 46.0
## Empurrão do direcional só para virar (mirar) sem sair andando.
const TOQUE_MIRAR := 0.15
## O gancho só vale se o voo deixar pelo menos isso mais perto (ou mais longe, fugindo).
const GANHO_GANCHO := 150.0
## Invisível há tanto tempo sem achar ninguém: aparece de novo.
const TEMPO_MAXIMO_INVISIVEL := 12.0

var eu: CharacterBody2D # o camaleão que este cérebro controla
var nivel: Dictionary = {}

var _tempo_pensar := 0.0
var _destino := Vector2.INF # para onde está andando (INF = parado)
var _mira_lingua := Vector2.ZERO # vai jogar a língua nesta direção assim que puder
var _validade_mira := 0.0
var _quer_sumir := false # segurando o invisível até sumir
var _tempo_segurando := 0.0
var _quer_aparecer := false
var _quer_muda := false # um toque no invisível com o poder "muda"
var _tempo_perto := 0.0 # há quanto tempo tem alguém ao alcance do golpe
var _tempo_travado := 0.0
var _fuga_travado := Vector2.ZERO # direção sorteada para sair de uma quina
var _tempo_fuga_travado := 0.0
var _esquiva := Vector2.ZERO
var _tempo_esquiva := 0.0
var _tempo_invisivel := 0.0
var _sem_alvo := 0.0 # segundos sem saber onde está ninguém
var _evitar_pistas := false
var _lado := 1.0 # para que lado contorna as paredes (fica o mesmo por um tempo)
var _rota: Array[Vector2] = [] # caminho pelo mapa até o destino (caminhos.gd)
var _rota_para := Vector2.INF # para qual destino a rota foi calculada
var _tempo_rota := 0.0 # quando recalcular a rota
var _tentou_se_soltar := false
var _brigando := true # no momento quer ir para cima (sorteado pela agressividade)
var _tempo_humor := 0.0 # quando sorteia de novo se quer briga
var _intervalo := 0.3 # quanto tempo passou desde a última vez que pensou
var _indo_na_bolha := 0.0 # segundos que ainda fica decidido a buscar uma bolha
var _chave_golpe: Variant = null # de qual lembrança veio o alvo do golpe (para esquecer depois)
var _estava_invisivel: Dictionary = {} # camaleão -> estava invisível na última olhada
## O que ele sabe dos invisíveis: camaleão -> {"pos", "vel", "idade"}.
var _memoria: Dictionary = {}
## Peles velhas (poder "muda"): casca -> true se ele acha que é um camaleão de verdade.
var _cascas: Dictionary = {}


func _init(camaleao: CharacterBody2D, dificuldade: String) -> void:
	eu = camaleao
	nivel = NIVEIS.get(dificuldade, NIVEIS["medio"])
	_tempo_pensar = randf_range(0.2, 0.6) # não sai todo mundo pensando junto
	_lado = 1.0 if randf() < 0.5 else -1.0


## Os botões do bot neste frame (o camaleão lê como se fosse um controle).
func agir(delta: float) -> Dictionary:
	var acoes := {
		"mover": Vector2.ZERO, "golpe": false, "lingua": false,
		"apertou_invisivel": false, "segurando_invisivel": false,
	}
	var reacao: float = nivel["reacao"]
	_tempo_pensar -= delta
	if _tempo_pensar <= 0.0:
		_intervalo = maxf(reacao * randf_range(0.6, 1.0), 0.08)
		_tempo_pensar = _intervalo
		_pensar()
	if eu.invisivel:
		_tempo_invisivel += delta
	else:
		_tempo_invisivel = 0.0

	# Sendo puxado pela língua de alguém: depois de reagir, golpeia para se soltar
	# (o golpe solta e ainda bate em quem puxou, se ele estiver perto).
	if eu._sendo_puxado():
		if not _tentou_se_soltar and eu._tempo_puxado >= maxf(reacao, eu.TEMPO_ATE_SE_SOLTAR):
			_tentou_se_soltar = true
			acoes["golpe"] = true
		return acoes
	_tentou_se_soltar = false

	# Língua fora: fica parado esperando (apertar de novo soltaria).
	if eu._estado_lingua != "":
		return acoes

	# Alguém ao alcance do golpe (visto, ou um invisível que ele acabou de notar):
	# golpeia depois de um tempinho de reação.
	var alvo_golpe := _alvo_do_golpe()
	if alvo_golpe != Vector2.INF:
		_tempo_perto += delta
		if _tempo_perto >= reacao * 0.6 and eu._recarga_golpe <= 0.0:
			_tempo_perto = 0.0
			acoes["mover"] = eu.position.direction_to(alvo_golpe) * TOQUE_MIRAR
			acoes["golpe"] = true
			if _chave_golpe != null:
				_memoria.erase(_chave_golpe) # golpeou onde achava que ele estava: acertou ou errou
			return acoes
	else:
		_tempo_perto = 0.0

	# Poder "muda": um toque no invisível troca de pele e some na hora.
	if _quer_muda:
		_quer_muda = false
		if eu.lingua == "muda" and not eu.invisivel:
			acoes["apertou_invisivel"] = true
			return acoes

	# Língua planejada: vira para o lado (como um jogador mirando) e lança.
	_validade_mira -= delta
	if _mira_lingua != Vector2.ZERO:
		if _validade_mira <= 0.0 or eu.invisivel:
			_mira_lingua = Vector2.ZERO
		elif _pode_lancar_lingua():
			acoes["mover"] = _mira_lingua * TOQUE_MIRAR
			acoes["lingua"] = true
			_mira_lingua = Vector2.ZERO
			_quer_sumir = false
			return acoes

	# Invisibilidade: segura o botão até sumir; um toque para aparecer.
	if _quer_sumir and not eu.invisivel:
		_tempo_segurando += delta
		# Manda "apertou" junto toda vez: se um golpe ou a língua interromper,
		# a carga recomeça como se ele tivesse apertado de novo.
		acoes["segurando_invisivel"] = true
		acoes["apertou_invisivel"] = true
		if _tempo_segurando > eu.TEMPO_PARA_SUMIR + 0.5:
			_quer_sumir = false # não deu (ficou preso, a língua saiu...): desiste
	else:
		_quer_sumir = false
		_tempo_segurando = 0.0
	if _quer_aparecer:
		_quer_aparecer = false
		if eu.invisivel:
			acoes["apertou_invisivel"] = true

	acoes["mover"] = _movimento(delta)
	return acoes


# --- Pensar (algumas vezes por segundo, conforme a reação) ---------------------

func _pensar() -> void:
	_olhar(_intervalo)
	_indo_na_bolha -= _intervalo
	_tempo_humor -= _intervalo
	if _tempo_humor <= 0.0:
		_brigando = randf() < float(nivel["agressividade"])
		_tempo_humor = randf_range(1.0, 2.5)
	var agressividade: float = nivel["agressividade"]
	var poderes: float = nivel["poderes"]
	_evitar_pistas = eu.invisivel and randf() < float(nivel["cuidado"])

	var alvo := _alvo_visivel()
	var suspeita := _suspeita_mais_recente()
	_sem_alvo = 0.0 if (alvo or suspeita != Vector2.INF) else _sem_alvo + _intervalo

	if _desviar_de_lingua():
		return

	# Em perigo (alguém visível chegando perto): com a muda, troca de pele; com o
	# gancho, foge voando; se for pouco agressivo, se afasta.
	if alvo and not eu.invisivel:
		var distancia := eu.position.distance_to(alvo.position)
		if distancia < 240.0 and eu.lingua == "muda" and randf() < poderes:
			_quer_muda = true
			_destino = _ponto_longe_de(alvo.position)
			return
		# Fugir com o gancho: mais para quem é pouco agressivo (chance por segundo).
		var chance_fuga := poderes * (1.0 - agressividade) * 1.5 * _intervalo
		if distancia < 200.0 and eu.lingua == "gancho" and randf() < chance_fuga:
			var fuga := _direcao_gancho(alvo.position, true)
			if fuga != Vector2.ZERO:
				_planejar_lingua(fuga)
				return

	if eu.invisivel:
		_pensar_invisivel(alvo, suspeita)
		return

	if alvo:
		# Alvo longe: às vezes aproveita para buscar uma bolha ou sumir antes.
		var longe := eu.position.distance_to(alvo.position) > 450.0
		if longe and (_buscar_bolha(poderes, alvo.position) or _talvez_sumir(poderes)):
			return
		_pensar_com_alvo(alvo.position, _velocidade_de(alvo), _grudado(alvo), agressividade, poderes)
	elif suspeita != Vector2.INF:
		# Um invisível foi notado: a língua pega (e revela) invisível também.
		_pensar_com_alvo(suspeita, Vector2.ZERO, false, agressividade, poderes)
	else:
		_pensar_sem_alvo(poderes)
	_talvez_gancho(poderes)


## Poder "gancho": em vez de andar até longe, se puxa pelas paredes (chance por
## segundo, conforme "poderes"). Só quando um voo deixa bem mais perto do destino.
func _talvez_gancho(poderes: float) -> void:
	if eu.lingua != "gancho" or eu.invisivel or _mira_lingua != Vector2.ZERO or _destino == Vector2.INF:
		return
	if eu.position.distance_to(_destino) < 280.0 or not _pode_lancar_lingua():
		return
	if randf() < poderes * 1.5 * _intervalo:
		var direcao := _direcao_gancho(_destino, false)
		if direcao != Vector2.ZERO:
			var destino := _destino
			_planejar_lingua(direcao)
			_destino = destino # depois do voo continua indo para o mesmo lugar


## Está preso num grude (não anda nem usa a língua por um tempinho)?
func _grudado(alvo: Node2D) -> bool:
	if not (alvo is CharacterBody2D):
		return false
	var tempo: float = alvo._tempo_grudado
	return tempo > 0.0


## Com um alvo à vista (ou suspeita de onde está um invisível).
## preso: o alvo está grudado num grude (hora de correr e golpear).
func _pensar_com_alvo(onde: Vector2, velocidade: Vector2, preso: bool, agressividade: float,
		poderes: float) -> void:
	var distancia := eu.position.distance_to(onde)
	var alcance: float = Linguas.TIPOS[eu.lingua]["alcance"]
	var parede: bool = eu._bate_em_parede(eu.position, onde)
	var caminho_livre := not parede
	if distancia <= eu.ALCANCE_GOLPE * 0.9 and not parede:
		_destino = Vector2.INF # o golpe é tratado a cada frame em agir()
		return
	# Grudado não foge: perto, corre e golpeia (a língua arrancaria ele do grude).
	if preso and (distancia < 320.0 or parede):
		_destino = onde
		return
	# Poder "grude": joga a língua no caminho de quem vem, mesmo de longe. Se
	# errar, o rastro de grude fica no chão entre os dois e prende quem passar.
	if eu.lingua == "grude" and caminho_livre and _pode_lancar_lingua() \
			and distancia >= alcance * 0.92 and distancia < alcance + 380.0 \
			and randf() < poderes * 1.5 * _intervalo:
		_planejar_lingua(eu.position.direction_to(onde + velocidade * 0.7))
		return
	if caminho_livre and distancia < alcance * 0.92 and _pode_lancar_lingua() \
			and randf() < 0.25 + 0.6 * agressividade:
		_planejar_lingua(_mirar(onde, velocidade, distancia))
		return
	if _brigando:
		_destino = onde
	elif distancia < DISTANCIA_SEGURA:
		_destino = _ponto_longe_de(onde)
	else:
		# Longe o bastante: anda de lado, esperando uma chance.
		var lado := eu.position.direction_to(onde).orthogonal() * _lado
		_destino = _limitar_arena(eu.position + lado * 120.0)


## Invisível: caça no corpo a corpo (não dá para usar a língua).
func _pensar_invisivel(alvo: Node2D, suspeita: Vector2) -> void:
	var onde := Vector2.INF
	if alvo:
		onde = alvo.position
	elif suspeita != Vector2.INF:
		onde = suspeita
	if onde != Vector2.INF:
		_destino = onde
		return
	# Ninguém por perto: depois de um tempo, aparece de novo (para usar a língua
	# ou pegar uma bolha).
	var tem_bolha := not eu.get_tree().get_nodes_in_group("upgrades_no_chao").is_empty()
	if _tempo_invisivel > TEMPO_MAXIMO_INVISIVEL or (_sem_alvo > 4.0 and (tem_bolha or randf() < 0.3)):
		_quer_aparecer = true
	if _destino == Vector2.INF or eu.position.distance_to(_destino) < 40.0:
		_destino = _ponto_qualquer()


## Ninguém à vista: busca bolha de poder, pensa em sumir ou passeia.
func _pensar_sem_alvo(poderes: float) -> void:
	if _buscar_bolha(poderes, Vector2.INF):
		return
	_talvez_sumir(poderes)
	if _destino == Vector2.INF or eu.position.distance_to(_destino) < 40.0 or randf() < 0.05:
		_destino = _ponto_qualquer()


## Vai atrás de uma bolha de poder (passando por cima ou puxando com a língua),
## se estiver com a língua básica e tiver vontade. Com um inimigo em "inimigo",
## só se a bolha estiver mais perto que ele. Devolve true se decidiu ir.
func _buscar_bolha(poderes: float, inimigo: Vector2) -> bool:
	var lingua: String = eu.lingua
	if lingua != Linguas.BASICA:
		return false
	var bolha := _bolha_mais_perto()
	if bolha == null:
		return false
	var distancia := eu.position.distance_to(bolha.position)
	if inimigo != Vector2.INF and distancia > eu.position.distance_to(inimigo):
		return false
	if _indo_na_bolha <= 0.0:
		if randf() >= poderes:
			return false
		_indo_na_bolha = 1.5 # decidiu: não fica mudando de ideia a cada instante
	var alcance: float = Linguas.TIPOS[lingua]["alcance"]
	var parede: bool = eu._bate_em_parede(eu.position, bolha.position)
	if distancia < alcance * 0.9 and distancia > 80.0 and _pode_lancar_lingua() and not parede:
		_planejar_lingua(eu.position.direction_to(bolha.position)) # puxa com a língua
	else:
		_destino = bolha.position # ou passa por cima
	return true


## De vez em quando (conforme "invisibilidade") começa a sumir para caçar
## escondido. Sumir larga o poder (menos a muda), então quem liga para os
## poderes só some com a língua básica. Devolve true se decidiu sumir.
func _talvez_sumir(poderes: float) -> bool:
	if _quer_sumir or eu.invisivel:
		return false
	var lingua: String = eu.lingua
	var pode_sumir := lingua == Linguas.BASICA or lingua == "muda" or randf() > poderes
	var chance := float(nivel["invisibilidade"]) * 0.4 * _intervalo # por segundo
	if pode_sumir and randf() < chance and not _deixaria_pista(eu.position):
		if lingua == "muda":
			_quer_muda = true
		else:
			_quer_sumir = true
		return true
	return false


func _planejar_lingua(direcao: Vector2) -> void:
	_mira_lingua = direcao.normalized()
	_validade_mira = 0.35
	_destino = Vector2.INF


func _pode_lancar_lingua() -> bool:
	return not eu.invisivel and eu._estado_lingua == "" and eu._recarga_lingua <= 0.0 \
		and eu._tempo_grudado <= 0.0


## Direção da língua para pegar quem está em "onde": adianta a mira para onde
## ele está andando (conforme "prever") e erra um pouco (conforme "erro_mira").
func _mirar(onde: Vector2, velocidade: Vector2, distancia: float) -> Vector2:
	var rapidez: float = Linguas.TIPOS[eu.lingua]["velocidade"]
	var adiantado := onde + velocidade * (distancia / rapidez) * float(nivel["prever"])
	var erro: float = nivel["erro_mira"]
	return eu.position.direction_to(adiantado).rotated(randf_range(-erro, erro))


## Uma língua vindo na direção dele? Às vezes (esquiva) ele sai para o lado.
func _desviar_de_lingua() -> bool:
	for outro in _outros():
		if outro._estado_lingua != "indo" or outro.invisivel:
			continue
		var para_mim: Vector2 = eu.position - outro.position
		var alcance: float = Linguas.TIPOS[outro.lingua]["alcance"]
		var dir: Vector2 = outro.direcao
		var na_frente := para_mim.dot(dir)
		var de_lado := absf(para_mim.cross(dir))
		if na_frente > 0.0 and na_frente < alcance + 30.0 and de_lado < 50.0 \
				and randf() < float(nivel["esquiva"]):
			var lado := dir.orthogonal()
			if lado.dot(para_mim) < 0.0:
				lado = -lado
			_esquiva = lado
			_tempo_esquiva = 0.35
			return true
	return false


# --- Olhar (o que ele vê na tela) -------------------------------------------

func _outros() -> Array:
	var lista: Array = []
	for outro in eu.get_tree().get_nodes_in_group("camaleoes"):
		if outro != eu and outro.vivo:
			lista.append(outro)
	return lista


## Visível para ele: quem não está invisível, ou está dentro do "olho".
func _ve(outro: Node) -> bool:
	return not outro.invisivel or eu._enxerga(outro)


## Atualiza o que ele sabe sobre os invisíveis, só com o que dá para ver na tela.
func _olhar(passou: float) -> void:
	var deteccao: float = nivel["deteccao"]
	var memoria: float = nivel["memoria"]
	for outro in _outros():
		if _ve(outro):
			_memoria.erase(outro)
			_estava_invisivel[outro] = false
			continue
		# Acabou de sumir na frente dele: lembra onde foi (a menos que tenha usado muda de pele,
		# caso em que a casca fica no lugar e o bot só descobre se notar pista visual).
		if _estava_invisivel.get(outro, false) == false:
			var usou_muda := false
			for casca in eu.get_tree().get_nodes_in_group("cascas"):
				if not casca.is_queued_for_deletion() and casca.position.distance_to(outro.position) < 50.0:
					usou_muda = true
					break
			if not usou_muda and randf() < 0.4 + deteccao * 0.6:
				_memoria[outro] = {"pos": outro.position, "vel": Vector2.ZERO, "idade": 0.0}
		_estava_invisivel[outro] = true
		var erro := _pista_de(outro)
		if erro >= 0.0 and randf() < deteccao:
			var chute: Vector2 = outro.position + Vector2.from_angle(randf() * TAU) * randf() * erro
			_memoria[outro] = {"pos": chute, "vel": outro.get_real_velocity(), "idade": 0.0}
	for outro in _memoria.keys():
		var lembranca: Dictionary = _memoria[outro]
		lembranca["idade"] = float(lembranca["idade"]) + passou
		if not is_instance_valid(outro) or not outro.vivo or float(lembranca["idade"]) > memoria:
			_memoria.erase(outro)
	for outro in _estava_invisivel.keys():
		if not is_instance_valid(outro):
			_estava_invisivel.erase(outro)
	# Pele velha do "muda": parece um camaleão parado. Quem tem pouca detecção cai.
	for casca in eu.get_tree().get_nodes_in_group("cascas"):
		if not _cascas.has(casca):
			_cascas[casca] = randf() > deteccao * 0.9
	for casca in _cascas.keys():
		if not is_instance_valid(casca) or casca.is_queued_for_deletion():
			_cascas.erase(casca)


## Se um invisível está deixando alguma pista na tela agora, devolve o quanto
## ela é imprecisa (em px); -1 se não deixa nenhuma.
func _pista_de(outro: Node) -> float:
	var mapa: Dictionary = eu.mapa
	var pes: Vector2 = outro.position + PES
	var andando: bool = outro.get_real_velocity().length() > 20.0
	if Mapas.na_luz(mapa, outro.position + PES):
		return 8.0 # sombra no sol: bem certinho
	if Mapas.na_poca(mapa, pes) and (andando or randf() < 0.3):
		return 14.0 # ondinhas
	if outro._tempo_pes_sujos > 0.0 and andando:
		return 18.0 # pegadas
	for item in mapa.get("grama", []):
		var capim: Rect2 = item
		if Mapas.dentro_arredondado(capim, pes):
			return 28.0 # capim deitando
	if andando and Mapas.ponte_em(mapa, pes).has_area():
		return 30.0 # ondinhas do lado da ponte
	return -1.0


## Inimigo visível (ou pele velha que ele acha que é inimigo) mais perto.
func _alvo_visivel() -> Node2D:
	var candidatos: Array = []
	for outro in _outros():
		if _ve(outro):
			candidatos.append(outro)
	for casca in _cascas:
		if _cascas[casca] and is_instance_valid(casca):
			candidatos.append(casca)
	return _mais_perto(candidatos)


## Onde ele acha que está o invisível de que se lembra mais recentemente
## (adiantado para onde ele estava indo, conforme "prever").
func _suspeita_mais_recente() -> Vector2:
	var melhor := Vector2.INF
	var menor_idade := INF
	for outro in _memoria:
		var lembranca: Dictionary = _memoria[outro]
		var idade: float = lembranca["idade"]
		if idade < menor_idade:
			menor_idade = idade
			var pos: Vector2 = lembranca["pos"]
			var vel: Vector2 = lembranca["vel"]
			melhor = pos + vel * minf(idade, 1.0) * float(nivel["prever"])
	return melhor


## Onde golpear agora: alguém visível (ou pele velha) ao alcance, ou um
## invisível que ele acabou de notar ali perto. Vector2.INF = ninguém.
func _alvo_do_golpe() -> Vector2:
	var alcance: float = eu.ALCANCE_GOLPE * 0.9
	_chave_golpe = null
	var alvo := _alvo_visivel()
	if alvo and eu.position.distance_to(alvo.position) <= alcance \
			and not eu._bate_em_parede(eu.position, alvo.position):
		return alvo.position
	for outro in _memoria:
		var lembranca: Dictionary = _memoria[outro]
		var pos: Vector2 = lembranca["pos"]
		if eu.position.distance_to(pos) <= alcance and not eu._bate_em_parede(eu.position, pos):
			_chave_golpe = outro
			return pos
	return Vector2.INF


func _velocidade_de(alvo: Node2D) -> Vector2:
	if alvo is CharacterBody2D:
		var corpo: CharacterBody2D = alvo
		return corpo.get_real_velocity()
	return Vector2.ZERO


func _bolha_mais_perto() -> Node2D:
	var lista: Array = []
	for item in eu.get_tree().get_nodes_in_group("upgrades_no_chao"):
		if not item.na_lingua and not Mapas.na_agua(eu.mapa, item.position):
			lista.append(item)
	return _mais_perto(lista)


func _mais_perto(nos: Array) -> Node2D:
	var melhor: Node2D = null
	var melhor_distancia := INF
	for no in nos:
		var no2d: Node2D = no
		var distancia := eu.position.distance_to(no2d.position)
		if distancia < melhor_distancia:
			melhor = no2d
			melhor_distancia = distancia
	return melhor


# --- Andar ------------------------------------------------------------------

## Direção do direcional neste frame: vai para o destino pelo caminho do mapa
## (contornando paredes e rios), desviando no caminho de água, grude e, se for
## o caso, de lugares que deixam pista.
func _movimento(delta: float) -> Vector2:
	if _tempo_esquiva > 0.0:
		_tempo_esquiva -= delta
		return _contornar(_esquiva)
	if _tempo_fuga_travado > 0.0:
		_tempo_fuga_travado -= delta
		return _contornar(_fuga_travado)
	if _destino == Vector2.INF or eu.position.distance_to(_destino) < 12.0:
		_tempo_travado = 0.0
		return Vector2.ZERO
	var direcao := _contornar(eu.position.direction_to(_proximo_ponto(delta)))
	# Querendo andar mas quase parado (enroscado numa quina): sai para um lado
	# um pouco e calcula a rota de novo.
	if direcao != Vector2.ZERO and eu.get_real_velocity().length() < eu.VELOCIDADE * 0.25:
		_tempo_travado += delta
		if _tempo_travado > 0.5:
			_tempo_travado = 0.0
			_fuga_travado = _contornar(Vector2.from_angle(randf() * TAU))
			_tempo_fuga_travado = 0.35
			_lado = -_lado
			_tempo_rota = 0.0
	else:
		_tempo_travado = 0.0
	return direcao


## Para onde andar agora: direto para o destino se der (nada no meio), senão o
## ponto mais adiantado da rota que dá para alcançar em linha reta.
func _proximo_ponto(delta: float) -> Vector2:
	if _trajeto_livre(eu.position, _destino):
		_rota.clear()
		_tempo_rota = 0.0
		return _destino
	_tempo_rota -= delta
	if _tempo_rota <= 0.0 or _rota_para.distance_to(_destino) > 40.0:
		_rota = Caminhos.caminho(eu.mapa, eu.position, _destino)
		_rota_para = _destino
		_tempo_rota = 0.6
	while not _rota.is_empty() and eu.position.distance_to(_rota[0]) < 16.0:
		_rota.remove_at(0)
	if _rota.is_empty():
		return _destino
	# Pula os pontos do meio quando dá para ir reto até um mais adiante.
	var melhor := 0
	for i in range(1, mini(_rota.size(), 6)):
		if _trajeto_livre(eu.position, _rota[i]):
			melhor = i
	for _i in melhor:
		_rota.remove_at(0)
	return _rota[0]


## Dá para andar em linha reta daqui até lá sem bater (o corpo todo) nem cair na água?
func _trajeto_livre(de: Vector2, ate: Vector2) -> bool:
	if Mapas.caminho_afunda(eu.mapa, de, ate, 10.0):
		return false
	var raio: float = eu.RAIO
	var lado := de.direction_to(ate).orthogonal() * (raio - 2.0)
	for desvio: Vector2 in [Vector2.ZERO, lado, -lado]:
		if eu._bate_em_parede(de + desvio, ate + desvio):
			return false
	return true


## A direção livre mais parecida com a desejada (gira um pouco por vez para o
## lado preferido e para o outro). ZERO se estiver tudo bloqueado.
func _contornar(desejada: Vector2) -> Vector2:
	if desejada == Vector2.ZERO:
		return Vector2.ZERO
	if _livre(desejada):
		return desejada
	for passo in range(1, 9):
		for sinal: float in [_lado, -_lado]:
			var tentativa := desejada.rotated(sinal * passo * 0.35)
			if _livre(tentativa):
				return tentativa
	return Vector2.ZERO


func _livre(direcao: Vector2) -> bool:
	var a_frente := eu.position + direcao * OLHAR_A_FRENTE
	if Mapas.caminho_afunda(eu.mapa, eu.position, a_frente):
		return false
	# Confere o corpo todo (o meio e os dois lados), não só uma linha.
	var raio: float = eu.RAIO
	var lado := direcao.orthogonal() * (raio - 2.0)
	for desvio: Vector2 in [Vector2.ZERO, lado, -lado]:
		if eu._bate_em_parede(eu.position + desvio, a_frente + desvio):
			return false
	if float(nivel["cuidado"]) > 0.3 and _pisaria_grude(a_frente):
		return false
	if _evitar_pistas and _deixaria_pista(a_frente) and not _deixaria_pista(eu.position):
		return false
	return true


func _pisaria_grude(ponto: Vector2) -> bool:
	for grude in eu.get_tree().get_nodes_in_group("grudes"):
		if grude.dono != eu and grude._pisou(ponto + PES):
			return true
	return false


## Este lugar entrega quem está invisível (sol, poça, capim)?
func _deixaria_pista(ponto: Vector2) -> bool:
	var mapa: Dictionary = eu.mapa
	if Mapas.na_luz(mapa, ponto + PES) or Mapas.na_poca(mapa, ponto + PES):
		return true
	for item in mapa.get("grama", []):
		var capim: Rect2 = item
		if Mapas.dentro_arredondado(capim, ponto + PES):
			return true
	return false


## Garante que o ponto fique dentro dos limites internos navegáveis da arena.
func _limitar_arena(ponto: Vector2) -> Vector2:
	return Vector2(
		clampf(ponto.x, 65.0, 1535.0),
		clampf(ponto.y, 65.0, 835.0)
	)


## Um ponto do outro lado, longe de "perigo".
func _ponto_longe_de(perigo: Vector2) -> Vector2:
	var para_longe := perigo.direction_to(eu.position)
	if para_longe == Vector2.ZERO:
		para_longe = Vector2.from_angle(randf() * TAU)
	var ponto := eu.position + para_longe.rotated(randf_range(-0.6, 0.6)) * 250.0
	return _limitar_arena(ponto)


## Um lugar sorteado do chão para passear (fora das paredes e da água).
func _ponto_qualquer() -> Vector2:
	for _tentativa in 20:
		var ponto := Vector2(randf_range(90.0, 1510.0), randf_range(90.0, 810.0))
		if Mapas.lugar_livre(eu.mapa, ponto, 30.0):
			return ponto
	return eu.position


## Poder "gancho": direção para jogar a língua numa parede e voar até ela.
## longe = true: a parede que deixa mais longe de "ponto" (fugir); false: a
## que deixa mais perto (chegar). Só vale se o voo ajudar de verdade (pelo
## menos GANHO_GANCHO px), não enroscar em quina no caminho e não terminar na
## água. ZERO se nenhuma serve.
func _direcao_gancho(ponto: Vector2, longe: bool) -> Vector2:
	var alcance: float = Linguas.TIPOS["gancho"]["alcance"]
	var raio: float = eu.RAIO
	var agora := eu.position.distance_to(ponto)
	var melhor := Vector2.ZERO
	var melhor_nota := -INF
	for i in 24:
		var direcao := Vector2.from_angle(TAU * i / 24.0)
		var batida: Dictionary = eu._parede_entre(eu.position, eu.position + direcao * alcance)
		if batida.is_empty():
			continue
		var parede: Vector2 = batida["position"]
		var voo := eu.position.distance_to(parede)
		if voo < 140.0:
			continue
		# O voo para a RAIO + 8 px da parede (camaleao.gd).
		var chegada := parede - direcao * (raio + 8.0)
		if Mapas.afunda(eu.mapa, chegada) or Mapas.afunda(eu.mapa, chegada - direcao * 20.0):
			continue
		# Os lados do corpo também não podem bater antes (senão enrosca numa quina e cai no meio).
		var lado := direcao.orthogonal() * (raio - 2.0)
		var enrosca := false
		for desvio: Vector2 in [lado, -lado]:
			var batida_lado: Dictionary = eu._parede_entre(eu.position + desvio, chegada + desvio)
			if not batida_lado.is_empty():
				enrosca = true
		if enrosca:
			continue
		var depois := chegada.distance_to(ponto)
		var nota := depois - agora if longe else agora - depois
		if nota < GANHO_GANCHO:
			continue
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = direcao
	return melhor
