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

;Normalize using median (useful for Flats and test flats)
normFlux = FLTARR(512,16)
FOR i = 0, 15 DO BEGIN
    medianValue = MEDIAN(flatData[*,i])
    normFlux[*,i] = flatData[*,i] / medianValue    
ENDFOR

;Smooth flux
smoothWidth = 10
smoothFlux = SMOOTH(flatData,smoothWidth,EDGE_TRUNCATE=1)

;Normalize smoothed flux
normSmoothFlux = FLTARR(512,16)
FOR i = 0, 15 DO BEGIN
    medianSmoothValue = MEDIAN(smoothFlux[*,i])
    normSmoothFlux[*,i] = smoothFlux[*,i] / medianSmoothValue    
ENDFOR

;Output
output = {readflatOutput, $
    flux    :   flatData, $
    normflux    :   normFlux, $
    smoothflux  :   smoothFlux, $
    normsmooth  :   normSmoothFlux, $
    smoothwidth :   smoothWidth, $
    frame   :   inputFrame}

RETURN, output

END 
