PRO flatcompare, TEST=test, FLAT=flat, PS=ps

;+
;Name:
;		flatcompare
;Purpose:
;		Compare "test" flat and averaged flat
;Calling sequence:
;		flatcompare
;Input:
;		
;Output:
;		
;Keywords:
;		
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                                    ;Set compile options

IF NOT KEYWORD_SET(flat) THEN BEGIN                             
    flat = readbinaryflat()
ENDIF 

IF NOT KEYWORD_SET(test) THEN BEGIN                             
    def_test_dir = '/home/hatcher/2017-12-21-all-orders-data/'
    def_test_file = 'All-Ord-2017-12-21-41588.spe'
    RESTORE, def_test_dir + def_test_file, /VERBOSE
    test = frame1
ENDIF

IF KEYWORD_SET(ps) THEN BEGIN
    output_dir = '/home/hatcher/Plots/'
    filename = 'flatcompare'                             
    SPAWN, 'ls ' + output_dir, listing
    count = 0
    FOR item = 0, N_ELEMENTS(listing)-1 DO BEGIN
        count = count + STRCMP(filename, listing[item], filename.STRLEN()) 
    ENDFOR
    filename = filename + STRING(count+1)
    SET_PLOT, 'ps'
    DEVICE, /COLOR, BITS_PER_PIXEL=8
    DEVICE, FILENAME=output_dir+filename
    DEVICE, XSIZE=7, YSIZE=7, XOFFSET=0.5, YOFFSET=3, /INCHES
ENDIF

!P.MULTI = [0,2,8,0,0]
;WINDOW, XSIZE=1000, YSIZE=1000
maximum = MAX(flat/test)
minimum = MIN(flat/test)

FOR order=0,15 DO BEGIN
    b = 400
    ar = LINDGEN(b)
    br = LINDGEN(512-b, START=b)

    ratio = flat[*,order] / test[*,order]
    result1 = REGRESS(ar,ratio[0:b-1],CONST=const1,CORRELATION=r1)    
    result2 = REGRESS(br,ratio[b:*],CONST=const2,CORRELATION=r2)    
    y1 = ar*result1[0] + const1 
    y2 = br*result2[0] + const2 

    PLOT, ratio, TITLE='Order: ' + STRING(order+1), yrange = [minimum,maximum]
    OPLOT, ar, y1
    OPLOT, br, y2
    XYOUTS, 10, 1.5, $
     'Constant = ' + STRING(const1) + '!C' +  $
     'Coefficients = ' + STRING(result1[0]) + '!C' +  $ 
     'Correlation = ' + STRING(r1), $
     /DATA, CHARSIZE=2
    XYOUTS, 300, 1.5, $
     'Constant = ' + STRING(const2) + '!C' +  $
     'Coefficients = ' + STRING(result2[0]) +  '!C' +    $
     'Correlation = ' + STRING(r2), $
     /DATA, CHARSIZE=2
    
ENDFOR

END 
