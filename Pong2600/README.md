Pong2600
=====

Um clone do clássico jogo Pong para o Atari 2600 com múltiplos modos de jogo.

[Open this project in 8bitworkshop](http://8bitworkshop.com/redir.html?platform=vcs&githubURL=https%3A%2F%2Fgithub.com%2Fkamaleon70%2FPong2600&file=Pong2600.dasm).

## Modos de Jogo

O jogo possui **4 modos diferentes** que podem ser selecionados usando o switch **Game Select** do console:

### 🔵 Modo 0: Normal
- Modo padrão do jogo
- Velocidade normal da bola
- Paddles de tamanho padrão
- Cor do playfield: **Ciano**

### ⚡ Modo 1: Fast Ball
- A bola se move **2x mais rápido** que o normal
- Aumenta significativamente a dificuldade
- Cor do playfield: **Vermelho**

### 📏 Modo 2: Big Paddles
- Os paddles ficam com **largura dobrada**
- Mais fácil de defender, ideal para iniciantes
- Cor do playfield: **Roxo**

### 👻 Modo 3: Invisible Ball
- A bola **pisca e fica invisível** periodicamente
- Desafio de memória e reflexos
- Cor do playfield: **Branco**

## Controles

### Player 0 (Esquerda):
- **Joystick Cima/Baixo**: Move paddle verticalmente
- **Joystick Esquerda/Direita**: Move paddle horizontalmente

### Player 1 (Direita):
- **Joystick Cima/Baixo**: Move paddle verticalmente
- **Joystick Esquerda/Direita**: Move paddle horizontalmente

### Console:
- **Game Select**: Alterna entre os 4 modos de jogo (a cor do playfield muda)
- **Game Reset**: Reinicia o jogo

## Pontuação

- O primeiro jogador a marcar **32 pontos** vence
- Quando um jogador marca, o placar pisca
- Após a vitória, pressione **Game Reset** para jogar novamente

## Compilação

```bash
dasm Pong2600.asm -f3 -oPong2600.bin -lPong2600.lst -sPong2600.sym
```

## Executar

Use um emulador de Atari 2600 como **Stella** para executar o arquivo `Pong2600.bin`.
