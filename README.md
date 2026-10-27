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
- Invisível, o ataque vira um golpe corpo a corpo de curto alcance.
- Ao voltar a ficar visível, o camaleão está desarmado até passar por cima de uma arma no chão.
- Há uma arma extra no centro do mapa.
- Projéteis também acertam camaleões invisíveis.
- Quem sobrar vivo ganha a rodada; a próxima começa sozinha depois de 2 segundos.

## Estrutura

- `scenes/main.tscn`: cena principal (a arena é montada por código).
- `scripts/main.gd`: arena, rodadas e placar.
- `scripts/camaleao.gd`: movimento, tiro, invisibilidade e golpe.
- `scripts/bala.gd`: projétil.
- `scripts/arma_no_chao.gd`: arma que pode ser pega do chão.
- `scripts/controles.gd`: mapa de teclas (autoload).

A arte é toda placeholder, desenhada com `_draw()`.
