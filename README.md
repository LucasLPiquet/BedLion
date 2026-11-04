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

## Menu, lobby e bots

- **Menu inicial**: Jogar, Configurações e Sair (mouse, setas + Enter ou direcional + A).
- **Configurações**: volume e tela cheia, salvos sozinhos em `user://configuracoes.cfg`. Ainda não há sons; o volume já fica guardado.
- **Lobby** (depois de Jogar):
  1. Cada jogador aperta o **golpe** no próprio teclado ou controle (F, . ou A) para entrar numa vaga. Com os **lados** troca a cor do camaleão (8 cores, cada um com uma diferente), com o **golpe** de novo fica pronto e com o **invisível** desfaz ou sai. Quando todo mundo que entrou está pronto (ou alguém clica em Continuar), vai para a escolha dos bots.
  2. **Bots**: quantos completam a partida (até 4 camaleões; jogando sozinho precisa de pelo menos 1) e a dificuldade: **fácil, médio ou difícil**. Cima/baixo escolhe a linha, os lados mudam, golpe começa e invisível volta. Também dá para clicar.
  - **Esc** volta para o menu (no lobby e no meio da partida).
- **Bots** (`scripts/bot.gd`): jogam com os mesmos botões de um jogador (andar, golpe, língua, segurar o invisível), então seguem as mesmas regras: miram andando para o lado, precisam segurar 1 s para sumir, não usam a língua invisíveis, largam o poder ao sumir. Também não trapaceiam: só sabem onde está um invisível pelas pistas que aparecem na tela (sombra no sol, capim mexendo, ondinha na poça ou na ponte, pegadas de pé sujo, o vulto do poder olho) ou porque viram ele sumir ali, e jogam a língua ou golpeiam onde acham que ele está. A dificuldade muda (números em `NIVEIS`, no topo de `bot.gd`):
  - **tempo de reação** (fácil 0,55 s, médio 0,32 s, difícil 0,16 s): de quanto em quanto tempo pensam, quanto demoram para golpear e para se soltar de uma língua;
  - **precisão**: quanto a língua sai torta e se adiantam a mira para onde o alvo está indo;
  - **agressividade**: ir para cima ou ficar longe esperando;
  - **uso de poderes**: buscar bolhas e usar cada poder direito (gancho para fugir ou chegar, muda de pele quando está em perigo);
  - **uso da invisibilidade**: com que frequência somem para caçar no corpo a corpo, e se evitam sol, capim e poças quando estão invisíveis;
  - **detecção de invisível**: chance de notar cada pista (e de não cair na pele velha da muda), e por quanto tempo lembram onde viram um invisível;
  - **esquiva**: chance de sair da frente de uma língua vindo neles.

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
  - **Puxar com a língua**: a língua também pega bolhas de poder no chão de longe (inclusive a que um invisível acabou de largar) e traz até a sua boca. Se você está com a língua básica, já pega na hora; se já tem um poder, o que veio cai aos seus pés.
    - A língua volta com a bolha um pouco mais devagar (`VELOCIDADE_TRAZER_ITEM` em `scripts/camaleao.gd`). Enquanto ela está na língua, ninguém pega passando por cima.
    - Se alguém passar por cima da língua, ela é cortada e a bolha cai ali. Se você soltar a língua (ou for pego, ou morrer) no meio do caminho, ela também cai onde estava; em cima da água, afunda e some.
    - Se a ponta encostar num camaleão e numa bolha no mesmo instante, ela fica com o que estiver mais perto.
  - **Laranja (gancho)**: a língua vira um grappling. Se ela bater numa parede, gruda lá e puxa **você** até a parede, voando por cima de tudo, até da água. Durante o voo, o direcional balança você para os lados (dá para fazer curva). Apertar a língua no meio do voo solta e você sai **arremessado** com o embalo, que vai freando; dá para emendar outro gancho antes de cair. Se o embalo acabar em cima da água, você afunda. A língua também vai mais longe (480 px).
  - **Verde (grude)**: quando a língua erra (bate na parede ou chega no fim sem pegar ninguém), deixa um **rastro de grude** por todo o caminho que ela fez (menos em cima da água). Quem pisar, **mesmo invisível**, fica preso 1,2 s e aparece; só o pedaço pisado some, o resto do rastro continua. Preso não anda nem usa a língua, mas ainda golpeia, e logo depois de se soltar tem um instante para sair sem grudar de novo. Quem soltou não gruda; cada um pode ter 2 rastros no chão (o mais antigo some) e eles duram 10 s.
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
  - **Capinzal**: dois campos grandes de capim alto com uma faixa de sol no meio.
  - **Água**: quem pisar na água afunda e morre (também se for puxado pela língua para dentro dela). A língua passa por cima da água. Pontes são seguras. Upgrades e cocô de pombo nunca caem na água nem nas paredes.
  - **Pistas de quem está invisível**: o mapa entrega quem passa, visível ou não. Ficar parado fora dessas áreas continua seguro.
    - **Capim alto** (`grama` em `mapas.gd`): esconde metade de quem está dentro (só a cabeça aparece). Quem passa deita as folhas, que ficam mais claras e demoram uns 1,5 s para voltar, deixando um rastro (`scripts/grama_alta.gd`).
    - **Poças** (`pocas`): rasas, não matam. Andando nelas saem ondinhas; parado, sai uma ondinha menor a cada 1,4 s; quem sai fica 2,5 s deixando pegadas molhadas (`scripts/pistas.gd`).
    - **Pontes**: andar nelas faz ondinhas na água do lado.
    - **Manchas de sol** (`luz`): dentro delas aparece a sombra de quem está invisível (`scripts/luz.gd`).
  - Para criar um mapa novo, copie um dos blocos de `scripts/mapas.gd` e mude o nome e as posições. As explicações de cada campo estão no topo do arquivo.
  - Intervalo, limite e pontos ficam no topo de `scripts/main.gd`.

O jogo suporta até 4 participantes simultâneos via teclado e controles externos:

- `scenes/menu.tscn`, `scenes/lobby.tscn`, `scenes/configuracoes.tscn`: menu inicial (a primeira cena), lobby e configurações (`scripts/menu.gd`, `scripts/lobby.gd`, `scripts/configuracoes.gd`; peças visuais em `scripts/ui.gd`).
- `scenes/main.tscn`: a arena (montada por código). Aberta direto (F6 no editor), entram os teclados e controles conectados, e F1 liga bots de teste.
- `scripts/partida.gd`: quem joga (vem do lobby), cores, dificuldades e configurações (autoload `Partida`).
- `scripts/main.gd`: arena, rodadas e placar.
- `scripts/camaleao.gd`: movimento, língua, invisibilidade e golpe (de jogadores e bots).
- `scripts/bot.gd`: o que os bots pensam e quais botões apertam, por dificuldade.
- `scripts/desenho_camaleao.gd`: desenho do camaleão (feito com formas, sem imagem).
- `scripts/coco_pombo.gd` e `scripts/pegada.gd`: cocô de pombo que cai do céu e as pegadas de quem pisa nele (ou sai de uma poça).
- `scripts/mapas.gd`: lista de mapas (paredes, água, pontes, onde cada um começa, onde caem os upgrades).
- `scripts/cenario.gd`: desenho do mapa (chão, cerca viva, blocos de pedra, água, pontes, enfeites).
- `scripts/agua.gd`: brilhinhos que piscam na água.
- `scripts/grama_alta.gd`: capim alto que se mexe quando alguém passa.
- `scripts/luz.gd`: manchas de sol e a sombra de quem está invisível dentro delas.
- `scripts/pistas.gd` e `scripts/ondulacao.gd`: ondinhas em poças e pontes, e pegadas molhadas.
- `scripts/efeito_afundar.gd`: camaleão afundando com splash quando cai na água.
- `scripts/placar.gd`: placar no topo da tela.
- `scripts/efeito_morte.gd`: "puf" quando um camaleão morre.
- `scripts/linguas.gd`: língua básica e poderes, seus números e o desenho da língua.
- `scripts/lingua_no_chao.gd`: bolha de poder que pode ser pega do chão.
- `scripts/grude.gd`: rastro de grude que o poder "grude" deixa no chão.
- `scripts/casca.gd`: pele velha que o poder "muda de pele" deixa para trás.
- `scripts/efeito_texto.gd`: nome do poder subindo em cima de quem pegou.
- `scripts/efeito_golpe.gd`: risco visual do golpe curto.
- `scripts/controles.gd`: teclas e botões de cada controle (autoload).
- `arte/referencia_camaleao.jpg`: desenho de referência do camaleão.

### Atalhos
- **Esc:** Volta para o menu.
- **F1:** Só abrindo a arena direto (sem lobby): alterna os bots de teste (sem, parados, fáceis, médios, difíceis).
- **F2:** Reinicia a rodada no próximo mapa.
