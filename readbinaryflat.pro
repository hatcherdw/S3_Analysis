FUNCTION readbinaryflat, flat_data, FILE = file, BIT32OFF = bit32off

;+
;Name:
;		readbinaryflat
;Purpose:
;		Function for reading binary flat files
;Calling sequence:
;		flat = readbinaryflat(file)
;Input:
;		None
;Output:
;		flat_data   :   512 columns, 16 rows    
;Keywords:
;		BIT32   :   New CCD format switch. Default is ON (BIT32 not specified). 
;       FILE    :   Path to flat file. Default is frame 41589.
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2			                    ;Set compile options

IF KEYWORD_SET(bit32off) THEN BEGIN             ;Turn off 32-bit
    PRINT, 'BIT32OFF'
    flat_data = UINTARR(512,16)                  
ENDIF ELSE BEGIN
    flat_data = FLTARR(512,16)                  ;32-bit on by default
ENDELSE 

IF NOT KEYWORD_SET(file) THEN BEGIN             ;If no file provided, use default file
    def_dir = '/home/hatcher/RAW-FLATS/'
    def_file = '41589.RAW.spec'
    file = def_dir + def_file                  
    PRINT, 'Using default flat file: ' + file
ENDIF

OPENR, flat_file_unit, file, /GET_LUN
READU, flat_file_unit, flat_data
CLOSE, flat_file_unit
FREE_LUN, flat_file_unit

RETURN, flat_data

END 
