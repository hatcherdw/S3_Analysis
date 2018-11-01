;;------------------------------------------------------------------------------
;;
;;       Preferences
;;

;;+
;;Name:
;;      preferences
;;Purpose:
;;      Define system variables
;;Calling sequence:
;;      preferences
;;Positional parameters:
;;      None
;;Keyword parameters:
;;      None
;;Output:
;;      None
;;Author and history:
;;      Daniel Hatcher, 2018
;;Notes:
;;      Expected format for flat list
;;      #Date         Frame
;;      YYYY-MM-DD    12345
;;-

PRO preferences

COMPILE_OPT IDL2

;;Directory containing flat list
flatListDir = '/home/central/hatch1dw/Programs/S3_Analysis/'

;;Flat list filename 
flatListFile = 'flat_list_new_CCD.txt'

;;Directory containing flats
flatDir = '/storage/hatch1dw/RAW-FLATS-ALL-NEW-CCD/'

;;Directory containing frames
frameDir = '/storage/hatch1dw/NEW-CCD-all-orders-data/'

;;Define read-only system variables
DEFSYSV, '!FLATLIST', flatListDir + flatListFile, 1
DEFSYSV, '!FLATDIR', flatDir, 1
DEFSYSV, '!FRAMEDIR', frameDir, 1

END

;;------------------------------------------------------------------------------
;;
;;      Locate flat
;;

;;+
;;Name:
;;      locateflat
;;Purpose:
;;      Locate flat frame number using date and flat list in preferences
;;Calling sequence:
;;      Reuslt = locateflat(inputDate)
;;Positional parameters:
;;      inputDate   :   string formatted YYYY-MM-DD   
;;Keyword parameters:
;;      None
;;Output:
;;      flat    :   string frame number of length 5
;;Author and history:
;;      Daniel Hatcher, 2018
;;-

FUNCTION locateflat, inputDate

COMPILE_OPT IDL2

;;Check input
IF STRCMP(SIZE(inputDate,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Input is not of type STRING!'
ENDIF
IF STRLEN(inputDate) NE 10 THEN BEGIN
    MESSAGE, 'Input is not 10 characters long!'
ENDIF 

;;Read flat dates and frame numbers from list
OPENR, logicalUnitNumber, !FLATLIST, /GET_LUN
numLines = FILE_LINES(!FLATLIST)

line = ''
locateError = 1B
FOR i = 0, numLines-1 DO BEGIN
    READF, logicalUnitNumber, line
    firstCharacter = STRMID(line,0,1)
    ;;Skip comments and empty lines
    IF STRCMP(firstCharacter,'#') EQ 0 AND STRLEN(line) GT 0 THEN BEGIN
        flatDate = STRMID(line,0,10)
        flatFrame = STRMID(line,13,5)
        IF STRCMP(flatDate,inputDate) EQ 1 THEN BEGIN
            locateError = 0B
            BREAK        
        ENDIF
    ENDIF
ENDFOR
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

IF locateError THEN BEGIN
    MESSAGE, "Flat for date "+inputDate+" not found!"
ENDIF

RETURN, flatFrame

END

;;------------------------------------------------------------------------------
;;
;;      Read flat
;;

;;+
;;Name:
;;      readflat
;;Purpose:
;;      Read, smooth, and normalize flat
;;Calling sequence:
;;      Result = readflat(inputFrame)
;;Positional parameters:
;;      inputFrame  :   String of length 5
;;Keyword parameters:
;;      None
;;Output:
;;      output  :   structure with tags:
;;          flux        :   512x16 raw flat data    
;;          normflux    :   512x16 median normalized flux
;;          smoothflux  :   512x16 smoothed flux
;;          normsmooth  ;   512x16 median normalized, smoothed flux
;;Author and history:
;;      Daniel Hatcher, 2018
;;-

FUNCTION readflat, inputFrame

COMPILE_OPT IDL2

;;Check input
IF STRCMP(SIZE(inputFrame,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Input is not of type STRING!'
ENDIF
IF STRLEN(inputFrame) NE 5 THEN BEGIN
    MESSAGE, 'Input is not 5 characters long!'
ENDIF 

;;Specify path
extension = '.RAW.spec'
path = !FLATDIR + inputFrame + extension

;;Check if old or new CCD
;;Frame 22684 first with new CCD
IF LONG(inputFrame) GE 22684 THEN BEGIN
    ;;NEW CCD
    flatData = FLTARR(512,16)
ENDIF ELSE BEGIN
    ;;OLD CCD
    flatData = UINTARR(512,16)
    PRINT, 'Frame number indicates old CCD.'
ENDELSE

;;Read flat flux data
OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

;;Smooth flux
smoothWidth = 10
smoothFlux = SMOOTH(flatData,smoothWidth,EDGE_TRUNCATE=1)

;;Normalize using median
;;Each order normalized separately
normFlux = FLTARR(512,16)
normSmoothFlux = FLTARR(512,16)
FOR i = 0, 15 DO BEGIN
    medianValue = MEDIAN(flatData[*,i])
    normFlux[*,i] = flatData[*,i] / medianValue
    medianSmoothValue = MEDIAN(smoothFlux[*,i])
    normSmoothFlux[*,i] = smoothFlux[*,i] / medianSmoothValue
ENDFOR

;;Output
output = {readflatOutput, $
    flux    :   flatData, $
    normflux    :   normFlux, $
    smoothflux  :   smoothFlux, $
    normsmooth  :   normSmoothFlux}

RETURN, output

END

;;------------------------------------------------------------------------------
;;
;;      Filter
;;

;;+
;;Name:
;;      filter
;;Purpose:
;;      1D boxcar smoothing with adaptive-width edge truncation
;;Calling sequence:
;;      Result = filter(inputArray,inputWidth,TYPE=string) 
;;Positional parameters:
;;      inputArray   :   values to be smoothed, 1D
;;      inputWidth   :   width of boxcar
;;Keyword parameters:
;;      TYPE    :   type of averaging - either 'mean' or 'median', required
;;Output:
;;      output  :   1D smoothed array of same length as input
;;Author and history:
;;      Daniel Hatcher, 2018
;;-

FUNCTION filter, inputArray, inputWidth, TYPE=type

COMPILE_OPT IDL2

;;Check input
arraySize = SIZE(inputArray)
IF arraySize[0] GT 1 THEN BEGIN
    MESSAGE, "Array must be 1D!"
ENDIF
IF NOT KEYWORD_SET(type) THEN BEGIN
    MESSAGE, 'Filter type not provided!'
ENDIF

num = arraySize[1]
output = FLTARR(num)

;;First and last elements will not be filtered, so just output them
output[0] = inputArray[0]
output[-1] = inputArray[-1]

FOR i = 1, num-2 DO BEGIN
    ;;Edge truncate left
    IF i LT inputWidth/2 THEN BEGIN
        filterWindow = LINDGEN(2*i)
    ;;Edge truncate right
    ENDIF ELSE IF i+inputWidth/2 GT num THEN BEGIN
        diff = num-i
        filterWindow = LINDGEN(2*diff,START=i-diff)
    ;;No truncation
    ENDIF ELSE BEGIN
        filterWindow = LINDGEN(inputWidth,START=i-inputWidth/2)
    ENDELSE
    type = STRLOWCASE(type)
    IF STRCMP(type,'median') EQ 1 THEN BEGIN
        output[i] = MEDIAN(inputArray[filterWindow])
    ENDIF ELSE IF STRCMP(type,'mean') EQ 1 THEN BEGIN
        output[i] = MEAN(inputArray[filterWindow])
    ENDIF
ENDFOR

RETURN, output

END

;;------------------------------------------------------------------------------
;;
;;      Peak finder
;;

;;+
;;Name:
;;      zscorepeaks
;;Purpose:
;;      Robust thresholding algorithm
;;Calling sequence:
;;      Result = zscorepeaks(inputData,LAG=integer,T=float,INF=float
;;      [,SCREEN=binary])
;;Positional parameters:
;;      inputData   :   1D array with unknown peak positions
;;Keyword parameters:
;;      LAG     :   Size of moving average window
;;      T       :   Threshold z-score for signal
;;      INF     :   Influence of signal on mean and standard deviation
;;                  If 0, excluded from moving average
;;                  If 1, included
;;      SCREEN  :   Screen output flag, 1 is on
;;Output:
;;      output  :   structure with tags:
;;          signals :   array of signals, same length as input
;;          upper   :   array of threshold upper limit, same length as input    
;;          lower   :   array of threshold lower limit, same length as input
;;          avg     :   array of moving average, same length as input
;;Author and history:
;;      Jean-Paul van Brakel, 2014  :   Algorithm construction
;;      https://stackoverflow.com/questions/22583391/
;;      peak-signal-detection-in-realtime-timeseries-data 
;;      Daniel Hatcher, 2018    :   IDL implementation
;;-

FUNCTION zscorepeaks,inputData,LAG=inputLag,T=inputT,INF=inputInf, $
    SCREEN=inputScreen

COMPILE_OPT IDL2

;;Check input
dataSize = SIZE(inputData)
IF dataSize[0] GT 1 THEN BEGIN
    MESSAGE, "Input must be 1D!"
ENDIF

num = dataSize[1]

IF inputLag LT num THEN BEGIN
    ;;Allocations
    signals = LONARR(num)
    avgFilter = FLTARR(num)
    stdFilter = FLTARR(num+1)

    ;;Not dealing with realtime data, so filtered array does not need to be
    ;;allocated dynamically.
    filtered = FLTARR(num)

    ;;Initializations
    filtered[0:inputLag] = inputData[0:inputLag]
    avgFilter[inputLag] = MEAN(inputData[0:inputLag])
    stdFilter[inputLag] = STDDEV(inputData[0:inputLag])

    ;;Exclude initial lagged values from signal array
    signals[0:inputLag-1] = -2

    ;;Signal calculation
    FOR i = inputLag+1, num-1 DO BEGIN
        diff = ABS(inputData[i]-avgFilter[i-1])
        IF diff GT inputT*stdFilter[i-1] THEN BEGIN
            IF inputData[i] GT avgFilter[i-1] THEN BEGIN
                ;;Positive signal
                signals[i] = 1
            ENDIF ELSE BEGIN
                ;;Negative signal
                signals[i] = -1
            ENDELSE
            ;;Change influence of signal
            filtered[i] = inputInf*inputData[i] + (1-inputInf)*filtered[i-1]
        ENDIF ELSE BEGIN
            ;;No signal
            signals[i] = 0
            filtered[i] = inputData[i]
        ENDELSE
        ;;Adjust filters
        avgFilter[i] = MEAN(filtered[i-inputLag:i])
        stdFilter[i] = STDDEV(filtered[i-inputLag:i])
    ENDFOR

    ;;Upper and lower thresholds
    upper = avgFilter+InputT*stdFilter
    lower = avgFilter-InputT*stdFilter

    ;;Use NaNs for cleaner plotting of lagged values
    upper[0:inputLag] = !VALUES.F_NAN
    lower[0:inputLag] = !VALUES.F_NAN

ENDIF ELSE BEGIN
    ;;If input is smaller than lag, find outliers without moving
    signals = LONARR(num)
    avgFilter = MEAN(inputData)
    stdFilter = STDDEV(inputData)
    upper = FLTARR(num)
    lower = FLTARR(num)

    ;;Positive outliers
    signals[WHERE(inputData GT avgFilter+stdFilter, /NULL)] = 1

    ;;Negative outliers
    signals[WHERE(inputData LT avgFilter-stdFilter, /NULL)] = -1

    upper[*] = avgFilter+InputT*stdFilter
    lower[*] = avgFilter-InputT*stdFilter
ENDELSE

;;Plotting
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

;;------------------------------------------------------------------------------
;;
;;      Continuum normalization
;;

FUNCTION contnorm, wave, flux, pixel, FRAME=frame, WIDTH=inputWidth, $
    SCREEN=inputScreen

COMPILE_OPT IDL2

;;Check inputs
waveSize = SIZE(wave)
fluxSize = SIZE(flux)

IF waveSize[0] NE 1 OR fluxSize[0] NE 1 THEN BEGIN
    MESSAGE, "Inputs must be 1D!"
ENDIF
IF waveSize[1] NE fluxSize[1] THEN BEGIN
    MESSAGE, "Input lengths must match!"
ENDIF

;;If width not specified, search
IF NOT KEYWORD_SET(inputWidth) THEN BEGIN
    ;;Search for left and right shoulder of Ha feature
    ;;Maximum search distance beyond lab frame pixel
    searchWidth = 50

    ;;Buffer around core not to be searched
    coreBuffer = 10

    ;;Create search indices
    leftSearch = LINDGEN(searchWidth-coreBuffer,START=pixel-searchWidth)
    ;;Search starting from right end of spectrum (reversed)
    rightSearch = REVERSE(LINDGEN(searchWidth-coreBuffer, $
        START=pixel+coreBuffer))

    ;;Search blue (left) side of Ha
    leftResult = zscorepeaks(flux[leftSearch],LAG=10,T=1.5,INF=0.1)

    ;;Search red (right) side of Ha
    rightResult = zscorepeaks(flux[rightSearch],LAG=10,T=1.5,INF=0.1)

    ;;Find first position of last signal (blue side of Ha)
    FOR i = N_ELEMENTS(leftSearch)-1,0,-1 DO BEGIN
        lastValue = leftResult.signals[-1]
        IF leftResult.signals[i] NE lastValue THEN BEGIN
            leftShoulder = leftSearch[i]
            BREAK
        ENDIF
    ENDFOR

   ;;Find first position of last signal (red side of Ha)
    FOR i = N_ELEMENTS(rightSearch)-1,0,-1 DO BEGIN
        lastValue = rightResult.signals[-1]
        IF rightResult.signals[i] NE lastValue THEN BEGIN
            rightShoulder = rightSearch[i]
            BREAK
        ENDIF
    ENDFOR

    ;;Choose largest width
    width = MAX([(rightShoulder-pixel),(pixel-leftShoulder)])
ENDIF ELSE BEGIN
    ;;If specified, use input width
    width = inputWidth
ENDELSE

;;If width is very large, warn user
limit = 10
IF N_ELEMENTS(flux)-width LT limit THEN BEGIN
    limString = STRTRIM(STRING(limit),2)
    PRINT, "Less than "+limString+" pixels on red end of spectrum!"
ENDIF

;;Remove feature
totalPixels = N_ELEMENTS(flux)
leftPixels = LINDGEN(pixel-width)
rightPixels = LINDGEN(totalPixels-(pixel+width),START=pixel+width)
patchedPixels = LINDGEN((width*2)+1,START=pixel-width)

;;Median filter left and right separately
medianWidth = 50
medianLeft = filter(flux[leftPixels],medianWidth,TYPE='median')
medianRight = filter(flux[rightPixels],medianWidth, $
    TYPE='median')

;;Reposition filtered arrays
separated = FLTARR(totalPixels)
separated[leftPixels] = medianLeft
separated[rightPixels] = medianRight

;;Interpolate across red region
joinedPixels = [leftPixels,rightPixels]
medianFlux = [medianLeft,medianRight]
interpolated = FLTARR(N_ELEMENTS(patchedPixels))
nLeft = N_ELEMENTS(leftPixels)
endPoints = [nLeft-1,nLeft]
slope = REGRESS(joinedPixels[endPoints],medianFlux[endPoints],CONST=const)
interpolated = const + patchedPixels*slope[0]
separated[patchedPixels] = interpolated

;;Boxcar filter
boxWidth = 25
boxFlux = filter(separated,boxWidth,TYPE='mean')

continuum = boxFlux

spectrum = flux/continuum

;;Output to screen?
IF KEYWORD_SET(inputScreen) THEN BEGIN
    IF NOT KEYWORD_SET(frame) THEN BEGIN
        PRINT, 'Frame number not provided in call to contnorm().'
        frame = ''
    ENDIF
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
        OPLOT, [wave[pixel-width],wave[pixel-width]],[MIN(flux),MAX(flux)]
        OPLOT, [wave[pixel+width],wave[pixel+width]],[MIN(flux),MAX(flux)]
        PLOT, wave,spectrum,xtitle='Wavelength (nm)', $
            ytitle='Normalized Flux',yrange=[0.9,1.1]
        OPLOT, wave[patchedPixels],spectrum[patchedPixels],COLOR=250
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
    spectrum    :   spectrum, $
    width   :   width, $
    patch   :   patchedPixels, $
    notpatch:   joinedPixels}

RETURN, output

END

;;------------------------------------------------------------------------------
;;
;;      Main
;;

FUNCTION bluenormalizer,inputFlux,inputWave,inputDate,inputFrame,$
    PRENORM=prenorm,WIDTH=inputWidth,NORMSCREEN=normScreen,$
    DIAGSCREEN=diagScreen,OUTFILE=outFile,FLAT=inputFlat

COMPILE_OPT IDL2

;;Define system variables
preferences

;;Zero indexed order
order = 0

;;H8 lab frame wavelength
H8 = 388.81

;;Hepsilon lab frame wavelength
He = 396.91

;;Select order
flux = inputFlux[*,order]
wave = inputWave[*,order]

;;Retrieve flat
IF NOT KEYWORD_SET(inputFlat) THEN BEGIN
    flat = readflat(locateflat(inputDate))
ENDIF ELSE BEGIN
    flat = readflat(inputFlat)
ENDELSE

;;Flat division 
flatDiv = flux / flat.normsmooth[*,order]

;;Break points
leftBreak = 200
rightBreak = 290

;;Define regions
leftPixels = LINDGEN(leftBreak)
middlePixels = LINDGEN(rightBreak-leftBreak,START=leftBreak)
rightPixels = LINDGEN(512-rightBreak,START=rightBreak)
leftFlux = flatDiv[leftPixels]
rightFlux = flatDiv[rightPixels]
leftWave = wave[leftPixels]
rightWave = wave[rightPixels]

;;Find pixel closest to wavelengths
distanceH8 = ABS(leftWave-H8)
minDistanceH8 = MIN(distanceH8,pixelH8)
distanceHe = ABS(rightWave-He)
minDistanceHe = MIN(distanceHe,pixelHe) 

;;Continuum normalization left and right
normalizedLeft = contnorm(leftWave,leftFlux,pixelH8,FRAME=inputFrame)
normalizedRight = contnorm(rightWave,rightFlux,pixelHe,FRAME=inputFrame)

;;Interpolate across middle region
slope = REGRESS([leftWave[-1],rightWave[0]],[normalizedLeft.continuum[-1],$
    normalizedRight.continuum[0]],CONST=const)
middleInterpolation = const + middlePixels*slope[0]
middleDiv = flatDiv[middlePixels] / middleInterpolation

PLOT, leftWave, leftFlux, XRANGE=[MIN(leftWave),MAX(rightWave)]
OPLOT, rightWave, rightFlux
OPLOT, leftWave, normalizedLeft.continuum, LINESTYLE=2
OPLOT, rightWave, normalizedRight.continuum, LINESTYLE=2

RETURN, 0

END
