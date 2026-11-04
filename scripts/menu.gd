extends Control
## Menu inicial: Jogar (vai para o lobby), Configurações e Sair.
## Funciona com mouse, teclado (setas + Enter) e controle (direcional + A).

const Ui := preload("res://scripts/ui.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

var _tempo := 0.0
var _enfeite: Node2D


func _ready() -> void:
	size = Ui.TAMANHO
	Ui.fundo(self)

	_enfeite = Node2D.new()
	_enfeite.draw.connect(_desenhar_camaleoes)
	add_child(_enfeite)

	var titulo := Ui.rotulo("BedLion", 120, Vector2(0, 150))
	titulo.add_theme_color_override("font_color", Ui.AMARELO)
	add_child(titulo)
	add_child(Ui.rotulo("camaleões invisíveis na arena", 30, Vector2(0, 310)))

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 22)
	coluna.position = Vector2(Ui.TAMANHO.x / 2.0 - 190.0, 430)
	add_child(coluna)
	var jogar := Ui.botao("Jogar", Vector2(380, 84), 40)
	jogar.pressed.connect(func() -> void: Partida.ir_para(Partida.CENA_LOBBY))
	coluna.add_child(jogar)
	var configuracoes := Ui.botao("Configurações", Vector2(380, 84), 40)
	configuracoes.pressed.connect(func() -> void: Partida.ir_para(Partida.CENA_CONFIGURACOES))
	coluna.add_child(configuracoes)
	var sair := Ui.botao("Sair", Vector2(380, 70), 32)
	sair.pressed.connect(func() -> void: get_tree().quit())
	coluna.add_child(sair)
	jogar.grab_focus.call_deferred()

	add_child(Ui.rotulo("Enter / A para escolher", 20, Vector2(0, Ui.TAMANHO.y - 60)))


func _process(delta: float) -> void:
	_tempo += delta
	_enfeite.queue_redraw()


## Quatro camaleões andando no lugar dos lados do título, cada um de uma cor.
func _desenhar_camaleoes() -> void:
	var lugares: Array[Vector2] = [Vector2(360, 300), Vector2(1240, 300), Vector2(330, 650), Vector2(1270, 650)]
	for i in lugares.size():
		var cor: Color = Partida.CORES[i]["cor"]
		var direita := i % 2 == 0
		var mira := Vector2.RIGHT if direita else Vector2.LEFT
		var escala := Vector2.ONE * 2.4
		var balanco := Vector2(0, sin(_tempo * 2.0 + i) * 6.0)
		_enfeite.draw_set_transform(Vector2.ZERO)
		Desenho.desenhar(_enfeite, Transform2D(0.0, escala, 0.0, lugares[i] + balanco), cor, mira, direita, _tempo * 6.0 + i)
	_enfeite.draw_set_transform(Vector2.ZERO)
