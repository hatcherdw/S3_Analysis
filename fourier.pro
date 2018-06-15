FUNCTION fourier, wavelength, flux

;+
;Name:
;		TEMPLATE
;Purpose:
;		Template for creating procedures.
;Calling sequence:
;		TEMPLATE, arg1, arg2
;Input:
;		arg1
;Output:
;		arg2
;Keywords:
;		key1
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			            ;Set compile options

n = N_ELEMENTS(wavelength)
d = wavelength[1] - wavelength[0]

g = FFT(flux, /DOUBLE)

k = FINDGEN(n/2+1) / (n*d)
mag_g = ABS(g[0:n/2])^2

fftout = {output, $
          x :   k, $
          y :   g, $
          mag_y :   mag_g}

RETURN, fftout


END 
