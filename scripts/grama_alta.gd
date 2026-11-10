class_name GramaAlta
extends Node2D
## Capim alto ("grama" em mapas.gd). As folhas da frente de um camaleão são
## desenhadas por cima dele e as de trás por baixo, então quem está dentro fica
## meio escondido (só a cabeça aparece).
## Quando alguém passa, visível ou invisível, as folhas se deitam para os lados,
## ficam mais claras e demoram para voltar: fica um rastro de por onde a pessoa andou.
##
## Desempenho: o capim tem mais de mil folhas. Antes elas eram redesenhadas todo
## quadro com draw_multiline (cada traço com antisserrilhado vira 9 comandos de
## desenho, ~60 mil por quadro), o que travava em GPU integrada. Agora todas as
## folhas ficam numa malha só, montada uma vez por mapa, e é um shader que faz o
## vento, a dobra e o antisserrilhado. O script só atualiza uma textura pequena
## com a dobra de cada folha, e só quando alguma folha mudou.

const Mapas := preload("res://scripts/mapas.gd")
const Desenho := preload("res://scripts/desenho_camaleao.gd")

## Uma folha a cada tantos pixels quadrados de capim.
const AREA_POR_FOLHA := 150.0
## Até onde um camaleão empurra as folhas (a partir dos pés).
const RAIO_EMPURRAO := 30.0
## Quanto a folha deita no máximo (em radianos).
const DOBRA_MAXIMA := 1.1
## Velocidade com que a folha deita quando alguém passa e com que volta ao lugar.
## Voltar devagar é o que deixa o rastro.
const VELOCIDADE_DEITAR := 9.0
const VELOCIDADE_VOLTAR := 0.8
## Os pés ficam um pouco abaixo do centro do camaleão.
const PES := Desenho.PES

const COR := Color(0.36, 0.58, 0.22)
const COR_CONTORNO := Color(0.12, 0.22, 0.08)
const COR_DEITADA := Color(0.72, 0.78, 0.42)
## Grossura do contorno escuro e da folha por cima dele.
const LARGURA_CONTORNO := 3.4
const LARGURA_FOLHA := 2.2

## Largura (em texels) das texturas com os dados das folhas: uma folha por texel.
const LARGURA_TEXTURA := 256
## Cada traço da folha vira uma grade de 4x4 vértices: o miolo opaco e, em volta,
## uma borda de 1,25 px que some (igual ao antisserrilhado do draw_line do Godot).
const VERTICES_POR_TRACO := 16

const CODIGO_SHADER := """
shader_type canvas_item;

// Uma folha por texel. fixos: r = altura, g = inclinacao parada, b = fase do vento.
uniform sampler2D fixos : filter_nearest, repeat_disable;
// dobras: r = dobra atual, g = 1 se a folha esta atras de alguem.
uniform sampler2D dobras : filter_nearest, repeat_disable;
uniform int largura_textura = 256;
uniform float tempo = 0.0;
uniform bool camada_de_tras = false;
uniform vec4 cor_contorno = vec4(0.12, 0.22, 0.08, 1.0);
uniform vec4 cor_deitada = vec4(0.72, 0.78, 0.42, 1.0);
uniform float dobra_maxima = 1.1;
uniform float largura_contorno = 3.4;
uniform float largura_folha = 2.2;

const float BORDA = 1.25;

void vertex() {
	// VERTEX traz a base da folha, COLOR a cor dela e UV = (indice da folha, codigo do vertice).
	int folha = int(UV.x + 0.5);
	int codigo = int(UV.y + 0.5);
	ivec2 texel = ivec2(folha % largura_textura, folha / largura_textura);
	vec4 fixo = texelFetch(fixos, texel, 0);
	vec4 dinamico = texelFetch(dobras, texel, 0);
	vec2 base = VERTEX;
	bool atras = dinamico.g > 0.5;
	bool nesta_camada = camada_de_tras ? atras : !atras;
	if (!nesta_camada) {
		// A folha e desenhada na outra camada: some (triangulos sem area).
		VERTEX = base;
		COLOR = vec4(0.0);
	} else {
		float altura = fixo.r;
		float dobra = dinamico.r;
		float angulo = fixo.g + dobra + sin(tempo * 1.7 + fixo.b) * 0.07;
		vec2 ponta = base + vec2(sin(angulo), -cos(angulo)) * altura;
		vec2 meio = base + vec2(sin(angulo * 0.5), -cos(angulo * 0.5)) * altura * 0.5;

		int coluna = codigo & 3;
		int linha = (codigo >> 2) & 3;
		bool segundo_traco = ((codigo >> 4) & 1) == 1;
		bool contorno = ((codigo >> 5) & 1) == 0;

		vec2 de = segundo_traco ? meio : base;
		vec2 ate = segundo_traco ? ponta : meio;
		vec2 ao_longo = normalize(de - ate);
		vec2 lado = vec2(ao_longo.y, -ao_longo.x);
		float meia = (contorno ? largura_contorno : largura_folha) * 0.5;

		float deslocamento = meia + BORDA;
		if (coluna == 1) {
			deslocamento = meia;
		} else if (coluna == 2) {
			deslocamento = -meia;
		} else if (coluna == 3) {
			deslocamento = -meia - BORDA;
		}
		vec2 ponto = linha <= 1 ? de : ate;
		if (linha == 0) {
			ponto += ao_longo * BORDA;
		} else if (linha == 3) {
			ponto -= ao_longo * BORDA;
		}
		VERTEX = ponto + lado * deslocamento;

		vec4 cor = cor_contorno;
		if (!contorno) {
			cor = mix(COLOR, cor_deitada, abs(dobra) / dobra_maxima * 0.7);
		}
		bool miolo = linha >= 1 && linha <= 2 && coluna >= 1 && coluna <= 2;
		if (!miolo) {
			cor.a = 0.0;
		}
		COLOR = cor;
	}
	UV = vec2(0.0);
}
"""

## A malha e os dados fixos de cada mapa ficam guardados entre as rodadas.
static var _shader: Shader
static var _cache: Dictionary = {}

var mapa: Dictionary = {}
var _tempo := 0.0
var _atras: Node2D # desenha as folhas que estão atrás de algum camaleão (por baixo dele)
var _material_frente: ShaderMaterial
var _material_tras: ShaderMaterial
var _malha: ArrayMesh

var _bases := PackedVector2Array()
var _areas: Array[Rect2] = [] # área de cada bloco em que os pés afetam as folhas
var _folhas_do_bloco: Array[PackedInt32Array] = []
var _tem_dobra := PackedByteArray() # por bloco: alguma folha ainda deitada?
## Por folha, 4 floats (o texel): dobra, atrás (0 ou 1), 0, 0.
var _dados := PackedFloat32Array()
var _imagem_dobras: Image
var _textura_dobras: ImageTexture
var _linhas_textura := 1


func _ready() -> void:
	z_index = 1 # por cima dos camaleões
	var plano := _plano(mapa)
	_bases = plano["bases"]
	if _bases.is_empty():
		set_process(false)
		return
	_areas = plano["areas"]
	_folhas_do_bloco = plano["folhas_do_bloco"]
	_malha = plano["malha"]
	_linhas_textura = plano["linhas"]
	_tem_dobra.resize(_areas.size())
	_tem_dobra.fill(0)

	_dados.resize(LARGURA_TEXTURA * _linhas_textura * 4)
	_dados.fill(0.0)
	_imagem_dobras = Image.create_from_data(LARGURA_TEXTURA, _linhas_textura, false,
		Image.FORMAT_RGBAF, _dados.to_byte_array())
	_textura_dobras = ImageTexture.create_from_image(_imagem_dobras)

	_material_frente = _criar_material(plano["fixos"], false)
	_material_tras = _criar_material(plano["fixos"], true)
	material = _material_frente

	_atras = Node2D.new()
	_atras.z_index = -2 # 1 - 2 = -1: por baixo dos camaleões
	_atras.material = _material_tras
	_atras.visible = false
	_atras.draw.connect(_desenhar_malha.bind(_atras))
	add_child(_atras)


func _criar_material(fixos: ImageTexture, camada_de_tras: bool) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODIGO_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("fixos", fixos)
	mat.set_shader_parameter("dobras", _textura_dobras)
	mat.set_shader_parameter("largura_textura", LARGURA_TEXTURA)
	mat.set_shader_parameter("camada_de_tras", camada_de_tras)
	mat.set_shader_parameter("cor_contorno", COR_CONTORNO)
	mat.set_shader_parameter("cor_deitada", COR_DEITADA)
	mat.set_shader_parameter("dobra_maxima", DOBRA_MAXIMA)
	mat.set_shader_parameter("largura_contorno", LARGURA_CONTORNO)
	mat.set_shader_parameter("largura_folha", LARGURA_FOLHA)
	return mat


func _process(delta: float) -> void:
	_tempo += delta
	_material_frente.set_shader_parameter("tempo", _tempo)
	_material_tras.set_shader_parameter("tempo", _tempo)

	var pes := PackedVector2Array()
	for camaleao in get_tree().get_nodes_in_group("camaleoes"):
		if camaleao.vivo:
			pes.append(camaleao.position + PES)
	for casca in get_tree().get_nodes_in_group("cascas"):
		if not casca.is_queued_for_deletion():
			pes.append(casca.position + PES)

	var mudou := false
	var algum_atras := false
	var pes_bloco := PackedVector2Array()
	for b in _areas.size():
		var area: Rect2 = _areas[b]
		pes_bloco.clear()
		for pe: Vector2 in pes:
			if area.has_point(pe):
				pes_bloco.append(pe)
		# Bloco sem ninguém e com todas as folhas em pé: nada para fazer.
		if pes_bloco.is_empty() and _tem_dobra[b] == 0:
			continue

		var ainda_dobrado := not pes_bloco.is_empty()
		for i: int in _folhas_do_bloco[b]:
			var k := i * 4
			var dobra: float = _dados[k]
			var antes_dobra := dobra
			var antes_atras: float = _dados[k + 1]

			if pes_bloco.is_empty():
				# Sem ninguém por perto: só volta ao lugar devagar.
				if dobra != 0.0:
					dobra = move_toward(dobra, 0.0, VELOCIDADE_VOLTAR * delta)
					_dados[k] = dobra
					if dobra != 0.0:
						ainda_dobrado = true
				_dados[k + 1] = 0.0
			else:
				var base: Vector2 = _bases[i]
				var alvo := 0.0
				var atras := false
				for pe: Vector2 in pes_bloco:
					var dif := base - pe
					# Folha logo acima dos pés (atrás do corpo): vai para a camada de baixo.
					if absf(dif.x) < 30.0 and dif.y < -4.0 and dif.y > -60.0:
						atras = true
					if absf(dif.x) > RAIO_EMPURRAO or absf(dif.y) > RAIO_EMPURRAO:
						continue
					var distancia := dif.length()
					if distancia < RAIO_EMPURRAO:
						# Deita para o lado contrário de quem está pisando.
						var lado := 1.0 if dif.x >= 0.0 else -1.0
						alvo += lado * DOBRA_MAXIMA * (1.0 - distancia / RAIO_EMPURRAO * 0.6)

				alvo = clampf(alvo, -DOBRA_MAXIMA, DOBRA_MAXIMA)
				if absf(alvo) > absf(dobra) or (alvo != 0.0 and signf(alvo) != signf(dobra)):
					dobra = move_toward(dobra, alvo, VELOCIDADE_DEITAR * delta)
				else:
					dobra = move_toward(dobra, alvo, VELOCIDADE_VOLTAR * delta)
				_dados[k] = dobra
				_dados[k + 1] = 1.0 if atras else 0.0
				if atras:
					algum_atras = true

			if dobra != antes_dobra or _dados[k + 1] != antes_atras:
				mudou = true
		_tem_dobra[b] = 1 if ainda_dobrado else 0

	if mudou:
		_imagem_dobras.set_data(LARGURA_TEXTURA, _linhas_textura, false, Image.FORMAT_RGBAF,
			_dados.to_byte_array())
		_textura_dobras.update(_imagem_dobras)
	# A camada de trás só desenha quando tem alguém no meio do capim.
	_atras.visible = algum_atras


func _draw() -> void:
	_desenhar_malha(self)


func _desenhar_malha(item: CanvasItem) -> void:
	if _malha != null:
		item.draw_mesh(_malha, null)


## Sorteia as folhas do mapa e monta a malha com todas elas (uma vez por mapa).
static func _plano(dados_mapa: Dictionary) -> Dictionary:
	var chave := str(dados_mapa.get("semente", 7)) + str(dados_mapa.get("grama", []))
	if _cache.has(chave):
		return _cache[chave]

	var rng := RandomNumberGenerator.new()
	rng.seed = dados_mapa.get("semente", 7) + 1000
	var areas: Array[Rect2] = []
	# Cada folha: [base, altura, cor, fase do vento, inclinação parada, índice do bloco]
	var folhas: Array = []
	var indice_bloco := 0
	for item in dados_mapa.get("grama", []):
		var retangulo: Rect2 = item
		# Área dentro da qual os pés de um camaleão ou casca podem afetar as folhas deste bloco
		areas.append(Rect2(retangulo.position.x - 30.0, retangulo.position.y - 30.0,
			retangulo.size.x + 60.0, retangulo.size.y + 90.0))
		var quantidade := int(retangulo.get_area() / AREA_POR_FOLHA)
		for i in quantidade:
			var base := Vector2(rng.randf_range(retangulo.position.x, retangulo.end.x),
				rng.randf_range(retangulo.position.y, retangulo.end.y))
			if not Mapas.dentro_arredondado(retangulo, base, 4.0):
				continue
			# Folhas da borda são mais baixas, para o capim ter um contorno macio.
			var altura := rng.randf_range(18.0, 30.0)
			if not Mapas.dentro_arredondado(retangulo, base, 18.0):
				altura *= 0.65
			var cor := COR.lightened(rng.randf_range(-0.12, 0.12))
			folhas.append([base, altura, cor, rng.randf() * TAU, rng.randf_range(-0.25, 0.25), indice_bloco])
		indice_bloco += 1
	# Desenha de cima para baixo, assim as folhas da frente ficam por cima.
	folhas.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)

	var n := folhas.size()
	var linhas := maxi(1, ceili(float(n) / LARGURA_TEXTURA))
	var bases := PackedVector2Array()
	bases.resize(n)
	var folhas_do_bloco: Array[PackedInt32Array] = []
	for b in areas.size():
		folhas_do_bloco.append(PackedInt32Array())
	var fixos := PackedFloat32Array()
	fixos.resize(LARGURA_TEXTURA * linhas * 4)
	fixos.fill(0.0)
	for i in n:
		var folha: Array = folhas[i]
		bases[i] = folha[0]
		folhas_do_bloco[folha[5]].append(i)
		fixos[i * 4] = folha[1]
		fixos[i * 4 + 1] = folha[4]
		fixos[i * 4 + 2] = folha[3]

	var plano := {
		"bases": bases,
		"areas": areas,
		"folhas_do_bloco": folhas_do_bloco,
		"linhas": linhas,
		"malha": null,
		"fixos": null,
	}
	if n > 0:
		var imagem := Image.create_from_data(LARGURA_TEXTURA, linhas, false, Image.FORMAT_RGBAF,
			fixos.to_byte_array())
		plano["fixos"] = ImageTexture.create_from_image(imagem)
		plano["malha"] = _montar_malha(folhas)
	_cache[chave] = plano
	return plano


## Malha com dois traços por folha (base-meio e meio-ponta), primeiro todos os
## contornos e depois todas as folhas por cima, na mesma ordem do draw_multiline.
## Os vértices só guardam a base, a cor e um código; a forma sai do shader.
static func _montar_malha(folhas: Array) -> ArrayMesh:
	var n := folhas.size()
	var tracos := n * 2 * 2
	var total := tracos * VERTICES_POR_TRACO
	var vertices := PackedVector2Array()
	vertices.resize(total)
	var uvs := PackedVector2Array()
	uvs.resize(total)
	var cores := PackedColorArray()
	cores.resize(total)

	var v := 0
	for passada in 2: # 0 = contorno, 1 = folha
		for i in n:
			var folha: Array = folhas[i]
			var base: Vector2 = folha[0]
			var cor: Color = folha[2]
			for traco in 2:
				var codigo_traco := traco * 16 + passada * 32
				for k in VERTICES_POR_TRACO:
					vertices[v] = base
					cores[v] = cor
					uvs[v] = Vector2(i, codigo_traco + k) # k = linha * 4 + coluna
					v += 1

	# Grade 4x4 de cada traço: 9 quadradinhos, 2 triângulos cada. Nos cantos a
	# diagonal sai do vértice opaco, como no draw_line com antisserrilhado.
	var modelo := PackedInt32Array()
	for linha in 3:
		for coluna in 3:
			var a := linha * 4 + coluna
			var b := a + 1
			var d := a + 4
			var e := a + 5
			if (linha == 0 and coluna == 2) or (linha == 2 and coluna == 0):
				modelo.append_array([b, d, a, b, e, d])
			else:
				modelo.append_array([a, e, b, a, d, e])
	var indices := PackedInt32Array()
	indices.resize(tracos * modelo.size())
	var j := 0
	for t in tracos:
		var inicio := t * VERTICES_POR_TRACO
		for indice: int in modelo:
			indices[j] = inicio + indice
			j += 1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cores
	arrays[Mesh.ARRAY_INDEX] = indices
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
		Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return malha
