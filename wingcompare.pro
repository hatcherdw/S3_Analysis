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
;       FRAME   :   String frame number
; Author and history:
;       Daniel Hatcher, 2018 
;-

FUNCTION wingcompare, flux, centroid, left, right

COMPILE_OPT IDL2

leftDist = ABS(left-centroid)
rightDist = ABS(right-centroid)

;Colors
DEVICE, DECOMPOSED=0
LOADCT, 39, /SILENT

PLOT, leftDist, flux[left], PSYM=3
OPLOT, rightDist, flux[right], PSYM=3, COLOR=250

RETURN, 0

END
