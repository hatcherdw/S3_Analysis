PRO control
;Prototyping procedure for calling analysis modules

pixels = LINDGEN(512)+1

data = readascii()
flat = readbinaryflat()

normflat = flat[*,10]/MEDIAN(flat[*,10])

flatdiv = data.fl / normflat


patched_flux = roilocator(flatdiv, data.wl)  


END
