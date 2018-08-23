; Name: 
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
; Author and history:
;       Jean-Paul van Brakel, 2014  :   Algorithm construction (StackOverflow)                        
;       Daniel Hatcher, 2018    :   IDL implementation
;-

FUNCTION zscorepeaks,inputData,LAG=inputLag,T=inputT,INF=inputInf

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

    upper = avgFilter+InputT*stdFilter
    lower = avgFilter-InputT*stdFilter
    
    ;Use NaNs for cleaner plotting
    upper[0:inputLag] = !VALUES.F_NAN
    lower[0:inputLag] = !VALUES.F_NAN

    ;Plotting indicator
    plotting = 0 
    IF plotting THEN BEGIN
        !P.MULTI = [0,2,1,0,0]
        PLOT, inputData, title = 'Data', PSYM=3
        OPLOT, avgFilter
        OPLOT, upper
        OPLOT, lower
        PLOT, signals, title = 'Signals', yrange=[-1.5,1.5]
    ENDIF
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


output = {$
    signals :   signals, $
    upper  :   upper, $
    lower  :   lower, $
    avg :   avgFilter}    

RETURN, output 

END
