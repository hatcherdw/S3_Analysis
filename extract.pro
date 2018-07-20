FUNCTION extract, GRAFT = inputGraft, MAP = inputMap

COMPILE_OPT IDL2

;Check for rasterized order map
IF KEYWORD_SET(inputMap) THEN BEGIN
    mapType = SIZE(inputMap, /TNAME)
    isLong = STRCMP(mapType,'LONG')
    IF NOT isLong THEN BEGIN
        MESSAGE, 'Input map is not of type LONG!'
    ENDIF 
ENDIF

;Initialize matrix of extracted flux values
extracted = FLTARR(512,16)

;Extract and store 
FOR i = 0, 511 DO BEGIN
    FOR j = 0, 15 DO BEGIN
        row = inputMap[i,j]
        value = inputGraft[i,row]
        extracted[i,j] = value
    ENDFOR
ENDFOR

;Output
RETURN, extracted

END
