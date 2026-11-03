# BedLion

Jogo 2D multijogador local de arena (tela compartilhada) para até 4 jogadores.

Cada jogador controla um camaleão com duas ações principais: lançar a língua para puxar os adversários e desferir um golpe de curta distância para eliminá-los. Também é possível utilizar camuflagem para ficar temporariamente invisível. O último jogador que restar na arena pontua na rodada.

## Tecnologias

- **Motor:** Godot Engine 4.3+
- **Linguagem:** GDScript

## Como rodar

### Pré-requisitos
- [Godot Engine](https://godotengine.org/) versão 4.3 ou superior.

### Execução
1. Abra o Godot Engine.
2. Clique em **Importar** e selecione o arquivo `project.godot` na raiz deste projeto.
3. Pressione **F5** para iniciar o jogo.

## Controles

O jogo suporta até 4 participantes simultâneos via teclado e controles externos:

| Dispositivo | Mover | Golpe | Invisibilidade | Língua |
| :--- | :--- | :--- | :--- | :--- |
| **Teclado 1** | `W`, `A`, `S`, `D` | `F` | `G` | `H` |
| **Teclado 2** | Setas direcionais | `.` (ou Numpad 1) | `,` (ou Numpad 2) | `;` / `/` (ou Numpad 3) |
| **Controle** | Analógico esquerdo ou direcional | `A` ou `RB` | `B`, `LB` ou `LT` | `X` ou `RT` |

### Atalhos
- **F1:** Alterna o preenchimento de vagas com bots de teste.
- **F2:** Reinicia a rodada no próximo mapa.
