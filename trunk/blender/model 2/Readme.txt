*******************************
* Readme file for Truck.blend *
*******************************
Author: Robin Ritz

Truck.blend allows a simulation of the RC Monstertruck for testing controllers based on a silicon retina.
Some parameters of the simulation are still just estimated.
The folder 'Systemmatrizen' contains the informations about the dynamics of the truck and can be established from a simulink model using a matlab script.

Instructions to run the simulation:

1.) Copy the folder 'Systemmatrizen' into the same directory as blender.exe

2.) Run blender and open Truck.blend

3.) Optinal: Draw a line on the ground in the right window (The picture you see there is the texture of the ground)

4.) Put your mouse inside the top-left 3D window, and then push 'p' to start the simulation

5.) Push 'Esc' to quit

*************************************************************************************************************

There is the possibility to send jAER events to the jAERViewer using a python script of Albert Cardona.
For this open the file Truck_with_output.blend instead of Truck.blend.

Instructions to run the simulation with sending jAER events:

1.) Copy the folder 'Systemmatrizen' into the same directory as blender.exe

2.) Run blender and open Truck_with_output.blend

3.) Optinal: Draw a line on the ground in the right window (The picture you see there is the texture of the ground)

4.) Open the jAERViewer

5.) Put your mouse inside the top-left 3D window, and then push 'p' to start the simulation

6.) Open the input stream in the jAERViewer (File -> Open socket input stream, Port number is 8991)

7.) Choose the filter you wanna test in the jAERViewer

8.) Push 'Esc' to quit

**************************************************************************************************************

Controls:

up arrow	-> forward acceleration
left arrow	-> turn left
right arrow	-> trun right