PRO protonormalizer

@psplot
DEVICE, FILENAME='proto.ps'
frames = SINDGEN(2,START='41555')
FOR i = 0,N_ELEMENTS(frames)-1 DO BEGIN
    frame = frames[i]
    obj = restoreframe(frame=frame)
    wave = obj.wave
    flux = obj.flux
    date = obj.date
    name = obj.name
    normalized = hanormalizer(flux,wave,date,frame,name)
ENDFOR

DEVICE, /CLOSE_FILE
END
