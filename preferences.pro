PRO preferences
;Define new system variables that have system-specific 
;values (i.e. directory names) 
;Thrid argument is read-only flag. Set non-zero to prevent changes.

flatListDir = '/home/central/hatch1dw/Programs/S3_Analysis/'
flatListFile = 'flat_list_new_CCD.txt'
DEFSYSV, '!FLATLIST', flatListDir + flatListFile, 1 

flatDir = '/storage/hatch1dw/RAW-FLATS-ALL-NEW-CCD/'
DEFSYSV, '!FLATDIR', flatDir, 1

frameDir = '/storage/hatch1dw/NEW-CCD-all-orders-data/'
DEFSYSV, '!FRAMEDIR', frameDir, 1

fakeDir = '/storage/hatch1dw/2018-06-27-data-with-fake-flat/'
DEFSYSV, '!FAKEDIR', fakeDir, 1

testFlatListDir = '/home/central/hatch1dw/Programs/S3_Analysis/'
testFlatListFile = 'Test_Flat_List.txt'
DEFSYSV, '!TESTFLATLIST', testFlatListDir + testFlatListFile, 1

graftedDir = '/storage/hatch1dw/Grafted/'
DEFSYSV, '!GRAFTEDDIR', graftedDir, 1

END
