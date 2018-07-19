FUNCTION restoregrafted, FRAME = inputFrame, MAP = inputMap

;Name:
;       restoregrafted
; Purpose:
;       restore grafted test flats and Flats
; Calling sequence:
;       grafted = restoregrafted(FRAME=frame)
; Input:
;       None
; Output:
;       output    :   structure       
; Keywords:
;       FRAME   :   frame number string
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2

;Check input type
IF STRCMP(SIZE(inputFrame,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Frame number is not of type STRING!'
ENDIF

;Trim string
trimmedFrame = inputFrame.TRIM()

;List all files with matching frame number and save list
IF sysvarexists('!GRAFTEDDIR') THEN BEGIN
    SPAWN, 'ls ' + !GRAFTEDDIR  + '*' + trimmedFrame + '*', savedFile
ENDIF

;Restore 
RESTORE, savedFile

bit16 = grafted_data
bit8 = BYTSCL(grafted_data)

;If provided, overlay order map onto graft
IF KEYWORD_SET(inputMap) THEN BEGIN
    rasterizedMap = ROUND(inputMap)
    mapOverlay = bit8
    FOR i = 0, 511 DO BEGIN
        FOR j = 0, 15 DO BEGIN
            pixelOn = rasterizedMap[i,j]
            mapOverlay[i,pixelOn] = 255
        ENDFOR  
    ENDFOR
    ;Create anonymous otuput structure
    output = {$
        bit16   :   bit16, $
        bit8    :   bit8, $
        overlay :   mapOverlay}
ENDIF ELSE BEGIN
    ;Create anonymous otuput structure
    output = {$
        bit16   :   bit16, $
        bit8    :   bit8}
ENDELSE

RETURN, output

END
