# Testes Automatizados

Bateria de testes unitários executada diretamente pelo Godot Engine em modo headless.

---

## Como Executar

Na raiz do projeto, execute no terminal:

```bash
godot --headless --path . -s tests/test_runner.gd
```

* **Sucesso:** Retorna código de saída `0` e exibe `✓` para cada asserção.
* **Falha:** Retorna código de saída `1` e detalha a asserção que falhou.

---

## Estrutura dos Arquivos

* `test_runner.gd`: Ponto de entrada do script que orquestra as suítes e contabiliza os resultados.
* `test_mapas.gd`: Validações de limites de arena, integridade de coordenadas e pontos de início em `scripts/mapas.gd`.
* `test_linguas.gd`: Validações de alcance, velocidade, tempo de tração e integridade de poderes em `scripts/linguas.gd`.
* `test_controles.gd`: Validações de mapeamento obrigatório de ações em `scripts/controles.gd`.
