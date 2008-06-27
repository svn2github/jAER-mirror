# **********************************************************************************
# * Python Script to adjust and correct the drifting states of the RC Monstertruck *
# **********************************************************************************

# Author: Robin Ritz

# Import modules
import GameLogic as GL
import math as M
import Blender.Mathutils as MU

# Get orientation of the Body_Point
Orientation_Body_Point = GL.Globals['Body_Point'].getOrientation()
	
# Get orientation of the Body
Orientation_Body = GL.Globals['Body'].getOrientation()

# Adjust z
GL.Globals['z'] = (GL.Globals['Body_Point'].getPosition()[2] - GL.Globals['z_0']) * GL.Globals['Blender_Factor_Position']

# Adjust phi_x
if Orientation_Body[2][1] > 0:
	phi_x_Body = (M.pi/180.0) * MU.AngleBetweenVecs(MU.Vector(Orientation_Body[0][1],Orientation_Body[1][1],Orientation_Body[2][1]),MU.Vector(Orientation_Body_Point[0][1],Orientation_Body_Point[1][1],Orientation_Body_Point[2][1]))
else:
	phi_x_Body = - (M.pi/180.0) * MU.AngleBetweenVecs(MU.Vector(Orientation_Body[0][1],Orientation_Body[1][1],Orientation_Body[2][1]),MU.Vector(Orientation_Body_Point[0][1],Orientation_Body_Point[1][1],Orientation_Body_Point[2][1]))
GL.Globals['phi_x'] = phi_x_Body * GL.Globals['Blender_Factor_Angle']

# Adjust phi_y
if Orientation_Body[2][0] > 0:
	phi_y_Body = - (M.pi/180.0) * MU.AngleBetweenVecs(MU.Vector(Orientation_Body[0][0],Orientation_Body[1][0],Orientation_Body[2][0]),MU.Vector(Orientation_Body_Point[0][0],Orientation_Body_Point[1][0],Orientation_Body_Point[2][0]))
else:
	phi_y_Body = (M.pi/180.0) * MU.AngleBetweenVecs(MU.Vector(Orientation_Body[0][0],Orientation_Body[1][0],Orientation_Body[2][0]),MU.Vector(Orientation_Body_Point[0][0],Orientation_Body_Point[1][0],Orientation_Body_Point[2][0]))
GL.Globals['phi_y'] = phi_y_Body * GL.Globals['Blender_Factor_Angle']

# Correct phi_z
if 1: #abs(GL.Globals['phi_x']) < 0.01 and abs(GL.Globals['phi_y']) < 0.01:

	# -> get phi_z_Body_Point <-
	if Orientation_Body_Point[0][0] >= 0.0 and  Orientation_Body_Point[0][1] >= 0.0:
		phi_z_Body_Point = M.asin(Orientation_Body_Point[0][1])
	elif Orientation_Body_Point[0][0] <= 0.0 and Orientation_Body_Point[0][1] >= 0.0:
		phi_z_Body_Point = M.pi - M.asin(Orientation_Body_Point[0][1])
	elif Orientation_Body_Point[0][0] <= 0.0 and Orientation_Body_Point[0][1] <= 0.0:
		phi_z_Body_Point = M.pi - M.asin(Orientation_Body_Point[0][1])
	elif Orientation_Body_Point[0][0] >= 0.0 and Orientation_Body_Point[0][1] <= 0.0:
		phi_z_Body_Point = 2*M.pi + M.asin(Orientation_Body_Point[0][1])
	else:
		phi_z_Body_Point = 0.0
		
	# -> get phi_z_Body <-
	if Orientation_Body[0][0] >= 0.0 and  Orientation_Body[0][1] >= 0.0:
		phi_z_Body = M.asin(Orientation_Body[0][1])
	elif Orientation_Body[0][0] <= 0.0 and Orientation_Body[0][1] >= 0.0:
		phi_z_Body = M.pi - M.asin(Orientation_Body[0][1])
	elif Orientation_Body[0][0] <= 0.0 and Orientation_Body[0][1] <= 0.0:
		phi_z_Body = M.pi - M.asin(Orientation_Body[0][1])
	elif Orientation_Body[0][0] >= 0.0 and Orientation_Body[0][1] <= 0.0:
		phi_z_Body = 2*M.pi + M.asin(Orientation_Body[0][1])
	else:
		phi_z_Body = 0.0

	# -> calculate corrections <-
	Correction_phi_x = 0.0
	Correction_phi_y = 0.0
	Correction_phi_z = - (phi_z_Body - phi_z_Body_Point) * 0.1
	
	if Correction_phi_z > 0.01:
		Correction_phi_z = 0.0

	# -> correct drift <-
	Rotation_Speed_Body = GL.Globals['Motion_Actuator_Body'].getDRot()
	GL.Globals['Motion_Actuator_Body'].setDRot(Rotation_Speed_Body[0] + Correction_phi_x,Rotation_Speed_Body[1] + Correction_phi_y,Rotation_Speed_Body[2] + Correction_phi_z,Rotation_Speed_Body[3])
	GL.addActiveActuator(GL.Globals['Motion_Actuator_Body'],1)
