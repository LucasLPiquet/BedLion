class_name Grude
extends Node2D
## Rastro de grude que a língua com o poder "grude" deixa no chão quando erra:
## uma fileira de bolotas verdes por todo o caminho que a língua fez, da boca
## até onde a ponta parou (pulando os pedaços em cima da água).
## Quem pisar no rastro (visível ou invisível) fica preso por TEMPO_PRESO segundos
## e, se estava invisível, aparece. Só o pedaço em que ele pisou some; o resto do
## rastro continua lá. Quem soltou o grude não gruda nele.
## O rastro some depois de DURACAO segundos (ou quando todos os pedaços já pegaram alguém).

const Desenho := preload("res://scripts/desenho_camaleao.gd")

const DURACAO := 10.0
const TEMPO_PRESO := 1.2
## Só começa a pegar depois disso (para não grudar quem está bem em cima na hora).
const TEMPO_ARMAR := 0.3
## Distância (dos pés do camaleão ao centro de uma bolota) para contar como pisada.
const RAIO_PISAR := 24.0
## Quando alguém gruda, as bolotas até esta distância dos pés dele somem.
const RAIO_GASTAR := 40.0
## Espaço entre uma bolota e outra ao longo do caminho da língua.
const ESPACO := 22.0

const Mapas := preload("res://scripts/mapas.gd")

const VERDE := Color(0.55, 0.85, 0.2)
const CONTORNO := Color(0.08, 0.07, 0.1)

var dono: Node = null # quem soltou (não gruda nele)
## Centros das bolotas, no mundo. Quem cria preenche com pontos_no_caminho().
var pontos: Array[Vector2] = []
var _tempo := 0.0
var _vivas: Array[bool] = [] # bolotas que ainda não pegaram ninguém
var _tamanhos: Array[float] = [] # raio de cada bolota, sorteado uma vez


## Pontos de ESPACO em ESPACO de "de" até "ate", fora da água do mapa.
static func pontos_no_caminho(de: Vector2, ate: Vector2, mapa: Dictionary) -> Array[Vector2]:
	var lista: Array[Vector2] = []
	var quantos := maxi(int(de.distance_to(ate) / ESPACO), 0)
	for i in quantos + 1:
		var ponto := de.lerp(ate, 1.0 if quantos == 0 else float(i) / quantos)
		if not Mapas.na_agua(mapa, ponto):
			lista.append(ponto)
	return lista


func _ready() -> void:
	z_index = -1 # no chão, por baixo dos camaleões
	add_to_group("grudes")
	for i in pontos.size():
		_vivas.append(true)
		_tamanhos.append(randf_range(7.5, 10.5))


func _physics_process(delta: float) -> void:
	_tempo += delta
	queue_redraw()
	if _tempo >= DURACAO or not _vivas.has(true):
		queue_free()
		return
	if _tempo < TEMPO_ARMAR:
		return
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if camaleao == dono or not camaleao.vivo:
			continue
		var pes: Vector2 = camaleao.position + Desenho.PES
		if _pisou(pes) and camaleao.grudar(TEMPO_PRESO):
			_gastar(pes)


func _pisou(pes: Vector2) -> bool:
	for i in pontos.size():
		if _vivas[i] and pontos[i].distance_to(pes) <= RAIO_PISAR:
			return true
	return false


## O pedaço do rastro em volta de quem grudou some (para ele conseguir sair).
func _gastar(pes: Vector2) -> void:
	for i in pontos.size():
		if pontos[i].distance_to(pes) <= RAIO_GASTAR:
			_vivas[i] = false


func _draw() -> void:
	var alfa := clampf(DURACAO - _tempo, 0.0, 1.0) # vai sumindo no último segundo
	# "Ploft": as bolotas caem uma depois da outra, da boca até a ponta.
	var escalas: Array[float] = []
	for i in pontos.size():
		escalas.append(clampf((_tempo - i * 0.012) / 0.15, 0.0, 1.0))
	var achatar := Vector2(1.0, 0.6)
	# Contorno, depois o verde por cima: as bolotas vizinhas viram uma faixa só.
	for camada in 2:
		var cor_camada := Color(CONTORNO, 0.8 * alfa) if camada == 0 else Color(VERDE.darkened(0.15), 0.85 * alfa)
		var extra := 1.5 if camada == 0 else 0.0
		for i in pontos.size():
			if not _vivas[i]:
				continue
			var onde := to_local(pontos[i])
			var raio := _tamanhos[i] * lerpf(0.4, 1.0, escalas[i]) + extra
			if i + 1 < pontos.size() and _vivas[i + 1] and pontos[i].distance_to(pontos[i + 1]) <= ESPACO * 1.5:
				var largura := minf(_tamanhos[i], _tamanhos[i + 1]) * 1.1 * achatar.y * 2.0 + extra * 2.0
				draw_line(onde, to_local(pontos[i + 1]), cor_camada, largura * minf(escalas[i], escalas[i + 1]))
			draw_set_transform(onde, 0.0, achatar)
			draw_circle(Vector2.ZERO, raio, cor_camada)
			draw_set_transform(Vector2.ZERO)
	# Bolhinhas que estufam e brilho: dá para ver que é mole e grudento.
	for i in pontos.size():
		if not _vivas[i] or escalas[i] < 1.0:
			continue
		var onde := to_local(pontos[i])
		if i % 3 == 0:
			var bolha := 1.5 + 1.2 * sin(_tempo * 4.0 + i)
			draw_circle(onde + Vector2(3, -1), bolha, Color(VERDE.lightened(0.3), alfa))
		if i % 2 == 1:
			draw_circle(onde + Vector2(-3, -2), 1.8, Color(1, 1, 1, 0.5 * alfa))
