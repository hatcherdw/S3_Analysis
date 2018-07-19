FUNCTION readmap, FRAME = inputFrame

;+
; Name:
;       readmap
; Purpose:
;       Read order map files saved in binary format
; Calling sequence:
;       map = readmap(FRAME=frame)
; Input:
;       None
; Output:
;       output  : structure
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
    MESSAGE, 'Calling sequence is map = readmap(FRAME=<frame>)'
ENDELSE

;Specify path
extension = '.ordmap'
IF sysvarexists('!FLATDIR') THEN BEGIN
    path = !FLATDIR + inputFrame + extension
ENDIF

;Initialize map matrix
mapData = FLTARR(512,16)

;Read and store map
OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, mapData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;Rasterize map
rmap = ROUND(mapData)

;Output
output = {readmapOutput, $
    flt :   mapData, $
    ras :   rmap, $
    frame   :   inputFrame}

RETURN, output

END
