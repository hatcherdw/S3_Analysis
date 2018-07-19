FUNCTION rasterizemap, MAP = inputMap

;Rasterize
rasterizedMap = ROUND(inputMap)

;Initialize output matrix to size of 2d grafted frame
graftedMap = LONARR(512,400)

;Turn on pixels to make grafted map 
FOR i = 0, 511 DO BEGIN
    FOR j = 0, 15 DO BEGIN
        pixelOn = rasterizedMap[i,j]
        graftedMap[i,pixelOn] = 255
    ENDFOR 
ENDFOR

RETURN, graftedMap

END
