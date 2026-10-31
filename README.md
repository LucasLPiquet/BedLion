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

- **F2** pula para o próximo mapa (começa uma rodada nova, sem ponto para ninguém).
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
- **Língua** (só visível): sai reta da boca, vai até uns 330 px e volta. Se pegar outro camaleão, puxa ele até você em 0,5 s. A língua **não mata**: a ideia é trazer o outro para perto e dar o golpe. Se bater numa parede (ou na pedra do meio), ela para ali e volta, sem puxar ninguém; ela não pega quem está atrás de parede, e se uma parede ficar no meio enquanto puxa, ela solta.
  - Enquanto a língua está fora (indo, voltando ou puxando) você fica parado e não pode golpear: é a hora em que você está vulnerável.
  - Apertar a língua de novo solta na hora, mas aí a língua fica 1 s sem poder ser usada.
  - Quem foi pego pode se soltar apertando a língua ou o golpe, mas só depois de 0,25 s. Se soltar com o golpe, ele também bate (e mata se você estiver perto).
  - Se um terceiro camaleão passar por cima da língua esticada, ela é cortada.
  - Outros camaleões podem matar os dois com um golpe enquanto um puxa o outro.
  - Os números ficam no topo de `scripts/camaleao.gd` (`RECARGA_SOLTAR`, `TEMPO_ATE_SE_SOLTAR`, `LINGUA_PODE_SER_CORTADA`...) e em `scripts/linguas.gd` (alcance, velocidade e tempo da puxada).
- **Golpe**: curto, na frente do camaleão. Mata quem estiver a até 95 px (centro a centro) na direção em que ele olha (uns 85° para cada lado), ou quem estiver a até 50 px de qualquer lado. Não bate através de parede. Tem 0,5 s de espera entre um golpe e outro. Funciona visível e invisível (`ALCANCE_GOLPE`, `ANGULO_GOLPE`, `DISTANCIA_COLADO`, `RECARGA_GOLPE` em `scripts/camaleao.gd`).
- Para ficar invisível é preciso **segurar** o botão por 1 segundo (`TEMPO_PARA_SUMIR`). Enquanto carrega, aparece um anel branco se completando e o camaleão vai ficando transparente; soltar antes cancela. Com a língua fora não dá para começar a sumir.
- Invisível, ninguém vê o camaleão, nem o próprio jogador, e ele não pode usar a língua. Um toque no botão de invisível, ou **dar um golpe**, faz ele aparecer de novo. Por isso não dá para ficar batendo escondido: cada golpe entrega você.
- Se uma língua pegar um camaleão invisível (por sorte), ele aparece e é puxado.
- **Poderes**: uma bolha no centro do mapa no começo da rodada e mais uma a cada 10 segundos em um ponto sorteado (no máximo 2 no chão). Passe por cima para pegar; só dá para ter um por vez. O nome do poder aparece em cima de quem pegou, e uma bolinha com a cor dele fica em cima da cabeça. Ao ficar invisível, o poder cai no chão e você volta para a língua básica (menos a muda de pele, que é gasta). Todos giram em volta da língua e da invisibilidade:
  - **Laranja (gancho)**: se a língua bater numa parede, ela gruda lá e puxa **você** até a parede, voando por cima de tudo, até da água. Serve para fugir, atravessar lagos e chegar de surpresa. Apertar a língua no meio do voo solta (e se você estiver em cima da água, afunda). A língua também vai mais longe (480 px).
  - **Verde (grude)**: quando a língua erra (bate na parede ou chega no fim sem pegar ninguém), a ponta deixa uma bola de grude no chão. Quem pisar, **mesmo invisível**, fica preso 1,2 s e aparece. Preso não anda nem usa a língua, mas ainda golpeia. Quem soltou não gruda; cada um pode ter 2 grudes no chão (o mais antigo some) e eles duram 12 s.
  - **Bege (muda de pele)**: um toque no botão de invisível troca de pele: você some **na hora**, sem segurar, e a pele velha fica parada no lugar, igualzinha a você. Uma língua ou um golpe estoura a pele num "puf" branco; sozinha ela murcha em 8 s.
  - **Azul-claro (olho de camaleão)**: um círculo tracejado mostra até onde você enxerga (200 px). Quem estiver invisível lá dentro aparece como um vulto tremido, para todo mundo ver. Como ficar invisível larga o poder, quem tem o olho fica visível: é o caçador de invisíveis.
  - Os números de cada poder ficam em `scripts/linguas.gd` (e em `scripts/grude.gd` e `scripts/casca.gd`). As línguas antigas (longa e rápida) continuam lá; para voltar com elas, coloque `"longa"` ou `"rapida"` na lista `UPGRADES`.
- **Cocô de pombo**: a cada 4 s cai um cocô num lugar sorteado (no máximo 4 no mapa). Antes aparece uma sombra no chão por 1 s, para dar tempo de sair. Quem levar o cocô na cabeça ou pisar nele fica com os pés sujos e deixa **pegadas** por 6 s, mesmo invisível. O cocô fica 15 s no chão e as pegadas somem em 3 s (`INTERVALO_COCO`, `MAX_COCOS` em `scripts/main.gd`; `TEMPO_AVISO`, `TEMPO_PEGADAS`, `TEMPO_NO_CHAO` em `scripts/coco_pombo.gd`).
- **Arena**: 1600 x 900 (`TAMANHO` em `scripts/main.gd`), esticada para caber na janela.
- **Mapas**: a cada rodada o mapa muda. Os mapas de `scripts/mapas.gd` são embaralhados e saem um por vez, então todos aparecem antes de algum repetir (e nunca o mesmo duas rodadas seguidas). O nome do mapa aparece embaixo de "Rodada N". **F2** pula para o próximo mapa na hora (útil para testar).
  - **Jardim**: o mapa original, aberto, com 4 blocos de pedra.
  - **Labirinto**: muitos muros e corredores.
  - **Lago**: um lago grande no meio com uma ponte atravessando.
  - **Rios**: dois rios de cima a baixo, cada um com duas pontes.
  - **Ruínas**: muros espalhados e dois laguinhos redondos.
  - **Água**: quem pisar na água afunda e morre (também se for puxado pela língua para dentro dela). A língua passa por cima da água. Pontes são seguras. Upgrades e cocô de pombo nunca caem na água nem nas paredes.
  - Para criar um mapa novo, copie um dos blocos de `scripts/mapas.gd` e mude o nome e as posições. As explicações de cada campo estão no topo do arquivo.
  - Intervalo, limite e pontos ficam no topo de `scripts/main.gd`.

## Estrutura

- `scenes/main.tscn`: cena principal (a arena é montada por código).
- `scripts/main.gd`: arena, quem joga, rodadas e placar.
- `scripts/camaleao.gd`: movimento, língua, invisibilidade, golpe e o bot de teste.
- `scripts/desenho_camaleao.gd`: desenho do camaleão (feito com formas, sem imagem).
- `scripts/coco_pombo.gd` e `scripts/pegada.gd`: cocô de pombo que cai do céu e as pegadas de quem pisa nele.
- `scripts/mapas.gd`: lista de mapas (paredes, água, pontes, onde cada um começa, onde caem os upgrades).
- `scripts/cenario.gd`: desenho do mapa (chão, cerca viva, blocos de pedra, água, pontes, enfeites).
- `scripts/agua.gd`: brilhinhos que piscam na água.
- `scripts/efeito_afundar.gd`: camaleão afundando com splash quando cai na água.
- `scripts/placar.gd`: placar no topo da tela.
- `scripts/efeito_morte.gd`: "puf" quando um camaleão morre.
- `scripts/linguas.gd`: língua básica e poderes, seus números e o desenho da língua.
- `scripts/lingua_no_chao.gd`: bolha de poder que pode ser pega do chão.
- `scripts/grude.gd`: bola de grude que o poder "grude" deixa no chão.
- `scripts/casca.gd`: pele velha que o poder "muda de pele" deixa para trás.
- `scripts/efeito_texto.gd`: nome do poder subindo em cima de quem pegou.
- `scripts/efeito_golpe.gd`: risco visual do golpe curto.
- `scripts/controles.gd`: teclas e botões de cada controle (autoload).
- `arte/referencia_camaleao.jpg`: desenho de referência do camaleão.

A arte ainda é toda desenhada por código com `_draw()`. Quando houver um PNG do camaleão, dá para trocar o desenho de `desenho_camaleao.gd` por um sprite.
