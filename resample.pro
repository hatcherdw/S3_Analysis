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

;Set compile options
COMPILE_OPT IDL2

;Number of samples after resampling.
nsamples = 512 
min_wave = MIN(wavelength)
max_wave = MAX(wavelength)
;Resample spacing
dsamples = (max_wave - min_wave) / nsamples 
samples = FINDGEN(nsamples, START=min_wave, INCREMENT=dsamples)

;Interpolate using new samples
y_values = INTERPOL(flux, wavelength, samples) 

resampled = {resampled_values, $
             x  :   samples, $
             y  :   y_values}

RETURN, resampled

END 
