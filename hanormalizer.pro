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

;;Define read-only system variables
DEFSYSV, '!FLATLIST', flatListDir + flatListFile, 1
DEFSYSV, '!FLATDIR', flatDir, 1

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
;;      Centroid finder
;;

;;+
;;Name:
;;      centroid
;;Purpose:
;;      Find centroid of Ha feature assuming Gaussian wing profile. 
;;      Also determines amount of continuum to include for later comparisons.
;;Calling sequence:
;;      Result = centroid(inputFlux[,FRAME=string][,SCREEN=binary])
;;Positional parameters:
;;      inputFlux   :   512x1 array of floats
;;Keyword parameters:
;;      FRAME   :   string frame number
;;      SCREEN  :   Screen output flag, 1 is on
;;Output:
;;      output  :   structure with tags:
;;          centroid    :   center of the fitted Gaussian (float)
;;          left        :   pixels used for fitting on left (integer array)
;;          right       :   pixels used for fitting on right (integer array)
;;          const       :   constant of fit (float)
;;Author and history:
;;      Daniel Hatcher, 2018
;;-

FUNCTION centroid, inputFlux, FRAME=inputFrame, SCREEN=inputScreen

COMPILE_OPT IDL2

inputSize = SIZE(inputFlux)
IF inputSize[0] GT 1 THEN BEGIN
    MESSAGE, "Input must be 1D!"
ENDIF
IF inputSize[1] NE 512 THEN BEGIN
    MESSAGE, "Input must have length 512! Given: "+STRING(inputSize[1])
ENDIF

;;Median smoothing
sFlux = filter(inputFlux,5,TYPE='median')

;;Find extreme values
roi = LINDGEN(150,START=250)
minFlux = MIN(sFlux[roi],minInd)
maxFlux = MAX(sFlux[roi],maxInd)
minInd = roi[minInd]
maxInd = roi[maxInd]

;;How extreme?
minDist = ABS(1.0 - minFlux)
maxDist = ABS(1.0 - maxFlux)

;;Choose most extreme
IF maxDist GT minDist THEN BEGIN
    extreme = maxInd
ENDIF ELSE IF minDist GT maxDist THEN BEGIN
    extreme = minInd
ENDIF

limit = 0.45*ABS(sFlux[extreme]-1.0)

;;Find first point beyond limit
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

;;Wing pixel locations
length = 512 - rightStop
left = LINDGEN(length,START=leftStop-length)
right = LINDGEN(length,START=rightStop)

fluxLeft = sFlux[left]
fluxRight = SFlux[right]

;;Turn off math error reporting to suppress benign underflow error messages
;;that sometimes occur when fitting gaussian
currentExcept = !EXCEPT
!EXCEPT = 0

;;Flush current math error register
void = CHECK_MATH()

;;Fit single gaussian
IF extreme EQ maxInd THEN BEGIN
    fit = GAUSSFIT([left,right],[fluxLeft,fluxRight],A,NTERMS=5)
ENDIF ELSE IF extreme EQ minInd THEN BEGIN
    ;;If extreme point is a minimum, provide estimates
    fit = GAUSSFIT([left,right],[fluxLeft,fluxRight],A,NTERMS=5,$
        ESTIMATES=[-1,350,50,1,0.01])
ENDIF

;;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;;Report any other math errors
    MESSAGE, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)
ENDIF

;;Restore original reporting condition
!EXCEPT = currentExcept

;;Resampling
range = right[-1]-left[0]
xsamples = FINDGEN(range,START=left[0])
z = (xsamples - A[1])/A[2]
rfit = A[0]*exp((-(z^2))/2) + A[3] + A[4]*xsamples

centroid = A[1]

IF KEYWORD_SET(inputScreen) THEN BEGIN
    IF inputScreen EQ 1 THEN BEGIN
        PLOT, left, sFlux[left], PSYM=4, xrange=[MIN(left),MAX(right)],$
            title=frame
        OPLOT, right, sFlux[right], PSYM=4
        OPLOT, xsamples,rfit
    ENDIF
ENDIF

output = {$
    centroid    :   centroid, $
    left    :   left, $
    right   :   right, $
    const   :   A[3]}

RETURN, output

END

;;------------------------------------------------------------------------------
;;
;;      Continuum normalization
;;

;;+
;;Name:
;;      contnorm
;;Purpose:
;;      Continuum normalization of raw SSS H alpha order
;;Calling sequence:
;;      Result = contnorm(wave,flux,pixleHa[,FRAME=string][,WIDTH=integer]
;;      [,SCREEN=binary])
;;Positional parameters:
;;      wave    :   512x1 array of wavelengths
;;      flux    :   512x1 array of flat-divided flux values
;;      pixelHa :   pixel nearest to Ha lab wavelength
;;Keyword parameters:
;;      FRAME   :   string frame number (for plotting)
;;      WIDTH   :   Ha feature width, dynamic if not provided
;;      SCREEN  :   Screen output flag, 1 is on 
;;Output:
;;      output  :   structure with tags:
;;          continuum   :   512x1 estimate of the continuum
;;          spectrum    :   512x1 input flux divided by continuum
;;          width       :   integer width of the Ha patch
;;          patch       :   array of patched pixels
;;          notpatch    :   array of pixels not part of the patch
;;Author and history:
;;      C.A.L. Bailer-Jones et al., 1998    :  Filtering algorithm
;;      Daniel Hatcher, 2018    :   IDL implementation
;;-

FUNCTION contnorm, wave, flux, pixelHa, FRAME=frame, WIDTH=inputWidth, $
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
IF waveSize[1] NE 512 OR fluxSize[1] NE 512 THEN BEGIN
    MESSAGE, "Inputs must have length 512!"
ENDIF

;;If width not specified, search
IF NOT KEYWORD_SET(inputWidth) THEN BEGIN
    ;;Search for left and right shoulder of Ha feature
    ;;Maximum search distance beyond Ha
    searchWidth = 100

    ;;Buffer around Ha core not to be searched
    coreBuffer = 20

    ;;Create search indices
    leftSearch = LINDGEN(searchWidth-coreBuffer,START=pixelHa-searchWidth)
    ;;Search starting from right end of spectrum (reversed)
    rightSearch = REVERSE(LINDGEN(searchWidth-coreBuffer, $
        START=pixelHa+coreBuffer))

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
    width = MAX([(rightShoulder-pixelHa),(pixelHa-leftShoulder)])
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

;;Remove Ha feature
totalPixels = N_ELEMENTS(flux)
leftPixels = LINDGEN(pixelHa-width)
rightPixels = LINDGEN(totalPixels-(pixelHa+width),START=pixelHa+width)
patchedPixels = LINDGEN((width*2)+1,START=pixelHa-width)

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
        OPLOT, [wave[pixelHa-width],wave[pixelHa-width]],[MIN(flux),MAX(flux)]
        OPLOT, [wave[pixelHa+width],wave[pixelHa+width]],[MIN(flux),MAX(flux)]
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

;;Output structure
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
;;      Wing comparison
;;

;;+
;;Name:
;;      wingcompare
;;Purpose:
;;      Compare wings of the Ha feature assuming a Gaussian wing profile
;;Calling sequence:
;;      wingcompare, flux,centroid,left,right,frame[,SCREEN=bianry]
;;Positional parameters:
;;      flux    :   continuum normalized flux
;;      centroid:   center as determined by centroid function (float)
;;      left    :   array of pixels left of wing 
;;      right   :   array of pixels right of wing 
;;      frame   :   string frame number (for plotting)
;;Keyword parameters:
;;      SCREEN  :   Screen output flag, 1 is on
;;Output:
;;      None
;;Author and history:
;;      Daniel Hatcher, 2018
;;-

PRO wingcompare, flux, centroid, left, right, frame, SCREEN=inputScreen

COMPILE_OPT IDL2

leftDist = ABS(left-centroid)
rightDist = ABS(right-centroid)

;Turn off math error reporting to suppress benign underflow error messages
;that sometimes occur when fitting gaussian
currentExcept = !EXCEPT
!EXCEPT = 0

;Flush current math error register
void = CHECK_MATH()

;Fit left and right gaussians
nterms = 4
fitL = GAUSSFIT(leftDist,flux[left],coeffL,NTERMS=nterms)
fitR = GAUSSFIT(rightDist,flux[right],coeffR,NTERMS=nterms)

;Resample
rsLeft = FINDGEN(2*N_ELEMENTS(left),START=MIN([leftDist,rightDist]),$
    INCREMENT=0.5)
rsRight = rsLeft

;Calculate fit at resampled points
rsLeftFit = FLTARR(N_ELEMENTS(rsLeft))
rsRightFit = FLTARR(N_ELEMENTS(rsRight))
FOR i = 0, N_ELEMENTS(rsLeft)-1 DO BEGIN
    zL = (rsLeft[i] - coeffL[1]) / coeffL[2]
    rsLeftFit[i] = coeffL[0]*exp((-zL^2)/2)+coeffL[3]
    zR = (rsRight[i] - coeffR[1]) / coeffR[2]
    rsRightFit[i] = coeffR[0]*exp((-zR^2)/2)+coeffR[3]
ENDFOR

;Check for floating underflow error
floating_point_underflow = 32
status = CHECK_MATH()
IF (status AND NOT floating_point_underflow) NE 0 THEN BEGIN
    ;Report any other math errors
    PRINT, 'IDL CHECK_MATH() error: ' + STRTRIM(status, 2)
ENDIF

;Restore original reporting condition
!EXCEPT = currentExcept

IF KEYWORD_SET(inputScreen) THEN BEGIN
    IF inputScreen EQ 1 THEN BEGIN
        ;;Colors
        DEVICE, DECOMPOSED=0
        LOADCT, 39, /SILENT

        !P.MULTI = [0,1,4,0,0]

        PLOT, left,flux[left],PSYM=3,title=frame,$
            yrange=[MIN(flux[[left,right]]),MAX(flux[[left,right]])], $
            xrange=[MIN(left),MAX(right)], $
            xtitle='Pixel',ytitle='Normalized flux'
        OPLOT, right,flux[right],PSYM=3, COLOR=250
        OPLOT, [centroid,centroid],[MIN(flux),MAX(flux)]

        PLOT, leftDist, flux[left], PSYM=3, $
            yrange=[MIN(flux[[left,right]]),MAX(flux[[left,right]])],$
            xtitle = 'Distance from centroid',ytitle='Normalized flux'
        OPLOT, rightDist, flux[right], PSYM=3, COLOR=250
        OPLOT, rsLeft, rsLeftFit
        OPLOT, rsRight, rsRightFit, COLOR = 250

        measure = (rsRightFit/rsLeftFit) - (coeffR[3]/coeffL[3])
        tot = TOTAL(ABS(measure))
        PLOT, rsLeft, measure, $
            title='Right Fit / Left Fit - Right Constant / Left Constant', $
                xtitle='Distance from centroid'
        OPLOT, [MIN(rsLeft),MAX(rsLeft)],[0.0,0.0],LINESTYLE=2

        currentTot = FLTARR(N_ELEMENTS(rsLeft))
        FOR i = 0, N_ELEMENTS(rsLeft)-1 DO BEGIN
            currentTot[i] = TOTAL(ABS(measure[0:i]))
        ENDFOR
        PLOT, rsLeft, currentTot, title='Cumulative percent difference', $
            xtitle='Distance from centroid'
        OPLOT, [MIN(rsLeft),MAX(rsLeft)], [tot,tot], LINESTYLE=2
        XYOUTS, 100,0.5*tot,STRTRIM(STRING(tot),2)
    ENDIF
ENDIF

END

;;------------------------------------------------------------------------------
;;
;;      Main
;;

;;+
;;Name:
;;      hanormalizer
;;Purpose:
;;      Continuum normalization of H-alpha SSS order
;;Calling sequence:
;;      Result = hanormalizer(inputFlux,inputWave,inputDate,inputFrame,
;;      [,PRENORM=integer][,WIDTH=integer][,NORMSCREEN=binary]
;;      [,DIAGSCREEN=binary][,OUTFILE=string][,FLAT=string])
;;Positional parameters:
;;      inputFlux   :   512x16 array of floats (raw flux, no flat division)
;;      inputWave   :   512x16 array of floats
;;      inputDate   :   Date fromatted as YYYY-MM-DD
;;      inputFrame  :   string frame number of length 5 (for plotting)
;;Optional parameters (keywords):
;;      PRENORM     :   order used for prenormalization, recommend 11 (index 0)
;;      WIDTH       :   width of H-alpha feature
;;      NORMSCREEN  :   binary output flag for normalization plots, 1 is on
;;      DIAGSCREEN  :   binary output flag for diagnostic plots, 1 is on
;;      OUTFILE     :   path to output file (PostScript)
;;      FLAT        :   string frame number of length 5 
;;Output:
;;      normalized.spectrum :   continuum normalized spectrum (512 float array)
;;Author and history:
;;      Daniel Hatcher, 2018
;;-

FUNCTION hanormalizer,inputFlux,inputWave,inputDate,inputFrame,PRENORM=prenorm,$
    WIDTH=inputWidth,NORMSCREEN=normScreen,DIAGSCREEN=diagScreen,$
    OUTFILE=outFile,FLAT=inputFlat

COMPILE_OPT IDL2

;;Define system variables
preferences

;;Check NORMSCREEN and set default
IF NOT KEYWORD_SET(normScreen) THEN BEGIN
    normScreen = 0
ENDIF

;;Create output file and turn on screens
IF KEYWORD_SET(outFile) THEN BEGIN
    SET_PLOT, 'ps'
    DEVICE, /COLOR, BITS_PER_PIXEL=8
    DEVICE, XSIZE=7, YSIZE=10, XOFFSET=0.5, YOFFSET=0.5, /INCHES
    DEVICE, FILENAME = outFile
    normScreen = 1
    diagScreen = 1
ENDIF

;;Zero indexed Halpha order
order = 10

;;Ha lab frame wavelength
Ha = 656.28

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

;;Prenormalization with nearby order
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

;;Find pixel closest to Ha lab wavelength
distance = ABS(wave - Ha)
minDistance = MIN(distance,pixelHa)

;;Continuum normalization
IF KEYWORD_SET(inputWidth) THEN BEGIN
    normalized = contnorm(wave,flatDiv,pixelHa,FRAME=inputFrame,$ 
        WIDTH=inputWidth,SCREEN=normScreen)
ENDIF ELSE BEGIN
    normalized = contnorm(wave,flatDiv,pixelHa,FRAME=inputFrame,$
        SCREEN=normScreen) 
ENDELSE

;;Diagnostic plots
IF KEYWORD_SET(diagScreen) THEN BEGIN
    IF diagScreen EQ 1 THEN BEGIN
        c = centroid(normalized.spectrum)
        wingcompare,normalized.spectrum,c.centroid,c.left,c.right,$
            inputFrame,SCREEN=1
    ENDIF
ENDIF

;;Close output file
IF KEYWORD_SET(outFile) THEN BEGIN
    DEVICE, /CLOSE_FILE
ENDIF

RETURN, normalized.spectrum

END
