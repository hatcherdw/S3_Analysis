PRO preferences
;Define new system variables that have system-specific 
;values (i.e. directory names) 
;Thrid argument is read-only flag. Set non-zero to prevent changes.

flatListDir = '/home/central/hatch1dw/IDL/S3_Analysis/'
flatListFile = 'flat_list_new_CCD.txt'
DEFSYSV, '!FLATLIST', flatListDir + flatListFile, 1 

flatDir = '/home/central/hatch1dw/RAW-FLATS-ALL-NEW-CCD/'
DEFSYSV, '!FLATDIR', flatDir, 1

frameDir = '/home/central/hatch1dw/NEW-CCD-all-orders-data/'
DEFSYSV, '!FRAMEDIR', frameDir, 1

testFlatListDir = '/home/central/hatch1dw/IDL/S3_Analysis/'
testFlatListFile = 'Test_Flat_List.txt'
DEFSYSV, '!TESTFLATLIST', testFlatListDir + testFlatListFile, 1

END
