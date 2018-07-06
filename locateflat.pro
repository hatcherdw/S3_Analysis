FUNCTION locateflat, DATE=inputDate

;+
; Name:
;       locateflat
; Purpose:
;       Given the date of a frame, find the flat that is closest in time
; Calling sequence:
;       flat = locateflat(DATE=date)
; Input:
;       None
; Output:
;       flat    :   string frame number   
; Keywords:
;       inputDate   :   string YYYY-MM-DD
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2

IF NOT KEYWORD_SET(inputDate) THEN BEGIN
    MESSAGE, 'Calling sequence is flat = locateflat(DATE=date)'
ENDIF ELSE IF STRCMP(SIZE(inputDate,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Input is not of type STRING!'
ENDIF

;Read flat dates and frame numbers from list
IF sysvarexists('!FLATLIST') THEN BEGIN
    OPENR, logicalUnitNumber, !FLATLIST, /GET_LUN
    numLines = FILE_LINES(!FLATLIST)
ENDIF
line = ''
dates = LIST()
frames = LIST()
FOR i = 0, numLines-1 DO BEGIN
    READF, logicalUnitNumber, line
    firstCharacter = STRMID(line,0,1)
    IF STRCMP(firstCharacter,'#') EQ 0 AND STRLEN(line) GT 0 THEN BEGIN
        dates.ADD, STRMID(line,0,10)
        frames.ADD, STRMID(line,13,5)       
    ENDIF
ENDFOR 
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber
datesArray = dates.TOARRAY()
framesArray = frames.TOARRAY() 

;Convert flat dates
numDates = N_ELEMENTS(datesArray)
julianDatesArray = STRARR(numDates)
FOR i = 0, numDates-1 DO BEGIN
    julianDatesArray[i] = juldate(datesArray[i])
ENDFOR

;Convert input date to Julian date
julianDate = juldate(inputDate)

;Compare dates
diffJulDates = LONARR(numDates)
FOR i = 0, numDates-1 DO BEGIN
    diffJulDates[i] = ABS(julianDate - julianDatesArray[i])
ENDFOR

;Select flat with nearest date
sortedDiffJulDates = SORT(diffJulDates)
sortedFramesArray = framesArray[sortedDiffJulDates]
flat = sortedFramesArrray[0]
RETURN, flat

END
