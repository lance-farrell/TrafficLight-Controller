	AREA DATA, READWRITE
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_PORTF_AMSEL_R EQU 0x40025528
GPIO_PORTF_PCTL_R  EQU 0x4002552C
GPIO_PORTF_PDR_R   EQU 0x40025514
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
	
GPIO_PORTF_IS_R    EQU 0x40025404  ; Interrupt Sense (0=edge, 1=level)
GPIO_PORTF_IBE_R   EQU 0x40025408  ; Interrupt Both Edges (0=single, 1=both)
GPIO_PORTF_IEV_R   EQU 0x4002540C  ; Interrupt Event (0=falling/low, 1=rising/high)
GPIO_PORTF_IM_R    EQU 0x40025410  ; Interrupt Mask (0=masked, 1=sent to NVIC)
GPIO_PORTF_ICR_R   EQU 0x4002541C  ; Interrupt Clear (Write 1 to clear flag)


NVIC_EN0_R         EQU 0xE000E100  ; Enable Interrupts 0-31 (Port F is #30)

        AREA    |.text|, CODE, READONLY
        THUMB
        EXPORT  PORTF_Init
		EXPORT	PORTF_Output

;------------PORTF_Init------------
PORTF_Init
    LDR R1, =SYSCTL_RCGCGPIO_R      ; 1) activate clock for Port B
    LDR R0, [R1]                 
    ORR R0, R0, #0x20               ; set bit1 to turn on clock
    STR R0, [R1]                  
    NOP
    NOP                             ; allow time for clock to finish
    LDR R1, =GPIO_PORTF_LOCK_R      ; 2) unlock the lock register
    LDR R0, =0x4C4F434B             ; unlock GPIO Port B Commit Register
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_CR_R        ; enable commit for Port B
    MOV R0, #0xFF                   ; 1 means allow access
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AMSEL_R     ; 3) disable analog functionality
    MOV R0, #0                      ; 0 means analog is off
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_PCTL_R      ; 4) configure as GPIO
    MOV R0, #0x00000000             ; 0 means configure Port B as GPIO
    STR R0, [R1]                  
    LDR R1, =GPIO_PORTF_DIR_R       ; 5) set direction register
    MOV R0,#0x0E                    ; SET PB1, PB2 and PB# as outputs, the rest as inputs
    STR R0, [R1]                    
    LDR R1, =GPIO_PORTF_AFSEL_R     ; 6) regular Port Bunction
    MOV R0, #0                      ; 0 means disable alternate function 
    STR R0, [R1]                    
	LDR R1, =GPIO_PORTF_PDR_R     ; 
    MOV R0, #0x10                    
    STR R0, [R1]  
    LDR R1, =GPIO_PORTF_DEN_R       ; 7) enable Port B digital port
    MOV R0, #0xFF                   ; 1 means enable digital I/O
    STR R0, [R1]   
;; Interrupt configuration    
    ; a) Edge-sensitive (not level-sensitive)
    LDR R1, =GPIO_PORTF_IS_R
    MOV R0, #0                      ; 0 = edge sensitive
    STR R0, [R1]
    ; b) Not both edges (we only want one specific edge)
    LDR R1, =GPIO_PORTF_IBE_R
    MOV R0, #0                      ; 0 = not both edges
    STR R0, [R1]
    ; c) Select Rising Edge
    LDR R1, =GPIO_PORTF_IEV_R
    MOV R0, #0x10              ; We need to set PF4 to rising edge (1)
    STR R0, [R1]
    ; d) Clear any prior pending interrupts
    LDR R1, =GPIO_PORTF_ICR_R
    MOV R0, #0x10                   ; Clear flag for PF4
    STR R0, [R1]
    ; e) Unmask (Enable) the interrupt for PF4
    LDR R1, =GPIO_PORTF_IM_R
    MOV R0, #0x10                   ; 1 = enable interrupt for PF4
    STR R0, [R1]
    ; f) Enable Port F Interrupts in the NVIC (Interrupt #30)
    LDR R1, =NVIC_EN0_R
    LDR R0, =0x40000000             ; Bit 30 = 1
    STR R0, [R1]

    BX  LR      

;------------PORTF_Output------------
PORTF_Output
    LDR R1, =GPIO_PORTF_DATA_R ; pointer to Port B data
    STR R0, [R1]               
    BX  LR                    

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file


