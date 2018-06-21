FUNCTION juldate, inputDate, julianDate

;Compute Julian date using dates as formatted in the SSS logs
;Format: YYYY-MM-DD

;Check input type
IF STRCMP(SIZE(inputDate,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Input date is not of type STRING!'
ENDIF

;Check input length
IF STRLEN(inputDate) NE 10 THEN BEGIN
    MESSAGE, 'Input date is not 10 characters long!'
ENDIF 

year = STRMID(inputDate,0,4)
month = STRMID(inputDate,5,2)
day = STRMID(inputDate,8,2)

julianDate = JULDAY(month,day,year)

RETURN, julianDate
END
