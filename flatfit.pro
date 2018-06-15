FUNCTION flatfit, flat, flatfit_output, ORDER = order

;+
;Name:
;		flatfit
;Purpose:
;		Function for removing wavelength-dependent variation in flat field 
;Calling sequence:
;		normalflat = flatfit(flat)
;Input:
;		flat
;Output:
;		flatfit_output  ;   structure with fits coeffs and normalized flat
;Keywords:
;		ORDER   ;   echelle order 
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                                ;Set compile options

IF NOT KEYWORD_SET(order) THEN BEGIN                        ;If none provided, use order 11
    order = 11
    PRINT, 'Using default order: ' + STRING(order)
ENDIF

pixels = LINDGEN(512) + 1
roi = flat[*,order-1]                                       ;Region of interest in flat frame

fit_order = 2
coeffs = POLY_FIT(pixels, roi, fit_order, /DOUBLE)          ;quadratic fit 

values = FLTARR(512)
FOR i = 0, fit_order DO BEGIN
     values = values + coeffs[i]*pixels^i
ENDFOR

normalflat = roi / values                                   ;"normalize" flat

flatfit_output = {out, $
                  fit   :   coeffs, $
                  nflat :   normalflat}

RETURN, flatfit_output

END 
