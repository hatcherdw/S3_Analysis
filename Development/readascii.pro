FUNCTION readascii, FILE = file, AsciiData

;+
;Name:
;		readascii
;Purpose:
;		Reads two column frame ASCII files
;Calling sequence:
;		AsciiData = readascii(file)
;Input:
;       None
;Output:
;		AsciiData	;	Structure containing array of header strings, array of wavelength floats, array of flux floats  
;Keywords:
;		File
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2													;Set compile options

IF NOT KEYWORD_SET(file) THEN BEGIN                                 ;If file not specified, use default file
    defdir = '/home/hatcher/28_Tau_spectra/28_Tau_Raw_spec/'        ;Default directory
    deffile = 'Ord-11-2017-12-21-41581.txt'                         ;Default file
	file = defdir + deffile
	PRINT, 'Using default ASCII file: ' + file
ENDIF

nlines = FILE_LINES(file)											;Get number of lines in file
line_array = STRARR(nlines)											;Create string array of file lines
line = ''															;Line input variable
nheader = 0															;Initialize header counter

OPENR, iunit, file, /GET_LUN										;Open input file

FOR i = 0, nlines - 1 DO BEGIN										
	READF, iunit, line												;Read line
	line_array[i] = line 											;Store line
	ascii1 = STRMID(line_array[i], 0, 1)                            ;Check first character
	IF STRCMP(ascii1, '%') EQ 1 THEN BEGIN							
		nheader = nheader + 1                                       ;If header, add to header count
	ENDIF
ENDFOR

FREE_LUN, iunit 													;Close input file

ndata = nlines - nheader											;Number of data lines

header_array = STRARR(nheader)										;Create header array
wave = FLTARR(ndata)												;Create wavelength array
flux = FLTARR(ndata)												;Create flux array
w = 0.0D0															;Create wavelength input variable
f = 0.0D0															;Create flux input variable

header_array = line_array[0:nheader-1]								;Assign header lines to header sting array

FOR i = nheader, nlines-1 DO BEGIN
    READS, line_array[i], w, f, FORMAT = '(F11.6, F13.6)'           ;Read data lines with formats
    
	index = i - nheader												;Change line array index to data array index 
	wave[index] = w													;Place w value in array
	flux[index] = f													;Place f value in array
ENDFOR

AsciiData = {AsciiData, $											;Create output structure 
			head : header_array, $
			wl : wave, $
			fl : flux}

RETURN, AsciiData

END 
