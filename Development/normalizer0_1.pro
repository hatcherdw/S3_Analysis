;-------------------------------------------------------------------------------
;
;       Preferences
;
PRO preferences

COMPILE_OPT IDL2

;Directory containing flat list
flatListDir = '/home/central/hatch1dw/Programs/S3_Analysis/'
;Flat list filename 
flatListFile = 'flat_list_new_CCD.txt'

;Directory containing flats
flatDir = '/storage/hatch1dw/RAW-FLATS-ALL-NEW-CCD/'

;Directory containing frames
frameDir = '/storage/hatch1dw/NEW-CCD-all-orders-data/'

DEFSYSV, '!FLATLIST', flatListDir + flatListFile, 1
DEFSYSV, '!FLATDIR', flatDir, 1
DEFSYSV, '!FRAMEDIR', frameDir, 1

END

;-------------------------------------------------------------------------------
;
;       Julian date converter
;
FUNCTION juldate, inputDate

COMPILE_OPT IDL2

;Check input type
IF STRCMP(SIZE(inputDate,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Input date is not of type STRING!'
ENDIF

;Check input length
IF STRLEN(inputDate) NE 10 THEN BEGIN
    MESSAGE, 'Input date is not 10 characters long!'
ENDIF

;Expected format: YYYY-MM-DD
year = STRMID(inputDate,0,4)
month = STRMID(inputDate,5,2)
day = STRMID(inputDate,8,2)

julianDate = JULDAY(month,day,year)

RETURN, julianDate

END

;-------------------------------------------------------------------------------
;
;       Locate flat
;
FUNCTION locateflat, DATE=inputDate

COMPILE_OPT IDL2

;Check input existence and type
IF NOT KEYWORD_SET(inputDate) THEN BEGIN
    MESSAGE, 'Please provide input date!'
ENDIF ELSE IF STRCMP(SIZE(inputDate,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Input is not of type STRING!'
ENDIF

;Read flat dates and frame numbers from list
OPENR, logicalUnitNumber, !FLATLIST, /GET_LUN
numLines = FILE_LINES(!FLATLIST)

line = ''
dates = LIST()
frames = LIST()
FOR i = 0, numLines-1 DO BEGIN
    READF, logicalUnitNumber, line
    firstCharacter = STRMID(line,0,1)
    ;Ignore comments and first line
    IF STRCMP(firstCharacter,'#') EQ 0 AND STRLEN(line) GT 0 THEN BEGIN
        dates.ADD, STRMID(line,0,10)
        frames.ADD, STRMID(line,13,5)
    ENDIF
ENDFOR
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber
datesArray = dates.TOARRAY()
framesArray = frames.TOARRAY()

;Convert flat dates to JD
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
flat = sortedFramesArray[0]

RETURN, flat

END

;-------------------------------------------------------------------------------
;
;       Read flat
;
FUNCTION readflat, FRAME = inputFrame

COMPILE_OPT IDL2

;Check input existence and type
IF KEYWORD_SET(inputFrame) THEN BEGIN
    type = SIZE(inputFrame,/TNAME)
    isString = STRCMP(type,'STRING')
    IF NOT isString THEN BEGIN
        MESSAGE, 'Input is not of type STRING!'
    ENDIF
ENDIF ELSE BEGIN
    MESSAGE, 'Please provide input frame number!'
ENDELSE

;Specify path
extension = '.RAW.spec'
path = !FLATDIR + inputFrame + extension

;Check if old or new CCD
;Frame 22684 first with new CCD
IF LONG(inputFrame) GE 22684 THEN BEGIN
    ;NEW CCD
    flatData = FLTARR(512,16)
ENDIF ELSE BEGIN
    ;OLD CCD
    flatData = UINTARR(512,16)
    PRINT, 'Frame number indicates old CCD.'
ENDELSE

;Read flat flux data
OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;Smooth flux
smoothWidth = 10
smoothFlux = SMOOTH(flatData,smoothWidth,EDGE_TRUNCATE=1)

;Normalize using median (useful for Flats and test flats)
;Each order normalized separately
normFlux = FLTARR(512,16)
normSmoothFlux = FLTARR(512,16)
FOR i = 0, 15 DO BEGIN
    medianValue = MEDIAN(flatData[*,i])
    normFlux[*,i] = flatData[*,i] / medianValue
    medianSmoothValue = MEDIAN(smoothFlux[*,i])
    normSmoothFlux[*,i] = smoothFlux[*,i] / medianSmoothValue
ENDFOR

;Output
output = {readflatOutput, $
    flux    :   flatData, $
    normflux    :   normFlux, $
    smoothflux  :   smoothFlux, $
    normsmooth  :   normSmoothFlux, $
    smoothwidth :   smoothWidth, $
    frame   :   inputFrame}

RETURN, output

END

;-------------------------------------------------------------------------------
;
;       Filter
;
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

;-------------------------------------------------------------------------------
;
;       Peak finder
;

;Name:
;       zscorepeaks
; Purpose:
;       Robust thresholding algorithm
; Calling sequence:
;       Result = zscorepeaks(DATA=array,LAG=integer,T=float,INF=float)
; Positional parameters:
;       inputData
; Output:
;       signals :   Array of peak (+1) and valley (-1) positions
; Keyword parameters:
;       LAG     :   Size of moving average window
;       T       :   Threshold z-score for signal
;       INF     :   Influence of singal on mean and standard deviation
;                   If 0, signals are excluded from moving average
;                   If 1, signals are merely flagged, not excluded
;      SCREEN   :   screen output flag
; Author and history:
;       Jean-Paul van Brakel, 2014  :   Algorithm construction (StackOverflow)
;       Daniel Hatcher, 2018    :   IDL implementation
;-

FUNCTION zscorepeaks,inputData,LAG=inputLag,T=inputT,INF=inputInf, $
    SCREEN=inputScreen

COMPILE_OPT IDL2

num = N_ELEMENTS(inputData)

IF inputLag LT num THEN BEGIN
    ;Allocations
    signals = LONARR(num)
    avgFilter = FLTARR(num)
    stdFilter = FLTARR(num+1)

    ;Not dealing with realtime data, so filtered array does not need to be
    ;allocated dynamically.
    filtered = FLTARR(num)

    ;Initializations
    filtered[0:inputLag] = inputData[0:inputLag]
    avgFilter[inputLag] = MEAN(inputData[0:inputLag])
    stdFilter[inputLag] = STDDEV(inputData[0:inputLag])

    ;Exclude initial lagged values from signal array
    signals[0:inputLag-1] = -2

    ;Signal calculation
    FOR i = inputLag+1, num-1 DO BEGIN
        diff = ABS(inputData[i]-avgFilter[i-1])
        IF diff GT inputT*stdFilter[i-1] THEN BEGIN
            IF inputData[i] GT avgFilter[i-1] THEN BEGIN
                ;Positive signal
                signals[i] = 1
            ENDIF ELSE BEGIN
                ;Negative signal
                signals[i] = -1
            ENDELSE
            ;Change influence of signal
            filtered[i] = inputInf*inputData[i] + (1-inputInf)*filtered[i-1]
        ENDIF ELSE BEGIN
            ;No signal
            signals[i] = 0
            filtered[i] = inputData[i]
        ENDELSE
        ;Adjust filters
        avgFilter[i] = MEAN(filtered[i-inputLag:i])
        stdFilter[i] = STDDEV(filtered[i-inputLag:i])
    ENDFOR

    ;Upper and lower thresholds
    upper = avgFilter+InputT*stdFilter
    lower = avgFilter-InputT*stdFilter

    ;Use NaNs for cleaner plotting of lagged values
    upper[0:inputLag] = !VALUES.F_NAN
    lower[0:inputLag] = !VALUES.F_NAN

ENDIF ELSE BEGIN
    ;If input is smaller than lag, find outliers without moving
    signals = LONARR(num)
    avgFilter = MEAN(inputData)
    stdFilter = STDDEV(inputData)
    upper = FLTARR(num)
    lower = FLTARR(num)

    ;Positive outliers
    signals[WHERE(inputData GT avgFilter+stdFilter, /NULL)] = 1

    ;Negative outliers
    signals[WHERE(inputData LT avgFilter-stdFilter, /NULL)] = -1

    upper[*] = avgFilter+InputT*stdFilter
    lower[*] = avgFilter-InputT*stdFilter
ENDELSE

;Plotting
IF KEYWORD_SET(inputScreen) THEN BEGIN
    IF inputScreen EQ 1 THEN BEGIN
        !P.MULTI = [0,2,1,0,0]
        PLOT, inputData, title = 'Data', PSYM=3
        OPLOT, avgFilter
        OPLOT, upper
        OPLOT, lower
        PLOT, signals, title = 'Signals', yrange=[-1.5,1.5]
    ENDIF
ENDIF

output = {$
    signals :   signals, $
    upper  :   upper, $
    lower  :   lower, $
    avg :   avgFilter}

RETURN, output

END

;-------------------------------------------------------------------------------
;
;       Centroid finder
;

FUNCTION centroid, inputFlux, frame, SCREEN=inputScreen

COMPILE_OPT IDL2

sFlux = filter(inputFlux,5,TYPE='median')

;Find extreme values
roi = LINDGEN(150,START=250)
minFlux = MIN(sFlux[roi],minInd)
maxFlux = MAX(sFlux[roi],maxInd)
minInd = roi[minInd]
maxInd = roi[maxInd]

;How extreme?
minDist = ABS(1.0 - minFlux)
maxDist = ABS(1.0 - maxFlux)

;Choose most extreme
IF maxDist GT minDist THEN BEGIN
    extreme = maxInd
ENDIF ELSE IF minDist GT maxDist THEN BEGIN
    extreme = minInd
ENDIF

limit = 0.45*ABS(sFlux[extreme]-1.0)

;Find first point beyond limit
FOR i = 0, extreme DO BEGIN
    IF ABS(sFlux[i]-1.0) GT limit THEN BEGIN
        leftStop = i
        BREAK
    ENDIF
ENDFOR
FOR j = N_ELEMENTS(sFlux)-1, extreme, -1 DO BEGIN
    IF ABS(sFlux[j]-1.0) GT limit THEN BEGIN
        rightStop = j
        BREAK
    ENDIF
ENDFOR

;Wing pixel locations
length = 512 - rightStop
left = LINDGEN(length,START=leftStop-length)
right = LINDGEN(length,START=rightStop)

fluxLeft = sFlux[left]
fluxRight = SFlux[right]

;Turn off math error reporting to suppress benign underflow error messages
;that sometimes occur when fitting gaussian
currentExcept = !EXCEPT
!EXCEPT = 0

;Flush current math error register
void = CHECK_MATH()

;Flush current math error register
void = CHECK_MATH()

;Fit single gaussian
fit = GAUSSFIT([left,right],[fluxLeft,fluxRight],A,NTERMS=5)

;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;Report any other math errors
    MESSAGE, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)
ENDIF

;Restore original reporting condition
!EXCEPT = currentExcept

;Resampling
range = right[-1]-left[0]
xsamples = FINDGEN(range,START=left[0])
PRINT, xsamples
z = (xsamples - A[1])/A[2]
rfit = A[0]*exp((-(z^2))/2) + A[3] + A[4]*xsamples

centroid = A[1]

IF KEYWORD_SET(inputScreen) AND inputScreen EQ 1 THEN BEGIN
    ;PLOT, sFlux,title=frame, PSYM=4
    PLOT, left, sFlux[left], PSYM=4, xrange=[MIN(left),MAX(right)],title=frame
    OPLOT, right, sFlux[right], PSYM=4
    ;OPLOT, [centroid,centroid],[MIN(inputFlux),MAX(inputFlux)]
    OPLOT, xsamples,rfit
ENDIF

output = {$
    centroid    :   centroid, $
    left    :   left, $
    right   :   right, $
    const   :   A[3]}

RETURN, output

END

;-------------------------------------------------------------------------------
;
;       Normalize
;

;+
; Name:
;       normalize
; Purpose:
;       Automated continuum normalization
; Calling sequence:
;       Result = normalize(wave,flux,pixelHa)
; Positional parameters:
;       wave    :   array of wavelengths
;       flux :   array of flattened fluxes
;       pixelHa :   pixel nearest Ha (656.28 nm)
; Output:
;       output  :   structure
; Keyword parameters:
;       WIDTH   :   Red zone width
;       SCREEN  :   Screen output?
; Author and history:
;       C.A.L. Bailer-Jones et al., 1998    :  Filtering algorithm
;       Daniel Hatcher, 2018    :   IDL implementation and patching automation
;-

FUNCTION normalize, wave, flux, pixelHa, frame, WIDTH=inputWidth, $
    SCREEN=inputScreen

COMPILE_OPT IDL2

;If width not specified, search
IF NOT KEYWORD_SET(inputWidth) THEN BEGIN
    ;Search for left and right shoulder of Ha feature
    ;Maximum search distance beyond Ha
    searchWidth = 100

    ;Buffer around Ha core not to be searched
    coreBuffer = 20

    ;Create search indices
    leftSearch = LINDGEN(searchWidth-coreBuffer,START=pixelHa-searchWidth)
    ;Search starting from right end of spectrum (reversed)
    rightSearch = REVERSE(LINDGEN(searchWidth-coreBuffer, $
        START=pixelHa+coreBuffer))

    ;Search blue (left) side of Ha
    leftResult = zscorepeaks(flux[leftSearch],LAG=10,T=1.5,INF=0.1)

    ;Search red (right) side of Ha
    rightResult = zscorepeaks(flux[rightSearch],LAG=10,T=1.5,INF=0.1)

    ;Find first position of last signal (blue side of Ha)
    FOR i = N_ELEMENTS(leftSearch)-1,0,-1 DO BEGIN
        lastValue = leftResult.signals[-1]
        IF leftResult.signals[i] NE lastValue THEN BEGIN
            leftShoulder = leftSearch[i]
            BREAK
        ENDIF
    ENDFOR

    ;Find first position of last signal (red side of Ha)
    FOR i = N_ELEMENTS(rightSearch)-1,0,-1 DO BEGIN
        lastValue = rightResult.signals[-1]
        IF rightResult.signals[i] NE lastValue THEN BEGIN
            rightShoulder = rightSearch[i]
            BREAK
        ENDIF
    ENDFOR

    ;Choose largest width
    width = MAX([(rightShoulder-pixelHa),(pixelHa-leftShoulder)])
ENDIF ELSE BEGIN
    ;If specified, use input width
    width = inputWidth
ENDELSE

;If width is very large, warn user
limit = 10
IF N_ELEMENTS(flux)-width LT limit THEN BEGIN
    limString = STRTRIM(STRING(limit),2)
    PRINT, "Less than "+limString+" pixels on red end of spectrum!"
ENDIF

;Remove Ha feature
totalPixels = N_ELEMENTS(flux)
leftPixels = LINDGEN(pixelHa-width)
rightPixels = LINDGEN(totalPixels-(pixelHa+width),START=pixelHa+width)
patchedPixels = LINDGEN((width*2)+1,START=pixelHa-width)

;Median filter left and right separately
medianWidth = 50
medianLeft = filter(flux[leftPixels],medianWidth,TYPE='median')
medianRight = filter(flux[rightPixels],medianWidth, $
    TYPE='median')

;Reposition filtered arrays
separated = FLTARR(totalPixels)
separated[leftPixels] = medianLeft
separated[rightPixels] = medianRight

;Interpolate across red region
joinedPixels = [leftPixels,rightPixels]
medianFlux = [medianLeft,medianRight]
interpolated = FLTARR(N_ELEMENTS(patchedPixels))
nLeft = N_ELEMENTS(leftPixels)
endPoints = [nLeft-1,nLeft]
slope = REGRESS(joinedPixels[endPoints],medianFlux[endPoints],CONST=const)
interpolated = const + patchedPixels*slope[0]
separated[patchedPixels] = interpolated

;Boxcar filter
boxWidth = 25
boxFlux = filter(separated,boxWidth,TYPE='mean')

continuum = boxFlux

normalized = flux/continuum

;Output to screen?
IF KEYWORD_SET(inputScreen) THEN BEGIN
    IF inputScreen EQ 1 THEN BEGIN
        !P.MULTI = [0,1,2,0,0]

        ;Colors
        DEVICE, DECOMPOSED=0
        LOADCT, 39, /SILENT

        titleText = frame+" Width: "+STRTRIM(STRING(width),2)
        PLOT, wave,flux,PSYM=3,title=titleText,xtitle='Wavelength (nm)', $
            ytitle='Flattened Flux',yrange=[MIN(continuum),MAX(continuum)]
        OPLOT, wave[leftPixels],continuum[leftPixels]
        OPLOT, wave[rightPixels],continuum[rightPixels]
        OPLOT, wave[patchedPixels],continuum[patchedPixels],LINESTYLE=2
        OPLOT, [wave[pixelHa-width],wave[pixelHa-width]],[MIN(flux),MAX(flux)]
        OPLOT, [wave[pixelHa+width],wave[pixelHa+width]],[MIN(flux),MAX(flux)]
        PLOT, wave,normalized,xtitle='Wavelength (nm)', $
            ytitle='Normalized Flux',yrange=[0.9,1.1]
        OPLOT, wave[patchedPixels],normalized[patchedPixels],COLOR=250
        OPLOT, [wave[0],wave[-1]],[0.99,0.99],LINESTYLE=1
        OPLOT, [wave[0],wave[-1]],[1.01,1.01],LINESTYLE=1
        OPLOT, [wave[0],wave[-1]],[0.98,0.98],LINESTYLE=2
        OPLOT, [wave[0],wave[-1]],[1.02,1.02],LINESTYLE=2
        OPLOT, [wave[0],wave[-1]],[0.97,0.97]
        OPLOT, [wave[0],wave[-1]],[1.03,1.03]
    ENDIF
ENDIF

;Output structure
output = {$
    continuum   :   continuum, $
    normalized  :   normalized, $
    width   :   width, $
    patch   :   patchedPixels, $
    notpatch:   joinedPixels, $
    ends    :   joinedPixels[endPoints]}

RETURN, output

END

;-------------------------------------------------------------------------------
;
;       Main
;

;+
; Name:
;       normalizer
; Purpose:
;       Continuum normalization of H-alpha SSS orders
; Calling sequence:
;       Result = normalizer(inputFlux,inputWave,inputDate,inputFrame,
;       [,PRENORM=integer][,WIDTH=integer][,NORMSCREEN=binary]
;       [,DIAGSCREEN=binary][,OUTFILE=string])
; Positional parameters:
;       inputFlux   :   512xn array, where n is number of extracted orders
;       inputWave   :   512xn array, where n is number of extracted orders
;       inputDate   :   Date fromatted as YYYY-MM-DD
;       inputFrame  :   string frame number
; Optional parameters (keywords):
;       PRENORM     :   order used for prenormalization
;       WIDTH       :   width of H-alpha feature
;       NORMSCREEN  :   binary output flag for normalization plots
;       DIAGSCREEN  :   binary output flag for diagnostic plots
;       OUTFILE     :   path to output file (PostScript)
; Output:
;
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION normalizer,inputFlux,inputWave,inputDate,inputFrame,PRENORM=prenorm,$
    WIDTH=inputWidth,NORMSCREEN=normScreen,DIAGSCREEN=diagScreen,OUTFILE=outFile

COMPILE_OPT IDL2

;Zero indexed order
order = 10

;Ha lab frame wavelength
Ha = 656.28

flux = inputFlux[*,order]
wave = inputWave[*,order]
flat = readflat(frame=locateflat(date=inputDate))
flatDiv = flux / flat.normsmooth[*,order]

;Prenormalization with nearby order
IF KEYWORD_SET(prenorm) THEN BEGIN
    IF order EQ prenorm THEN BEGIN
        MESSAGE, 'Order and prenorm-order equal!'
    ENDIF ELSE BEGIN
        prenormDiv = flux[*,prenorm] / flat.normsmooth[*,prenorm]
        prenormMedDiv = prenormDiv / MEDIAN(prenormDiv)
        prenormSmooth = filter(prenormMedDiv,50,TYPE='median')
        prenormalized = flatDiv / prenormSmooth
        flatDiv = prenormalized
    ENDELSE
ENDIF

distance = ABS(wave - Ha)
minDistance = MIN(distance,pixelHa)

;If an outfile is provided, output normalization plots by default
IF KEYWORD_SET(outFile) THEN BEGIN
    SET_PLOT, 'ps'
    DEVICE, /COLOR, BITS_PER_PIXEL=8
    DEVICE, XSIZE=7, YSIZE=10, XOFFSET=0.5, YOFFSET=0.5, /INCHES
    DEVICE, FILENAME = outFile
    IF KEYWORD_SET(inputWidth) THEN BEGIN
        normalized = normalize(wave,flatDiv,pixelHa,inputFrame,$ 
            WIDTH=inputWidth,SCREEN=1)
    ENDIF ELSE BEGIN
        normalized = normalize(wave,flatDiv,pixelHa,inputFrame,$
            SCREEN=1) 
    ENDELSE
    DEVICE, /CLOSE_FILE
;If not outfile provided, follow normscreen keyword
ENDIF ELSE BEGIN
    IF KEYWORD_SET(inputWidth) THEN BEGIN
        normalized = normalize(wave,flatDiv,pixelHa,inputFrame,$ 
            WIDTH=inputWidth,SCREEN=normScreen)
    ENDIF ELSE BEGIN
        normalized = normalize(wave,flatDiv,pixelHa,inputFrame,$
            SCREEN=normScreen) 
    ENDELSE
ENDELSE

RETURN, normalized.normalized

END

