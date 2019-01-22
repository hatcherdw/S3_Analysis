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

FUNCTION centroid, inputFlux, frame, SCREEN=inputScreen

COMPILE_OPT IDL2

sFlux = filter(inputFlux,5,TYPE='median')

;Find extreme values
roi = LINDGEN(150,START=250)
minFlux = MIN(sFlux[roi],minInd)
maxFlux = MAX(sFlux[roi],maxInd)
minInd = roi[minInd]
maxInd = roi[maxInd]

;How extreme?
minDist = ABS(1.0 - minFlux)
maxDist = ABS(1.0 - maxFlux)

;Choose most extreme
IF maxDist GT minDist THEN BEGIN 
    extreme = maxInd
ENDIF 
IF minDist GT maxDist THEN BEGIN 
    extreme = minInd
ENDIF

limit = 0.45*ABS(sFlux[extreme]-1.0)

;Find first point beyond limit
FOR i = 0, extreme DO BEGIN
    IF ABS(sFlux[i]-1.0) GT limit THEN BEGIN
        leftStop = i
        BREAK
    ENDIF
ENDFOR
FOR j = N_ELEMENTS(sFlux)-1, extreme, -1 DO BEGIN
    IF ABS(sFlux[j]-1.0) GT limit THEN BEGIN
        rightStop = j
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
IF extreme EQ maxInd THEN BEGIN
    fit = GAUSSFIT([left,right],[fluxLeft,fluxRight],A,NTERMS=5)
ENDIF ELSE IF extreme EQ minInd THEN BEGIN
    fit = GAUSSFIT([left,right],[fluxLeft,fluxRight],A,NTERMS=5,$
        ESTIMATES=[-1,350,50,1,0.01])
ENDIF

;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;Report any other math errors
    PRINT, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)    
ENDIF

;Restore original reporting condition
!EXCEPT = currentExcept 


;Resampling
range = right[-1]-left[0]
xsamples = FINDGEN(range,START=left[0])
z = (xsamples - A[1])/A[2]
rfit = A[0]*exp((-(z^2))/2) + A[3] + A[4]*xsamples

centroid = A[1]

IF KEYWORD_SET(inputScreen) AND inputScreen EQ 1 THEN BEGIN
    ;PLOT, sFlux,title=frame, PSYM=4
    PLOT, left, sFlux[left], PSYM=4, xrange=[MIN(left),MAX(right)],title=frame
    OPLOT, right, sFlux[right], PSYM=4
    ;OPLOT, [centroid,centroid],[MIN(inputFlux),MAX(inputFlux)]
    OPLOT, xsamples,rfit
ENDIF

output = {$
    centroid    :   centroid, $
    left    :   left, $
    right   :   right, $
    const   :   A[3]}

RETURN, output

END
