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
	test_tela_fim_partida()

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

func test_tela_fim_partida() -> void:
	var main: Node = MainScript.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	main._ready()
	
	assert_true(main.get("_tela_fim_partida") != null, "Tela de fim de partida é instanciada no HUD")
	var tela: Control = main.get("_tela_fim_partida")
	assert_true(not tela.visible, "Tela de fim de partida inicia oculta")
	
	main._exibir_fim_partida(0)
	assert_true(tela.visible, "Tela de fim de partida torna-se visível ao atingir limite")
	var rotulo_vencedor: Label = main.get("_rotulo_vencedor")
	assert_true(rotulo_vencedor.text.contains("venceu a partida"), "Nome e mensagem do vencedor são exibidos")
	var container: VBoxContainer = main.get("_container_placar_final")
	assert_true(container.get_child_count() > 0, "Resumo do placar final lista os participantes")
	
	main._ocultar_fim_partida()
	assert_true(not tela.visible, "_ocultar_fim_partida oculta a tela de vitória")
	
	main.free()
