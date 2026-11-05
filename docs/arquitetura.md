# Arquitetura do Projeto

Este documento detalha a organização técnica, a hierarquia de nós e os papéis dos scripts no projeto BedLion.

---

## 1. Visão Geral

* **Engine:** Godot Engine 4.3+ (compatível com 4.7+)
* **Linguagem:** GDScript com tipagem estática e classes canônicas (`class_name`)
* **Paradigma:** Orientado a nós e cenas com gerenciamento centralizado por sinais e singletons (autoloads).
* **Resolução Base:** 1600x900 (16:9) com modo de estiramento `canvas_items` e proporção `keep`.

---

## 2. Estrutura de Cenas

* **`scenes/menu.tscn`:** Ponto de entrada do jogo (`run/main_scene`). Apresenta o menu inicial com opções para navegar ao Lobby, Configurações ou sair do jogo.
* **`scenes/lobby.tscn`:** Sala de espera local para até 4 participantes. Permite que jogadores humanos conectem teclados ou gamepads, escolham suas cores exclusivas, confirmem prontidão e configurem a quantidade e dificuldade dos bots.
* **`scenes/configuracoes.tscn`:** Interface de opções do jogo para ajuste de volume master de áudio e alternância de tela cheia, com persistência automática em `user://configuracoes.cfg`.
* **`scenes/main.tscn`:** Cena da arena de jogo. Instancia a arena, limites físicos, câmera, interface HUD (placar e mensagens de rodada) e gerencia os ciclos de spawn, combate e encerramento de rodadas.

---

## 3. Papel dos Scripts

A lógica está distribuída em scripts modulares dentro do diretório `scripts/`:

| Script | Tipo / Herança | Responsabilidade Principal |
| :--- | :--- | :--- |
| `main.gd` | `Node2D` | Orquestração da partida, contagem de pontos, controle de rodadas, spawn de poderes e cocôs. |
| `partida.gd` | `Node` (Autoload) | Singleton global de sessão: armazena jogadores ativos, configurações de bots e opções de áudio/vídeo. |
| `controles.gd` | `Node` (Autoload) | Singleton global para mapeamento e leitura unificada de ações em múltiplos teclados e gamepads. |
| `camaleao.gd` | `CharacterBody2D` | Entidade do camaleão (jogadores e bots). Trata movimentação, língua, golpe corpo a corpo e camuflagem. |
| `desenho_camaleao.gd` | `RefCounted` | Renderização vetorial procedural do camaleão e definição geométrica dos pés e da boca. |
| `bot.gd` | `RefCounted` | Cérebro da inteligência artificial: percepção de pistas, tomada de decisões, mira e evasão por nível de dificuldade. |
| `caminhos.gd` | `RefCounted` | Grade de navegação A* (`AStarGrid2D`) para cálculo de rotas dos bots contornando muros e rios. |
| `mapas.gd` | `RefCounted` | Catálogo de mapas: coordenadas de muros, corpos d'água, pontes, poças, capim alto, luz e pontos de início/upgrade. |
| `cenario.gd` | `Node2D` | Renderização estática do terreno (chão de ladrilhos, cerca viva, pedras, pontes e decorações). |
| `agua.gd` | `Node2D` | Partículas e brilhos visuais procedurais sobre as superfícies de lagos e rios. |
| `grama_alta.gd` | `Node2D` | Camada de capim alto que oculta jogadores e reage fisicamente à passagem de corpos. |
| `luz.gd` | `Node2D` | Projeção de áreas de sol que revelam a silhueta da sombra de jogadores camuflados. |
| `pistas.gd` | `Node` | Sistema de rastros e pegadas molhadas ao atravessar ou sair de poças e pontes. |
| `ondulacao.gd` | `Node2D` | Efeito visual de anéis expansivos de onda em água rasa. |
| `linguas.gd` | `RefCounted` | Tabela de propriedades de cada tipo de língua e upgrade (alcance, velocidade, tempo e cores). |
| `lingua_no_chao.gd` | `Area2D` | Bolha de poder coletável posicionada na arena. |
| `grude.gd` | `Node2D` | Rastro de gosma deixado no solo pela língua do poder grude que imobiliza adversários. |
| `casca.gd` | `Node2D` | Réplica estática deixada para trás pelo poder muda de pele como isca para adversários. |
| `coco_pombo.gd` | `Node2D` | Armadilha aérea que cai periodicamente, sujando os pés de quem pisar. |
| `pegada.gd` | `Node2D` | Marca de pegada temporária deixada por camaleões com os pés sujos de cocô ou água. |
| `placar.gd` | `Control` | Exibição visual da pontuação acumulada de cada jogador no topo da tela. |
| `ui.gd` | `RefCounted` | Utilitários de construção de interface e integração com o recurso de tema compartilhado (`ui_tema.tres`). |
| `menu.gd` | `Control` | Controlador da tela de menu inicial e navegação. |
| `lobby.gd` | `Control` | Controlador da sala de seleção de jogadores, cores e parâmetros de bots. |
| `configuracoes.gd` | `Control` | Controlador da tela de opções de áudio e exibição. |
| `efeito_afundar.gd` | `Node2D` | Efeito visual de camaleão submergindo em água com respingos. |
| `efeito_golpe.gd` | `Node2D` | Risco visual do arco de ataque do golpe corporal de curta distância. |
| `efeito_morte.gd` | `Node2D` | Efeito de fumaça gerado na eliminação do camaleão ou da casca. |
| `efeito_texto.gd` | `Node2D` | Texto flutuante temporário exibindo o nome de poderes coletados. |

---

## 4. Sistema de Entrada e Autoloads

O projeto utiliza dois singletons globais registrados em `project.godot`:

1. **`Controles` (`scripts/controles.gd`):** Abstrai as diferenças de hardware e fornece uma API unificada para leitura de inputs direcionais e ações (`golpe`, `invisivel`, `lingua`) para Teclado 1 (`WASD`/`F`/`G`/`H`), Teclado 2 (Setas/Teclado Numérico) e múltiplos gamepads conectados via `Input.get_connected_joypads()`.
2. **`Partida` (`scripts/partida.gd`):** Persiste o estado global entre transições de tela, incluindo a lista de jogadores confirmados no lobby, slots de bots e suas dificuldades, além de gerenciar a leitura e gravação das configurações do usuário.

---

## 5. Ciclo de Vida da Aplicação e da Partida

1. **Menu Principal (`menu.tscn`):** O usuário seleciona iniciar uma nova sessão ou ajustar opções globais.
2. **Configurações do Lobby (`lobby.tscn`):** Os jogadores ingressam, escolhem cores distintas e definem bots. Os dados são salvos em `Partida` e a cena transiciona para `main.tscn`.
3. **Inicialização da Rodada (`main.gd`):** `main.gd` consulta `Partida` para instanciar os camaleões, sorteia um mapa em `mapas.gd` (garantindo alternância) e monta o cenário e colisões.
4. **Combate:** Jogadores e bots interagem em tempo real utilizando física 2D (camada `camaleoes` colidindo com camada `paredes`).
5. **Eliminação e Resolução:** Quando um camaleão é atingido ou cai na água, é eliminado. Golpes simultâneos no mesmo quadro são resolvidos em conjunto permitindo detecção justa de empate.
6. **Pontuação e Rodadas:** Ao restar apenas um sobrevivente (ou em caso de empate), os pontos são atribuídos em `placar.gd`. Se a meta for alcançada, a partida encerra; caso contrário, uma nova rodada é iniciada no próximo mapa.
