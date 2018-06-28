FUNCTION sysvarexists, inputSysVar, output

DEFSYSV, inputSysVar, EXISTS=i
IF i EQ 1 THEN BEGIN
    output = 1B
ENDIF ELSE IF i EQ 0 THEN BEGIN
    output = 0B
    MESSAGE, 'System variable ' + inputSysVar + ' does not exist! Check' + $
        ' preferences and startup files.'
ENDIF

RETURN, output
END
