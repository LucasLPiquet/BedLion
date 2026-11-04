extends Control
## Tela de configurações: volume e tela cheia. Salva sozinha ao mudar
## (partida.gd guarda em user://configuracoes.cfg). Esc / B / Voltar volta para o menu.
## Ainda não há sons no jogo; o volume já fica guardado para quando tiver.

const Ui := preload("res://scripts/ui.gd")

var _volume: HSlider
var _rotulo_volume: Label
var _tela_cheia: CheckButton


func _ready() -> void:
	size = Ui.TAMANHO
	Ui.fundo(self)
	add_child(Ui.painel(Rect2(450, 170, 700, 560)))
	var titulo := Ui.rotulo("Configurações", 64, Vector2(0, 200))
	titulo.add_theme_color_override("font_color", Ui.AMARELO)
	add_child(titulo)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 30)
	coluna.position = Vector2(560, 340)
	coluna.custom_minimum_size = Vector2(480, 0)
	add_child(coluna)

	_rotulo_volume = Label.new()
	_rotulo_volume.add_theme_font_size_override("font_size", 32)
	coluna.add_child(_rotulo_volume)
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 100.0
	_volume.step = 5.0
	_volume.value = Partida.volume * 100.0
	_volume.custom_minimum_size = Vector2(480, 40)
	_volume.value_changed.connect(_ao_mudar_volume)
	coluna.add_child(_volume)
	_atualizar_rotulo_volume()

	_tela_cheia = CheckButton.new()
	_tela_cheia.text = "Tela cheia"
	_tela_cheia.add_theme_font_size_override("font_size", 32)
	_tela_cheia.button_pressed = Partida.tela_cheia
	_tela_cheia.toggled.connect(_ao_mudar_tela_cheia)
	coluna.add_child(_tela_cheia)

	var voltar := Ui.botao("Voltar", Vector2(480, 76), 34)
	voltar.pressed.connect(_voltar)
	coluna.add_child(voltar)

	add_child(Ui.rotulo("Os sons ainda vão chegar: o volume já fica guardado.", 20, Vector2(0, 690)))
	_volume.grab_focus.call_deferred()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_voltar()


func _ao_mudar_volume(valor: float) -> void:
	Partida.volume = valor / 100.0
	Partida.aplicar_configuracoes()
	Partida.salvar_configuracoes()
	_atualizar_rotulo_volume()


func _ao_mudar_tela_cheia(ligada: bool) -> void:
	Partida.tela_cheia = ligada
	Partida.aplicar_configuracoes()
	Partida.salvar_configuracoes()


func _atualizar_rotulo_volume() -> void:
	_rotulo_volume.text = "Volume: %d%%" % roundi(_volume.value)


func _voltar() -> void:
	Partida.ir_para(Partida.CENA_MENU)
