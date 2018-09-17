; Name:
;       normalize
; Purpose:
;       Automated continuum normalization
; Calling sequence:
;       Result = normalize(wave,flux,pixelHa)
; Positional parameters:
;       wave    :   array of wavelengths
;       flux :   array of flattened fluxes
;       pixelHa :   pixel nearest Ha (656.28 nm)
; Output:
;       output  :   structure with continuum, and red zone width 
; Keyword parameters:
;       WIDTH   :   Red zone width
;       IGNORE  :   Wavelengths to be ignored (fixed width patching)
;       FIT     :   Fit parameters for red region
; Author and history:
;       C.A.L. Bailer-Jones et al., 1998    :  Filtering algorithm 
;       Daniel Hatcher, 2018    :   IDL implementation and patching automation
;-

FUNCTION normalize, wave, flux, pixelHa, frame, WIDTH=inputWidth, $
    IGNORE=inputIgnore, FIT=inputFit

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
    leftResult = zscorepeaks(flux[leftSearch],LAG=10,T=1.5,INF=0.1)

    ;Search red (right) side of Ha
    rightResult = zscorepeaks(flux[rightSearch],LAG=10,T=1.5,INF=0.1)

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
IF N_ELEMENTS(flux)-width LT limit THEN BEGIN
    limString = STRTRIM(STRING(limit),2)
    PRINT, "Less than "+limString+" pixels on red end of spectrum!"
ENDIF

;Remove Ha feature
totalPixels = N_ELEMENTS(flux)
leftPixels = LINDGEN(pixelHa-width)
rightPixels = LINDGEN(totalPixels-(pixelHa+width),START=pixelHa+width)
patchedPixels = LINDGEN((width*2)+1,START=pixelHa-width)

;Median filter left and right separately
medianWidth = 50
medianLeft = filter(flux[leftPixels],medianWidth,TYPE='median')
medianRight = filter(flux[rightPixels],medianWidth, $
    TYPE='median')

;Reposition filtered arrays
separated = FLTARR(totalPixels)
separated[leftPixels] = medianLeft
separated[rightPixels] = medianRight

;Interpolate across red region 
joinedPixels = [leftPixels,rightPixels]
medianFlux = [medianLeft,medianRight]
interpolated = FLTARR(N_ELEMENTS(patchedPixels))
nLeft = N_ELEMENTS(leftPixels)
endPoints = [nLeft-1,nLeft]
;If fit parameters not provided, use linear interpolation
IF NOT KEYWORD_SET(inputFit) THEN BEGIN
    slope = REGRESS(joinedPixels[endPoints],medianFlux[endPoints],CONST=const)
    interpolated = const + patchedPixels*slope[0]
ENDIF ELSE BEGIN
;Use provided fit
    FOR i = 0, N_ELEMENTS(inputFit)-1 DO BEGIN
        interpolated += (patchedPixels^i)*inputFit[i]
    ENDFOR
ENDELSE
separated[patchedPixels] = interpolated

;Boxcar filter
boxWidth = 25
boxFlux = filter(separated,boxWidth,TYPE='mean')

continuum = boxFlux

normalized = flux/continuum

;Output to screen?
screen = 1
IF screen THEN BEGIN
    !P.MULTI = [0,1,2,0,0]

    ;Colors
    DEVICE, DECOMPOSED=0
    LOADCT, 39, /SILENT

    titleText = frame+" Width: "+STRTRIM(STRING(width),2)
    PLOT, wave,flux,PSYM=3,title=titleText,xtitle='Wavelength (nm)', $
        ytitle='Flattened Flux',yrange=[MIN(continuum),MAX(continuum)]
    OPLOT, [wave[leftShoulder],wave[rightShoulder]],[flux[leftShoulder],$
        flux[rightShoulder]],PSYM=4
    OPLOT, wave[leftPixels],continuum[leftPixels]
    OPLOT, wave[rightPixels],continuum[rightPixels]
    OPLOT, wave[patchedPixels],continuum[patchedPixels],LINESTYLE=2
    OPLOT, [wave[pixelHa-width],wave[pixelHa-width]],[MIN(flux),MAX(flux)]
    OPLOT, [wave[pixelHa+width],wave[pixelHa+width]],[MIN(flux),MAX(flux)]
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
    patch   :   patchedPixels, $
    shoulders   :   [leftShoulder,rightShoulder]}

RETURN, output

END
