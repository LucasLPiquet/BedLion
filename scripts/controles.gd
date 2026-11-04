extends Node
## Registra no InputMap os controles de todo mundo ao iniciar o jogo.
## Cada jogador usa um "controle", que é o prefixo das ações dele:
## "teclado1", "teclado2" ou "pad0", "pad1"... (um por controle de videogame).
## Para trocar uma tecla ou botão, basta mudar os dicionários abaixo.

const TECLADOS := {
	"teclado1": {
		"cima": [KEY_W],
		"baixo": [KEY_S],
		"esquerda": [KEY_A],
		"direita": [KEY_D],
		"golpe": [KEY_F],
		"invisivel": [KEY_G],
		"lingua": [KEY_H],
	},
	"teclado2": {
		"cima": [KEY_UP],
		"baixo": [KEY_DOWN],
		"esquerda": [KEY_LEFT],
		"direita": [KEY_RIGHT],
		"golpe": [KEY_PERIOD, KEY_KP_1],
		"invisivel": [KEY_COMMA, KEY_KP_2],
		# A tecla depois do ponto: "/" no teclado americano, ";" no brasileiro.
		"lingua": [KEY_SLASH, KEY_SEMICOLON, KEY_KP_3],
	},
}

## Botões do controle (nomes do Xbox: A, B, X, LB, RB e o direcional).
const BOTOES_PAD := {
	"cima": [JOY_BUTTON_DPAD_UP],
	"baixo": [JOY_BUTTON_DPAD_DOWN],
	"esquerda": [JOY_BUTTON_DPAD_LEFT],
	"direita": [JOY_BUTTON_DPAD_RIGHT],
	"golpe": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER],
	"invisivel": [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER],
	"lingua": [JOY_BUTTON_X],
}
## Eixos do controle: [eixo, sentido]. Analógico esquerdo move; RT é a língua, LT o invisível.
const EIXOS_PAD := {
	"cima": [JOY_AXIS_LEFT_Y, -1.0],
	"baixo": [JOY_AXIS_LEFT_Y, 1.0],
	"esquerda": [JOY_AXIS_LEFT_X, -1.0],
	"direita": [JOY_AXIS_LEFT_X, 1.0],
	"lingua": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"invisivel": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}
## Teclas e botões extras nas ações nativas de interface (menus e configurações).
const INTERFACE_TECLAS := {
	"ui_up": [KEY_W],
	"ui_down": [KEY_S],
	"ui_left": [KEY_A],
	"ui_right": [KEY_D],
	"ui_accept": [KEY_F],
	"ui_cancel": [KEY_G],
}
const INTERFACE_BOTOES_PAD := {
	"ui_up": [JOY_BUTTON_DPAD_UP],
	"ui_down": [JOY_BUTTON_DPAD_DOWN],
	"ui_left": [JOY_BUTTON_DPAD_LEFT],
	"ui_right": [JOY_BUTTON_DPAD_RIGHT],
	"ui_accept": [JOY_BUTTON_A],
	"ui_cancel": [JOY_BUTTON_B],
}
const INTERFACE_EIXOS_PAD := {
	"ui_up": [JOY_AXIS_LEFT_Y, -1.0],
	"ui_down": [JOY_AXIS_LEFT_Y, 1.0],
	"ui_left": [JOY_AXIS_LEFT_X, -1.0],
	"ui_right": [JOY_AXIS_LEFT_X, 1.0],
}
## Quantos controles de videogame são registrados (pad0 até pad7).
const MAX_PADS := 8
## Quanto o analógico precisa ser empurrado para contar (evita andar sozinho).
const ZONA_MORTA := 0.3


func _ready() -> void:
	for teclado in TECLADOS:
		for acao in TECLADOS[teclado]:
			var nome := _criar_acao("%s_%s" % [teclado, acao])
			for tecla in TECLADOS[teclado][acao]:
				var evento := InputEventKey.new()
				evento.keycode = tecla
				InputMap.action_add_event(nome, evento)

	# Uma ação separada para cada controle (o "device" diz de qual controle é),
	# assim cada jogador só responde ao próprio controle.
	for pad in MAX_PADS:
		for acao in BOTOES_PAD:
			var nome := _criar_acao("pad%d_%s" % [pad, acao])
			for botao in BOTOES_PAD[acao]:
				var evento := InputEventJoypadButton.new()
				evento.device = pad
				evento.button_index = botao
				InputMap.action_add_event(nome, evento)
			if not EIXOS_PAD.has(acao):
				continue
			var eixo: Array = EIXOS_PAD[acao]
			var movimento := InputEventJoypadMotion.new()
			movimento.device = pad
			movimento.axis = eixo[0]
			movimento.axis_value = eixo[1]
			InputMap.action_add_event(nome, movimento)

	_registrar_interface()


func _registrar_interface() -> void:
	for acao in INTERFACE_TECLAS:
		_criar_acao(acao)
		for tecla in INTERFACE_TECLAS[acao]:
			var evento := InputEventKey.new()
			evento.keycode = tecla
			if not InputMap.action_has_event(acao, evento):
				InputMap.action_add_event(acao, evento)
	for acao in INTERFACE_BOTOES_PAD:
		_criar_acao(acao)
		for botao in INTERFACE_BOTOES_PAD[acao]:
			var evento := InputEventJoypadButton.new()
			evento.device = -1
			evento.button_index = botao
			if not InputMap.action_has_event(acao, evento):
				InputMap.action_add_event(acao, evento)
	for acao in INTERFACE_EIXOS_PAD:
		_criar_acao(acao)
		var eixo: Array = INTERFACE_EIXOS_PAD[acao]
		var movimento := InputEventJoypadMotion.new()
		movimento.device = -1
		movimento.axis = eixo[0]
		movimento.axis_value = eixo[1]
		if not InputMap.action_has_event(acao, movimento):
			InputMap.action_add_event(acao, movimento)


func _criar_acao(nome: String) -> String:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome, ZONA_MORTA)
	return nome


## Texto curto de ajuda para mostrar na tela (golpe / invisível / língua).
func descricao(controle: String) -> String:
	match controle:
		"teclado1":
			return "WASD, F/G/H"
		"teclado2":
			return "setas, . / , / ;"
	if controle.begins_with("pad"):
		return "controle %d, A/B/X" % (int(controle.substr(3)) + 1)
	return "bot"


## Nomes curtos dos botões para mostrar na tela (lobby).
const NOMES_TECLADO := {
	"teclado1": {"golpe": "F", "invisivel": "G", "lingua": "H", "lados": "A/D", "cima_baixo": "W/S"},
	"teclado2": {"golpe": ".", "invisivel": ",", "lingua": ";", "lados": "direcional", "cima_baixo": "direcional"},
}
const NOMES_PAD := {"golpe": "A", "invisivel": "B", "lingua": "X", "lados": "direcional", "cima_baixo": "direcional"}


## Nome curto do botão de uma ação para mostrar na tela (ex.: "F", ".", "A").
func nome_botao(controle: String, acao: String) -> String:
	if NOMES_TECLADO.has(controle):
		return NOMES_TECLADO[controle].get(acao, "?")
	return NOMES_PAD.get(acao, "?")
