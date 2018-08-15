; Name: 
;       zscorepeaks
; Purpose:
;       Robust thresholding algorithm 
; Calling sequence:
;       Result = zscorepeaks(DATA=array,LAG=integer,T=float,INF=float) 
; Positional parameters:
;       None
; Output:
;       signals :   Array of peak (+1) and valley (-1) positions
; Keyword parameters:
;       DATA    :   Data vector
;       LAG     :   Size of moving average window
;       T       :   Threshold z-score for signal
;       INF     :   Influence of singal on mean and standard deviation 
;                   If 0, signals are excluded from moving average
;                   If 1, signals are merely flagged, not excluded
; Author and history:
;       Jean-Paul van Brakel, 2014  :   Algorithm construction (StackOverflow)                        
;       Daniel Hatcher, 2018    :   IDL implementation
;-

FUNCTION zscorepeaks,DATA=inputData,LAG=inputLag,T=inputT,INF=inputInf

COMPILE_OPT IDL2

;Allocations
signals = LONARR(N_ELEMENTS(inputData))
avgFilter = FLTARR(N_ELEMENTS(inputData)+1)
stdFilter = FLTARR(N_ELEMENTS(inputData)+1)

;Not dealing with realtime data, so filtered array does not need to be 
;allocated dynamically.
filtered = FLTARR(N_ELEMENTS(inputData))

;Initializations
filtered[0:inputLag] = inputData[0:inputLag]
avgFilter[inputLag] = MEAN(inputData[0:inputLag])
stdFilter[inputLag] = STDDEV(inputData[0:inputLag])

;Exclude initial lagged values from signal array by 
;arbitrarily setting them to -2
signals[0:inputLag-1] = -2

;Signal calculation
FOR i = inputLag+1, N_ELEMENTS(inputData)-1 DO BEGIN
    IF ABS(inputData[i]-avgFilter[i-1]) GT inputT*stdFilter[i-1] THEN BEGIN
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

;Plotting indicator
plotting = 1 

IF plotting THEN BEGIN
    !P.MULTI = [0,2,1,0,0]
    PLOT, inputData, title = 'Data', PSYM=3
    OPLOT, avgFilter + inputT*stdFilter
    OPLOT, avgFilter - inputT*stdFilter
    PLOT, signals, title = 'Signals', yrange=[-1.5,1.5]
ENDIF

RETURN, signals

END
