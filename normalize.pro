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
;       output  :   structure with continuum, and red zone width 
; Keyword parameters:
;       WIDTH   :   Red zone width
;       IGNORE  :   Wavelengths to be ignored (fixed width patching)
; Author and history:
;       C.A.L. Bailer-Jones et al., 1998    :  Filtering algorithm 
;       Daniel Hatcher, 2018    :   IDL implementation and patching automation
;-

;-------------------------------------------------------------------------------
;
; Purpose: Filtering function with edge truncation
;
FUNCTION normalizefilter, array, width, TYPE=type

COMPILE_OPT IDL2

num = N_ELEMENTS(array)
output = FLTARR(num)

;First and last elements will not be filtered, so just output them
output[0] = array[0]
output[-1] = array[-1]

FOR i = 1, num-2 DO BEGIN
    ;Edge truncate left
    IF i LT width/2 THEN BEGIN
        filterWindow = LINDGEN(2*i)
    ;Edge truncate right
    ENDIF ELSE IF i+width/2 GT num THEN BEGIN
        diff = num-i
        filterWindow = LINDGEN(2*diff,START=i-diff)
    ;No truncation
    ENDIF ELSE BEGIN
        filterWindow = LINDGEN(width,START=i-width/2)
    ENDELSE
    IF STRCMP(type,'median') EQ 1 THEN BEGIN
        output[i] = MEDIAN(array[filterWindow])
    ENDIF ELSE IF STRCMP(type,'mean') EQ 1 THEN BEGIN
        output[i] = MEAN(array[filterWindow])
    ENDIF
ENDFOR 

RETURN, output

END

;-------------------------------------------------------------------------------
;
; Purpose: Main function
;
FUNCTION normalize, wave, flatdiv, pixelHa, frame, WIDTH=inputWidth, $
    IGNORE = inputIgnore

COMPILE_OPT IDL2

;If width not specified, search
IF NOT KEYWORD_SET(inputWidth) THEN BEGIN
    ;Search for left and right shoulder of Ha feature
    ;Maximum search distance beyond Ha
    searchWidth = 100

    ;Buffer around Ha core not to be searched
    coreBuffer = 20

    ;Create search indices 
    leftSearch = LINDGEN(searchWidth-coreBuffer,START=pixelHa-searchWidth)
    ;Search starting from right end of spectrum (reversed)
    rightSearch = REVERSE(LINDGEN(searchWidth-coreBuffer, $
        START=pixelHa+coreBuffer))

    ;Search blue (left) side of Ha
    leftResult = zscorepeaks(flatdiv[leftSearch],LAG=10,T=1.5,INF=0.1)

    ;Search red (right) side of Ha
    rightResult = zscorepeaks(flatdiv[rightSearch],LAG=10,T=1.5,INF=0.1)

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

    ;Choose largest width
    width = MAX([(rightShoulder-pixelHa),(pixelHa-leftShoulder)])
ENDIF ELSE BEGIN
    ;If specified, use input width 
    width = inputWidth
ENDELSE

;If width is very large, warn user
limit = 10
IF N_ELEMENTS(flatdiv)-width LT limit THEN BEGIN
    limString = STRTRIM(STRING(limit),2)
    PRINT, "Less than "+limString+" pixels on red end of spectrum!"
ENDIF

;Remove Ha feature
totalPixels = N_ELEMENTS(flatdiv)
leftPixels = LINDGEN(pixelHa-width)
rightPixels = LINDGEN(totalPixels-(pixelHa+width),START=pixelHa+width)
patchedPixels = LINDGEN((width*2)+1,START=pixelHa-width)

;Median filter left and right separately
medianWidth = 50
medianLeft = normalizefilter(flatdiv[leftPixels],medianWidth,TYPE='median')
medianRight = normalizefilter(flatdiv[rightPixels],medianWidth, $
    TYPE='median')

;Reposition filtered arrays
separated = FLTARR(totalPixels)
separated[leftPixels] = medianLeft
separated[rightPixels] = medianRight

;Interpolate across red region 
joinedPixels = [leftPixels,rightPixels]
medianFlux = [medianLeft,medianRight]
nLeft = N_ELEMENTS(leftPixels)
endPoints = [nLeft-1,nLeft]
slope = REGRESS(joinedPixels[endPoints],medianFlux[endPoints],CONST=const)
interpolated = const + patchedPixels*slope[0]
separated[patchedPixels] = interpolated

;Boxcar filter
boxWidth = 25
boxFlux = normalizeFilter(separated,boxWidth,TYPE='mean')

continuum = boxFlux

normalized = flatdiv/continuum

;Output to screen?
screen = 1
IF screen THEN BEGIN
    !P.MULTI = [0,1,2,0,0]

    ;Colors
    DEVICE, DECOMPOSED=0
    LOADCT, 39, /SILENT

    titleText = frame+" Width: "+STRTRIM(STRING(width),2)
    PLOT, wave,flatdiv,PSYM=3,title=titleText,xtitle='Wavelength (nm)', $
        ytitle='Flattened Flux',yrange=[MIN(continuum),MAX(continuum)]
    OPLOT, [wave[leftShoulder],wave[rightShoulder]],[flatdiv[leftShoulder],$
        flatdiv[rightShoulder]],PSYM=4
    OPLOT, wave[leftPixels],continuum[leftPixels]
    OPLOT, wave[rightPixels],continuum[rightPixels]
    OPLOT, wave[patchedPixels],continuum[patchedPixels],LINESTYLE=2
    OPLOT, [wave[pixelHa-width],wave[pixelHa-width]],[MIN(flatdiv),MAX(flatdiv)]
    OPLOT, [wave[pixelHa+width],wave[pixelHa+width]],[MIN(flatdiv),MAX(flatdiv)]
    PLOT, wave,normalized,xtitle='Wavelength (nm)', $
        ytitle='Normalized Flux',yrange=[0.9,1.1]
    OPLOT, wave[patchedPixels],normalized[patchedPixels],COLOR=250
    OPLOT, [wave[0],wave[-1]],[0.99,0.99],LINESTYLE=1
    OPLOT, [wave[0],wave[-1]],[1.01,1.01],LINESTYLE=1
    OPLOT, [wave[0],wave[-1]],[0.98,0.98],LINESTYLE=2
    OPLOT, [wave[0],wave[-1]],[1.02,1.02],LINESTYLE=2
    OPLOT, [wave[0],wave[-1]],[0.97,0.97]
    OPLOT, [wave[0],wave[-1]],[1.03,1.03]
ENDIF

;Output structure 
output = {$
    continuum   :   continuum, $
    width   :   width, $
    join   :   joinedPixels, $
    patch   :   patchedPixels}

RETURN, output

END
