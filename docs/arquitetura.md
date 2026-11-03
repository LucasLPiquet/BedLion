# Arquitetura do Projeto

Este documento detalha a organização técnica, a hierarquia de nós e os papéis dos scripts no projeto BedLion.

---

## 1. Visão Geral

* **Engine:** Godot Engine 4.3+
* **Linguagem:** GDScript
* **Paradigma:** Orientado a nós e cenas com gerenciamento centralizado por sinais e autoloads.

---

## 2. Estrutura de Cenas

* **`scenes/main.tscn`:** Cena principal que instancia a arena, os limites do mapa, a câmera e os nós de interface. A montagem física e visual do cenário é gerada dinamicamente a partir das definições do mapa ativo.

---

## 3. Papel dos Scripts

A lógica está distribuída em scripts modulares dentro do diretório `scripts/`:

| Script | Tipo / Herança | Responsabilidade Principal |
| :--- | :--- | :--- |
| `main.gd` | `Node2D` | Orquestração da partida, contagem de pontos, controle de rodadas e ciclo de spawn. |
| `camaleao.gd` | `CharacterBody2D` | Entidade do jogador. Trata física de movimento, estados de língua, golpe, camuflagem e IA de bots. |
| `mapas.gd` | `RefCounted` | Dicionários de configuração dos mapas: coordenadas de muros, lagos, pontes e pontos de início. |
| `cenario.gd` | `Node2D` | Construção e renderização dos elementos do cenário e suas áreas de colisão. |
| `controles.gd` | `Node` (Autoload) | Singleton global para mapeamento e leitura de entradas de múltiplos teclados e controles externos. |
| `linguas.gd` | `RefCounted` | Definição de parâmetros da língua padrão e variações de poderes (alcance, velocidade e comportamento). |
| `lingua_no_chao.gd` | `Area2D` | Entidade de orbe de poder coletável posicionada no solo. |
| `placar.gd` | `Control` | Exibição visual da pontuação acumulada de cada jogador no topo da tela. |
| `pistas.gd` / `ondulacao.gd` | `Node2D` | Detecção de presença sobre água e pontes, gerando ondulações visuais e pegadas molhadas. |
| `grama_alta.gd` / `luz.gd` | `Area2D` | Mecânicas ambientais para detecção e revelação de jogadores camuflados. |
| `coco_pombo.gd` / `pegada.gd` | `Node2D` | Mecânica de armadilhas no solo e geração de rastros de pegadas. |
| `efeito_*.gd` | `Node2D` | Efeitos visuais transitórios instanciados durante golpes, eliminações e afogamento. |

---

## 4. Sistema de Entrada e Autoloads

O arquivo `scripts/controles.gd` está configurado como um **Autoload** no `project.godot`. Ele abstrai as diferenças entre teclado 1, teclado 2 e gamepads analógicos, fornecendo uma interface única de leitura de vetores direcionais e botões de ação para cada slot de jogador.

---

## 5. Ciclo de Vida da Partida

1. **Inicialização:** `main.gd` consulta `mapas.gd`, seleciona um mapa aleatório e solicita a `cenario.gd` a montagem das colisões e superfícies.
2. **Posicionamento:** Instanciação dos camaleões nos pontos de spawn definidos pelo mapa.
3. **Loop de Jogo:** Cada camaleão processa seus comandos via `camaleao.gd` emitindo sinais ao executar ataques ou sofrer danos.
4. **Eliminação:** Quando um jogador é atingido ou afunda, emite o sinal `morreu(camaleao)`.
5. **Fim de Rodada:** Ao restar apenas um jogador vivo, `main.gd` incrementa a pontuação em `placar.gd`. Se a pontuação limite for atingida, declara vitória final; caso contrário, avança para a próxima rodada após breve intervalo.
