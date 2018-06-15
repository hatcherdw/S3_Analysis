PRO plotascii, wave, flux, head

;+
;Name:
;		plotascii
;Purpose:
;		Plot 2D ASCII spectra
;Calling sequence:
;		plotascii, wave, flux
;Input:
;		wave	;	Array of wavelength values
;		flux	;	Array of flux values
;		head	;	Array of header string values
;Output:
;		None
;Keywords:
;		None
;Author:
;		Daniel Hatcher, 2018
;-

COMPILE_OPT IDL2								;set compile options

HeadTrim = head.remove(0,1)						;remove first two characters '% '
HeadJoin = HeadTrim.join(', ')					;join header items with commas
HeadComp = STRCOMPRESS(HeadJoin, /REMOVE_ALL)	;remove all whitespace

DEVICE, decomposed=0
LOADCT, 12 

PLOT, wave, flux, $
PSYM=10, $
title = HeadComp, $						 
xtitle = 'Wavelength (nm)', $
ytitle = 'Flux', $
color = 19, $
background = 255

END 
