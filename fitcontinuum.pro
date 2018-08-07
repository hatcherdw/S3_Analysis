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
; Purpose: Utility function. Smoothes, finds peaks, sorts peaks, patches
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

RETURN, 0

END

;-----------------------------------------------------------------------------
;
; Purpose: Main routine
;
FUNCTION fitcontinuum, FLUX=inputFlux, WAVE=inputWave

COMPILE_OPT IDL2

IF NOT checkarrays(FLUX=inputFlux,WAVE=inputWave) THEN STOP

;Find pixel with wavelength closest to Ha (656.28 nm)
;Index stored in pixelHa
Ha = 656.28
distMin = MIN(ABS(inputWave-Ha),pixelHa)

;Subset flux and wavelength arrays by excluding 'red' zone
redWidth = 50
leftZone = LINDGEN(pixelHa - redWidth)
rightZone = LINDGEN(512-pixelHa-redWidth,START=pixelHa+redWidth)
leftWave = inputWave[leftZone]
rightWave = inputWave[rightZone]
leftFlux = inputFlux[leftZone]
rightFlux = inputFlux[rightZone]

;Pass zoned flux arrays to utility function
leftPatch = fitcontinuum_utility(leftFlux)
rightPatch = fitcontinuum_utility(rightFlux)

;Fit polynomial to remaining 'continuum' points

;Divide out continuum

;Examine normalization

RETURN, 0

END
