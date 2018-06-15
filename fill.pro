FUNCTION fill, wavelength, flux, filled_flux

;+
;Name:
;		fill
;Purpose:
;		Fill patched areas with linear interpolation
;Calling sequence:
;		filled_flux = fill(wavelength, flux)
;Input:
;		wavelength  ;   1D array of wavelength values
;       flux        ;   1D array of flux values 
;Output:
;		filled_flux ;   1D array of filled-in flux values
;Keywords:
;		None
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                            ;Set compile options

n = N_ELEMENTS(flux)

data_edges_x = LIST()                                   ;Dynamic array for data edge pixel values
data_edges_y = LIST()                                   ;Dynamic array for data edge flux values

FOR i = 1, n-2 DO BEGIN                                 ;Search for NaNs
    IF FINITE(flux[i], /NAN) AND $                      ;FINITE(flux[i], /NAN) = 1 if NaN
    FINITE(flux[i-1]) THEN BEGIN                        ;FINITE(flux[i-1]) =1 if not +-infinity or NaN
        data_edges_x.add, i-1                           ;Add pixel value
        data_edges_y.add, flux[i-1]                     ;Add flux value
    ENDIF       
    IF FINITE(flux[i], /NAN) AND $                      ;Same as above but for right, max edge
    FINITE(flux[i+1]) THEN BEGIN 
        data_edges_x.add, i+1
        data_edges_y.add, flux[i+1]
    ENDIF       
ENDFOR

nedges = N_ELEMENTS(data_edges_x)

FOR i = 0, nedges-1, 2 DO BEGIN                         ;Loop in steps of 2
    xrange = data_edges_x[i+1] - data_edges_x[i]        ;Wavlength range to be filled
    xarray = LINDGEN(xrange, START=data_edges_x[i])     ;Generate integers over patch range
    
    slope = (data_edges_y[i+1] - data_edges_y[i]) / $   ;Compute slope over patch range
    (data_edges_x[i+1] - data_edges_x[i])

    FOR j = 0, xrange-1 DO BEGIN
        flux[xarray[j]] =  slope*j + data_edges_y[i]    ;Replace NaNs with linearly interpolated values    
    ENDFOR    
ENDFOR

filled_flux = flux

RETURN, filled_flux

END 
