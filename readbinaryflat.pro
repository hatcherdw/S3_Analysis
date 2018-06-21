FUNCTION readbinaryflat, FRAME = inputFrame, flatData

;Set compile options
COMPILE_OPT IDL2			                    

;Check input existence and type
IF KEYWORD_SET(inputFrame) THEN BEGIN
    type = SIZE(inputFrame,/TNAME)
    isString = STRCMP(type,'STRING')
    CASE isString OF
        1 : frame = inputFrame
        0 : MESSAGE, 'Input is not of type STRING!'
    ENDCASE
ENDIF ELSE BEGIN
    MESSAGE, 'Please provide a frame number string!'
ENDELSE

;Check if old or new CCD 
IF LONG(frame) GE 22684 THEN BEGIN
    ;NEW CCD
    flatData = FLTARR(512,16)
ENDIF ELSE BEGIN
    ;OLD CCD
    flatData = UINTARR(512,16)
ENDELSE

directory = '/home/hatcher/RAW-FLATS-ALL-NEW-CCD/'
extension = '.RAW.spec'
path = directory + frame + extension

OPENR, logicalUnitNumber, path, /GET_LUN
READU, logicalUnitNumber, flatData
CLOSE, logicalUnitNumber
FREE_LUN, logicalUnitNumber

RETURN, flatData

END 
