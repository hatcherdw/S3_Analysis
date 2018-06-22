PRO locateflat, DATE=inputDate, NUMFLATS=inputNumFlats

;Given the date of a frame, find the flat(s) that are closest in time.
;User can specify how many flats to locate. 
;Default is flat(s) occuring within 7 days. 

;Read flat dates and frame numbers from list
flatList = '/home/hatcher/Lists/flat_list_new_CCD.txt'
OPENR,logicalUnitNumber, flatList, /GET_LUN
numLines = FILE_LINES(flatList)
line = ''
dates = LIST()
frames = LIST()
FOR i = 0, numLines-1 DO BEGIN
    READF, logicalUnitNumber, line
    firstCharacter = STRMID(line,0,1)
    IF STRCMP(firstCharacter,'#') EQ 0 THEN BEGIN
        dates.ADD, STRMID(line,0,10)
        frames.ADD, STRMID(line,13,5)       
    ENDIF
ENDFOR 
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

;Select flat(s) with nearest date(s)
sortedDiffJulDates = SORT(diffJulDates)
sortedFramesArray = framesArray[sortedDiffJulDates]
lessThanWeek = WHERE(diffJulDates LT 7,count)
lessThanWeekFrames = framesArray[lessThanWeek] 
IF KEYWORD_SET(inputNumFlats) THEN BEGIN
    nearest = LONARR(inputNumFlats)
    nearestIndex = LINDGEN(inputNumFlats)
    nearest = sortedFramesArray[nearestIndex]
    count = inputNumFlats
    PRINT, nearest
ENDIF ELSE BEGIN
    nearest = lessThanWeekFrames
    numFlats = STRING(count)
    PRINT, 'Found ' + numFlats.TRIM() + ' flat frames within one week of ' + $
        inputDate
    PRINT, nearest
ENDELSE

END
