FUNCTION restoreframe, FRAME = inputFrame

;+
; Name:
;       restoreframe
; Purpose:
;       Restore frame data from IDL save variables
; Calling sequence:
;       frame = restoreframe(frame)
; Input:
;       None
; Output:
;       output  :   named structure restoreframeOutput
; Keywords:
;       FRAME   :   frame number
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2		                                

;Check input type
IF KEYWORD_SET(inputFrame) THEN BEGIN
    isString = STRCMP(SIZE(inputFrame,/TNAME),'STRING')
    IF NOT isString THEN BEGIN
        MESSAGE, 'Frame number is not of type STRING!'
    ENDIF
ENDIF ELSE BEGIN
    MESSAGE, 'Provide frame number string!'
ENDELSE

;Trim string
trimmedFrame = inputFrame.TRIM()

;List all files with matching frame number and save list 
IF sysvarexists('!FRAMEDIR') THEN BEGIN
    SPAWN, 'ls ' + !FRAMEDIR  + '*' + trimmedFrame + '*', savedFile
ENDIF 

;If more than one file found, stop
foundFiles = SIZE(savedFile, /N_ELEMENTS)
IF foundFiles GT 1 THEN BEGIN
    MESSAGE, 'Found more than one file with frame number ' + trimmedFrame
ENDIF

;Restore variables
RESTORE, savedFile

;Normalize flux using median (useful for test flats)
normFlux = FLTARR(512,16)
FOR i = 0, 15 DO BEGIN
    medianValue = MEDIAN(frame1[*,i])
    normFlux[*,i] = frame1[*,i] / medianValue 
ENDFOR

;Create output structure
output = {restoreframeOutput, $
    flux    :   frame1, $
    wave    :   wavelengths, $
    name    :   object_name, $
    date    :   object_date, $
    frame   :   inputFrame, $
    normflux    :   normFlux}

RETURN, output

END 
