;+
; Name:
;       sysvarexists
; Purpose:
;       Checks if input string is a defined system variable
; Calling sequence:
;       output = sysvarexists(inputSysVar)
; Positional input:
;       inputSysVar :   string starting with !
; Output:
;       output  :   byte 
; Keywords:
;       None
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION sysvarexists, inputSysVar

COMPILE_OPT IDL2

;Checks existence, does not redefine 
DEFSYSV, inputSysVar, EXISTS=i
IF i EQ 1 THEN BEGIN
    output = 1B
ENDIF ELSE IF i EQ 0 THEN BEGIN
    output = 0B
    MESSAGE, 'System variable ' + inputSysVar + ' does not exist! Check' + $
        ' preferences and startup files.'
ENDIF

RETURN, output

END
