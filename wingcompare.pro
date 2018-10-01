; Name:
;       wingcompare
; Purpose:
;       Compare the wings of H-alpha feature for symmetry
; Calling sequence:
;
; Positional parameters:
;
;
; Output:
;
; Keyword parameters:
;
; Author and history:
;       Daniel Hatcher, 2018 
;-

FUNCTION wingcompare, flux, edgePixels, pixelHa, frame

COMPILE_OPT IDL2

;Find extreme values nearest to Ha lab wavelength
near = LINDGEN(40,START=pixelHa-20)
minNear = MIN(flux[near],minInd) 
maxNear = MAX(flux[near],maxInd)

;Difference from 1
minDist = ABS(flux[near[minInd]]-1.0) 
maxDist = ABS(flux[near[maxInd]]-1.0) 

;Choose most extreme
IF minDist GT maxDist THEN extreme = near[minInd]
IF maxDist GT minDist THEN extreme = near[maxInd]

;Set upper limit
upperLimit = 0.2*flux[extreme]
FOR i = 0, extreme DO BEGIN
    IF ABS(flux[i]-1.0) GT upperLimit THEN BEGIN
        leftStop = i
        BREAK  
    ENDIF
ENDFOR
FOR j = N_ELEMENTS(flux)-1, extreme, -1 DO BEGIN
    IF ABS(flux[j]-1.0) GT upperLimit THEN BEGIN
        rightStop = j
        BREAK
    ENDIF
ENDFOR

;Wing pixel locations
length = 512 - rightStop
left = LINDGEN(length,START=leftStop-length)
right = LINDGEN(length,START=rightStop)

;Fit separate gaussians to left and right
rawFitL = GAUSSFIT(left,flux[left],NTERMS=4)
rawFitR = GAUSSFIT(right,flux[right],NTERMS=4)

fitL = rawFitL
fitR = rawFitR

FOR i = 0, 20 DO BEGIN
    IF i EQ 0 THEN prev = TOTAL(ABS((fitR/fitL)-1))

    IF fitR[-1]/fitL[0] GT 1 THEN BEGIN
        fitL = fitL + 0.01*i                
        current = TOTAL(ABS((fitR/fitL)-1))
        IF current GT prev THEN BEGIN
            fitL = fitL - 0.01                
            BREAK
        ENDIF ELSE BEGIN 
            prev = current
            CONTINUE
        ENDELSE
    ENDIF
    IF fitR[-1]/fitL[0] LT 1 THEN BEGIN
        fitR = fitR + 0.01*i                
        current = TOTAL(ABS((fitR/fitL)-1))
        IF current GT prev THEN BEGIN
            fitR = fitR - 0.01                
            BREAK
        ENDIF ELSE BEGIN 
            prev = current
            CONTINUE
        ENDELSE
    ENDIF
ENDFOR

!P.MULTI = [0,1,3,0,0]
DEVICE, DECOMPOSED=0
LOADCT, 39, /SILENT

PLOT, left, flux[left], PSYM=3, title=frame, xrange=[MIN(left),MAX(right)], $
    yrange=[MIN(flux[left]),MAX(flux[left])]
OPLOT, right, flux[right], PSYM=3, COLOR=250
OPLOT, left,rawFitL
OPLOT, right,rawFitR, COLOR=250

PLOT, REVERSE(flux[left]), PSYM=3,yrange=[MIN(fitL),MAX(fitL)]
OPLOT, REVERSE(fitL) 
OPLOT, flux[right], PSYM=3, COLOR=250
OPLOT, fitR, COLOR=250

ratio = fitR/REVERSE(fitL)
PLOT, ratio,yrange=[MIN(ratio),MAX(ratio)]

RETURN, 0

END
