; Name:
;       wingcompare
; Purpose:
;       Compare the wings of H-alpha feature for symmetry
; Calling sequence:
;       Result = wingcompare()
; Positional parameters:
;       flux    :   Array of flux values   
;       width   :   Width used in constructin of continuum
;       centroid    :   center of Ha feature
; Output:
;       None
; Keyword parameters:
;
; Author and history:
;       Daniel Hatcher, 2018 
;-

FUNCTION wingcompare, flux, centroid, left, right, frame

COMPILE_OPT IDL2

leftDist = ABS(left-centroid)
rightDist = ABS(right-centroid)

;Turn off math error reporting to suppress benign underflow error messages
;that sometimes occur when fitting gaussian
currentExcept = !EXCEPT
!EXCEPT = 0

;Flush current math error register
void = CHECK_MATH()

;Fit left and right gaussians
nterms = 4
fitL = GAUSSFIT(leftDist,flux[left],coeffL,NTERMS=nterms)
fitR = GAUSSFIT(rightDist,flux[right],coeffR,NTERMS=nterms)

;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;Report any other math errors
    MESSAGE, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)
ENDIF

;Restore original reporting condition
!EXCEPT = currentExcept

;Colors
DEVICE, DECOMPOSED=0
LOADCT, 39, /SILENT

!P.MULTI = [0,1,3,0,0]

PLOT, left,flux[left],PSYM=3,title=frame,$
    yrange=[MIN(flux[[left,right]]),MAX(flux[[left,right]])], $
    xrange=[MIN(left),MAX(right)], $
    xtitle='Pixel',ytitle='Normalized flux'
OPLOT, right,flux[right],PSYM=3, COLOR=250
OPLOT, [centroid,centroid],[MIN(flux),MAX(flux)]

PLOT, leftDist, flux[left], PSYM=3, $
    yrange=[MIN(flux[[left,right]]),MAX(flux[[left,right]])],$
    xtitle = 'Distance from centroid',ytitle='Normalized flux'
OPLOT, rightDist, flux[right], PSYM=3, COLOR=250
OPLOT, leftDist, fitL
OPLOT, rightDist, fitR, COLOR = 250

coeffText = ['Height','Center','Width','Constant','Linear','Quadratic']

coeffLString = ''
coeffRString = ''
coeffLegend = ''
FOR i = 0,nterms-1 DO BEGIN
    coeffLegend += coeffText[i] + '!C'
    coeffLString += STRTRIM(STRING(coeffL[i]),2) + '!C'
    coeffRString += STRTRIM(STRING(coeffR[i]),2) + '!C'
ENDFOR 

fitLnorm = REVERSE(fitL)
fitRnorm = fitR
cumTot = FLTARR(N_ELEMENTS(fitL))
FOR i = 0, N_ELEMENTS(fitL)-1 DO BEGIN
    cumTot[i] = TOTAL(ABS(fitRnorm[0:i]-fitLnorm[0:i]))
ENDFOR
tot = TOTAL(ABS(fitRnorm-fitLnorm))
XYOUTS, 0.4, 0.5, coeffLegend, /NORMAL
XYOUTS, 0.6, 0.5, coeffLString, /NORMAL
XYOUTS, 0.8, 0.5, coeffRString, COLOR=250, /NORMAL

PLOT, cumTot, title='Cumulative total'
XYOUTS, 100, tot, STRTRIM(STRING(tot),2), /DATA

RETURN, 0

END
