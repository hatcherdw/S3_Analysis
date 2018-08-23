PRO nlfilter, inputFrame

COMPILE_OPT IDL2

;Restore and read data
obj = restoreframe(frame=inputframe)
flat = readflat(frame=locateflat(date=obj.date))

;Flat divide
order = 10
flatdiv = obj.flux[*,order] / flat.normsmooth[*,order]
wave = obj.wave[*,order]

;Identifiy Ha pixel (lab frame)
Ha = 656.28
distance = ABS(wave - Ha)
minDistance = MIN(distance,pixelHa)

;Search for left and right shoulder of Ha feature
searchWidth = 100
leftSearch = LINDGEN(searchWidth,START=pixelHa-searchWidth)
rightSearch = REVERSE(LINDGEN(searchWidth,START=pixelHa))
leftResult = zscorepeaks(flatdiv[leftSearch],LAG=10,T=1.5,INF=0)
rightResult = zscorepeaks(flatdiv[rightSearch],LAG=10,T=1.5,INF=0)
FOR i = searchWidth-1,0,-1 DO BEGIN
    lastValue = leftResult.signals[-1]
    IF leftResult.signals[i] NE lastValue THEN BEGIN
        leftShoulder = leftSearch[i]
        BREAK
    ENDIF 
ENDFOR
FOR i = 0,searchwidth-1 DO BEGIN
    lastValue = rightResult.signals[0]    
    IF rightResult.signals[i] NE lastValue THEN BEGIN
        rightShoulder = rightSearch[i]
        BREAK
    ENDIF
ENDFOR

;Remove Ha feature
width = ((rightShoulder-pixelHa)+(pixelHa-leftShoulder))/2
totalPixels = N_ELEMENTS(flatdiv)
leftPixels = LINDGEN(pixelHa-width)
rightPixels = LINDGEN(totalPixels-(pixelHa+width),START=pixelHa+width)
patchedPixels = LINDGEN((width*2)+1,START=pixelHa-Width)

;Join left and right ends
joinPixels = [leftPixels,rightPixels]
joinedWave = [wave[joinPixels]]
joinedFlux = [flatdiv[joinPixels]]

;Median filter joined "spectrum"
medianWidth = 50
numJoin = N_ELEMENTS(joinedWave)
medianFlux = FLTARR(numJoin)
medianFlux = joinedFlux
FOR i = medianWidth,numJoin-medianWidth-1 DO BEGIN
    medianWindow = LINDGEN(medianWidth,START=i-(medianWidth/2))
    medianFlux[i] = MEDIAN(joinedFlux[medianWindow])
ENDFOR

;Separate and interpolate
separated = FLTARR(totalPixels)
FOR i = 0,numJoin-1 DO BEGIN
    separated[joinPixels[i]] = medianFlux[i]
ENDFOR
endPoints = [leftPixels[-1],rightPixels[0]]
slope = REGRESS(endPoints,flatdiv[endPoints],CONST=const)
interpolated = const + patchedPixels*slope[0]
separated[patchedPixels] = interpolated

;Boxcar filter
boxWidth = 25
boxFlux = FLTARR(totalPixels)
boxFlux = separated
FOR i = boxWidth, totalPixels-boxWidth-1 DO BEGIN 
    boxWindow = LINDGEN(boxWidth,START=i-(boxWidth/2))
    boxFlux[i] = MEAN(separated[boxWindow])
ENDFOR

PRINT, width
!P.MULTI = [0,2,1,0,0]
PLOT, flatdiv, PSYM=3
OPLOT, boxFlux
PLOT, flatdiv/boxFlux

END
