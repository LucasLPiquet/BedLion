class_name Lobby
extends Control
## Lobby (antes da partida), em duas etapas:
## 1. Entrar: cada jogador aperta o golpe no próprio teclado ou controle para
##    entrar numa vaga. Com os lados ele troca a cor do camaleão (cada um fica
##    com uma cor diferente), com o golpe de novo fica pronto e com o botão de
##    invisível desfaz (ou sai da vaga). Quando todo mundo que entrou está pronto,
##    vai para a etapa 2.
## 2. Bots: quantos bots completam a partida e a dificuldade deles (fácil, médio
##    ou difícil). Qualquer jogador que entrou mexe: cima/baixo escolhe a linha,
##    os lados mudam o valor, golpe começa e invisível volta para a etapa 1.
## Tudo também funciona com o mouse. Esc volta para o menu.
## O resultado vai para Partida.jogadores (partida.gd), que a arena (main.gd) usa.

const Ui := preload("res://scripts/ui.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

const MAX_JOGADORES := 4
const TECLADOS := ["teclado1", "teclado2"]
## Cartões das vagas.
const LARGURA_CARTAO := 320.0
const ALTURA_CARTAO := 420.0
const TOPO_CARTAO := 170.0
const ESPACO_CARTAO := 36.0
## Depois de mudar de etapa, ignora os botões por um instante (para o mesmo
## aperto não valer duas vezes).
const ESPERA_ETAPA := 0.25

## Cada vaga: {} vazia, ou {"controle": String, "cor": int (índice em Partida.CORES), "pronto": bool}.
var _vagas: Array = [{}, {}, {}, {}]
var _etapa := "entrar" # "entrar" ou "bots"
var _quantidade_bots := 0
var _dificuldade := "medio"
var _linha := 0 # etapa 2: 0 = quantidade de bots, 1 = dificuldade
var _espera := 0.0
var _tempo := 0.0

var _desenho: Node2D
var _titulo: Label
var _ajuda: Label
var _botao_continuar: Button
var _painel_bots: Control
var _rotulo_bots: Label
var _botoes_dificuldade: Array = []
var _rotulo_linha_bots: Label
var _rotulo_linha_dificuldade: Label
var _fundo_cartao: StyleBoxFlat
var _fundo_cartao_vazio: StyleBoxFlat


func _ready() -> void:
	size = Ui.TAMANHO
	Ui.fundo(self)
	_fundo_cartao = StyleBoxFlat.new()
	_fundo_cartao.set_corner_radius_all(22)
	_fundo_cartao.set_border_width_all(4)
	_fundo_cartao.bg_color = Ui.COR_PAINEL

	_fundo_cartao_vazio = StyleBoxFlat.new()
	_fundo_cartao_vazio.set_corner_radius_all(22)
	_fundo_cartao_vazio.set_border_width_all(4)
	_fundo_cartao_vazio.bg_color = Color(Ui.COR_PAINEL, 0.45)
	_fundo_cartao_vazio.border_color = Color(0, 0, 0, 0.6)
	_quantidade_bots = Partida.quantidade_bots
	_dificuldade = Partida.dificuldade_bots

	_titulo = Ui.rotulo("", 56, Vector2(0, 50))
	_titulo.add_theme_color_override("font_color", Ui.AMARELO)
	add_child(_titulo)

	_desenho = Node2D.new()
	_desenho.draw.connect(_desenhar_vagas)
	add_child(_desenho)

	_ajuda = Ui.rotulo("", 22, Vector2(0, Ui.TAMANHO.y - 56))
	add_child(_ajuda)

	_botao_continuar = Ui.botao("Continuar", Vector2(300, 70), 32)
	_botao_continuar.focus_mode = Control.FOCUS_NONE
	_botao_continuar.position = Vector2(Ui.TAMANHO.x / 2.0 - 150.0, 640)
	_botao_continuar.pressed.connect(_continuar_com_mouse)
	add_child(_botao_continuar)

	var voltar := Ui.botao("Menu", Vector2(160, 56), 26)
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.position = Vector2(40, 40)
	voltar.pressed.connect(func() -> void: Partida.ir_para(Partida.CENA_MENU))
	add_child(voltar)

	_montar_painel_bots()
	Input.joy_connection_changed.connect(_ao_mudar_controle)
	_espera = ESPERA_ETAPA
	_atualizar()


func _ao_mudar_controle(aparelho: int, conectado: bool) -> void:
	if conectado:
		return
	var vaga := _vaga_de("pad%d" % aparelho)
	if vaga < 0:
		return
	_vagas[vaga] = {}
	if _etapa == "bots":
		if _humanos() == 0:
			_voltar_para_entrar()
		else:
			_atualizar()
	elif _todos_prontos():
		_ir_para_bots()
	else:
		_atualizar()


func _process(delta: float) -> void:
	_tempo += delta
	_espera -= delta
	if _espera <= 0.0:
		for controle in _controles_disponiveis():
			if _espera > 0.0:
				break # mudou de etapa agora: o resto espera o próximo aperto
			if _etapa == "entrar":
				_entrada_etapa_entrar(controle)
			else:
				_entrada_etapa_bots(controle)
	_desenho.queue_redraw()


func _unhandled_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla and tecla.pressed and not tecla.echo:
		if tecla.keycode == KEY_ESCAPE:
			Partida.ir_para(Partida.CENA_MENU)
		elif tecla.keycode == KEY_G and _espera <= 0.0 and _etapa == "entrar" and _vaga_de("teclado1") < 0:
			Partida.ir_para(Partida.CENA_MENU)
		elif (tecla.keycode == KEY_ENTER or tecla.keycode == KEY_KP_ENTER) and _espera <= 0.0:
			_continuar_com_mouse()
		return
	var botao := evento as InputEventJoypadButton
	if botao and botao.pressed and botao.button_index == JOY_BUTTON_B and _espera <= 0.0:
		if _vaga_de("pad%d" % botao.device) < 0:
			Partida.ir_para(Partida.CENA_MENU)


## Teclados e controles conectados (cada um pode entrar numa vaga).
func _controles_disponiveis() -> Array:
	var lista: Array = TECLADOS.duplicate()
	for pad in Input.get_connected_joypads():
		if pad < Controles.MAX_PADS:
			lista.append("pad%d" % pad)
	return lista


func _apertou(controle: String, acao: String) -> bool:
	return Input.is_action_just_pressed(controle + "_" + acao)


# --- Etapa 1: entrar e escolher a cor ----------------------------------------

func _entrada_etapa_entrar(controle: String) -> void:
	var vaga := _vaga_de(controle)
	if vaga < 0:
		if _apertou(controle, "golpe"):
			_entrar(controle)
		return
	var dados: Dictionary = _vagas[vaga]
	if dados["pronto"]:
		if _apertou(controle, "invisivel"):
			dados["pronto"] = false
			_atualizar()
		return
	if _apertou(controle, "esquerda"):
		dados["cor"] = _proxima_cor_livre(dados["cor"], -1)
	elif _apertou(controle, "direita"):
		dados["cor"] = _proxima_cor_livre(dados["cor"], 1)
	elif _apertou(controle, "golpe"):
		dados["pronto"] = true
		_atualizar()
		if _todos_prontos():
			_ir_para_bots()
	elif _apertou(controle, "invisivel"):
		_vagas[vaga] = {}
		_atualizar()


func _entrar(controle: String) -> void:
	for i in _vagas.size():
		if _vagas[i].is_empty():
			_vagas[i] = {"controle": controle, "cor": _proxima_cor_livre(i - 1, 1), "pronto": false}
			_atualizar()
			return


func _vaga_de(controle: String) -> int:
	for i in _vagas.size():
		if not _vagas[i].is_empty() and _vagas[i]["controle"] == controle:
			return i
	return -1


func _cores_usadas() -> Array:
	var usadas: Array = []
	for vaga in _vagas:
		if not vaga.is_empty():
			usadas.append(vaga["cor"])
	return usadas


## A próxima cor (andando "passo" para um lado) que ninguém está usando.
func _proxima_cor_livre(atual: int, passo: int) -> int:
	var usadas := _cores_usadas()
	var total: int = Partida.CORES.size()
	var cor := atual
	for _i in total:
		cor = posmod(cor + passo, total)
		if not usadas.has(cor):
			return cor
	return posmod(atual, total)


func _humanos() -> int:
	var quantos := 0
	for vaga in _vagas:
		if not vaga.is_empty():
			quantos += 1
	return quantos


func _todos_prontos() -> bool:
	if _humanos() == 0:
		return false
	for vaga in _vagas:
		if not vaga.is_empty() and not vaga["pronto"]:
			return false
	return true


func _continuar_com_mouse() -> void:
	if _etapa == "entrar":
		if _humanos() == 0:
			return
		for vaga in _vagas:
			if not vaga.is_empty():
				vaga["pronto"] = true
		_ir_para_bots()
	else:
		_comecar()


# --- Etapa 2: bots e dificuldade ---------------------------------------------

func _ir_para_bots() -> void:
	if _humanos() >= MAX_JOGADORES:
		_quantidade_bots = 0
		_comecar()
		return
	_etapa = "bots"
	_espera = ESPERA_ETAPA
	_linha = 0
	_ajustar_bots(0)
	_atualizar()


func _voltar_para_entrar() -> void:
	_etapa = "entrar"
	_espera = ESPERA_ETAPA
	for vaga in _vagas:
		if not vaga.is_empty():
			vaga["pronto"] = false
	_atualizar()


func _entrada_etapa_bots(controle: String) -> void:
	if _vaga_de(controle) < 0:
		return
	if (_apertou(controle, "cima") or _apertou(controle, "baixo")) and _quantidade_bots > 0:
		_linha = posmod(_linha + (-1 if _apertou(controle, "cima") else 1), 2)
		_atualizar()
	elif _apertou(controle, "esquerda") or _apertou(controle, "direita"):
		var passo := -1 if _apertou(controle, "esquerda") else 1
		if _linha == 0:
			_ajustar_bots(passo)
		else:
			_mudar_dificuldade(passo)
	elif _apertou(controle, "golpe"):
		_comecar()
	elif _apertou(controle, "invisivel"):
		_voltar_para_entrar()


## Com uma pessoa só precisa de pelo menos um bot; as vagas que sobram são o máximo.
func _limites_bots() -> Vector2i:
	var humanos := _humanos()
	return Vector2i(1 if humanos <= 1 else 0, MAX_JOGADORES - humanos)


func _ajustar_bots(passo: int) -> void:
	var limites := _limites_bots()
	_quantidade_bots = clampi(_quantidade_bots + passo, limites.x, limites.y)
	_atualizar()


func _mudar_dificuldade(passo: int) -> void:
	var lista: Array = Partida.DIFICULDADES
	_dificuldade = lista[posmod(lista.find(_dificuldade) + passo, lista.size())]
	_atualizar()


func _escolher_dificuldade(dificuldade: String) -> void:
	if _quantidade_bots <= 0:
		return
	_dificuldade = dificuldade
	_linha = 1
	_atualizar()


## Cores dos bots: as primeiras que nenhum jogador escolheu.
func _cores_dos_bots() -> Array:
	var usadas := _cores_usadas()
	var cores: Array = []
	for i in Partida.CORES.size():
		if cores.size() >= _quantidade_bots:
			break
		if not usadas.has(i):
			cores.append(i)
	return cores


func _comecar() -> void:
	var jogadores: Array = []
	for vaga in _vagas:
		if vaga.is_empty():
			continue
		var cor: Dictionary = Partida.CORES[vaga["cor"]]
		jogadores.append({"nome": cor["nome"], "cor": cor["cor"], "controle": vaga["controle"], "bot": ""})
	for indice in _cores_dos_bots():
		var cor: Dictionary = Partida.CORES[indice]
		jogadores.append({"nome": cor["nome"], "cor": cor["cor"], "controle": "", "bot": _dificuldade})
	if jogadores.size() < 2:
		return
	Partida.jogadores = jogadores
	if _humanos() < MAX_JOGADORES:
		Partida.quantidade_bots = _quantidade_bots
	Partida.dificuldade_bots = _dificuldade
	Partida.ir_para(Partida.CENA_ARENA)


# --- Tela ---------------------------------------------------------------------

func _montar_painel_bots() -> void:
	_painel_bots = Control.new()
	_painel_bots.position = Vector2(0, 610)
	add_child(_painel_bots)
	_painel_bots.add_child(Ui.painel(Rect2(300, 0, 1000, 170)))

	_rotulo_linha_bots = Ui.rotulo("Bots", 32, Vector2(330, 22), 260)
	_rotulo_linha_bots.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_painel_bots.add_child(_rotulo_linha_bots)
	var menos := Ui.botao("-", Vector2(60, 56), 34)
	menos.position = Vector2(620, 18)
	menos.focus_mode = Control.FOCUS_NONE
	menos.pressed.connect(func() -> void:
		_linha = 0
		_ajustar_bots(-1))
	_painel_bots.add_child(menos)
	_rotulo_bots = Ui.rotulo("0", 36, Vector2(690, 20), 90)
	_painel_bots.add_child(_rotulo_bots)
	var mais := Ui.botao("+", Vector2(60, 56), 34)
	mais.position = Vector2(790, 18)
	mais.focus_mode = Control.FOCUS_NONE
	mais.pressed.connect(func() -> void:
		_linha = 0
		_ajustar_bots(1))
	_painel_bots.add_child(mais)

	_rotulo_linha_dificuldade = Ui.rotulo("Dificuldade", 32, Vector2(330, 100), 260)
	_rotulo_linha_dificuldade.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_painel_bots.add_child(_rotulo_linha_dificuldade)
	for i in Partida.DIFICULDADES.size():
		var dificuldade: String = Partida.DIFICULDADES[i]
		var botao := Ui.botao(Partida.NOMES_DIFICULDADE[dificuldade], Vector2(150, 56), 26)
		botao.position = Vector2(620 + i * 165, 94)
		botao.focus_mode = Control.FOCUS_NONE
		botao.toggle_mode = true
		botao.pressed.connect(_escolher_dificuldade.bind(dificuldade))
		_painel_bots.add_child(botao)
		_botoes_dificuldade.append(botao)

	var comecar := Ui.botao("Começar", Vector2(200, 130), 34)
	comecar.position = Vector2(1090, 20)
	comecar.focus_mode = Control.FOCUS_NONE
	comecar.pressed.connect(_comecar)
	_painel_bots.add_child(comecar)


func _atualizar() -> void:
	var nos_bots := _etapa == "bots"
	_painel_bots.visible = nos_bots
	_botao_continuar.visible = not nos_bots and _humanos() > 0
	if nos_bots:
		var limites := _limites_bots()
		_quantidade_bots = clampi(_quantidade_bots, limites.x, limites.y)
		var sem_bots := _quantidade_bots == 0
		if sem_bots:
			_linha = 0
		_titulo.text = "Bots"
		_rotulo_bots.text = str(_quantidade_bots)
		_rotulo_linha_bots.add_theme_color_override("font_color", Ui.AMARELO if _linha == 0 else Color.WHITE)
		var cor_dificuldade := Color(1, 1, 1, 0.35) if sem_bots else (Ui.AMARELO if _linha == 1 else Color.WHITE)
		_rotulo_linha_dificuldade.add_theme_color_override("font_color", cor_dificuldade)
		for i in _botoes_dificuldade.size():
			var botao: Button = _botoes_dificuldade[i]
			botao.disabled = sem_bots
			botao.modulate.a = 0.5 if sem_bots else 1.0
			botao.set_pressed_no_signal(not sem_bots and Partida.DIFICULDADES[i] == _dificuldade)
		_ajuda.text = "cima/baixo: escolhe a linha    lados: muda    golpe: começar    invisível: voltar    Esc: menu"
	else:
		_titulo.text = "Escolha seu camaleão"
		_ajuda.text = "golpe: entra / fica pronto    lados: muda a cor    invisível: desfaz / sai    Esc: menu"


func _desenhar_vagas() -> void:
	var fonte := ThemeDB.fallback_font
	var total := MAX_JOGADORES * LARGURA_CARTAO + (MAX_JOGADORES - 1) * ESPACO_CARTAO
	var inicio := (Ui.TAMANHO.x - total) / 2.0
	var cores_bots: Array = _cores_dos_bots() if _etapa == "bots" else []
	var proximo_bot := 0
	for i in MAX_JOGADORES:
		var x := inicio + i * (LARGURA_CARTAO + ESPACO_CARTAO)
		var cartao := Rect2(x, TOPO_CARTAO, LARGURA_CARTAO, ALTURA_CARTAO)
		# Na etapa 2 os cartões ficam mais baixos para caber o painel dos bots.
		if _etapa == "bots":
			cartao.size.y = 400.0
		var meio := cartao.position.x + LARGURA_CARTAO / 2.0
		var vaga: Dictionary = _vagas[i]

		if not vaga.is_empty():
			var cor: Color = Partida.CORES[vaga["cor"]]["cor"]
			var pronto: bool = vaga["pronto"]
			_fundo_cartao.border_color = cor if pronto else Color(cor, 0.5)
			_fundo_cartao.draw(_desenho.get_canvas_item(), cartao)
			_texto(fonte, Vector2(meio, cartao.position.y + 50), "Jogador %d" % (i + 1), 28, Color.WHITE)
			var balanco := 0.0 if pronto else sin(_tempo * 3.0 + i) * 5.0
			var passo := _tempo * 7.0 if not pronto else 0.0
			Desenho.desenhar(_desenho, Transform2D(0.0, Vector2.ONE * 3.0, 0.0,
				Vector2(meio, cartao.position.y + 170 + balanco)), cor, Vector2.RIGHT, true, passo)
			_desenho.draw_set_transform(Vector2.ZERO)
			var controle: String = vaga["controle"]
			_texto(fonte, Vector2(meio, cartao.position.y + 290), Partida.CORES[vaga["cor"]]["nome"], 32, cor.lightened(0.2))
			_texto(fonte, Vector2(meio, cartao.position.y + 325), Controles.descricao(controle), 18, Color(1, 1, 1, 0.7))
			if pronto:
				_texto(fonte, Vector2(meio, cartao.position.y + 370), "PRONTO!", 30, Ui.AMARELO)
			else:
				var lados := Controles.nome_botao(controle, "lados")
				_texto(fonte, Vector2(meio, cartao.position.y + 362), "< %s: cor >" % lados, 20, Color.WHITE)
				_texto(fonte, Vector2(meio, cartao.position.y + 392), "%s: pronto" % Controles.nome_botao(controle, "golpe"), 20, Ui.AMARELO)
		elif proximo_bot < cores_bots.size():
			var indice: int = cores_bots[proximo_bot]
			proximo_bot += 1
			var cor_bot: Color = Partida.CORES[indice]["cor"]
			_fundo_cartao.border_color = Color(cor_bot, 0.4)
			_fundo_cartao.draw(_desenho.get_canvas_item(), cartao)
			_texto(fonte, Vector2(meio, cartao.position.y + 50), "Bot", 28, Color.WHITE)
			Desenho.desenhar(_desenho, Transform2D(0.0, Vector2.ONE * 3.0, 0.0,
				Vector2(meio, cartao.position.y + 170)), Color(cor_bot, 0.85), Vector2.LEFT, false, 0.0)
			_desenho.draw_set_transform(Vector2.ZERO)
			_texto(fonte, Vector2(meio, cartao.position.y + 290), Partida.CORES[indice]["nome"], 32, cor_bot.lightened(0.2))
			_texto(fonte, Vector2(meio, cartao.position.y + 330), Partida.NOMES_DIFICULDADE[_dificuldade], 24, Ui.AMARELO)
		else:
			_fundo_cartao_vazio.draw(_desenho.get_canvas_item(), cartao)
			if _etapa == "entrar":
				var piscar := 0.6 + 0.4 * sin(_tempo * 4.0)
				_texto(fonte, Vector2(meio, cartao.position.y + 180), "Aperte golpe", 28, Color(1, 1, 1, piscar))
				_texto(fonte, Vector2(meio, cartao.position.y + 215), "para entrar", 28, Color(1, 1, 1, piscar))
				_texto(fonte, Vector2(meio, cartao.position.y + 270), "F  /  .  /  A", 24, Color(Ui.AMARELO, piscar))
			else:
				_texto(fonte, Vector2(meio, cartao.position.y + 200), "vazio", 24, Color(1, 1, 1, 0.4))


## Texto centrado em "centro" (x no meio, y na linha de base) com contorno escuro.
func _texto(fonte: Font, centro: Vector2, texto: String, tamanho: int, cor: Color) -> void:
	if texto == "":
		return
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var onde := Vector2(centro.x - largura / 2.0, centro.y)
	_desenho.draw_string_outline(fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, maxi(4, tamanho / 5), Ui.CONTORNO)
	_desenho.draw_string(fonte, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
