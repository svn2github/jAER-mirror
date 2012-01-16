Copyright June 13, 2011 Andreas Steiner, Inst. of Neuroinformatics, UNI-ETH Zurich

This file is part of uart_MDC2D.

uart_MDC2D is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

uart_MDC2D is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with uart_MDC2D.  If not, see <http://www.gnu.org/licenses/>.


INTRODUCTION
------------

This project consists of different header and source files as
well as "test files" that are developed on EPFL's dsPIC 
development board (featuring a dsPIC33F128MC802) and later on
the MDC2Dv2 board (with a dsPIC33F128MC804 a, a motion detection
chip MDC2D, a USB interfacing FT232R and a DAC AD5391).

On one side, this software can read out the pixel values of
the MDC2D chip and stream them to a computer over the UART USB
and on the other side the software can use the pixel values to
calculate two-dimensional optical flow values using an algorithm
by MV Srinivasan (see [1]).

This firmware is part of a semester project at ETH Zurich; see
the report of the project that can be found under
	http://n.ethz.ch/~andstein/MDC2Dsrinivasan.pdf


COMPILATION
-----------

Download MPLAB IDE from http://www.microchip.com; for development
the version v8.63 was used on a Windows XP SP3 machine; the firmware
was also successfully compiled and programmed on the device using the
new "MPLAB IDE X" (based on NetBeans) under Windows 7 as well as Linux.

After installing the MPLAB IDE make sure you install the right C
compiler for the dsPIC33 family. Search on the Microchip website
for "MPLAB C Compiler for dsPIC" -- you can download a free "lite"
version of this compiler (which was used for testing this firmware)
once you registered on their webpage.

Eventually, the toolsuite needs to be set in MPLAB IDE prior to
compilation of the code : right click on project, then choose
"Select Language Toolsuite" and verify that the installed programs
are correctly listed (search for "mplabc30\v3.30\bin\pic30-*.ex"
in your MPLAB installation directory).


STRUCTURE
---------

shared source/header files
  - config.h : communication settings etc
  - command.[ch] : command parsing + handling
  - uart.[ch] : initializing and using UART <-> USB
  - port.[ch] : pin mappings etc
  - DAC.[ch] : communication with the AD5391
  - MDC2D.[ch] : communication with the MDC2D
  - time.[ch] : oscillator configuration, system clock
  - string.[ch] : basic string handling
  - var.[ch] : using dynamic internal variables
  
main files
  - main.c : include this file to compile the actual firmware
    ("include" means move it into the "Source Files" group)
  - test_*.c : each of this source files contains a main
    entry point and thereby only one can be compiled at any time,
    while the others should be removed from project" (right click
    on the file in the project tab to remove)


All the files contain DOXYGEN documentation; please see
	http://www.doxygen.org


COMMUNICATION WITH COMPUTER
---------------------------

1) FTDI's driver needs be installed; it can be downloaded at
   http://ftdichip.com -- after succesfull installation, the
   device appears as a new serial communication port (COM* in
   windows)

2) basic communication facilities (e.g. with test_countdown.c)
   can be asserted via HyperTerminal (Windows) or via minicom
   (Linux) -- it is important to set the serial line parameters
   to the same values as specified in uart.c

3) for testing the command.[ch] and the actual firmware, please
   see the package ch.unizh.ini.jaer.projects.dspic.serial that is
   shipped with jAER (download at http://jaer.sourceforge.net)
   
4) for the full streaming, display of frames and setting of
   biases, the class ch.unizh.ini.jaer.projects.opticalflow.MotionViewerMain_MDC2D
   should be used


REFERENCES
----------

1) Mandyam V. Srinivasan. An image-interpolation technique for 
   the computation of optic flow and egomotion. 
   Biological Cybernetics, 71:401-415, 1994. 10.1007/BF00198917.

