; Name:
;       winginterpolate
; Purpose:
;       Compare the wings of H-alpha feature for symmetry
; Calling sequence:
;       Result = winginterpolate()
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

FUNCTION winginterpolate, flux, centroid, left, right, frame, SCREEN=inputScreen

COMPILE_OPT IDL2

leftDist = ABS(left-centroid)
rightDist = ABS(right-centroid)

xinterp = FINDGEN(N_ELEMENTS(left),START=MIN([leftDist,rightDist]))

resultL = INTERPOL(flux[left],leftDist,xinterp,/QUADRATIC)
resultR = INTERPOL(flux[right],rightDist,xinterp,/QUADRATIC)

!P.MULTI = [0,1,2,0,0]
PLOT, xinterp, resultL, title=frame
OPLOT, xinterp, resultR, LINESTYLE=2
PLOT, xinterp, resultR/resultL


RETURN, 0
END
