FUNCTION readflat, FRAME = inputFrame 

;+
; Name:
;       readflat
; Purpose:
;       Read flat files saved in binary format
; Calling sequence:
;       flat = readflat(FRAME=frame)
; Input:
;       None
; Output:
;       output  :   structure 
; Keywords:
;       FRAME   :   frame number   
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                    

;Check input existence and type
IF KEYWORD_SET(inputFrame) THEN BEGIN
    type = SIZE(inputFrame,/TNAME)
    isString = STRCMP(type,'STRING')
    IF NOT isString THEN BEGIN 
        MESSAGE, 'Input is not of type STRING!'
    ENDIF
ENDIF ELSE BEGIN
    MESSAGE, 'Calling sequence is flat = readbinaryflat(FRAME=<frame>)'
ENDELSE

;Specify path
extension = '.RAW.spec'
IF sysvarexists('!FLATDIR') THEN BEGIN  
    path = !FLATDIR + inputFrame + extension
ENDIF

;Check if old or new CCD 
IF LONG(inputFrame) GE 22684 THEN BEGIN
    ;NEW CCD
    flatData = FLTARR(512,16)
ENDIF ELSE BEGIN
    ;OLD CCD
    flatData = UINTARR(512,16)
    PRINT, 'Frame number indicates old CCD.'
ENDELSE

;Read flat flux data
OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;Output
output = {readflatOutput, $
    flux    :   flatData, $
    frame   :   inputFrame}

RETURN, output

END 
