class_name GramaAlta
extends Node2D
## Capim alto ("grama" em mapas.gd). As folhas da frente de um camaleão são
## desenhadas por cima dele e as de trás por baixo, então quem está dentro fica
## meio escondido (só a cabeça aparece).
## Quando alguém passa, visível ou invisível, as folhas se deitam para os lados,
## ficam mais claras e demoram para voltar: fica um rastro de por onde a pessoa andou.

const Mapas := preload("res://scripts/mapas.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

## Uma folha a cada tantos pixels quadrados de capim.
const AREA_POR_FOLHA := 150.0
## Até onde um camaleão empurra as folhas (a partir dos pés).
const RAIO_EMPURRAO := 30.0
## Quanto a folha deita no máximo (em radianos).
const DOBRA_MAXIMA := 1.1
## Velocidade com que a folha deita quando alguém passa e com que volta ao lugar.
## Voltar devagar é o que deixa o rastro.
const VELOCIDADE_DEITAR := 9.0
const VELOCIDADE_VOLTAR := 0.8
## Os pés ficam um pouco abaixo do centro do camaleão.
const PES := Desenho.PES

const COR := Color(0.36, 0.58, 0.22)
const COR_CONTORNO := Color(0.12, 0.22, 0.08)
const COR_DEITADA := Color(0.72, 0.78, 0.42)

var mapa: Dictionary = {}
# Cada folha: [base, altura, cor, fase do vento, inclinação parada, dobra atual, atrás de alguém, indice_bloco]
var _folhas: Array = []
var _blocos: Array = [] # cada um: {"area": Rect2, "tem_dobra": bool, "pes": Array}
var _tempo := 0.0
var _atras: Node2D # desenha as folhas que estão atrás de algum camaleão (por baixo dele)
var _tinha_atras := false

# Buffers reutilizados para desenhar em lote sem alocações repetidas a cada quadro
var _pontos_frente := PackedVector2Array()
var _cores_frente := PackedColorArray()
var _pontos_tras := PackedVector2Array()
var _cores_tras := PackedColorArray()


func _ready() -> void:
	z_index = 1 # por cima dos camaleões
	_atras = Node2D.new()
	_atras.z_index = -2 # 1 - 2 = -1: por baixo dos camaleões
	_atras.draw.connect(_desenhar.bind(_atras, true))
	add_child(_atras)
	var rng := RandomNumberGenerator.new()
	rng.seed = mapa.get("semente", 7) + 1000
	var indice_bloco := 0
	for item in mapa.get("grama", []):
		var retangulo: Rect2 = item
		# Área dentro da qual os pés de um camaleão ou casca podem afetar as folhas deste bloco
		var area_afetada := Rect2(retangulo.position.x - 30.0, retangulo.position.y - 30.0,
			retangulo.size.x + 60.0, retangulo.size.y + 90.0)
		_blocos.append({"area": area_afetada, "tem_dobra": false, "pes": []})
		var quantidade := int(retangulo.get_area() / AREA_POR_FOLHA)
		for i in quantidade:
			var base := Vector2(rng.randf_range(retangulo.position.x, retangulo.end.x),
				rng.randf_range(retangulo.position.y, retangulo.end.y))
			if not Mapas.dentro_arredondado(retangulo, base, 4.0):
				continue
			# Folhas da borda são mais baixas, para o capim ter um contorno macio.
			var altura := rng.randf_range(18.0, 30.0)
			if not Mapas.dentro_arredondado(retangulo, base, 18.0):
				altura *= 0.65
			var cor := COR.lightened(rng.randf_range(-0.12, 0.12))
			_folhas.append([base, altura, cor, rng.randf() * TAU, rng.randf_range(-0.25, 0.25), 0.0, false, indice_bloco])
		indice_bloco += 1
	# Desenha de cima para baixo, assim as folhas da frente ficam por cima.
	_folhas.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)

	var n_folhas := _folhas.size()
	_pontos_frente.resize(n_folhas * 4)
	_pontos_frente.clear()
	_cores_frente.resize(n_folhas * 2)
	_cores_frente.clear()
	_pontos_tras.resize(n_folhas * 4)
	_pontos_tras.clear()
	_cores_tras.resize(n_folhas * 2)
	_cores_tras.clear()

	set_process(not _folhas.is_empty())


func _process(delta: float) -> void:
	_tempo += delta
	var pes: Array = []
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if camaleao.vivo:
			pes.append(camaleao.position + PES)
	for casca in get_tree().get_nodes_in_group("cascas"):
		if not casca.is_queued_for_deletion():
			pes.append(casca.position + PES)

	for bloco in _blocos:
		var area: Rect2 = bloco["area"]
		var pes_bloco: Array = []
		for pe in pes:
			if area.has_point(pe):
				pes_bloco.append(pe)
		bloco["pes"] = pes_bloco

	var blocos_com_dobra: Dictionary = {}
	var algum_atras := false
	for folha in _folhas:
		var bloco_idx: int = folha[7]
		var bloco: Dictionary = _blocos[bloco_idx]
		var pes_bloco: Array = bloco["pes"]
		var dobra: float = folha[5]

		# Sem jogadores por perto: pula recálculo de distância e só desdobra se necessário
		if pes_bloco.is_empty():
			if not bloco["tem_dobra"]:
				continue
			if dobra != 0.0:
				dobra = move_toward(dobra, 0.0, VELOCIDADE_VOLTAR * delta)
				folha[5] = dobra
				if dobra != 0.0:
					blocos_com_dobra[bloco_idx] = true
			folha[6] = false
			continue

		var base: Vector2 = folha[0]
		var alvo := 0.0
		var atras := false
		for pe in pes_bloco:
			var dif: Vector2 = base - pe
			# Folha logo acima dos pés (atrás do corpo): vai para a camada de baixo.
			if absf(dif.x) < 30.0 and dif.y < -4.0 and dif.y > -60.0:
				atras = true
			if absf(dif.x) > RAIO_EMPURRAO or absf(dif.y) > RAIO_EMPURRAO:
				continue
			var distancia := dif.length()
			if distancia < RAIO_EMPURRAO:
				# Deita para o lado contrário de quem está pisando.
				var lado := 1.0 if dif.x >= 0.0 else -1.0
				alvo += lado * DOBRA_MAXIMA * (1.0 - distancia / RAIO_EMPURRAO * 0.6)

		alvo = clampf(alvo, -DOBRA_MAXIMA, DOBRA_MAXIMA)
		if absf(alvo) > absf(dobra) or (alvo != 0.0 and signf(alvo) != signf(dobra)):
			dobra = move_toward(dobra, alvo, VELOCIDADE_DEITAR * delta)
		else:
			dobra = move_toward(dobra, alvo, VELOCIDADE_VOLTAR * delta)
		folha[5] = dobra
		folha[6] = atras
		if dobra != 0.0:
			blocos_com_dobra[bloco_idx] = true
		if atras:
			algum_atras = true

	for i in _blocos.size():
		var bloco: Dictionary = _blocos[i]
		bloco["tem_dobra"] = not bloco["pes"].is_empty() or blocos_com_dobra.has(i)

	queue_redraw()
	if algum_atras or _tinha_atras:
		_atras.queue_redraw()
	_tinha_atras = algum_atras


func _draw() -> void:
	_desenhar(self, false)


## Desenha as folhas de uma das camadas (atrás dos camaleões ou na frente).
func _desenhar(item: CanvasItem, camada_de_tras: bool) -> void:
	var pontos: PackedVector2Array = _pontos_tras if camada_de_tras else _pontos_frente
	var cores: PackedColorArray = _cores_tras if camada_de_tras else _cores_frente
	pontos.clear()
	cores.clear()
	for folha in _folhas:
		if folha[6] != camada_de_tras:
			continue
		var base: Vector2 = folha[0]
		var altura: float = folha[1]
		var cor: Color = folha[2]
		var dobra: float = folha[5]
		var vento := sin(_tempo * 1.7 + folha[3]) * 0.07
		var angulo: float = folha[4] + dobra + vento
		var ponta := base + Vector2(sin(angulo), -cos(angulo)) * altura
		var meio := base + Vector2(sin(angulo * 0.5), -cos(angulo * 0.5)) * altura * 0.5
		pontos.append(base)
		pontos.append(meio)
		pontos.append(meio)
		pontos.append(ponta)
		var cor_folha: Color = cor.lerp(COR_DEITADA, absf(dobra) / DOBRA_MAXIMA * 0.7)
		cores.append(cor_folha)
		cores.append(cor_folha)
	if pontos.is_empty():
		return
	item.draw_multiline(pontos, COR_CONTORNO, 3.4, true)
	item.draw_multiline_colors(pontos, cores, 2.2, true)
