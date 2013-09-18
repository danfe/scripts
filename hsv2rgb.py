#!/usr/bin/env python

from colorsys import *

yellow =	[ 50, 95, 95 ]
magenta =	[ 330, 95, 75 ]
cyan =		[ 90, 100, 70 ]
orange =	[ 15, 95, 95 ]
indigo = 	[ 250, 85, 35 ]
green =		[ 130, 80, 45 ]
red =		[ 360, 100, 100 ]
blue =		[ 220, 90, 55 ]
salad =		[ 75, 90, 55 ]

chem_green =	[ 130, 70, 70 ]
chem_orange =	[ 30, 80, 90 ]

for c in [ yellow, magenta, cyan, orange, indigo, green, red, blue, salad,
  chem_green, chem_orange ]:
	n = [ c[0] / 360.0, c[1] / 100.0, c[2] / 100.0 ]
	print [hex(int(round(y * 255))) for y in hsv_to_rgb(*n)]
