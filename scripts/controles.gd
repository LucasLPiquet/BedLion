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
		"atacar": [KEY_F],
		"invisivel": [KEY_G],
	},
	"teclado2": {
		"cima": [KEY_UP],
		"baixo": [KEY_DOWN],
		"esquerda": [KEY_LEFT],
		"direita": [KEY_RIGHT],
		"atacar": [KEY_PERIOD, KEY_KP_1],
		"invisivel": [KEY_COMMA, KEY_KP_2],
	},
}

## Botões do controle (nomes do Xbox: A, B, LB, RB e o direcional).
const BOTOES_PAD := {
	"cima": [JOY_BUTTON_DPAD_UP],
	"baixo": [JOY_BUTTON_DPAD_DOWN],
	"esquerda": [JOY_BUTTON_DPAD_LEFT],
	"direita": [JOY_BUTTON_DPAD_RIGHT],
	"atacar": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER],
	"invisivel": [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER],
}
## Eixos do controle: [eixo, sentido]. Analógico esquerdo move; gatilhos RT/LT.
const EIXOS_PAD := {
	"cima": [JOY_AXIS_LEFT_Y, -1.0],
	"baixo": [JOY_AXIS_LEFT_Y, 1.0],
	"esquerda": [JOY_AXIS_LEFT_X, -1.0],
	"direita": [JOY_AXIS_LEFT_X, 1.0],
	"atacar": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"invisivel": [JOY_AXIS_TRIGGER_LEFT, 1.0],
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
			var eixo: Array = EIXOS_PAD[acao]
			var movimento := InputEventJoypadMotion.new()
			movimento.device = pad
			movimento.axis = eixo[0]
			movimento.axis_value = eixo[1]
			InputMap.action_add_event(nome, movimento)


func _criar_acao(nome: String) -> String:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome, ZONA_MORTA)
	return nome


## Texto curto de ajuda para mostrar na tela (primeiro botão ataca, segundo fica invisível).
func descricao(controle: String) -> String:
	match controle:
		"teclado1":
			return "WASD, F/G"
		"teclado2":
			return "setas, . / ,"
	if controle.begins_with("pad"):
		return "controle %d, A/B" % (int(controle.substr(3)) + 1)
	return "bot"
