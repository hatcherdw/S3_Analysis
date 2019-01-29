PRO protonormalizer

@psplot
DEVICE, FILENAME='proto.ps'
frames = SINDGEN(21000,START='22000')
FOR i = 0,N_ELEMENTS(frames)-1 DO BEGIN
    frame = frames[i]
    obj = restoreframe(frame=frame)
    IF ISA(obj,"STRUCT") THEN BEGIN
        wave = obj.wave
        flux = obj.flux
        date = obj.date
        name = obj.name
        normalized = hanormalizer(flux,wave,date,frame,name)
    ENDIF
ENDFOR

DEVICE, /CLOSE_FILE
END
