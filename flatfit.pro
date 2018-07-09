FUNCTION flatfit, TEST = inputTest, FLAT = inputFlat, ORDER = inputOrder

;+
;Name:
;       flatfit       
;Purpose:
;       Calculate flat function using test and averaged flats
;Calling sequence:
;       f = flat(TEST=test,FLAT=flat)
;Input:
;       None
;Output:
;       flatfitOutput   :   structure
;Keywords:
;       TEST    :   array
;       FLAT    :   array
;       ORDER   :   integer (optional)
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2

IF NOT KEYWORD_SET(inputOrder) THEN BEGIN
    order = 10
    PRINT, 'Using default order 11 (index 1).'
ENDIF ELSE BEGIN
    order = inputOrder
ENDELSE 

subsetTest = inputTest[*,order]
subsetFlat = inputFlat[*,order]
medianFLat = MEDIAN(subsetFlat)
medianTest = MEDIAN(subsetTest)

;Normalize flat with median = 1
normalizedFlat = subsetFlat / medianFlat

;Divide test by normalized flat
testDivNormFlat = subsetTest / normalizedFlat

;Normalize divided test flat with median = 1
normDividedTest = testDivNormFlat / medianTest

pixels = LINDGEN(512)

;Find remaining variation
slope = REGRESS(pixels, normDividedTest, CONST=const)
fittedValues = const + pixels*slope[0]

;Flatten
flattened = normDividedTest / fittedValues

output = {flatfitOutput, $
    fits    :   fittedValues, $
    div     :   flattened, $
    normFlat    :   normalizedFlat, $
    slope   :   slope}

RETURN, output
END 
