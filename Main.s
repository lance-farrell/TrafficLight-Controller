
        AREA    DATA, READWRITE, ALIGN=2
Pedestrian_Flag SPACE 1         ;space for input
        ALIGN
Time_Counter    SPACE 4         ; Countdown timer
        ALIGN


        AREA    |.text|, CODE, READONLY
        THUMB
        
        ; External Driver Imports
        IMPORT  PORTB_Init      ; SSD Pins
        IMPORT  PORTF_Init      ; LEDs and Pedestrian Button
        IMPORT  SysTick_Init    ; 1-Second Heartbeat
        IMPORT  PORTF_Output    ; Write to PF1-PF3
        IMPORT  PORTB_Output    ; Write to PB0-PB7
        
        EXPORT  Start
        EXPORT  GPIOPortF_Handler 
        EXPORT  SysTick_Handler  


SSD_Table
    DCB 0x77 ; 0
    DCB 0x14 ; 1
    DCB 0xB3 ; 2
    DCB 0xB6 ; 3
    DCB 0xD4 ; 4
    DCB 0xE6 ; 5
    DCB 0xE7 ; 6
    DCB 0x34 ; 7
    DCB 0xF7 ; 8
    DCB 0xF6 ; 9
    ALIGN

Start
        BL  PORTB_Init          
        BL  PORTF_Init          
        
        LDR R0, =16000000
        BL  SysTick_Init        
        
        CPSIE  I                
        
        B   State_Green

SysTick_Handler
        LDR R0, =Time_Counter
        LDR R1, [R0]
        CMP R1, #0
        BEQ Skip_Dec           
        SUB R1, #1
        STR R1, [R0]
		
		BX LR
		
GPIOPortF_Handler
        LDR R0, =Pedestrian_Flag
        MOV R1, #1
        STR R1, [R0]
        LDR R0, =0x4002541C     ; GPIO_PORTF_ICR_R
        MOV R1, #0x10           ; Target pin PF4
        STR R1, [R0]
        BX  LR

		

; ===== FSM =====
State_Green
        MOV R0, #0x08
        BL  PORTF_Output
        ; Set 30 second timer
        LDR R0, =Time_Counter
        MOV R1, #30
        STR R1, [R0]
        B   Green_Poll

Green_Poll
        LDR R0, =Pedestrian_Flag
        LDR R1, [R0]
        CMP R1, #1
        BEQ Bridge_Pedestrian  

        LDR R0, =Time_Counter
        LDR R1, [R0]
        CMP R1, #0
        BEQ State_Normal_Yellow ; Natural exit to Normal Yellow
        
        B   Green_Poll


State_Normal_Yellow
        MOV R0, #0x04
        BL  PORTF_Output
        LDR R0, =Time_Counter
        MOV R1, #10
        STR R1, [R0]
        B   Normal_Yellow_Poll

Normal_Yellow_Poll
        LDR R0, =Time_Counter
        LDR R1, [R0]
        CMP R1, #0
        BEQ State_Red
        B   Normal_Yellow_Poll


Bridge_Pedestrian
        LDR R0, =Pedestrian_Flag
        MOV R1, #0
        STR R1, [R0]
        B   State_Ped_Yellow

State_Ped_Yellow
        LDR R0, =Time_Counter
        MOV R1, #10
        STR R1, [R0]
        B   Ped_Yellow_Poll

Ped_Yellow_Poll
        LDR R0, =Time_Counter
        LDR R4, [R0]
        LDR R2, =SSD_Table
        LDRB R0, [R2, R4]
        BL  PORTB_Output

        ; FLASHING LOGIC
        AND R1, R4, #0x01
        CMP R1, #0
        BEQ Yellow_On           ; If Even, Turn ON
        MOV R0, #0x00           ; If Odd, Turn OFF
        B   Apply_Flash
Yellow_On
        MOV R0, #0x04           ; PF2 = 1
Apply_Flash
        BL  PORTF_Output
        CMP R4, #0
        BEQ State_Red
        B   Ped_Yellow_Poll

State_Red
        MOV R0, #0x02
        BL  PORTF_Output
        LDR R0, =Time_Counter
        MOV R1, #10
        STR R1, [R0]
        B   Red_Poll

Red_Poll
        LDR R0, =Time_Counter
        LDR R1, [R0]
        CMP R1, #0
        BEQ State_Green        
        B   Red_Poll



Skip_Dec
        BX  LR


        ALIGN
        END

