; Name:
;       prenormalize
; Purpose:
;       Preliminary reduction and normalization 
; Calling sequence:
;       result = prenormalize,'inputFrame',ORDER=integer,NOD=integer
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

FUNCTION prenormalize, inputFrame, ORDER=inputOrder, NOD=inputNod

COMPILE_OPT IDL2

IF NOT KEYWORD_SET(inputOrder) THEN BEGIN
    order = 10
ENDIF ELSE BEGIN
    order = inputOrder
ENDELSE

obj = restoreframe(frame=inputFrame)
wave = obj.wave[*,order]
flat = readflat(frame=locateflat(date=obj.date))
flatdiv = obj.flux[*,order] / flat.normsmooth[*,order]

IF KEYWORD_SET(inputNod) THEN BEGIN 
    IF inputNod EQ order THEN BEGIN
        MESSAGE, 'Order and nod equal!'
    ENDIF ELSE BEGIN
        noddiv = obj.flux[*,inputNod] / flat.normsmooth[*,inputNod]
        
    ENDELSE
ENDIF 

Ha = 656.28
distance = ABS(wave - Ha)
minDistance = MIN(distance,pixelHa)

RETURN, 0

END
