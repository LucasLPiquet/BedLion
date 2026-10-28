# BedLion

Jogo 2D de multiplayer local (tela compartilhada) no estilo Boomerang Fu, feito em Godot 4 com GDScript.
Cada jogador é um camaleão que pode ficar invisível, mas para isso precisa largar a arma.

## Como rodar

Abra a pasta no Godot 4.3 (ou mais novo) e aperte F5.

## Controles

| Jogador | Mover | Atacar | Invisível |
|---|---|---|---|
| Verde | W A S D | F | G |
| Laranja | Setas | `.` (ou Numpad 1) | `,` (ou Numpad 2) |

As teclas ficam em `scripts/controles.gd`.

## Regras do protótipo

- Todo camaleão começa com a arma inicial, que atira projéteis em linha reta.
- Ficar invisível esconde o camaleão de todo mundo, inclusive do próprio jogador, e larga a arma no chão.
- Invisível, o ataque vira um golpe corpo a corpo: mata quem estiver a até 75 px (centro a centro) e mostra um anel rápido, que entrega por um instante onde você está. O alcance é `ALCANCE_GOLPE` em `scripts/camaleao.gd`.
- Ao voltar a ficar visível, o camaleão está desarmado até passar por cima de uma arma no chão.
- Há uma pistola extra no centro do mapa.
- A cada 10 segundos aparece uma espingarda (com brilho pulsando) em um ponto sorteado do mapa, no máximo 2 ao mesmo tempo. Ela atira 5 balas em leque com alcance curto e tem 6 tiros; quando acaba, você fica desarmado. Passar por cima dela com a pistola troca as armas (a pistola fica no chão). Intervalo, limite e pontos ficam no topo de `scripts/main.gd`; os números das armas, em `scripts/armas.gd`.
- Projéteis também acertam camaleões invisíveis.
- Quem sobrar vivo ganha a rodada; a próxima começa sozinha depois de 2 segundos.

## Estrutura

- `scenes/main.tscn`: cena principal (a arena é montada por código).
- `scripts/main.gd`: arena, rodadas e placar.
- `scripts/camaleao.gd`: movimento, tiro, invisibilidade e golpe.
- `scripts/bala.gd`: projétil.
- `scripts/arma_no_chao.gd`: arma que pode ser pega do chão.
- `scripts/armas.gd`: tipos de arma e seus números.
- `scripts/efeito_golpe.gd`: anel visual do golpe.
- `scripts/controles.gd`: mapa de teclas (autoload).

A arte é toda placeholder, desenhada com `_draw()`.
