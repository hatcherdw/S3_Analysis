; Name:
;       preprocess
; Purpose:
;       Preliminary reduction and normalization 
; Calling sequence:
;       result = preprocess,'inputFrame',ORDER=integer,NOD=integer
; Positional parameters:
;       inputFrame   :   frame number as string 
; Output:
;       
; Keyword parameters:
;       ORDER   :   echelle order to be reduced
;       NOD     :   order to nod to for prenormalization 
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION preprocess, inputFrame, ORDER=inputOrder, NOD=inputNod

COMPILE_OPT IDL2

IF NOT KEYWORD_SET(inputOrder) THEN BEGIN
    order = 10
    PRINT, 'Using default order 11!'
ENDIF ELSE BEGIN
    order = inputOrder
ENDELSE

obj = restoreframe(frame=inputFrame)
wave = obj.wave[*,order]
flat = readflat(frame=locateflat(date=obj.date))
flatDiv = obj.flux[*,order] / flat.normsmooth[*,order]

IF KEYWORD_SET(inputNod) THEN BEGIN 
    IF inputNod EQ order THEN BEGIN
        MESSAGE, 'Order and nod equal!'
    ENDIF ELSE BEGIN
        nodDiv = obj.flux[*,inputNod] / flat.normsmooth[*,inputNod]
        nodNorm = nodDiv / MEDIAN(nodDiv)
        nodSmooth = filter(nodNorm,50,TYPE='median')
        preNorm = flatDiv / nodSmooth
    ENDELSE
ENDIF ELSE BEGIN
    MESSAGE, 'Nod order not set!'
ENDELSE  

Ha = 656.28
distance = ABS(wave - Ha)
minDistance = MIN(distance,pixelHa)

output = {$
    wave    :   wave, $
    pixelHa :   pixelHa, $
    flatDiv :   flatDiv, $
    nodDiv  :   nodDiv, $
    nodSmooth   :   nodSmooth, $
    preNorm :   preNorm}

RETURN, output

END
