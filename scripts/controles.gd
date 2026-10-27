extends Node
## Registra os controles dos dois jogadores no InputMap ao iniciar o jogo.
## Para trocar uma tecla, basta mudar este dicionário.

const MAPA := {
	"p1": {
		"cima": [KEY_W],
		"baixo": [KEY_S],
		"esquerda": [KEY_A],
		"direita": [KEY_D],
		"atacar": [KEY_F],
		"invisivel": [KEY_G],
	},
	"p2": {
		"cima": [KEY_UP],
		"baixo": [KEY_DOWN],
		"esquerda": [KEY_LEFT],
		"direita": [KEY_RIGHT],
		"atacar": [KEY_PERIOD, KEY_KP_1],
		"invisivel": [KEY_COMMA, KEY_KP_2],
	},
}


func _ready() -> void:
	for jogador in MAPA:
		for acao in MAPA[jogador]:
			var nome: String = "%s_%s" % [jogador, acao]
			if not InputMap.has_action(nome):
				InputMap.add_action(nome)
			for tecla in MAPA[jogador][acao]:
				var evento := InputEventKey.new()
				evento.keycode = tecla
				InputMap.action_add_event(nome, evento)
