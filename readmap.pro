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

;Specify paths
mapExtension = '.ordmap'
fitsExtension = '.ordproffits'
IF sysvarexists('!FLATDIR') THEN BEGIN
    mapPath = !FLATDIR + inputFrame + mapExtension
    fitsPath = !FLATDIR + inputFrame + fitsExtension
ENDIF

;Initialize map matrix and fits matrix
numOrds = 16
orderWidth = 9
mapData = FLTARR(512,numOrds)
fitsData = FLTARR(orderWidth, 6, numOrds)

;Read and store map
OPENR, logicalUnitNumber, mapPath, /GET_LUN
READU, logicalUnitNumber, mapData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;Rasterize map
rasterMap = ROUND(mapData)

;Read and store fits
OPENR, logicalUnitNumber, fitsPath, /GET_LUN
READU, logicalUnitNumber, fitsData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;Output
output = {readmapOutput, $
    flt :   mapData, $
    ras :   rasterMap, $
    fits:   fitsData, $
    frame   :   inputFrame}

RETURN, output

END
