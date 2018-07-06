FUNCTION juldate, inputDate, julianDate

;+
; Name:
;       juldate
; Purpose:
;       Compute Julian date using dates as formatted in SSS logs 
; Calling sequence:
;       juldate, inputDate     
; Input:
;       inputDate   :   string formatted YYYY-MM-DD
; Output:
;       julianDate  :   integer   
; Keywords:
;       None
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2

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
