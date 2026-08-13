		INCLUDE tm4c123gh6pm_constants.s
        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT   SysTick_Init

SysTick_Init
    ; disable SysTick during setup
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R (pointer)
    MOV R2, #0
    STR R2, [R1]                    ; disable SysTick
    ; Init reload reg
    LDR R1, =NVIC_ST_RELOAD_R       ; R1 = &NVIC_ST_RELOAD_R (pointer)
    SUB R0, R0, #1                  ; counts down from RELOAD to 0
    STR R0, [R1]                    ; establish interrupt period
    ; any write to current clears it
    LDR R1, =NVIC_ST_CURRENT_R      ; R1 = &NVIC_ST_CURRENT_R (pointer)
    STR R2, [R1]                    ; writing to counter clears it
    ; set NVIC system interrupt 15 to priority 2
    LDR R1, =NVIC_SYS_PRI3_R        ; R1 = &NVIC_SYS_PRI3_R (pointer)
    LDR R2, [R1]                    ; friendly access
    AND R2, R2, #0x00FFFFFF         ; R2 = R2&0x00FFFFFF (clear interrupt 15 priority)
    ORR R2, R2, #0x40000000         ; R2 = R2|0x40000000 (interrupt 15 priority is in bits 31-29)
    STR R2, [R1]                    ; set SysTick to priority 2
    ; enable SysTick with core clock
    LDR R1, =NVIC_ST_CTRL_R         ; R1 = &NVIC_ST_CTRL_R
    ; ENABLE SysTick (bit 0), INTEN enable interrupts (bit 1), and CLK_SRC (bit 2) is internal
    MOV R2, #7
    STR R2, [R1]                    ; store a 7 to NVIC_ST_CTRL_R
    ; end critical section
    BX  LR                          ; return

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file


