;Boolean function to test for local maximum or local minimum
FUNCTION isextremum, inputLeft, inputCenter, inputRight

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
