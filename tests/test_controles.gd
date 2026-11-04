extends RefCounted

const Controles := preload("res://scripts/controles.gd")

var passed := 0
var failed := 0

func get_suite_name() -> String:
	return "Testes de Controles (scripts/controles.gd)"

func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ %s" % message)
		passed += 1
	else:
		printerr("  ✗ FALHA: %s" % message)
		failed += 1

func run_tests() -> void:
	test_teclados_configurados()
	test_acoes_obrigatorias_teclado()
	test_configuracao_gamepad()

func test_teclados_configurados() -> void:
	assert_true(Controles.TECLADOS.has("teclado1"), "Configuração do Teclado 1 existe")
	assert_true(Controles.TECLADOS.has("teclado2"), "Configuração do Teclado 2 existe")

func test_acoes_obrigatorias_teclado() -> void:
	var acoes := ["cima", "baixo", "esquerda", "direita", "golpe", "invisivel", "lingua"]
	for teclado_id in ["teclado1", "teclado2"]:
		var mapa: Dictionary = Controles.TECLADOS.get(teclado_id, {})
		for acao in acoes:
			assert_true(mapa.has(acao) and mapa[acao].size() > 0, "'%s' mapeia a ação obrigatória '%s'" % [teclado_id, acao])

func test_configuracao_gamepad() -> void:
	assert_true(Controles.BOTOES_PAD.has("golpe"), "Gamepad possui botão mapeado para golpe")
	assert_true(Controles.BOTOES_PAD.has("invisivel"), "Gamepad possui botão mapeado para invisibilidade")
	assert_true(Controles.BOTOES_PAD.has("lingua"), "Gamepad possui botão mapeado para língua")
	assert_true(Controles.MAX_PADS >= 4, "Suporta ao menos 4 controles conectados simultaneamente")
