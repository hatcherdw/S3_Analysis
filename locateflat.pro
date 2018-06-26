FUNCTION locateflat, DATE=inputDate

;Given the date of a frame, find the flat that is closest in time.

;Read flat dates and frame numbers from list
OPENR, logicalUnitNumber, !FLATLIST, /GET_LUN
numLines = FILE_LINES(!FLATLIST)
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
RETURN, sortedFramesArray[0]

END
