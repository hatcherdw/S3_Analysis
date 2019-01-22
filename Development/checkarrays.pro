;+
; Name:
;       checkarrays
; Purpose:
;       Perform routine checks of flux and wavelength arrays before analysis
; Calling sequence:
;       status = checkarrays(FLUX=flux,WAVE=wave)       
; Input:
;
; Output:
;       status
; Keywords:
;       FLUX, WAVE
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION checkarrays, FLUX=inputFLux, WAVE=inputWave

status = 1B

;Check input existence
IF NOT KEYWORD_SET(inputFlux) THEN BEGIN
    PRINT, 'Please provide flux input array!'
    status = 0B
ENDIF
IF NOT KEYWORD_SET(inputWave) THEN BEGIN
    PRINT, 'Please provide wavelength input array!'
    status = 0B
ENDIF

;Check input sizes
fluxSizeVector = SIZE(inputFlux)
waveSizeVector = SIZE(inputWave)
IF fluxSizeVector[0] GT 1 THEN BEGIN
    PRINT, 'Flux array has more than one dimension!'
    status = 0B
ENDIF
IF waveSizeVector[0] GT 1 THEN BEGIN
    PRINT, 'Wavelength array has more than one dimension!'
    status = 0B
ENDIF
IF fluxSizeVector[-1] NE waveSizeVector[-1] THEN BEGIN
    PRINT, 'Input sizes do not match!'
    status = 0B
ENDIF
IF fluxSizeVector[-1] LT 2 THEN BEGIN
    PRINT, 'Flux array has less than 2 elements!'
    status = 0B
ENDIF
IF waveSizeVector[-1] LT 2 THEN BEGIN
    PRINT, 'Wavelength array has less than 2 elements!'
    status = 0B
ENDIF

;Check input types
IF STRCMP(SIZE(inputFlux,/TNAME),'DOUBLE') EQ 0 THEN BEGIN
    PRINT, 'Flux input is not of type DOUBLE!'
    status = 0B
ENDIF
IF STRCMP(SIZE(inputWave,/TNAME),'DOUBLE') EQ 0 THEN BEGIN
    PRINT, 'Wavelength input is not of type DOUBLE!'
    status = 0B
ENDIF

RETURN, status

END
