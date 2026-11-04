extends RefCounted

const Mapas := preload("res://scripts/mapas.gd")
const Caminhos := preload("res://scripts/caminhos.gd")

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
	test_pontos_livres_de_parede_e_agua()
	test_conectividade_rotas()

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

func test_pontos_livres_de_parede_e_agua() -> void:
	for mapa in Mapas.MAPAS:
		var nome: String = mapa.get("nome", "")
		var inicios_livres := true
		for pos in mapa.get("inicios", []):
			if _ponto_em_parede(mapa, pos) or Mapas.afunda(mapa, pos):
				inicios_livres = false
				break
		assert_true(inicios_livres, "Mapa '%s': posições iniciais não caem em parede ou água" % nome)

		var upgrades_livres := true
		for pos in mapa.get("pontos_upgrade", []):
			if _ponto_em_parede(mapa, pos) or Mapas.na_agua(mapa, pos):
				upgrades_livres = false
				break
		assert_true(upgrades_livres, "Mapa '%s': pontos de upgrade não caem em parede ou água" % nome)

func test_conectividade_rotas() -> void:
	for mapa in Mapas.MAPAS:
		var nome: String = mapa.get("nome", "")
		var inicios: Array = mapa.get("inicios", [])
		var todas_rotas_conectadas := true
		for i in inicios.size():
			for j in range(i + 1, inicios.size()):
				var rota := Caminhos.caminho(mapa, inicios[i], inicios[j])
				if rota.is_empty():
					todas_rotas_conectadas = false
					break
			if not todas_rotas_conectadas:
				break
		assert_true(todas_rotas_conectadas, "Mapa '%s': há rota conectada entre todas as posições iniciais" % nome)

func _ponto_em_parede(mapa: Dictionary, ponto: Vector2) -> bool:
	for parede in mapa.get("paredes", []):
		var retangulo: Rect2 = parede
		if retangulo.has_point(ponto):
			return true
	return false
