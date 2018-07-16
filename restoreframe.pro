FUNCTION restoreframe, inputFrame

;+
; Name:
;       restoreframe
; Purpose:
;       Restore frame data from IDL save variables
; Calling sequence:
;       frame = restoreframe(frame)
; Input:
;       inputFrame  :   string frame number
; Output:
;       output  :   named structure restoreframeOutput
; Keywords:
;       None
; Author and history:
;       Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2		                                

;Check input type
IF STRCMP(SIZE(inputFrame,/TNAME),'STRING') EQ 0 THEN BEGIN
    MESSAGE, 'Frame number is not of type STRING!'
ENDIF 

;Trim string
trimmedFrame = inputFrame.TRIM()

;List all files with matching frame number and save list 
IF sysvarexists('!FRAMEDIR') THEN BEGIN
    SPAWN, 'ls ' + !FRAMEDIR  + '*' + trimmedFrame + '*', savedFile
ENDIF 


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
