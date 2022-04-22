#!/usr/bin/env python3
#

# coe file format
''' 
  MEMORY_INITIALIZATION_RADIX=16;
  memory_initialization_vector =
  B7014000,
  996173A0,
  0130B701,
  800073A0;
'''

# example: python3 makecoe.py bootrom.bin > bootrom.coe

from sys import argv

# for the fpga, set swapped = 1
swapped = 1

binfile = argv[1]

with open(binfile, "rb") as f:
    bindata = f.read()

print("MEMORY_INITIALIZATION_RADIX=16;")
print("memory_initialization_vector = ")
for i in range( len(bindata) // 4):
    w = bindata[4*i : 4*i+4]
    if(swapped == 1):
        if( (i == (len(bindata)//4 -1)) && ((4*i+4) == len(bindata))):
		    #print an end mark in the end of file
            print("%02x%02x%02x%02x;" % (w[3], w[2], w[1], w[0]))
        else:
            print("%02x%02x%02x%02x," % (w[3], w[2], w[1], w[0]))
    else:
        if( (i == (len(bindata)//4 -1)) && ((4*i+4) == len(bindata))):
		    #print an end mark in the end of file
            print("%02x%02x%02x%02x;" % (w[0], w[1], w[2], w[3]))
        else:
            print("%02x%02x%02x%02x," % (w[0], w[1], w[2], w[3]))

# for compressed instruction, maybe 2 bytes left
if ((4*i+4) < len(bindata)) :
    w = bindata[4*i+4 : 4*i+6]
    if(swapped == 1):
        print("%02x%02x%02x%02x;" % (w[1], w[0]))
    else:
        print("%02x%02x%02x%02x;" % (w[0], w[1]))	 