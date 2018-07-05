FUNCTION restoreframe, inputFrame

;Set compile options 
COMPILE_OPT IDL2		                                

;Check input type
IF STRCMP(SIZE(inputFrame,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Frame number is not of type STRING!'
ENDIF 

;Change to data directory
IF sysvarexists('!FRAMEDIR') THEN CD, !FRAMEDIR 

;Trim string
trimmedFrame = inputFrame.TRIM()

;List all files with matching frame number and save list 
SPAWN, 'ls *' + trimmedFrame + '*', savedFile

;If more than one file found, stop
foundFiles = SIZE(savedFile, /N_ELEMENTS)
IF foundFiles GT 1 THEN BEGIN
    MESSAGE, 'Found more than one file with frame number ' + trimmedFrame
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
         frame :   inputFrame $  
         }

RETURN, output

END 
