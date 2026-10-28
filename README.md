# BedLion

Jogo 2D de multiplayer local (tela compartilhada) no estilo Boomerang Fu, feito em Godot 4 com GDScript.
Cada jogador é um camaleão com uma língua que puxa os outros e um golpe de perto que mata. Dá para ficar invisível, mas aí só sobra o golpe.

## Como rodar

Abra a pasta no Godot 4.3 (ou mais novo) e aperte F5.

## Jogadores e controles

Até 4 jogadores. Cada um joga com uma metade do teclado ou com um controle (Xbox ou parecido).
Quem entra, em ordem: teclado 1, teclado 2 e depois cada controle conectado. As cores das vagas são Verde, Laranja, Azul e Rosa.

| Controle | Mover | Golpe | Invisível | Língua |
|---|---|---|---|---|
| Teclado 1 | W A S D | F | G | H |
| Teclado 2 | Setas | `.` (ou Numpad 1) | `,` (ou Numpad 2) | `;` no teclado brasileiro, `/` no americano (ou Numpad 3) |
| Controle | Analógico esquerdo ou direcional | A ou RB | B, LB ou LT | X ou RT |

- **F1** troca o modo dos bots de teste: sem bots → bots parados → bots andando. Os bots completam até 4 jogadores. Trocar o modo recomeça a partida.
- Conectar ou desconectar um controle também recomeça a partida com os jogadores novos.
- Para jogar com um teclado só, tire um item da lista `TECLADOS` no topo de `scripts/main.gd`.
- As teclas e botões ficam em `scripts/controles.gd`.

## Partida

- Quem sobrar vivo ganha a rodada e 1 ponto. A próxima rodada começa sozinha depois de 2 segundos.
- Quem fizer 5 pontos ganha a partida, e uma nova começa depois de 4 segundos. O número fica em `PONTOS_PARA_VENCER` (`scripts/main.gd`).
- O placar fica no topo da tela: uma bolinha preenchida por ponto.

## Regras do protótipo

- Cada camaleão tem dois ataques: a **língua** e o **golpe**.
- **Língua** (só visível): sai reta da boca, vai até uns 260 px e volta. Se pegar outro camaleão, puxa ele até você em 0,5 s. A língua **não mata**: a ideia é trazer o outro para perto e dar o golpe. Se bater numa parede, ela volta.
  - Enquanto a língua está fora (indo, voltando ou puxando) você fica parado e não pode golpear: é a hora em que você está vulnerável.
  - Apertar a língua de novo solta na hora, mas aí a língua fica 1 s sem poder ser usada.
  - Quem foi pego pode se soltar apertando a língua ou o golpe, mas só depois de 0,25 s. Se soltar com o golpe, ele também bate (e mata se você estiver perto).
  - Se um terceiro camaleão passar por cima da língua esticada, ela é cortada.
  - Outros camaleões podem matar os dois com um golpe enquanto um puxa o outro.
  - Os números ficam no topo de `scripts/camaleao.gd` (`RECARGA_SOLTAR`, `TEMPO_ATE_SE_SOLTAR`, `LINGUA_PODE_SER_CORTADA`...) e em `scripts/linguas.gd` (alcance, velocidade e tempo da puxada).
- **Golpe**: curto, na frente do camaleão. Mata quem estiver a até 70 px (centro a centro) na direção em que ele olha, ou quem estiver colado de qualquer lado. Tem 0,5 s de espera entre um golpe e outro. Funciona visível e invisível (`ALCANCE_GOLPE`, `ANGULO_GOLPE`, `RECARGA_GOLPE` em `scripts/camaleao.gd`).
- Para ficar invisível é preciso **segurar** o botão por 1 segundo (`TEMPO_PARA_SUMIR`). Enquanto carrega, aparece um anel branco se completando e o camaleão vai ficando transparente; soltar antes cancela. Com a língua fora não dá para começar a sumir.
- Invisível, ninguém vê o camaleão, nem o próprio jogador, e ele não pode usar a língua. Um toque no botão de invisível, ou **dar um golpe**, faz ele aparecer de novo. Por isso não dá para ficar batendo escondido: cada golpe entrega você.
- Se uma língua pegar um camaleão invisível (por sorte), ele aparece e é puxado.
- **Upgrades de língua**: uma bolha no centro do mapa no começo da rodada e mais uma a cada 10 segundos em um ponto sorteado (no máximo 2 no chão). Passe por cima para pegar; só dá para ter um por vez. Uma bolinha com a cor do upgrade aparece em cima da cabeça.
  - **Roxa (longa)**: a língua vai até 420 px.
  - **Amarela (rápida)**: a língua é bem mais rápida e puxa em 0,3 s.
  - Ao ficar invisível, o upgrade cai no chão e você volta para a língua básica.
  - Intervalo, limite e pontos ficam no topo de `scripts/main.gd`.

## Estrutura

- `scenes/main.tscn`: cena principal (a arena é montada por código).
- `scripts/main.gd`: arena, quem joga, rodadas e placar.
- `scripts/camaleao.gd`: movimento, língua, invisibilidade, golpe e o bot de teste.
- `scripts/desenho_camaleao.gd`: desenho do camaleão (feito com formas, sem imagem).
- `scripts/cenario.gd`: desenho do mapa (chão, cerca viva, blocos de pedra, enfeites).
- `scripts/placar.gd`: placar no topo da tela.
- `scripts/efeito_morte.gd`: "puf" quando um camaleão morre.
- `scripts/linguas.gd`: tipos de língua (básica e upgrades), seus números e o desenho da língua.
- `scripts/lingua_no_chao.gd`: upgrade de língua que pode ser pego do chão.
- `scripts/efeito_golpe.gd`: risco visual do golpe curto.
- `scripts/controles.gd`: teclas e botões de cada controle (autoload).
- `arte/referencia_camaleao.jpg`: desenho de referência do camaleão.

A arte ainda é toda desenhada por código com `_draw()`. Quando houver um PNG do camaleão, dá para trocar o desenho de `desenho_camaleao.gd` por um sprite.
