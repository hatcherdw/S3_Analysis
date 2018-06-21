FUNCTION readbinaryflat, flatData, FILE = inputPath, BIT32OFF = bit32off

;Set compile options
COMPILE_OPT IDL2			                    

;Check if 32-bit turned off
IF KEYWORD_SET(bit32off) THEN BEGIN            
    PRINT, 'BIT32OFF'
    flatData = UINTARR(512,16)                  
ENDIF ELSE BEGIN
    flatData = FLTARR(512,16)                  
ENDELSE 

;If no input path provided, use default file
IF NOT KEYWORD_SET(file) THEN BEGIN                
    defaultDirectory = '/home/hatcher/RAW-FLATS/'
    defaultFile = '41589.RAW.spec'
    path = defaultDirectory + defaultFile                  
    PRINT, 'Using default flat file: ' + file
ENDIF ELSE BEGIN
    path = inputPath
ENDELSE

OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

RETURN, flatData

END 
