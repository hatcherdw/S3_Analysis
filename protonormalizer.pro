PRO protonormalizer

@psplot
DEVICE, FILENAME='proto.ps'
frames = SINDGEN(32,START='41555')
FOR i = 0,N_ELEMENTS(frames)-1 DO BEGIN
    frame = frames[i]
    obj = restoreframe(frame=frame)
    wave = obj.wave
    flux = obj.flux
    date = obj.date
    normalized = bluenormalizer(flux,wave,date,frame)
    ;normalized = hanormalizer(flux,wave,date,frame,NORMSCREEN=1)
ENDFOR

DEVICE, /CLOSE_FILE
END
