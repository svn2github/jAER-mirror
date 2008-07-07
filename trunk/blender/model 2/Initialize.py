# ******************************************************
# * Python Script for initializing the RC Monstertruck *
# ******************************************************

# Author: Robin Ritz

# Import modules
import GameLogic as GL
import time

# Define dictionary for global variables
GL.Globals = {}

# Initialize Blender factors
GL.Globals['Blender_Factor'] = 0.1
GL.Globals['Blender_Factor_Angle'] = 0.1665
GL.Globals['Blender_Factor_Position'] = 1.0
Blender_Factor = GL.Globals['Blender_Factor']

# Initialize manual control informations
GL.Globals['ManualSteering'] = 1
GL.Globals['ManualSpeedControl'] = 1

# Initialize route capturing informations
GL.Globals['CaptureRoute'] = 1

# Initialize state limits
GL.Globals['Lower_Limit_z'] = -0.05 * 100
GL.Globals['Upper_Limit_z'] = 0.05 * 100
GL.Globals['Lower_Limit_phi_x'] = -0.4 * 100
GL.Globals['Upper_Limit_phi_x'] = 0.4 * 100
GL.Globals['Lower_Limit_phi_y'] = -0.4 * 100
GL.Globals['Upper_Limit_phi_y'] = 0.4 * 100

# Load actuators and owners
Cont = GL.getCurrentController()
GL.Globals['Motion_Actuator_Body'] = Cont.getActuator("Motion Body")
GL.Globals['Motion_Actuator_Body_Point'] = Cont.getActuator("Motion Body Point")
GL.Globals['Rotation_Actuator_Wheel_1'] = Cont.getActuator("Rotation Wheel 1")
GL.Globals['Rotation_Actuator_Wheel_2'] = Cont.getActuator("Rotation Wheel 2")
GL.Globals['Rotation_Actuator_Wheel_3'] = Cont.getActuator("Rotation Wheel 3")
GL.Globals['Rotation_Actuator_Wheel_4'] = Cont.getActuator("Rotation Wheel 4")
GL.Globals['Body'] = GL.Globals['Motion_Actuator_Body'].getOwner()
GL.Globals['Body_Point'] = GL.Globals['Motion_Actuator_Body_Point'].getOwner()

# Initialize value of the drifting position state
GL.Globals['z_0'] =  GL.Globals['Body_Point'].getPosition()[2]

# Initialize timestamp
GL.Globals['Last_Timestamp'] = time.time() 

# Initialize states
GL.Globals['z'] = 0.0
GL.Globals['x_p'] = 0.0
GL.Globals['y_p'] = 0.0
GL.Globals['z_p'] = 0.0
GL.Globals['phi_x'] = 0.0
GL.Globals['phi_y'] = 0.0
GL.Globals['phi_x_p'] = 0.0
GL.Globals['phi_y_p'] = 0.0
GL.Globals['phi_z_p'] = 0.0
GL.Globals['omega_1'] = 0.0
GL.Globals['omega_2'] = 0.0
GL.Globals['omega_3'] = 0.0
GL.Globals['omega_4'] = 0.0
GL.Globals['delta_f'] = 0.0
GL.Globals['M_a_f'] = 0.0

# Initialize dynamics
GL.Globals['D_z'] = 0.0
GL.Globals['D_x_p'] = 0.0
GL.Globals['D_y_p'] = 0.0
GL.Globals['D_z_p'] = 0.0
GL.Globals['D_phi_x'] = 0.0
GL.Globals['D_phi_y'] = 0.0
GL.Globals['D_phi_x_p'] = 0.0
GL.Globals['D_phi_y_p'] = 0.0
GL.Globals['D_phi_z_p'] = 0.0
GL.Globals['D_omega_1'] = 0.0
GL.Globals['D_omega_2'] = 0.0
GL.Globals['D_omega_3'] = 0.0
GL.Globals['D_omega_4'] = 0.0

# Calculate mesh variables

# -> z <-
File = open("Systemmatrizen/MeshInfo/z.txt")
Values = File.readlines()
File.close()
GL.Globals['z_Range'] = float(Values[1])
GL.Globals['z_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['z_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['z_Mesh'] = 0.0

# -> x_p <-
File = open("Systemmatrizen/MeshInfo/x_p.txt")
Values = File.readlines()
File.close()
GL.Globals['x_p_Range'] = float(Values[1])
GL.Globals['x_p_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['x_p_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['x_p_Mesh'] = 0.0
	
# -> y_p <-
File = open("Systemmatrizen/MeshInfo/y_p.txt")
Values = File.readlines()
File.close()
GL.Globals['y_p_Range'] = float(Values[1])
GL.Globals['y_p_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['y_p_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['y_p_Mesh'] = 0.0

# -> z_p <-
File = open("Systemmatrizen/MeshInfo/z_p.txt")
Values = File.readlines()
File.close()
GL.Globals['z_p_Range'] = float(Values[1])
GL.Globals['z_p_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['z_p_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['z_p_Mesh'] = 0.0

# -> phi_x <-
File = open("Systemmatrizen/MeshInfo/phi_x.txt")
Values = File.readlines()
File.close()
GL.Globals['phi_x_Range'] = float(Values[1])
GL.Globals['phi_x_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['phi_x_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['phi_x_Mesh'] = 0.0

# -> phi_y <-
File = open("Systemmatrizen/MeshInfo/phi_y.txt")
Values = File.readlines()
File.close()
GL.Globals['phi_y_Range'] = float(Values[1])
GL.Globals['phi_y_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['phi_y_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['phi_y_Mesh'] = 0.0

# -> phi_x_p <-
File = open("Systemmatrizen/MeshInfo/phi_x_p.txt")
Values = File.readlines()
File.close()
GL.Globals['phi_x_p_Range'] = float(Values[1])
GL.Globals['phi_x_p_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['phi_x_p_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['phi_x_p_Mesh'] = 0.0

# -> phi_y_p <-
File = open("Systemmatrizen/MeshInfo/phi_y_p.txt")
Values = File.readlines()
File.close()
GL.Globals['phi_y_p_Range'] = float(Values[1])
GL.Globals['phi_y_p_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['phi_y_p_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['phi_y_p_Mesh'] = 0.0

# -> phi_z_p <-
File = open("Systemmatrizen/MeshInfo/phi_z_p.txt")
Values = File.readlines()
File.close()
GL.Globals['phi_z_p_Range'] = float(Values[1])
GL.Globals['phi_z_p_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['phi_z_p_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['phi_z_p_Mesh'] = 0.0
	
# -> omega_1 <-
File = open("Systemmatrizen/MeshInfo/omega_1.txt")
Values = File.readlines()
File.close()
GL.Globals['omega_1_Range'] = float(Values[1])
GL.Globals['omega_1_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['omega_1_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['omega_1_Mesh'] = 0.0

# -> omega_2 <-
File = open("Systemmatrizen/MeshInfo/omega_2.txt")
Values = File.readlines()
File.close()
GL.Globals['omega_2_Range'] = float(Values[1])
GL.Globals['omega_2_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['omega_2_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['omega_2_Mesh'] = 0.0

# -> omega_3 <-
File = open("Systemmatrizen/MeshInfo/omega_3.txt")
Values = File.readlines()
File.close()
GL.Globals['omega_3_Range'] = float(Values[1])
GL.Globals['omega_3_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['omega_3_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['omega_3_Mesh'] = 0.0

# -> omega_4 <-
File = open("Systemmatrizen/MeshInfo/omega_4.txt")
Values = File.readlines()
File.close()
GL.Globals['omega_4_Range'] = float(Values[1])
GL.Globals['omega_4_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['omega_4_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['omega_4_Mesh'] = 0.0

# -> delta_f <-
File = open("Systemmatrizen/MeshInfo/delta_f.txt")
Values = File.readlines()
File.close()
GL.Globals['delta_f_Range'] = float(Values[1])
GL.Globals['delta_f_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['delta_f_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['delta_f_Mesh'] = 0.0

# -> M_a_f <-
File = open("Systemmatrizen/MeshInfo/M_a_f.txt")
Values = File.readlines()
File.close()
GL.Globals['M_a_f_Range'] = float(Values[1])
GL.Globals['M_a_f_Min'] = float(Values[0])
if float(Values[1]) != 0.0:
	GL.Globals['M_a_f_Mesh'] = (float(Values[2]) - 1.0) / float(Values[1])
else:
	GL.Globals['M_a_f_Mesh'] = 0.0
