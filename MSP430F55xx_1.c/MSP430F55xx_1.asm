;******************************************************************************
; MSP430F55xx_1.asm — Teste GPIO para MSP430F5529LP
;
; CORREÇÕES aplicadas:
;   1. Exporta símbolo "main" (exigido pelo runtime C do CCStudio)
;   2. Remove seção .reset manual (o linker cmd já trata isso via rom_model)
;   3. Adiciona NOP após JMP final (corrige warning W5369 / errata CPU40)
;   4. Usa .global main em vez de _init como entry point
;
; Pinos:
;   LED1  → P1.0  (saída, ativo alto)
;   LED2  → P4.7  (saída, ativo alto)
;   S1    → P2.1  (entrada, pull-up, ativo baixo)
;   S2    → P1.1  (entrada, pull-up, ativo baixo)
;******************************************************************************

            .cdecls C,LIST,"msp430.h"

;------------------------------------------------------------------------------
; Constante de delay (~500 ms @ MCLK ~1 MHz padrão pós-reset)
;------------------------------------------------------------------------------
DELAY_COUNT .equ    50000

;------------------------------------------------------------------------------
; Exporta "main" para o runtime C encontrar o entry point
;------------------------------------------------------------------------------
            .global main

;------------------------------------------------------------------------------
; Segmento de código
;------------------------------------------------------------------------------
            .text
            .align  2

;==============================================================================
; main — inicialização (chamado pelo runtime C após o reset)
;==============================================================================
main:
            ; --- Para o Watchdog Timer ---
            MOV.W   #WDTPW|WDTHOLD, &WDTCTL

            ; --- LED1 (P1.0) como saída, apagado ---
            BIS.B   #BIT0, &P1DIR
            BIC.B   #BIT0, &P1OUT

            ; --- LED2 (P4.7) como saída, aceso (fase inversa) ---
            BIS.B   #BIT7, &P4DIR
            BIS.B   #BIT7, &P4OUT

            ; --- S1 (P2.1): entrada + pull-up ---
            BIC.B   #BIT1, &P2DIR
            BIS.B   #BIT1, &P2REN
            BIS.B   #BIT1, &P2OUT

            ; --- S2 (P1.1): entrada + pull-up ---
            BIC.B   #BIT1, &P1DIR
            BIS.B   #BIT1, &P1REN
            BIS.B   #BIT1, &P1OUT

;==============================================================================
; main_loop — polling de botões + pisca-pisca
;==============================================================================
main_loop:
            ; --- Testa S1 (P2.1, ativo baixo) ---
            BIT.B   #BIT1, &P2IN
            JNZ     check_s2
            ; S1 pressionado → LED1 ON, LED2 OFF
            BIS.B   #BIT0, &P1OUT
            BIC.B   #BIT7, &P4OUT
            NOP                         ; CPU40: NOP após jump no fim de seção
            JMP     main_loop
            NOP                         ; CPU40: NOP após JMP

check_s2:
            ; --- Testa S2 (P1.1, ativo baixo) ---
            BIT.B   #BIT1, &P1IN
            JNZ     do_blink
            ; S2 pressionado → LED2 ON, LED1 OFF
            BIC.B   #BIT0, &P1OUT
            BIS.B   #BIT7, &P4OUT
            NOP
            JMP     main_loop
            NOP

do_blink:
            ; --- Nenhum botão: toggle dos dois LEDs ---
            XOR.B   #BIT0, &P1OUT
            XOR.B   #BIT7, &P4OUT

            ; --- Delay por software ---
            MOV.W   #DELAY_COUNT, R15
delay_loop:
            DEC.W   R15
            JNZ     delay_loop

            NOP
            JMP     main_loop
            NOP                         ; CPU40: NOP obrigatório após JMP final

;==============================================================================
            .end