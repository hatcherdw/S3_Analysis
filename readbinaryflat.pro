FUNCTION readbinaryflat, FRAME = inputFrame, flatData

;+
; Name:
;       readbinaryflat
; Purpose:
;       Read flat files saved in binary format
; Calling sequence:
;       flat = readbinaryflat(FRAME=frame)
; Input:
;       None
; Output:
;       flatData    :   512x16 float array
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
    CASE isString OF
        1 : frame = inputFrame
        0 : MESSAGE, 'Input is not of type STRING!'
    ENDCASE
ENDIF ELSE BEGIN
    MESSAGE, 'Calling sequence is flat = readbinaryflat(FRAME=<frame>)'
ENDELSE

;Check if old or new CCD 
IF LONG(frame) GE 22684 THEN BEGIN
    ;NEW CCD
    flatData = FLTARR(512,16)
ENDIF ELSE BEGIN
    ;OLD CCD
    flatData = UINTARR(512,16)
ENDELSE

extension = '.RAW.spec'
IF sysvarexists('!FLATDIR') THEN BEGIN  
    path = !FLATDIR + frame + extension
ENDIF

OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

RETURN, flatData

END 
