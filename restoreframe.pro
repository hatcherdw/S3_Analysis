FUNCTION restoreframe, FRAME=inputFrame

;Set compile options 
COMPILE_OPT IDL2		                                

;Check for input
IF NOT KEYWORD_SET(inputFrame) THEN BEGIN
    MESSAGE, 'Provide a frame number!'
ENDIF

;Check input type
IF STRCMP(SIZE(inputFrame,/TNAME),'LONG') EQ 0 THEN BEGIN
    MESSAGE, 'Frame number is not of type LONG!'
ENDIF 

;Change to data directory
allFrameDirectory = '/home/hatcher/NEW-CCD-all-orders-data/'
CD, allFrameDirectory

;List all files with matching frame number 
frameNumberString = STRTRIM(STRING(inputFrame),2)
SPAWN, 'ls *' + frameNumberString + '*', savedFile 

;If more than one file found, stop
foundFiles = SIZE(savedFile, /N_ELEMENTS)
IF foundFiles GT 1 THEN BEGIN
    PRINT, 'Found more than one file with frame number ' + frameNumberString
    STOP
ENDIF

;Restore variables
RESTORE, savedFile

;Create output structure
output = { $
         restoreframeOutput, $
         flux  :   frame1, $
         wave  :   wavelengths, $
         name  :   object_name, $
         date  :   object_date, $
         frame :   frameNumberString $  
         }

RETURN, output

END 
