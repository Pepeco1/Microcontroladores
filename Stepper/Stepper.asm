#include <SFR51.inc>
cseg at 0

location EQU 2000h ; ponto de montagem

ljmp  startup

;-------------------------------------------------
ORG location; endereco inicial de montagem
;-------------------------------------------------

;Cabçalho do Paulmon2 ---------------------------

DB  A5h,E5h,e0h,A5h    ;signiture bytes
DB  35,255,0,0             ;id (35=prog, 253=startup, 254=command)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuario
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "Steppers",0               ;maximo 31 caracteres  mais o zero

ORG location+40            ;código executavel começa aqui


;port_b        EQU 4001h
;port_c        EQU 4002h
;port_abc_pgm  EQU 4003h
;cout          EQU 0030h ;imprime o acumulador na serial
;cin           EQU 0032h ;captura para o acumulador o que vem da serial
;esc           EQU 003Eh ;Checagem da tecla ESC do paulmon2
cont1         EQU 7Fh
cont2         EQU 7Eh
cont3         EQU 7Dh
port_1        EQU 90h

startup:
    ;mov  dptr, #port_abc_pgm     
    ;mov  a, #128                 ;128 = a: out, b:out, c:out
    ;movx @dptr, a

begin:
    setb TI                  ;SIMULAÇÃO LIGADA
    mov dptr, #tabela        ;dptr->tabela

loop:
    clr   a                  ;a<-0
    movc  a, @a+dptr         ;a<- o que dptr aponta
    acall update             ;atualiza os leds
    inc   dptr               ;incrementa dptr

    clr   a                  ;a<-0
    movc  a, @a+dptr         ;a<- o que dptr aponta
    jz    begin              ;volta para begin se a for 0(fim da tabela)
    acall delay              ;gasta ciclos de máquina
    inc   dptr               ;incrementa o dptr

    ;lcall esc                ;verifica de esc foi apertado
    ;jc    exit               ;se foi, sai
    sjmp  loop

exit:
    ret

update:
    ;push dph                ;guarda dptr
    ;push dp1

    ;mov  dptr, #port_1      ;dptr->port_1
    ;movx @dptr, a           ;manda 'a' para onde dptr esta apontando

    mov port_1, a
    ;pop dp1                 ;pega dptr de volta
    ;pop dph                 

    ret

delay:
    mov cont1, a           ;cont1 recebe o valor de 'a'(atualmente uma constante)
delay2:
    mov cont2, #100         ;cont2 recebe a constante 100
delay3:
    mov cont3, #255        ;cont3 recebe a constante 255
delay4:
    nop                  ;gasta ciclos de máquina
    nop
    nop
    nop
    nop
    nop
    djnz cont3, delay4
    djnz cont2, delay3      ;repete cont1*cont2 vezes
    djnz cont1, delay2

    ret

tabela:; gera agrupamentos de 8 bits

  DB 11111110b, 100
  DB 11111101b, 50
  DB 11111011b, 50
  DB 11110111b, 100
  DB 255,0
  
END