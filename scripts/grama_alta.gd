extends Node2D
## Capim alto ("grama" em mapas.gd). As folhas da frente de um camaleão são
## desenhadas por cima dele e as de trás por baixo, então quem está dentro fica
## meio escondido (só a cabeça aparece).
## Quando alguém passa, visível ou invisível, as folhas se deitam para os lados,
## ficam mais claras e demoram para voltar: fica um rastro de por onde a pessoa andou.

const Mapas := preload("res://scripts/mapas.gd")

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
const PES := Vector2(0, 18)

const COR := Color(0.36, 0.58, 0.22)
const COR_CONTORNO := Color(0.12, 0.22, 0.08)
const COR_DEITADA := Color(0.72, 0.78, 0.42)

var mapa: Dictionary = {}
# Cada folha: [base, altura, cor, fase do vento, inclinação parada, dobra atual, atrás de alguém]
var _folhas: Array = []
var _tempo := 0.0
var _atras: Node2D # desenha as folhas que estão atrás de algum camaleão (por baixo dele)


func _ready() -> void:
	z_index = 1 # por cima dos camaleões
	_atras = Node2D.new()
	_atras.z_index = -2 # 1 - 2 = -1: por baixo dos camaleões
	_atras.draw.connect(_desenhar.bind(_atras, true))
	add_child(_atras)
	var rng := RandomNumberGenerator.new()
	rng.seed = mapa.get("semente", 7) + 1000
	for item in mapa.get("grama", []):
		var retangulo: Rect2 = item
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
			_folhas.append([base, altura, cor, rng.randf() * TAU, rng.randf_range(-0.25, 0.25), 0.0, false])
	# Desenha de cima para baixo, assim as folhas da frente ficam por cima.
	_folhas.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	set_process(not _folhas.is_empty())


func _process(delta: float) -> void:
	_tempo += delta
	var pes: Array = []
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if camaleao.vivo:
			pes.append(camaleao.position + PES)
	for folha in _folhas:
		var base: Vector2 = folha[0]
		var alvo := 0.0
		var atras := false
		for pe in pes:
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
		var dobra: float = folha[5]
		if absf(alvo) > absf(dobra) or (alvo != 0.0 and signf(alvo) != signf(dobra)):
			dobra = move_toward(dobra, alvo, VELOCIDADE_DEITAR * delta)
		else:
			dobra = move_toward(dobra, alvo, VELOCIDADE_VOLTAR * delta)
		folha[5] = dobra
		folha[6] = atras
	queue_redraw()
	_atras.queue_redraw()


func _draw() -> void:
	_desenhar(self, false)


## Desenha as folhas de uma das camadas (atrás dos camaleões ou na frente).
func _desenhar(item: CanvasItem, camada_de_tras: bool) -> void:
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
		var linha := PackedVector2Array([base, meio, ponta])
		item.draw_polyline(linha, COR_CONTORNO, 3.4, true)
		# Deitada, a folha mostra o lado de baixo, mais claro: é isso que marca o rastro.
		item.draw_polyline(linha, cor.lerp(COR_DEITADA, absf(dobra) / DOBRA_MAXIMA * 0.7), 2.2, true)
