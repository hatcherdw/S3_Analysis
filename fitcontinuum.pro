;+
; Name:
;       fitcontinuum
; Purpose:
;       Estimate continuum
; Calling sequence:
;       result = fitcontinuum(FLUX=flux,WAVE=wave)
; Input:
;       None
; Output:
;       output  :   structure
; Keywords:
;       FLUX
;       WAVE
; Author and history:
;       Daniel Hatcher, 2018

;-----------------------------------------------------------------------------
;
; Purpose: Utility function. Smoothes, finds and sorts peaks, applies patches
;
FUNCTION fitcontinuum_utility, zoneArray

COMPILE_OPT IDL2

;Smooth for easier identification of peaks
smoothingWidth = 6
smoothArray = SMOOTH(zoneArray,smoothingWidth,EDGE_TRUNCATE=1)

;Find peaks
peaks = LIST()
FOR i = 1, N_ELEMENTS(smoothArray)-2 DO BEGIN
    left = smoothArray[i-1]
    center = smoothArray[i]
    right = smoothArray[i+1]
    IF center GE left AND center GE right THEN peaks.ADD, i
    IF center LE left AND center LE right THEN peaks.ADD, i
ENDFOR
peaksArray = peaks.TOARRAY()
numPeaks = N_ELEMENTS(peaksArray)

;Sort peaks by 'significance' 
sigArray = FLTARR(numPeaks)
FOR i = 0, numPeaks-1 DO BEGIN
    IF (i GT 0) AND (i LT numPeaks-1) THEN BEGIN
        previous = peaksArray[i-1]
        current = peaksArray[i]
        next = peaksArray[i+1] 
        leftHorDist = current - previous
        rightHorDist = next - current
        leftVerDist = ABS(zoneArray[current] - zoneArray[previous])
        rightVerDist = ABS(zoneArray[current] - zoneArray[next])
    ENDIF ELSE IF i EQ 0 THEN BEGIN 
        current = peaksArray[i]
        next = peaksArray[i+1] 
        leftHorDist = 0
        leftVerDist = 0
        rightHorDist = next - current
        rightVerDist = ABS(zoneArray[current] - zoneArray[next])
    ENDIF ELSE IF i EQ numPeaks-1 THEN BEGIN
        previous = peaksArray[i-1]
        current = peaksArray[i]
        rightHorDist = 0
        rightVerDist = 0
        leftHorDist = current - previous
        leftVerDist = ABS(zoneArray[current] - zoneArray[previous])
    ENDIF
    sigArray[i] = leftHorDist^2+leftVerDist^2+rightHorDist^2+rightVerDist^2 
ENDFOR
sortedPeaks = peaksArray[REVERSE(SORT(sigArray))]

;Calculate patch positions
numPatches = 5
patchWidth = 5
patchPixels = LIST() 
FOR i = 0, 4 DO BEGIN
    currentPatch = LINDGEN(2*patchWidth+1,START=sortedPeaks[i]-patchWidth)
    patchPixels.ADD, currentPatch
ENDFOR
patchPixelsArray = patchPixels.TOARRAY()

;Ignore duplicates
uniquePatchArray = patchPixelsArray[UNIQ(patchPixelsArray)]

;Apply patches
patched = LIST()
FOR i = 0, N_ELEMENTS(zoneArray)-1 DO BEGIN
    count = WHERE(i EQ patchPixelsArray, isPatch)
    IF NOT isPatch THEN patched.ADD, i
ENDFOR
patchedArray = patched.TOARRAY()

RETURN, patchedArray

END

;-----------------------------------------------------------------------------
;
; Purpose: Main routine
;
FUNCTION fitcontinuum, FLUX=inputFlux, WAVE=inputWave

COMPILE_OPT IDL2

IF NOT checkarrays(FLUX=inputFlux,WAVE=inputWave) THEN STOP

;Find pixel with wavelength closest to Ha (lab wavelength 656.28 nm)
;Index stored in pixelHa
Ha = 656.28
distMin = MIN(ABS(inputWave-Ha),pixelHa)

;Loop through red zone widths
redStart = 10
redStop = 100
stepSize = 1 
widths = LIST()
slopes = LIST()
FOR b = redStart,redStop,stepSize DO BEGIN
    widths.ADD, b
    ;Subset flux and wavelength arrays by excluding 'red' zone
    redWidth = b
    leftZone = LINDGEN(pixelHa - redWidth)
    rightZone = LINDGEN(512-pixelHa-redWidth,START=pixelHa+redWidth)
    leftWave = inputWave[leftZone]
    rightWave = inputWave[rightZone]
    leftFlux = inputFlux[leftZone]
    rightFlux = inputFlux[rightZone]

    ;Pass zoned flux arrays to utility function
    leftPatched = fitcontinuum_utility(leftFlux)
    rightPatched = fitcontinuum_utility(rightFlux)

    ;Subset using patches
    patchedWave = [leftWave[leftPatched],rightWave[rightPatched]]
    patchedFlux = [leftFlux[leftPatched],rightFlux[rightPatched]]

    ;Fit polynomial to remaining 'continuum' points
    fitDegree = 4
    polyCoeffs = POLY_FIT(patchedWave,patchedFlux,fitDegree,YFIT=fit)

    ;Calculate continuum
    continuum = 0.0
    greenContinuum = 0.0
    FOR i = 0, fitDegree DO BEGIN
        continuum = continuum + inputWave^i*polyCoeffs[i]
        greenContinuum = greenContinuum + [leftWave,rightWave]^i*polyCoeffs[i] 
    ENDFOR

    ;Divide out continuum
    greenNormalized = [leftFlux,rightFlux] / greenContinuum 

    ;Examine normalization
    slope = REGRESS([leftFLux,rightFlux],greenNormalized)
    slopes.ADD, ABS(slope[0])
    IF redWidth GT redStart THEN BEGIN
        IF ABS(slope[0]) LT minimum THEN BEGIN 
            normalized = inputFlux / continuum
            bestSize = b
        ENDIF
    ENDIF ELSE BEGIN
        minimum = ABS(slope[0])
    ENDELSE
ENDFOR
widthsArray = widths.TOARRAY()
slopesArray = slopes.TOARRAY()
PLOT, widthsArray, slopesArray, PSYM=4
PRINT, widthsArray[REVERSE(SORT(slopesArray))]
PRINT, bestSize
RETURN, normalized

END
