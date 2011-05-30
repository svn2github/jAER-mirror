Holds the project on PC-based processing of spike-based address-event information.
Based on the USB AER boards that uses the Cypress FX2 chip and the SiLabsC8051F320 chip 
for varous AER interfaces to AER chips, including silicon retinas, silicon cochleas, and
general purpose hardware interfaces to AER devices.

Also includes PC control of on-chip and off-chip (commodity DAC) control of chip biases.

Also includes control of a handy USB servo motor interface for experiments in robotics.

The home page of this project is 
http://sourceforge.net/projects/jaer/

Support for the DVS128 silicon retina is at
http://siliconretina.ini.uzh.ch

Windows: The main viewer can be launched with jAERViewer.exe.
Logging output can be shown by clicking the "Console" button on the lower right of the viewer.

Linux: USB hardware is only in alpha. Viewer can be launched with jAERViewer.sh script, if run
from root folder of jAER.


Folders are organized as follows

host - all code that runs on a host machine
utilities - useful command scripts to launch utilities
biasgenSettings - on-chip bias settings files for various chips
filterSettings - various settings for filtering events
jSmoothExeLauncher - files used for building Windows .exe launchers


tobi@ini.phys.ethz.ch
March 2009
