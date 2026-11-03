extends RefCounted

const Linguas := preload("res://scripts/linguas.gd")

var passed := 0
var failed := 0

func get_suite_name() -> String:
	return "Testes de Línguas e Poderes (scripts/linguas.gd)"

func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ %s" % message)
		passed += 1
	else:
		printerr("  ✗ FALHA: %s" % message)
		failed += 1

func run_tests() -> void:
	test_lingua_basica()
	test_todos_os_tipos()
	test_upgrades_validos()

func test_lingua_basica() -> void:
	assert_true(Linguas.TIPOS.has(Linguas.BASICA), "A língua básica padrão está presente em TIPOS")

func test_todos_os_tipos() -> void:
	for tipo_id in Linguas.TIPOS.keys():
		var dados: Dictionary = Linguas.TIPOS[tipo_id]
		var alcance: float = dados.get("alcance", 0.0)
		var velocidade: float = dados.get("velocidade", 0.0)
		var tempo_puxada: float = dados.get("tempo_puxada", 0.0)
		var cor = dados.get("cor", null)

		assert_true(alcance > 0.0, "Tipo '%s' possui alcance positivo (> 0)" % tipo_id)
		assert_true(velocidade > 0.0, "Tipo '%s' possui velocidade positiva (> 0)" % tipo_id)
		assert_true(tempo_puxada > 0.0, "Tipo '%s' possui tempo de puxada positivo (> 0)" % tipo_id)
		assert_true(cor is Color, "Tipo '%s' possui definição de cor válida" % tipo_id)

func test_upgrades_validos() -> void:
	assert_true(Linguas.UPGRADES.size() > 0, "A lista de UPGRADES contém itens")
	for up_id in Linguas.UPGRADES:
		assert_true(Linguas.TIPOS.has(up_id), "O upgrade '%s' está registrado no dicionário TIPOS" % up_id)
