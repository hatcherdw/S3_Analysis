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

nlines = FILE_LINES(flat_list)
nskip = 6
nframes = nlines-nskip

lines = STRARR(nlines)
line = ''

dates = STRARR(nframes)
years = STRARR(nframes)
months = STRARR(nframes)
days = STRARR(nframes)
frames = STRARR(nframes)
expor = STRARR(nframes)
expob = STRARR(nframes)

OPENR, iunit, flat_list, /GET_LUN
FOR i = 0, nlines-1 DO BEGIN
    READF, iunit, line
    lines[i] = line
    IF i GE nskip - 1 THEN BEGIN
        dates[i-nskip] = STRMID(lines[i], 0, 10)
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
stats = FLTARR(5,nframes,16)
means = FLTARR(1,nframes,16)

FOR i = 0, nframes-1 DO BEGIN
    frame_path = flat_dir + frames[i] + flat_ext
    all_flats[*,*,i] = readbinaryflat(FILE=frame_path)    
    FOR j = 0, 15 DO BEGIN
        result = CREATEBOXPLOTDATA(all_flats[*,j,i])
        result = TRANSPOSE(result)
        stats[*,i,j] = result
        means[0,i,j] = MEAN(all_flats[*,j,i])
    ENDFOR
ENDFOR

order = 11

;SET_PLOT, 'ps'
;DEVICE, /COLOR, BITS_PER_PIXEL=8
;DEVICE, FILENAME='Expo_Medians.ps' 
;DEVICE, XSIZE=7, YSIZE=10, XOFFSET=0.5, YOFFSET=0.5, /INCHES
!P.MULTI = [0,2,4,0,0]
WINDOW, XSIZE=1000, YSIZE=1000

;PLOT, expob, means[0,*,0], PSYM=4, xtitle='Exposure time',ytitle='Mean flux',title='Order: 1'
;PLOT, expob, stats[2,*,0], PSYM=4, xtitle='Exposure time',ytitle='Median flux',title='Order: 1'

FOR i = 0, 15 DO BEGIN
    PLOT, all_flats[*,i,*]
        
    ;PLOT, jdates, means[0,*,i], PSYM=1, $
    ;xtitle='Julian Date', ytitle='Flux', title='Order: '+STRING(i)

    ;PLOT, expor, means[0,*,i], PSYM=4, xtitle='Exposure time',ytitle='Mean flux', title='Order: '+STRING(i+1)
    ;PLOT, expor, stats[2,*,i], PSYM=4, xtitle='Exposure time',ytitle='Median flux', title='Order: '+STRING(i+1)
ENDFOR

;PLOT, jdates, stats[2,*,order-1], PSYM=4, yrange=[MIN(stats[*,*,order-1]),MAX(stats[*,*,order-1])], $
;xtitle='Julian Date', ytitle='Flux'
lower = FLTARR(2)
upper = FLTARR(2)
x = LONARR(2)
FOR i = 0, nframes-1 DO BEGIN
    lower = stats[0:1,i,order-1]
    upper = stats[3:4,i,order-1]
    x[*] = jdates[i]
    ;OPLOT, x, lower
    ;OPLOT, x, upper
ENDFOR

END 
