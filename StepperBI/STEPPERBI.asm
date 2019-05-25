; ------------- STEPPERBI.asm --------------
;30/04/2019
;acionamento bidirecional incremental de motor de passo
;granularidade 10, delay min 7, delta delay 24, delay max 247
; ----------------------------------------------------- 
#include <SFR51.inc>
CSEG   AT 0000h
ORG    0000h
  ljmp  2040h
ORG    2000h               ; endereco do codigo no 8051 s/ paulmon2
;cabe�alho:  todo programa deve ter um, para o PAULMON2 poder gerenciar
DB     A5h,E5h,E0h,A5h     ;signiture bytes
DB     35,255,0,0          ;id (35=prog)
DB     0,0,0,0             ;prompt code vector
DB     0,0,0,0             ;reserved
DB     0,0,0,0             ;reserved
DB     0,0,0,0             ;reserved
DB     0,0,0,0             ;user defined
DB     255,255,255,255     ;length and checksum (255=unused)
DB     "STEPPERBI",0         ;max 31 characters, plus the zero
ORG    2040h               ;executable code begins here
;----------------------------------------------------Paramos aqui
; constantes
; 82C55 memory locations P0->PA, PA, PC
port_b          EQU 4001h   ; 82C55 port B
port_c          EQU 4002h   ; 82C55 port C
port_1          EQU 90h
port_abc_pgm    EQU 4003h   ; registrador de programacao
;---------------nossas variaveis
dphc            EQU 7Fh     ; copia do dph
dplc            EQU 7Eh     ; copia do dpl
Passos          EQU 7Dh     ; numero de linhas da tabela
var0            EQU 7Ch     ;tempo de delay
var1            EQU 7Bh     ;vari�veis de delay
dir             EQU 7Ah     ;dire��o: "E","D" ou "P"
delay           EQU 79h     ;delay: variavel de temporiza��o
;---------------nossas constantes
delta           EQU 24      ;delta delay: granularidade do acionamento
delmin          EQU 7       ;delay m�nimo: velocidade m�xima
delmax          EQU 247     ;dela m�ximo: velocidade minima
 sjmp  startup ;salta as nossas subrotinas
;----------------rotinas trazidas do paulmon2
cout:
  setb  ti      ;simula serial livre	
  jnb	ti,cout ;aguarda a serial ser liberada
  clr	ti		;clr ti before the mov to sbuf!
  mov	sbuf,a  ;imprime o caractere
  ret
;----------------nossas subrotinas
cinn:	
  jnb	ri,sai  ;salta se a serial n�o estiver pronta
  clr	ri      ;libera serial
  mov	a,sbuf  ;le o caractere
sai:
  ret
pstri:	   ;imprime string0 imediato
  mov   dphc,dph
  mov   dplc,dpl  ;preserva dptr
  pop   dph
  pop   dpl       ;recupera endere�o da string
  push	acc       ;preserva o acumulador
pstr1:	
  clr	a         ;limpa o acumulador
  movc	a,@a+dptr ;pega um caractere da mensagem
  inc	dptr      ;avan�a para o pr�ximo caractere
  jz	pstr2     ;salta se j� foi o ultimo caractere
;  mov	c, acc.7
;  anl	a, #0x7F
  acall	cout      ;imprime o caractere
;  jc	pstr2
  sjmp	pstr1     ;vai imprimir o pr�ximo
pstr2:  
  pop	acc       ;recupera o acumulador
  push  dpl
  push  dph       ;empilha o endere�o de retorno
  mov   dpl,dplc
  mov   dph,dphc  ;recupera dptr
  ret
;---------------Programa principal
startup:
  acall pstri DB "STEPPERBI incremental: Aciona motor de passo (16/05/2019)",10,13,0
  acall pstri DB "Use as teclas E e D para incrementar o acionamento para a esquerda e a direita",10,13,0
  acall pstri DB "(ESC para encerrar)",10,13,0
;programa��o das portas A,B,C
  mov   dptr,#port_abc_pgm  ; dptr=port_abc_pgm
  mov   a,#128              ; acc=128 ; a, b e c saida
  movx  @dptr,a             ; *dptr=a
;inicializa��es
  mov   dir,#'P'            ;motor come�a parado  
begin:
  clr   a                   ;zera a resposta
  acall cinn                ;pega 1 caractere se houver
  jz    aciona              ;vai acionar se n�o h� novo comando
  anl   a,#11011111b        ;converte para maiusculo
  cjne  a,#'E',not_E        ;salta se n�o � um E
  acall cout                ;valida a entrada do usu�rio
  mov   b,a                 ;guarda uma c�pia da tecla
  cjne  a,dir,testaP        ;testa se tecla != de dire��o
subtrai:               ;delay <- delay - delta
  mov   a,delay             ;pega o delay atual 
  cjne  a,#(delta+delmin),t_1;Cy <- 1 se delay < 31: delay n�o � subtra�vel
t_1:
  jc    aciona              ;salta se j� estiver na velocidade m�xima
  subb  a,#delta             ;subtrai delta: novo delay
  mov   delay,a             ;guarda novo delay
  sjmp  aciona              ;vai acionar
testaP:
  mov   a,dir               ;pega direcao
  cjne  a,#'P',soma         ;salta se direcao e 'E' ou 'D'
  mov   delay,#delmax       ;comeca a se mover na direcao escolhida
  mov   dir,b               ;atualiza a direcao
  sjmp  aciona              ;vai acionar
soma:                  ;delay <- delay + delta
  mov   a,delay             ;pega o delay atual
;  cjne  a,#(delmax-delta+1),t2 ;Cy <- 1 se delay < 224: delay � som�vel 
  cjne  a,#224,t2           ;Cy <- 1 se delay < 224: delay � som�vel
t2:
  jnc   parada              ;velocidade menor que m�nima: parar
  add   a,#delta             ;soma delta: novo delay
  mov   delay,a             ;guarda novo delay
  ;mov   dir,b               ;guarda a nova(?) dire��o
  sjmp  aciona              ;vai acionar
parada:
  mov   dir,#'P'            ;motor parado
  sjmp  aciona              ;vai acionar
not_E:
  cjne  a,#'D',not_D        ;salta se n�o � um D
  acall cout                ;valida entrada do usu�rio  
  mov   b,a                 ;guarda uma c�pia da tecla
  cjne  a,dir,testaP        ;testa se tecla != de dire��o 
  sjmp  subtrai
not_D:
  cjne  a,#27,aciona         ;se tamb�m n�o � um ESC vai acionar
exit:
  clr   a                   ;configura��o que desliga as bobinas
  mov   dptr,#port_b        ; onde as bobinas do motor estao
  movx  @dptr,a             ; *dptr=acc; aciona os motores
  cpl   a                   ; inverte os bits
  mov   dptr,#port_c        ; onde os LEDs estao
  movx  @dptr,a             ; desliga os LEDs  
  acall pstri DB 10,13,"Execucao concluida",0
  ret                       ;retorna ao Paulmon2
aciona:
  mov   a,dir               ;pega a direcao
  cjne  a,#'E',not_tab_E    ;salta se n�o est� girando a esquerda
  mov   dptr,#table_esq     ;dptr -> table_esq
  sjmp  giro                ;vai percorrer
not_tab_E:
  cjne  a,#'D',not_tab_D    ;salta se n�o est� girando a direita
  mov   dptr,#table_dir     ;dptr -> table_dir
  sjmp  giro
not_tab_D:
  cjne  a,#'P',not_P        ;salta se n�o est� parado  
  ajmp  begin               ;motor esta parado, aguarda novo comando do usu�rio
not_P:
  acall pstri DB "Erro fatal! Velocidade inexistente",0
  sjmp  exit
giro:
  mov   Passos,#4          ; varLinhas=4
loop:
  clr   a                   ; acc=00h
  movc  a,@a+dptr           ; acc=tabela[0]
  push  dph                 ; guarda MSByte do dptr na pilha
  push  dpl                 ; guarda LSByte do dptr na pilha
  mov   dptr,#port_b        ; onde as bobinas do motor estao
  movx  @dptr,a             ; *dptr=acc; aciona os motores
  cpl   a                   ; inverte os bits
  mov port_1,a
  mov   dptr,#port_c        ; onde os LEDs estao
  movx  @dptr,a             ; liga os LEDs    
  pop   dpl                 ; resgata o LSByte do dptr
  pop   dph                 ; resgata o MSByte do dptr
  mov   var0,delay          ; inicializa a variavel de temporizacao
dly2:
  mov   var1,#250           ; var1=50  (constante de delay)
dly3:
  nop                       ; no operation
  nop nop nop nop nop
  nop nop nop nop nop
  nop nop nop nop nop
  
  nop nop nop nop nop
  nop nop nop nop nop
  nop nop nop nop nop
  nop nop nop nop nop
  nop nop nop nop nop
  nop nop nop nop nop
  djnz  var1,dly3           ; --var1 e pula se nao zero
  djnz  var0,dly2           ; --var0 e pula se nao zero
  inc   dptr                ; dptr++
  djnz  Passos,loop        ;reposiciona no inicio da tabela
  ajmp  begin                ; GOTO loop
table_esq:
DB 00000001b
DB 00000010b
DB 00000100b
DB 00001000b

table_dir:
DB 00001000b
DB 00000100b
DB 00000010b
DB 00000001b


END
