extends Node
## Pistas que os camaleões deixam no mapa, inclusive invisíveis:
## - Poça: andando nela faz ondinhas; parado faz uma ondinha de vez em quando;
##   saindo dela fica com os pés molhados e deixa pegadas por TEMPO_PES_MOLHADOS.
## - Ponte: andando nela faz ondinhas na água do lado.
## O capim que se mexe fica em grama_alta.gd e a sombra no sol em luz.gd.
## Os efeitos são criados no nó pai (o nó da rodada).

const Mapas := preload("res://scripts/mapas.gd")
const Ondulacao := preload("res://scripts/ondulacao.gd")

## A cada tantos pixels andados numa poça sai uma ondinha.
const DISTANCIA_ONDA_POCA := 30.0
## Parado numa poça, sai uma ondinha menor a cada tantos segundos.
const INTERVALO_ONDA_PARADO := 1.4
## Na ponte, uma ondinha na água do lado a cada tantos pixels andados.
const DISTANCIA_ONDA_PONTE := 45.0
## Pegadas molhadas depois de sair da poça.
const TEMPO_PES_MOLHADOS := 2.5
const COR_PEGADA_MOLHADA := Color(0.25, 0.32, 0.38, 0.55)
const PES := Vector2(0, 18)

var mapa: Dictionary = {}
var _estado: Dictionary = {} # camaleão -> {"antes", "andado", "parado"}


func _physics_process(delta: float) -> void:
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if not camaleao.vivo:
			continue
		if not _estado.has(camaleao):
			_estado[camaleao] = {"antes": camaleao.position, "andado": 0.0, "parado": 0.0}
		var estado: Dictionary = _estado[camaleao]
		var andou: float = camaleao.position.distance_to(estado["antes"])
		estado["antes"] = camaleao.position
		var pes: Vector2 = camaleao.position + PES

		if Mapas.na_poca(mapa, pes):
			camaleao.sujar_pes(TEMPO_PES_MOLHADOS, COR_PEGADA_MOLHADA)
			estado["andado"] += andou
			if andou > 0.5:
				estado["parado"] = 0.0
				if estado["andado"] >= DISTANCIA_ONDA_POCA:
					estado["andado"] = 0.0
					_ondinha(pes, 1.0)
			else:
				estado["parado"] += delta
				if estado["parado"] >= INTERVALO_ONDA_PARADO:
					estado["parado"] = 0.0
					_ondinha(pes, 0.6)
			continue
		estado["parado"] = 0.0

		var ponte := Mapas.ponte_em(mapa, pes)
		if ponte.has_area():
			estado["andado"] += andou
			if estado["andado"] >= DISTANCIA_ONDA_PONTE:
				estado["andado"] = 0.0
				_ondinha_do_lado(ponte, pes)
		else:
			estado["andado"] = 0.0

	for camaleao in _estado.keys():
		if not is_instance_valid(camaleao):
			_estado.erase(camaleao)


## Ondinha na água ao lado da ponte, na altura de quem anda (um lado sorteado).
func _ondinha_do_lado(ponte: Rect2, pes: Vector2) -> void:
	var deitada := ponte.size.x >= ponte.size.y
	var lados := [-1.0, 1.0]
	lados.shuffle()
	for lado in lados:
		var ponto: Vector2
		if deitada:
			ponto = Vector2(pes.x, ponte.get_center().y + lado * (ponte.size.y / 2.0 + 14.0))
		else:
			ponto = Vector2(ponte.get_center().x + lado * (ponte.size.x / 2.0 + 14.0), pes.y)
		if Mapas.na_agua(mapa, ponto):
			_ondinha(ponto, 0.8)
			return


func _ondinha(ponto: Vector2, tamanho: float) -> void:
	var onda := Ondulacao.new()
	onda.position = ponto
	onda.tamanho = tamanho
	get_parent().add_child(onda)
