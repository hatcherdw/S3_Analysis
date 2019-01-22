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

FUNCTION wingcompare, flux, centroid, left, right, frame, SCREEN=inputScreen

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

;Resample 
rsLeft = FINDGEN(2*N_ELEMENTS(left),START=MIN([leftDist,rightDist]),$ 
    INCREMENT=0.5)
rsRight = rsLeft

;Calculate fit at resampled points
rsLeftFit = FLTARR(N_ELEMENTS(rsLeft))
rsRightFit = FLTARR(N_ELEMENTS(rsRight))
FOR i = 0, N_ELEMENTS(rsLeft)-1 DO BEGIN
    zL = (rsLeft[i] - coeffL[1]) / coeffL[2]
    rsLeftFit[i] = coeffL[0]*exp((-zL^2)/2)+coeffL[3]
    zR = (rsRight[i] - coeffR[1]) / coeffR[2]
    rsRightFit[i] = coeffR[0]*exp((-zR^2)/2)+coeffR[3]
ENDFOR

;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;Report any other math errors
    PRINT, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)
ENDIF

;Restore original reporting condition
!EXCEPT = currentExcept

IF KEYWORD_SET(inputScreen) AND inputScreen EQ 1 THEN BEGIN
    ;Colors
    DEVICE, DECOMPOSED=0
    LOADCT, 39, /SILENT

    !P.MULTI = [0,1,4,0,0]

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
    OPLOT, rsLeft, rsLeftFit
    OPLOT, rsRight, rsRightFit, COLOR = 250

    coeffText = ['Height','Center','Width','Constant','Linear','Quadratic']

    coeffLString = ''
    coeffRString = ''
    coeffLegend = ''
    FOR i = 0,nterms-1 DO BEGIN
        coeffLegend += coeffText[i] + '!C'
        coeffLString += STRTRIM(STRING(coeffL[i]),2) + '!C'
        coeffRString += STRTRIM(STRING(coeffR[i]),2) + '!C'
    ENDFOR 

    measure = (rsRightFit/rsLeftFit) - (coeffR[3]/coeffL[3])
    ratio = flux[right]/flux[left]
    tot = TOTAL(ABS(measure))
    PLOT, rsLeft, measure, $
        title='Right Fit / Left Fit - Right Constant / Left Constant', $
            xtitle='Distance from centroid', yrange=[MIN(measure),MAX(ratio)]
    OPLOT, [MIN(rsLeft),MAX(rsLeft)],[0.0,0.0],LINESTYLE=2
    OPLOT, ratio, PSYM=3

    currentTot = FLTARR(N_ELEMENTS(rsLeft))
    FOR i = 0, N_ELEMENTS(rsLeft)-1 DO BEGIN
        currentTot[i] = TOTAL(ABS(measure[0:i]))
    ENDFOR 
    PLOT, rsLeft, currentTot, title='Cumulative percent difference', $
        xtitle='Distance from centroid'
    OPLOT, [MIN(rsLeft),MAX(rsLeft)], [tot,tot], LINESTYLE=2 
    XYOUTS, 100,0.5*tot,STRTRIM(STRING(tot),2)

ENDIF

RETURN, 0

END
