extends RefCounted
## Tipos de arma. Para criar ou ajustar uma arma, basta mexer neste dicionário.
## nivel: arma de nível maior substitui a de nível menor ao passar por cima.
## municao: -1 é infinita; quando acaba, o camaleão fica desarmado.
## alcance: distância máxima de cada bala (INF = até bater em algo).

const TIPOS := {
	"pistola": {
		"nivel": 1, "recarga": 0.35, "balas": 1, "espalhamento": 0.0,
		"alcance": INF, "municao": -1, "cor": Color(0.2, 0.2, 0.2),
	},
	"espingarda": {
		"nivel": 2, "recarga": 0.6, "balas": 5, "espalhamento": 0.5,
		"alcance": 380.0, "municao": 6, "cor": Color(0.85, 0.2, 0.25),
	},
}
