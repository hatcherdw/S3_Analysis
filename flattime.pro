PRO flattime

;+
;Name:
;		flattime
;Purpose:
;		Look at flat frames for new CCD through time
;Calling sequence:
;		flattime
;Input:
;		
;Output:
;		
;Keywords:
;		
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			;Set compile options

flat_ext = '.RAW.spec'
flat_dir = '/home/hatcher/RAW-FLATS-ALL-NEW-CCD/'
flat_list = flat_dir + 'flat_list_new_CCD.txt'

nskip = 6
nlines = FILE_LINES(flat_list)
nframes = nlines-nskip

years = STRARR(nframes)
months = STRARR(nframes)
days = STRARR(nframes)
frames = STRARR(nframes)
expor = STRARR(nframes)
expob = STRARR(nframes)

lines = STRARR(nlines)
line = ''

OPENR, iunit, flat_list, /GET_LUN

FOR i = 0, nlines-1 DO BEGIN
    READF, iunit, line
    lines[i] = line
    IF i GE nskip - 1 THEN BEGIN
        years[i-nskip] = STRMID(lines[i], 0, 4)
        months[i-nskip] = STRMID(lines[i], 5, 2)
        days[i-nskip] = STRMID(lines[i], 8, 2)
        frames[i-nskip] = STRMID(lines[i], 13, 5)
        expor[i-nskip] = STRMID(lines[i], 20, 3)
        expob[i-nskip] = STRMID(lines[i], 27, 2)
    ENDIF
ENDFOR

CLOSE, iunit
FREE_LUN, iunit

jdates = JULDAY(months,days,years)

all_flats = FLTARR(512,16,nframes) 
stats = FLTARR(5,16,nframes)
means = FLTARR(nframes,16)
linear = FLTARR(2,16)

FOR order = 0, 15 DO BEGIN
    FOR frame = 0, nframes-1 DO BEGIN
        frame_path = flat_dir + frames[frame] + flat_ext
        all_flats[*,*,frame] = readbinaryflat(FILE=frame_path)
        stats[*,order,frame] = TRANSPOSE(CREATEBOXPLOTDATA(all_flats[*,order,frame]))
        means[frame,order] = MEAN(all_flats[*,order,frame])
    ENDFOR  
    linear[1,order] = REGRESS(jdates[2:*],means[2:*,order],CONST=const)
    linear[0,order] = const 
ENDFOR

SET_PLOT, 'ps'
DEVICE, /COLOR, BITS_PER_PIXEL=8
DEVICE, FILENAME='SlopeOrder.ps'
DEVICE, XSIZE=7, YSIZE=7, XOFFSET=0.5, YOFFSET=3, /INCHES

PLOT, LINDGEN(16)+1, linear[1,*], $
xtitle = 'Order', $
ytitle = 'Time series slope (mean flux / day)', $
title = 'Time series slope vs. Order (excludes first two days)'
OPLOT, LINDGEN(16)+1, linear[1,*], PSYM=4

END
