The preferred method of download of jAER is by subversion checkout from the root URL svn://svn.code.sf.net/p/jaer/code/trunk

The runtime downloads are for convenience for trial use of jAER.

This folder holds the project on PC-based processing of spike-based address-event information.
Based on the USB AER boards that uses the Cypress FX2 chip and the SiLabsC8051F320 chip 
for varous AER interfaces to AER chips, including silicon retinas, silicon cochleas, and
general purpose hardware interfaces to AER devices. jAER also includes PC control of on-chip and off-chip (commodity DAC) control of chip biases, 
and control of a handy USB servo motor interface for experiments in robotics.

The home page of this project is 
http://jaerproject.net

Support for the DVS128 silicon retina is at
http://siliconretina.ini.uzh.ch

Windows: The main viewer can be launched with jAERViewer.exe.
Logging output can be shown by clicking the "Console" button on the lower right of the viewer.

Linux: USB hardware is in beta and regularly used with native driver. Viewer can be launched with jAERViewer.sh script, if run
from root folder of jAER.


Folders are organized as follows

host - all code that runs on a host machine
utilities - useful command scripts to launch utilities
biasgenSettings - on-chip bias settings files for various chips
filterSettings - various settings for filtering events
jSmoothExeLauncher - files used for building Windows .exe launchers using jsmoothgen. No longer using. Instead see
WinRun4J - new launcher started using Oct 2011

Tobi Delbruck
tobi@ini.uzh.ch
May 2013
