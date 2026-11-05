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
	test_menu_pausa()

func test_constantes_tremor() -> void:
	assert_true(MainScript.FORCA_TREMOR > 0.0 and MainScript.FORCA_TREMOR <= 10.0,
		"Força de tremor da tela é positiva e suave (<= 10.0 px)")
	assert_true(MainScript.DURACAO_TREMOR > 0.0 and MainScript.DURACAO_TREMOR <= 0.5,
		"Duração de tremor da tela é positiva e curta (<= 0.5 s)")

func test_mecanica_tremor() -> void:
	var main: Node = MainScript.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
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

func test_menu_pausa() -> void:
	var main: Node = MainScript.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	main._ready()
	
	assert_true(main.get("_menu_pausa") != null, "Menu de pausa é instanciado no HUD")
	var menu: Control = main.get("_menu_pausa")
	assert_true(not menu.visible, "Menu de pausa inicia oculto")
	assert_true(not tree.paused, "Jogo inicia despausado")
	
	main.alternar_pausa()
	assert_true(tree.paused, "Pausar o jogo congela o SceneTree (paused = true)")
	assert_true(menu.visible, "Menu de pausa torna-se visível ao pausar")
	
	main.alternar_pausa()
	assert_true(not tree.paused, "Despausar restaura o processamento normal (paused = false)")
	assert_true(not menu.visible, "Menu de pausa torna-se oculto ao despausar")
	
	main.free()
