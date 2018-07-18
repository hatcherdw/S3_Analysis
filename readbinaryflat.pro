FUNCTION rasterizemap, inputMap
;Utility module to rasterize order map and place on grafted frame

COMPILE_OPT IDL2

;Rasterize
rasterizedMap = ROUND(inputMap)

;Initialize output matrix to size of 2d grafted frame
graftedMap = LONARR(512,400)

;Turn on pixels to make grafted map
FOR i = 0, 511 DO BEGIN
    FOR j = 0, 15 DO BEGIN
        pixelOn = rasterizedMap[i,j]
        graftedMap[i,pixelOn] = 255
    ENDFOR
ENDFOR

RETURN, graftedMap

END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION readbinaryflat, FRAME = inputFrame 
;Command module

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
;       output    : structure 
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

;Specify paths
extension = '.RAW.spec'
mapExtension = '.ordmap'
IF sysvarexists('!FLATDIR') THEN BEGIN  
    path = !FLATDIR + frame + extension
    map = !FLATDIR + frame + mapExtension 
ENDIF

;Check if old or new CCD 
IF LONG(frame) GE 22684 THEN BEGIN
    ;NEW CCD
    flatData = FLTARR(512,16)
ENDIF ELSE BEGIN
    ;OLD CCD
    flatData = UINTARR(512,16)
ENDELSE

;Read flat flux data
OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;Initialize order map matrix
mapData = FLTARR(512,16)

;Read order map
OPENR, logicalUnitNumber, map, /GET_LUN
READU, logicalUnitNumber, mapData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

rMap = rasterizemap(mapData)

output = {readbinaryflatOutput, $
    flux    :   flatData, $
    map     :   mapData, $
    rmap    :   rMap} 

RETURN, output

END 
