; Name:
;       normalize
; Purpose:
;       Automated continuum normalization
; Calling sequence:
;       Result = normalize(wave,flatdiv,pixelHa)
; Positional parameters:
;       wave    :   array of wavelengths
;       flatdiv :   array of flattened fluxes
;       pixelHa :   pixel nearest Ha (656.28 nm)
; Output:
;       
; Keyword parameters:
;       None
; Author and history:
;       C.A.L. Bailer-Jones et al., 1998    :  Filtering algorithm        
;       Daniel Hatcher, 2018    :   IDL implementation and patching automation
;-

;-------------------------------------------------------------------------------
;
; Purpose: Filtering function with edge truncation
;
FUNCTION normalizefilter, array, width, MODE=mode

COMPILE_OPT IDL2

num = N_ELEMENTS(array)
output = FLTARR(num)
output = array

FOR i = 1, num-2 DO BEGIN
    IF i LT width/2 THEN BEGIN
        filterWindow = LINDGEN(2*i)
    ENDIF ELSE IF i+width/2 GT num THEN BEGIN
        diff = num-i
        filterWindow = LINDGEN(2*diff,START=i-diff)
    ENDIF ELSE BEGIN
        filterWindow = LINDGEN(width,START=i-width/2)
    ENDELSE
    IF STRCMP(mode,'median') EQ 1 THEN BEGIN
        output[i] = MEDIAN(array[filterWindow])
    ENDIF
    IF STRCMP(mode,'mean') EQ 1 THEN BEGIN
        output[i] = MEAN(array[filterWindow])
    ENDIF
ENDFOR 

RETURN, output

END

;-------------------------------------------------------------------------------
;
; Purpose: Main function
;
FUNCTION normalize, wave, flatdiv, pixelHa, frame

COMPILE_OPT IDL2

;Search for left and right shoulder of Ha feature
;Maximum search distance beyond Ha
searchWidth = 100

;Buffer around Ha core not to be searched
coreBuffer = 20

;Create search indices 
leftSearch = LINDGEN(searchWidth-coreBuffer,START=pixelHa-searchWidth)
rightSearch = REVERSE(LINDGEN(searchWidth-coreBuffer,START=pixelHa+coreBuffer))

;Search blue (left) side of Ha
leftResult = zscorepeaks(flatdiv[leftSearch],LAG=10,T=1,INF=0)

;Search red (right) side of Ha
rightResult = zscorepeaks(flatdiv[rightSearch],LAG=25,T=0.1,INF=0)

;Find first position of last signal (blue side of Ha)
FOR i = N_ELEMENTS(leftSearch)-1,0,-1 DO BEGIN
    lastValue = leftResult.signals[-1]
    IF leftResult.signals[i] NE lastValue THEN BEGIN
        leftShoulder = leftSearch[i]
        BREAK
    ENDIF 
ENDFOR

;Find first position of last signal (red side of Ha)
FOR i = N_ELEMENTS(rightSearch)-1,0,-1 DO BEGIN
    lastValue = rightResult.signals[-1]    
    IF rightResult.signals[i] NE lastValue THEN BEGIN
        rightShoulder = rightSearch[i]
        BREAK
    ENDIF
ENDFOR

;Remove Ha feature
;Choose largest width
width = MAX([(rightShoulder-pixelHa),(pixelHa-leftShoulder)])
totalPixels = N_ELEMENTS(flatdiv)
leftPixels = LINDGEN(pixelHa-width)
rightPixels = LINDGEN(totalPixels-(pixelHa+width),START=pixelHa+width)
patchedPixels = LINDGEN((width*2)+1,START=pixelHa-width)

;Method 1
;Join, median filter, interpolate, boxcar
method1 = 1
IF method1 THEN BEGIN
    ;Join remaining spectrum
    joinedPixels = [leftPixels,rightPixels]
    joinedWave = wave[joinedPixels]
    joinedFlux = flatdiv[joinedPixels]

    ;Median filter joined spectrum
    medianWidth = 50
    medianFlux = normalizefilter(joinedFlux,medianWidth,MODE='median')

    ;Separate median-filtered, joined spectrum
    separated = FLTARR(totalPixels)
    FOR i = 0,N_ELEMENTS(joinedPixels)-1 DO BEGIN
        separated[joinedPixels[i]] = medianFlux[i]
    ENDFOR

    ;Interpolate 
    nLeft = N_ELEMENTS(leftPixels)
    endPoints = [nLeft-1,nLeft+(medianWidth/2)]
    slope = REGRESS(joinedPixels[endPoints],medianFlux[endPoints],CONST=const)
    interpolated = const + patchedPixels*slope[0]
    separated[patchedPixels] = interpolated

    ;Boxcar filter
    boxWidth = 25
    boxFlux = normalizeFilter(separated,boxWidth,MODE='mean')

    continuum = boxFlux
ENDIF

;Method 2
;Join, median filter, spline
method2 = 0
IF method2 THEN BEGIN
    ;Join remaining spectrum
    joinedPixels = [leftPixels,rightPixels]
    joinedWave = wave[joinedPixels]
    joinedFlux = flatdiv[joinedPixels]

    ;Median filter joined spectrum
    medianWidth = 50
    medianFlux = normalizefilter(joinedFlux,medianWidth,MODE='median')
ENDIF

;Method 3
;Median separately, spline


;Output to screen?
screen = 1
IF screen THEN BEGIN
    PRINT, 'Width: ', STRTRIM(width,2)
    !P.MULTI = [0,1,2,0,0]
    PLOT, wave,flatdiv,PSYM=3,title=frame,xtitle='Wavelength (nm)', $
        ytitle='Flattened Flux'
    OPLOT, wave,continuum
    OPLOT, [wave[pixelHa-width],wave[pixelHa-width]],[MIN(flatdiv),MAX(flatdiv)]
    OPLOT, [wave[pixelHa+width],wave[pixelHa+width]],[MIN(flatdiv),MAX(flatdiv)]
    XYOUTS, wave[pixelHa-width],MAX(flatdiv),STRTRIM(STRING(width),2)
    PLOT, wave, flatdiv/continuum,xtitle='Wavelength (nm)', $
        ytitle='Normalized Flux',yrange=[0.5,1.5]
ENDIF

output = {normalizeOutput, $
    continuum   :   continuum, $
    width   :   width}
       

RETURN, output

END
