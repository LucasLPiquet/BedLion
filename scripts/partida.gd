extends Node
## Guarda o que foi escolhido fora da arena e vale para o jogo todo (autoload "Partida"):
## - quem joga, montado no lobby (lobby.gd) e lido pela arena (main.gd);
## - as configurações (volume e tela cheia), salvas em user://configuracoes.cfg.
## Também deixa a tela do mesmo tamanho (1600 x 900 esticado) em todas as cenas.

const TAMANHO_TELA := Vector2i(1600, 900)
const ARQUIVO_CONFIG := "user://configuracoes.cfg"

const CENA_MENU := "res://scenes/menu.tscn"
const CENA_LOBBY := "res://scenes/lobby.tscn"
const CENA_CONFIGURACOES := "res://scenes/configuracoes.tscn"
const CENA_ARENA := "res://scenes/main.tscn"

## Cores que dá para escolher no lobby. Cada jogador fica com uma diferente.
const CORES := [
	{"nome": "Verde", "cor": Color(0.45, 0.82, 0.35)},
	{"nome": "Laranja", "cor": Color(0.98, 0.6, 0.25)},
	{"nome": "Azul", "cor": Color(0.35, 0.65, 0.98)},
	{"nome": "Rosa", "cor": Color(0.95, 0.5, 0.78)},
	{"nome": "Amarelo", "cor": Color(0.98, 0.86, 0.3)},
	{"nome": "Roxo", "cor": Color(0.66, 0.48, 0.95)},
	{"nome": "Vermelho", "cor": Color(0.92, 0.3, 0.3)},
	{"nome": "Turquesa", "cor": Color(0.3, 0.85, 0.78)},
]

## Dificuldades dos bots (o que cada uma muda está em bot.gd).
const DIFICULDADES := ["facil", "medio", "dificil"]
const NOMES_DIFICULDADE := {"facil": "Fácil", "medio": "Médio", "dificil": "Difícil"}

## Quem joga a próxima partida: cada um {"nome", "cor", "controle", "bot"}.
## "bot" é "" para gente e a dificuldade ("facil", "medio", "dificil") para bot.
## Vazio = a arena foi aberta direto (F6 no editor): main.gd escolhe sozinho.
var jogadores: Array = []
## Última escolha de bots no lobby (para não precisar escolher de novo).
var quantidade_bots := 0
var dificuldade_bots := "medio"

## Configurações.
var volume := 0.8 # 0 a 1
var tela_cheia := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().content_scale_size = TAMANHO_TELA
	_carregar_configuracoes()
	aplicar_configuracoes()


func aplicar_configuracoes() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if tela_cheia else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != modo:
		DisplayServer.window_set_mode(modo)


func salvar_configuracoes() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value("audio", "volume", volume)
	arquivo.set_value("tela", "tela_cheia", tela_cheia)
	arquivo.save(ARQUIVO_CONFIG)


func _carregar_configuracoes() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO_CONFIG) != OK:
		return
	volume = float(arquivo.get_value("audio", "volume", volume))
	tela_cheia = bool(arquivo.get_value("tela", "tela_cheia", tela_cheia))


func ir_para(cena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(cena)


## Índice em CORES da cor com este nome (-1 se não achar).
static func indice_cor(nome: String) -> int:
	for i in CORES.size():
		if CORES[i]["nome"] == nome:
			return i
	return -1
