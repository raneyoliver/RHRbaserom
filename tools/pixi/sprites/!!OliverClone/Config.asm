;===============================================================
; RAM Configuration
;===============================================================
; To use this sprite package in your hack:
; 1. Set !BaseRAM to your desired free RAM start address
; 2. All RAM addresses will be automatically allocated from there
;===============================================================

!BaseRAM = $41A000           ; Default start address - change if needed

; Allocate RAM addresses sequentially
!State              = !BaseRAM+$00   ; Teleport state
!Spinning           = !BaseRAM+$01   ; Spinning state
!CloneSpeedX        = !BaseRAM+$02   ; X speed backup
!CloneSpeedY        = !BaseRAM+$03   ; Y speed backup
!TeleportReady      = !BaseRAM+$04   ; Can teleport flag
!JumpHeld           = !BaseRAM+$05   ; Jump button status
!TempSpinning       = !BaseRAM+$06   ; Temporary spin flag
!SpinDirection      = !BaseRAM+$07   ; Current spin direction
!StareTimer         = !BaseRAM+$08   ; Stare animation timer
!Frozen             = !BaseRAM+$09   ; Freeze state
!BouncingSpeed      = !BaseRAM+$0A   ; Current bounce speed
!PlayerOnlyStomped  = !BaseRAM+$0B   ; Player stomp counter
!IsMario            = !BaseRAM+$0C   ; Mario/Luigi flag
!SpriteDirection    = !BaseRAM+$0D   ; Facing direction
!OnPlatform         = !BaseRAM+$0E   ; Platform status
!PreviousState      = !BaseRAM+$0F   ; Last frame's state
!PlayerPosXLow      = !BaseRAM+$10   ; Player X position low byte
!PlayerPosXHigh     = !BaseRAM+$11   ; Player X position high byte
!PlayerPosYLow      = !BaseRAM+$12   ; Player Y position low byte
!PlayerPosYHigh     = !BaseRAM+$13   ; Player Y position high byte
!PlayerSpeedX       = !BaseRAM+$14   ; Player X speed
!PlayerSpeedY       = !BaseRAM+$15   ; Player Y speed
!Frame              = !BaseRAM+$16   ; Current animation frame
!RunningLevel       = !BaseRAM+$17   ; Running level flag from Extra Byte 4

; Sprite freezing RAM - must be after all other variables
!StartRAM           = !BaseRAM+$100  ; Start of sprite freeze backup area 