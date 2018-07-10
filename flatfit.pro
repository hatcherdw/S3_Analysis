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

;Fit linear or linear and quad 
allPixels = LINDGEN(512)
firstOrder = REGRESS(allPixels,normDividedTest,CONST=const)
IF firstOrder[0] GE 0.0 THEN BEGIN
    fittedValues = const + allPixels*firstOrder[0]
    breakPixel = 0
ENDIF ELSE BEGIN
    breakPixel = 410
    linearPixels = allPixels[0:breakPixel-1]
    linearFlux = normDividedTest[0:breakPixel-1]
    quadPixels = allPixels[breakPixel:*]
    quadFlux = normDividedTest[breakPixel:*]
    slope = REGRESS(linearPixels,linearFlux,CONST=const)
    linearFit = const + linearPixels*slope[0]
    quadCoeff = POLY_FIT(quadPixels,quadFlux,2,YFIT=quadFit)
    fittedValues = [linearFit, quadFit]
ENDELSE

output = {flatfitOutput, $
    fits    :   fittedValues, $
    normFlat    :   normalizedFlat, $
    normTest    :   normDividedTest, $
    breakpixel  :   breakPixel}

RETURN, output

END 
