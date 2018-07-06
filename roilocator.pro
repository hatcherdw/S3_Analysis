FUNCTION roilocator_isextremum, inputLeft, inputCenter, inputRight
;Utility module to test for local maximum or local minimum

COMPILE_OPT IDL2

IF ((inputCenter GE inputLeft) AND (inputCenter GE inputRight)) THEN BEGIN
    returnValue = 1B
ENDIF ELSE IF (inputCenter LE inputLeft) AND (inputCenter LE inputRight) THEN $
    BEGIN
    returnValue = 1B
ENDIF ELSE BEGIN
    returnValue = 0B
ENDELSE

RETURN, returnValue
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION roilocator, FLUX=inputFlux, WAVELENGTH=inputWavelength 

;+
; Name:
;       roilocator
; Purpose:
;       Locate and remove regions of apparent signal 
; Calling sequence:
;       patchedArray = roilocator(FLUX=inputFlux,WAVELENGTH=inputWavelength)
; Input:
;       None
; Output:
;       output  :   named structure roilocatorOutput
; Keywords:
;       inputFlux   :   float array
;       inputWavelength :   float array
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2

;Check input existence
IF NOT KEYWORD_SET(inputFlux) THEN BEGIN
    MESSAGE, 'Please provide flux input array!'
ENDIF
IF NOT KEYWORD_SET(inputWavelength) THEN BEGIN
    MESSAGE, 'Please provide wavelength input array!'
ENDIF

;Check input sizes
fluxSizeVector = SIZE(inputFlux)
wavelengthSizeVector = SIZE(inputWavelength)
IF fluxSizeVector[0] GT 1 THEN BEGIN
    MESSAGE, 'Flux array has more than one dimension!'
ENDIF
IF wavelengthSizeVector[0] GT 1 THEN BEGIN
    MESSAGE, 'Wavelength array has more than one dimension!'
ENDIF
IF fluxSizeVector[-1] NE wavelengthSizeVector[-1] THEN BEGIN
    MESSAGE, 'Input sizes do not match!'
ENDIF
IF fluxSizeVector[-1] LT 2 THEN BEGIN
    MESSAGE, 'Flux array has less than 2 elements!'
ENDIF
IF wavelengthSizeVector[-1] LT 2 THEN BEGIN
    MESSAGE, 'Wavelength array has less than 2 elements!'
ENDIF

;Check input types
IF STRCMP(SIZE(inputFlux,/TNAME),'DOUBLE') EQ 0 THEN BEGIN
    MESSAGE, 'Flux input is not of type DOUBLE!'
ENDIF
IF STRCMP(SIZE(inputWavelength,/TNAME),'DOUBLE') EQ 0 THEN BEGIN
    MESSAGE, 'Wavelength input is not of type DOUBLE!'
ENDIF

;Smooth flux
smoothingWidth = 5
smoothedFlux = SMOOTH(inputFlux,smoothingWidth)

;Find extrema
peakPositions = LIST()
peakAmplitudes = LIST()
numValues = N_ELEMENTS(inputFlux)
FOR i = (smoothingWidth+1), numValues-(smoothingWidth+1) DO BEGIN
    left = smoothedFlux[i-1]
    center = smoothedFlux[i]
    right = smoothedFlux[i+1]
    IF roilocator_isextremum(left,center,right) THEN BEGIN
        peakPositions.ADD, i
        peakAmplitudes.ADD, center
    ENDIF    
ENDFOR
peakPositionsArray = peakPositions.TOARRAY()
peakAmplitudesArray = peakAmplitudes.TOARRAY()

;Compute peak significance 
numPeaks = N_ELEMENTS(peakPositionsArray)
distanceMatrix = FLTARR(3,numPeaks-2)
FOR i = 1, numPeaks-2 DO BEGIN
    leftHorDist = peakPositionsArray[i] - peakPositionsArray[i-1] 
    rightHorDist = peakPositionsArray[i+1] - peakPositionsArray[i] 
    leftVertDist = ABS(peakAmplitudesArray[i] - peakAmplitudesArray[i-1])
    rightVertDist = ABS(peakAmplitudesArray[i] - peakAmplitudesArray[i+1])
    leftDistance = SQRT(leftHorDist^2 + leftVertDist^2)
    rightDistance = SQRT(rightHorDist^2 + rightVertDist^2)
    sumLeftRight = leftDistance + rightDistance
    diffLeftRight = ABS(leftDistance - rightDistance)
    distanceMatrix[0,i-1] = leftHorDist
    distanceMatrix[1,i-1] = rightHorDist
    distanceMatrix[2,i-1] = sumLeftRight * ABS(sumLeftRight/diffLeftRight) 
ENDFOR

;Sort peaks by signifigance
sortedDistanceIndices = REVERSE(SORT(distanceMatrix[2,*]))
sortedPeakPositions = peakPositionsArray[sortedDistanceIndices + 1]
FOR i = 0, 2 DO BEGIN
    distanceMatrix[i,*] = distanceMatrix[i,sortedDistanceIndices]
ENDFOR

;Define patch areas
numPatches = 5
patchesIndArray = LINDGEN(numPatches)
patchCenters = sortedPeakPositions[patchesIndArray]
patchPositions = LIST()
FOR i = 0, numPatches-1 DO BEGIN
    currentPatchSize = distanceMatrix[0,i] + distanceMatrix[1,i]
    currentPatchStart = sortedPeakPositions[i] - distanceMatrix[0,i]
    currentPatchPositions = LINDGEN(currentPatchSize,START=currentPatchStart)
    FOR j = 0, currentPatchSize-1 DO BEGIN
        patchPositions.ADD, currentPatchPositions[j]
    ENDFOR
ENDFOR
patchPositionsArray = patchPositions.TOARRAY()

;Sort list of patch positions
sortedPatchPositions = patchPositionsArray[SORT(patchPositionsArray)]

;Subset using unique positions 
uniquePatchPositions = sortedPatchPositions[UNIQ(sortedPatchPositions)]

;Create patched arrays
patchedPixels = LIST()
FOR i = 0, numValues DO BEGIN
    isPatch = WHERE(i EQ uniquePatchPositions, count)
    IF count EQ 0 THEN BEGIN
        patchedPixels.ADD, i
    ENDIF
ENDFOR
patchedPixelsArray = patchedPixels.TOARRAY()
patchedWavelengths = inputWavelength[patchedPixelsArray]
patchedFlux = inputFlux[patchedPixelsArray]

;Return patched arrays in structure
output = {roilocatorOutput, $
    flux    :   patchedFlux, $
    wavelength  :   patchedWavelengths}

RETURN, output
END
