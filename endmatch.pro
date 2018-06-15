FUNCTION endmatch, wavelength, flux, matched_structure

;+
;Name:
;		endmatch (name taken from Wall 1997)
;Purpose:
;		Performs a linear fit to the baseline array and subtracts for end-matching
;Calling sequence:
;		matched_structure = endmatch(wavelength, flux)
;Input:
;		wavelength  ;   1D array of wavelength values
;       flux        ;   1D array of flux values
;Output:
;		matched_structure   ;   named structure with subtracted values and result
;Keywords:
;		None
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                        ;Set compile options

n = N_ELEMENTS(wavelength)
b = REGRESS(wavelength, flux, const=a, /double)     ;Perform linear regression with double precision 

subs = wavelength*b[0] + a                          ;Values to be subtracted off

matched_structure = {matched_structure, $           ;Create structure
                     subtracted :   subs, $         ;Values to be subtracted     
                     sub_flux   :   flux - subs}    ;Resultant flux 

RETURN, matched_structure

END 
