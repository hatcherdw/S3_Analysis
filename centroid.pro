; Name:
;       centroid
; Purpose:
;       Find center of Ha feature
; Calling sequence:
;
; Positional parameters:
;
; Output:
;
; Keyword parameters:
;
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION centroid, inputFlux

COMPILE_OPT IDL2

sFlux = filter(inputFlux,5,TYPE='median')

;Find extreme values
roi = LINDGEN(100,START=300)
minFlux = MIN(sFlux[roi],minInd)
maxFlux = MAX(sFlux[roi],maxInd)
minInd = roi[minInd]
maxInd = roi[maxInd]

;How extreme?
minDist = 1.0 - minFlux
maxDist = maxFlux - 1.0

;Choose most extreme
IF minDist GT maxDist THEN extreme = minInd
IF maxDist GT minDist THEN extreme = maxInd

;Set upper limit
upperLimit = 0.2*sFlux[extreme]

;Find first point beyond upper limit
FOR i = 0, extreme DO BEGIN
    IF ABS(sFlux[i]-1.0) GT upperLimit THEN BEGIN
        leftStop = i-1
        BREAK
    ENDIF
ENDFOR
FOR j = N_ELEMENTS(sFlux)-1, extreme, -1 DO BEGIN
    IF ABS(sFlux[j]-1.0) GT upperLimit THEN BEGIN
        rightStop = j-1
        BREAK
    ENDIF
ENDFOR

;Wing pixel locations
length = 512 - rightStop
left = LINDGEN(length,START=leftStop-length)
right = LINDGEN(length,START=rightStop)

fluxLeft = sFlux[left]
fluxRight = SFlux[right]

;Turn off math error reporting to suppress benign underflow error messages
;that sometimes occur when fitting gaussian
currentExcept = !EXCEPT
!EXCEPT = 0

;Flush current math error register
void = CHECK_MATH()

;Fit single gaussian
fit = GAUSSFIT([left,right],[fluxLeft,fluxRight],A,NTERMS=5)
centroid = ROUND(A[1])

;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;Report any other math errors
    MESSAGE, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)    
ENDIF

;Restore original reporting condition
!EXCEPT = currentExcept 

;PLOT, inputFlux
;OPLOT, [centroid,centroid],[MIN(inputFlux),MAX(inputFlux)]

output = {$
    centroid    :   centroid, $
    left    :   left, $
    right   :   right}    

RETURN, output

END
