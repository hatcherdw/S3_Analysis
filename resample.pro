FUNCTION resample, wavelength, flux

;+
;Name:
;		resample
;Purpose:
;		Resample from original, unequally spaced data to equally spaced 
;Calling sequence:
;		resampled = resample(wavelength, flux)
;Input:
;		
;Output:
;		
;Keywords:
;		None
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                                            ;Set compile options

nsamples = 512                                                          ;Number of samples after resampling
min_wave = MIN(wavelength)
max_wave = MAX(wavelength)
dsamples = (max_wave - min_wave) / nsamples                             ;Resample spacing
samples = FINDGEN(nsamples, START=min_wave, INCREMENT=dsamples)

y_values = INTERPOL(flux, wavelength, samples)                          ;interpolation using new samples

resampled = {resampled_values, $
             x  :   samples, $
             y  :   y_values}

RETURN, resampled

END 
