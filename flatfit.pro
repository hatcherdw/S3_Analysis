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

;Normalize flat with median
normalizedFlat = subsetFlat / medianFlat

;Divide test by normalized flat
testDivNormFlat = subsetTest / normalizedFlat

;Normalize divided test flat with median 
medianTest = MEDIAN(subsetTest)
normDividedTest = testDivNormFlat / medianTest

;Fit polynomial to ratios
pixels = LINDGEN(512)
coeffs = POLY_FIT(pixels,normDividedTest,5,YFIT=fittedValues)
residuals = normDividedTest - fittedValues

output = {flatfitOutput, $
    fits        :   fittedValues, $
    normFlat    :   normalizedFlat, $
    divided     :   normDividedTest, $
    coeffs      :   coeffs, $
    residuals   :   residuals}      

RETURN, output

END 
