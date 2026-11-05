extends RefCounted

const MainScript := preload("res://scripts/main.gd")

var passed := 0
var failed := 0

func get_suite_name() -> String:
	return "Testes de Partida e Mecânicas (scripts/main.gd)"

func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ %s" % message)
		passed += 1
	else:
		printerr("  ✗ FALHA: %s" % message)
		failed += 1

func run_tests() -> void:
	test_constantes_tremor()
	test_mecanica_tremor()

func test_constantes_tremor() -> void:
	assert_true(MainScript.FORCA_TREMOR > 0.0 and MainScript.FORCA_TREMOR <= 10.0,
		"Força de tremor da tela é positiva e suave (<= 10.0 px)")
	assert_true(MainScript.DURACAO_TREMOR > 0.0 and MainScript.DURACAO_TREMOR <= 0.5,
		"Duração de tremor da tela é positiva e curta (<= 0.5 s)")

func test_mecanica_tremor() -> void:
	var main: Node = MainScript.new()
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	cam.position = Vector2.ZERO
	main.set("_camera", cam)
	main.add_child(cam)
	
	main.tremer_tela(0.2)
	assert_true(main.get("_tempo_tremor") == 0.2, "tremer_tela ativa o temporizador de tremor")
	
	main._process(0.1)
	assert_true(main.get("_tempo_tremor") < 0.2 and main.get("_tempo_tremor") > 0.0,
		"_process reduz o tempo de tremor restante")
	
	main._process(0.2)
	assert_true(main.get("_tempo_tremor") == 0.0, "Tempo de tremor é zerado após decorrida a duração")
	assert_true(cam.offset == Vector2.ZERO, "Posição da câmera é restaurada para a origem (offset zero)")
	
	main.free()
