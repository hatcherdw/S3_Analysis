FUNCTION roilocator, flux, wavelength, patch

;+
;Name:
;		roilocator
;Purpose:
;	    Locates regions of interest based on extremea locations and heights.	
;Calling sequence:
;		patch = roilocator(flux, wavelength)
;Input:
;		flux    ;   1D array of flux values
;       wavelength  ;   1D array of wavelengths
;Output:
;       patched_flux    ;   input flux values with NaNs inserted into signal regions
;Keywords:
;	    None
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                                                ;Set compile options

width = 5                                                                   ;Smoothing width
npatches = 7                                                                ;Number of patches
n = N_ELEMENTS(flux)                                                        ;Number of flux values

s = SMOOTH(flux, width)                                                     ;Smoothed flux values

pp = LIST()                                                                 ;Create dynamic array for peak positions 
pv = LIST()                                                                 ;Create dynamic array for peak values

FOR i = (width+1), n-(width+1) DO BEGIN                                     ;Search for peaks (extrema)
    IF $ 
    (s[i] GE s[i-1] AND s[i] GE s[i+1]) $
    OR $ 
    (s[i] LE s[i-1] AND s[i] LE s[i+1]) $
    THEN BEGIN
        pp.ADD, i                                                           ;Store peak position
        pv.ADD, s[i]                                                        ;Store peak value
    ENDIF    
ENDFOR

ppa = pp.TOARRAY()                                                          ;Peak position array                   
pva = pv.TOARRAY()                                                          ;Peak value array
npoints = N_ELEMENTS(ppa)                                                   ;Number of detected peaks

distance = LONARR(3,npoints-2)                                              ;Create distance matrix

FOR i = 1, npoints-2 DO BEGIN                                               ;Compute interpeak distances
    lhdist = ppa[i] - ppa[i-1]                                              ;Left horizontal distance
    rhdist = ppa[i+1] - ppa[i]                                              ;Right horizontal distance
    lvdist = ABS(pva[i] - pva[i-1])                                         ;Left vertical distance
    rvdist = ABS(pva[i] - pva[i+1])                                         ;Right vertical distance
    ldist = SQRT(lhdist^2 + lvdist^2)                                       ;Left pythag. distance       
    rdist = SQRT(rhdist^2 + rvdist^2)                                       ;Right pythag. distance
    sum = ldist + rdist
    diff = ABS(ldist - rdist)
    distance[0,i-1] = lhdist
    distance[1,i-1] = rhdist
    distance[2,i-1] = (ldist + rdist) * ABS(sum/diff)                       ;"Normalized" distance
                                                                            ;symmetric peaks have more weight
ENDFOR

dist_order = REVERSE(SORT(distance[2,*]))                                   ;Find sorted indices 

FOR i = 0, 2 DO BEGIN                                                       ;Sort peaks
    distance[i,*] = distance[i, dist_order]             
ENDFOR

ppa_order = ppa[dist_order + 1]                                             ;Sort point position array
ppa_patches = ppa_order[0:npatches-1]                                       ;Select patch center points
positions = LIST()

FOR i = 0, npatches-1 DO BEGIN
    patch_size = distance[0,i]+distance[1,i]                                ;Compute patch size
    patch_positions = LINDGEN(patch_size, START=ppa_order[i]-distance[0,i]) ;Create patch array
    FOR j =0, patch_size-1 DO BEGIN 
        positions.ADD, patch_positions[j]                                   ;Fill running list of patch positions 
    ENDFOR
ENDFOR

pa = positions.TOARRAY()

pa_sorted = pa[SORT(pa)]                                                    ;Sort cumulative list
pa_sorted_unique = pa_sorted[UNIQ(pa_sorted)]                               ;Subset of unique values

x = LIST()

FOR i = 0, n-1 DO BEGIN
    ind = WHERE(i EQ pa_sorted_unique, count)
    IF count EQ 0 THEN BEGIN
        x.ADD, i
    ENDIF 
ENDFOR
xa = x.TOARRAY()

patched_wavelength = wavelength[xa]
patched_flux = flux[xa]

patch = {patches, $
         wl :   patched_wavelength, $
         fl :   patched_flux}

RETURN, patch

END 
