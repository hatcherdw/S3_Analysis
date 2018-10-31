PRO protonormalizer,frame

obj = restoreframe(frame=frame)
wave = obj.wave
flux = obj.flux
date = obj.date
normlaized = hanormalizer(flux,wave,date,frame,DIAGSCREEN=1,OUTFILE='out.ps')


END
