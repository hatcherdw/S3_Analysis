; Name:
;       filter
; Purpose:
;       Apply smoothing with edge truncation
; Calling sequence:
;       result = filter(array,width,TYPE='type')
; Positional parameters:
;       array   :   array to be filtered
;       width   :   filtering width
; Output:
;       output  :   structure
; Keyword parameters:
;       TYPE    :   type of filter    
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION filter, array, width, TYPE=type

COMPILE_OPT IDL2

num = N_ELEMENTS(array)
output = FLTARR(num)

;First and last elements will not be filtered, so just output them
output[0] = array[0]
output[-1] = array[-1]

IF KEYWORD_SET(type) THEN BEGIN
    type = STRLOWCASE(type)
ENDIF ELSE BEGIN
    MESSAGE, 'Filter type not provided!'
ENDELSE

FOR i = 1, num-2 DO BEGIN
    ;Edge truncate left
    IF i LT width/2 THEN BEGIN
        filterWindow = LINDGEN(2*i)
    ;Edge truncate right
    ENDIF ELSE IF i+width/2 GT num THEN BEGIN
        diff = num-i
        filterWindow = LINDGEN(2*diff,START=i-diff)
    ;No truncation
    ENDIF ELSE BEGIN
        filterWindow = LINDGEN(width,START=i-width/2)
    ENDELSE
    IF STRCMP(type,'median') EQ 1 THEN BEGIN
        output[i] = MEDIAN(array[filterWindow])
    ENDIF ELSE IF STRCMP(type,'mean') EQ 1 THEN BEGIN
        output[i] = MEAN(array[filterWindow])
    ENDIF 
ENDFOR

RETURN, output

END
