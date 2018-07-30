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
;       FLUX    :   float array
;       WAVELENGTH  :   float array
; Author and history:
;       Daniel Hatcher, 2018
;-

;------------------------------------------------------------------------------
;
; Purpose: 
;       Test for local maximum or local minimum
;
FUNCTION roilocator_isextremum, inputLeft, inputCenter, inputRight

COMPILE_OPT IDL2

IF ((inputCenter GE inputLeft) AND (inputCenter GE inputRight)) THEN BEGIN
    ;Local maximum
    returnValue = 1B
ENDIF ELSE IF (inputCenter LE inputLeft) AND (inputCenter LE inputRight) THEN BEGIN
    ;Local minimum
    returnValue = 1B
ENDIF ELSE BEGIN
    ;Not an extremum
    returnValue = 0B
ENDELSE

RETURN, returnValue
END

;------------------------------------------------------------------------------
;
; Purpose:
;       Main routine
;
FUNCTION roilocator, FLUX=inputFlux, WAVE=inputWavelength, WIDTH=inputWidth, $
    PATCHES=inputPatches

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
IF NOT KEYWORD_SET(inputWidth) THEN BEGIN
    smoothingWidth = 6 
ENDIF ELSE BEGIN
    smoothingWidth = inputWidth
ENDELSE
smoothedFlux = SMOOTH(inputFlux,smoothingWidth,EDGE_TRUNCATE=1)

;Create list objects for dynamic allocation of peaks
peakPositions = LIST()
peakAmplitudes = LIST()
numValues = N_ELEMENTS(inputFlux)

;Find extrema
FOR i = (smoothingWidth+1), numValues-(smoothingWidth+1) DO BEGIN
    left = smoothedFlux[i-1]
    center = smoothedFlux[i]
    right = smoothedFlux[i+1]
    IF roilocator_isextremum(left,center,right) THEN BEGIN
        peakPositions.ADD, i
        peakAmplitudes.ADD, center
    ENDIF    
ENDFOR

;Convert list objects to arrays
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

;Sort peaks by significance
sortedDistanceIndices = REVERSE(SORT(distanceMatrix[2,*]))
sortedPeakPositions = peakPositionsArray[sortedDistanceIndices + 1]
FOR i = 0, 2 DO BEGIN
    distanceMatrix[i,*] = distanceMatrix[i,sortedDistanceIndices]
ENDFOR

;Define patch areas
IF NOT KEYWORD_SET(inputPatches) THEN BEGIN
    numPatches = 7
ENDIF ELSE BEGIN
    numPatches = inputPatches
ENDELSE
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

;Compute effective number of patches
effectivePatches = 0
FOR i = 0, N_ELEMENTS(patchedPixelsArray)-2 DO BEGIN
    IF patchedPixelsArray[i+1] - patchedPixelsArray[i] NE 1 THEN BEGIN
        effectivePatches = effectivePatches + 1
    ENDIF
ENDFOR

;Return patched arrays in structure
output = {$
    flux    :   patchedFlux, $
    pixels  :   patchedPixelsArray, $
    wave    :   patchedWavelengths, $
    missing :   inputWavelength[uniquePatchPositions], $
    missingpixels   :   uniquePatchPositions, $
    smoothflux  :   smoothedFlux, $
    numpatches  :   numPatches, $
    effectivepatches    :   effectivePatches, $
    smoothwidth   :   smoothingWidth}

RETURN, output
END
