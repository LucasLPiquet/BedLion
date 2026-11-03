extends RefCounted

const Mapas := preload("res://scripts/mapas.gd")

var passed := 0
var failed := 0

func get_suite_name() -> String:
	return "Testes de Mapas (scripts/mapas.gd)"

func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ %s" % message)
		passed += 1
	else:
		printerr("  ✗ FALHA: %s" % message)
		failed += 1

func run_tests() -> void:
	test_mapas_cadastrados()
	test_regras_de_cada_mapa()

func test_mapas_cadastrados() -> void:
	assert_true(Mapas.MAPAS.size() > 0, "A lista de mapas contém ao menos um mapa cadastrado")

func test_regras_de_cada_mapa() -> void:
	var limites_arena := Rect2(40, 40, 1520, 820)

	for mapa in Mapas.MAPAS:
		var nome: String = mapa.get("nome", "")
		assert_true(not nome.is_empty(), "O mapa possui nome válido")

		var inicios: Array = mapa.get("inicios", [])
		assert_true(inicios.size() >= 4, "Mapa '%s' possui ao menos 4 posições iniciais" % nome)

		var todos_dentro := true
		for pos in inicios:
			if not limites_arena.has_point(pos):
				todos_dentro = false
				break
		assert_true(todos_dentro, "Mapa '%s': todas as posições iniciais estão dentro dos limites da arena" % nome)

		var upgrades: Array = mapa.get("pontos_upgrade", [])
		assert_true(upgrades.size() > 0, "Mapa '%s' possui pontos para surgimento de upgrades" % nome)
