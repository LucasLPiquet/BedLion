extends SceneTree
## Test Runner simples e direto para execução headless no Godot 4.
## Execute com: godot --headless --path . -s tests/test_runner.gd

func _initialize() -> void:
	print("\n==================================================")
	print("  BedLion - Bateria de Testes Automatizados")
	print("==================================================\n")

	var suites := [
		preload("res://tests/test_mapas.gd").new(),
		preload("res://tests/test_linguas.gd").new(),
		preload("res://tests/test_controles.gd").new(),
	]

	var total_passed := 0
	var total_failed := 0

	for suite in suites:
		var suite_name: String = suite.get_suite_name()
		print("[%s]" % suite_name)
		suite.run_tests()
		total_passed += suite.passed
		total_failed += suite.failed
		print("")

	print("==================================================")
	print("Resultado: %d passaram, %d falharam" % [total_passed, total_failed])
	print("==================================================\n")

	if total_failed == 0:
		quit(0)
	else:
		quit(1)
