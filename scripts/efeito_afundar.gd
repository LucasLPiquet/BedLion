extends Node2D
## Camaleão que caiu na água: ele vai encolhendo e descendo enquanto some,
## com um "splash" de gotinhas e ondas em volta. Se ele estava invisível,
## aparecem só as ondas e as gotas (dá para ver onde ele caiu).

const Desenho := preload("res://scripts/desenho_camaleao.gd")

const DURACAO := 0.9
const COR_ONDA := Color(0.85, 0.95, 1.0)

var cor := Color.WHITE
var olhando_direita := true
var mostrar_corpo := true
var _tempo := 0.0
var _gotas: Array = [] # [direção, velocidade, tamanho]
var _respingo: Node2D # desenha ondas e gotas por cima do corpo


func _ready() -> void:
	z_index = 1
	_respingo = Node2D.new()
	_respingo.draw.connect(_desenhar_respingo)
	add_child(_respingo)
	for i in 10:
		var angulo := -PI / 2.0 + randf_range(-1.2, 1.2) # para cima, abrindo para os lados
		_gotas.append([Vector2.from_angle(angulo), randf_range(80.0, 160.0), randf_range(2.5, 4.5)])


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= DURACAO:
		queue_free()
		return
	# O corpo vai ficando transparente (só o desenho dele, não as ondas).
	self_modulate.a = 1.0 - clampf(_tempo / DURACAO / 0.7, 0.0, 1.0)
	queue_redraw()
	_respingo.queue_redraw()


## Corpo afundando: encolhe, desce e vai ficando azulado.
func _draw() -> void:
	var afundou := clampf(_tempo / DURACAO / 0.7, 0.0, 1.0)
	if not mostrar_corpo or afundou >= 1.0:
		return
	var escala := Desenho.ESCALA_JOGO * (1.0 - afundou * 0.6)
	var base := Transform2D(0.0, Vector2(escala, escala), 0.0, Vector2(0, afundou * 18.0))
	var cor_corpo := cor.lerp(Color(0.25, 0.58, 0.78), afundou * 0.6)
	Desenho.desenhar(self, base, cor_corpo, Vector2.RIGHT if olhando_direita else Vector2.LEFT,
		olhando_direita, 0.0)


func _desenhar_respingo() -> void:
	var t := _tempo / DURACAO
	var pes := Vector2(0, 14) # onde o corpo encosta na água

	# Ondas que se abrem (achatadas, como se fossem no chão).
	_respingo.draw_set_transform(pes, 0.0, Vector2(1.0, 0.45))
	for i in 3:
		var atraso := i * 0.18
		var onda := clampf((t - atraso) / (1.0 - atraso), 0.0, 1.0)
		if onda > 0.0:
			_respingo.draw_arc(Vector2.ZERO, lerpf(10.0, 46.0, onda), 0.0, TAU, 28, Color(COR_ONDA, 0.8 * (1.0 - onda)), 3.0, true)
	_respingo.draw_set_transform(Vector2.ZERO)

	# Gotinhas que pulam e caem de volta.
	for gota in _gotas:
		var direcao: Vector2 = gota[0]
		var velocidade: float = gota[1]
		var tamanho: float = gota[2]
		var segundos := _tempo
		var ponto := pes + direcao * velocidade * segundos + Vector2(0, 420.0 * segundos * segundos)
		if ponto.y > pes.y + 4.0:
			continue # já caiu de volta na água
		_respingo.draw_circle(ponto, tamanho, Color(COR_ONDA, 1.0 - t))
