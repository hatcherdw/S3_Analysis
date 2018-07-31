;+
; Name:
;       zoning
; Purpose:
;       Define 'red,' 'grey,' and 'green' zones and trim accordingly
; Calling sequence:
;
; Input:
;
; Output:
;
; Keywords:
;
; Author and history:
;       Daniel Hatcher, 2018
;-

FUNCTION zoning, WAVE=inputWave, FLUX=inputFlux, GREYSTART=inputGreyStart, $
    GREYSTOP=inputGreyStop

;Red zone (250:425)
;Grey zone (greyStart:250) and (425:greyStop) 
greyStart = inputGreyStart
greyStop = inputGreyStop
greenZoneLeft = LINDGEN(greyStart)
greenZoneRight = LINDGEN(512-greyStop,START=greyStop)
greenZone = [greenZoneLeft, greenZoneRight]

zonedFlux = inputFlux[greenZone]
zonedWave = inputWave[greenZone]

output = {$
    flux    :   zonedFlux, $
    wave    :   zonedWave}

RETURN, output

END
