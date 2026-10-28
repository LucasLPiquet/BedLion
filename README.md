# BedLion

Jogo 2D de multiplayer local (tela compartilhada) no estilo Boomerang Fu, feito em Godot 4 com GDScript.
Cada jogador é um camaleão que pode ficar invisível, mas para isso precisa largar a arma.

## Como rodar

Abra a pasta no Godot 4.3 (ou mais novo) e aperte F5.

## Jogadores e controles

Até 4 jogadores. Cada um joga com uma metade do teclado ou com um controle (Xbox ou parecido).
Quem entra, em ordem: teclado 1, teclado 2 e depois cada controle conectado. As cores das vagas são Verde, Laranja, Azul e Rosa.

| Controle | Mover | Atacar | Invisível |
|---|---|---|---|
| Teclado 1 | W A S D | F | G |
| Teclado 2 | Setas | `.` (ou Numpad 1) | `,` (ou Numpad 2) |
| Controle | Analógico esquerdo ou direcional | A, RB ou RT | B, LB ou LT |

- **F1** troca o modo dos bots de teste: sem bots → bots parados → bots andando. Os bots completam até 4 jogadores. Trocar o modo recomeça a partida.
- Conectar ou desconectar um controle também recomeça a partida com os jogadores novos.
- Para jogar com um teclado só, tire um item da lista `TECLADOS` no topo de `scripts/main.gd`.
- As teclas e botões ficam em `scripts/controles.gd`.

## Partida

- Quem sobrar vivo ganha a rodada e 1 ponto. A próxima rodada começa sozinha depois de 2 segundos.
- Quem fizer 5 pontos ganha a partida, e uma nova começa depois de 4 segundos. O número fica em `PONTOS_PARA_VENCER` (`scripts/main.gd`).
- O placar fica no topo da tela: uma bolinha preenchida por ponto.

## Regras do protótipo

- Todo camaleão começa com a pistola. Atacar com ela **joga a pistola como um bumerangue**: ela vai girando até uns 320 px e volta para a sua mão, matando quem acertar na ida e na volta. Enquanto ela está no ar você está desarmado. Se ela bater numa parede, cai no chão ali e qualquer um pode pegar. Se você estiver invisível ou já tiver pegado outra arma quando ela voltar, ela também cai no chão.
- **Sem arma na mão** (pistola no ar, perdida ou invisível), o ataque vira um **golpe curto** na frente do camaleão: mata quem estiver a até 70 px (centro a centro) na direção em que ele olha, ou quem estiver colado nele de qualquer lado. Tem 0,5 s de espera entre um golpe e outro. Os números ficam no topo de `scripts/camaleao.gd` (`ALCANCE_GOLPE`, `ANGULO_GOLPE`, `RECARGA_GOLPE`).
- Para ficar invisível é preciso **segurar** o botão por 1 segundo (`TEMPO_PARA_SUMIR`). Enquanto carrega, aparece um anel branco se completando e o camaleão vai ficando transparente; soltar antes cancela. Ao sumir, ele larga a arma no chão.
- Invisível, ninguém vê o camaleão, nem o próprio jogador. Um toque no botão de invisível, ou **dar um golpe**, faz ele aparecer de novo. Por isso não dá para ficar batendo escondido: cada golpe entrega você.
- Ao voltar a ficar visível, o camaleão está desarmado até passar por cima de uma arma no chão.
- Há uma pistola extra no centro do mapa.
- A cada 10 segundos aparece uma espingarda (com brilho pulsando) em um ponto sorteado do mapa, no máximo 2 ao mesmo tempo. Ela atira 5 balas em leque com alcance curto, espera 0,9 s entre tiros e tem 4 tiros; quando acaba, você fica desarmado. Passar por cima dela com a pistola troca as armas (a pistola fica no chão). Intervalo, limite e pontos ficam no topo de `scripts/main.gd`; os números das armas (velocidade, alcance, munição, se é arremesso ou tiro), em `scripts/armas.gd`.
- Projéteis e armas jogadas também acertam camaleões invisíveis.

## Estrutura

- `scenes/main.tscn`: cena principal (a arena é montada por código).
- `scripts/main.gd`: arena, quem joga, rodadas e placar.
- `scripts/camaleao.gd`: movimento, tiro, invisibilidade, golpe e o bot de teste.
- `scripts/desenho_camaleao.gd`: desenho do camaleão (feito com formas, sem imagem).
- `scripts/cenario.gd`: desenho do mapa (chão, cerca viva, blocos de pedra, enfeites).
- `scripts/placar.gd`: placar no topo da tela.
- `scripts/efeito_morte.gd`: "puf" quando um camaleão morre.
- `scripts/bala.gd`: projétil.
- `scripts/arma_lancada.gd`: arma jogada como bumerangue.
- `scripts/arma_no_chao.gd`: arma que pode ser pega do chão.
- `scripts/armas.gd`: tipos de arma e seus números.
- `scripts/efeito_golpe.gd`: risco visual do golpe curto.
- `scripts/controles.gd`: teclas e botões de cada controle (autoload).
- `arte/referencia_camaleao.jpg`: desenho de referência do camaleão.

A arte ainda é toda desenhada por código com `_draw()`. Quando houver um PNG do camaleão, dá para trocar o desenho de `desenho_camaleao.gd` por um sprite.
