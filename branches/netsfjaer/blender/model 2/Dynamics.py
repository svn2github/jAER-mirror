# *********************************************************************
# * Python Script for calculating the dynamics of the RC Monstertruck *
# *********************************************************************

# Author: Robin Ritz

# Import modules
import GameLogic as GL
import math as M
import time

# Get Blender factor
Blender_Factor = GL.Globals['Blender_Factor']

# Calculate time since last call
D_t = time.time() - GL.Globals['Last_Timestamp']
GL.Globals['Last_Timestamp'] = time.time()

# Calculate current states
GL.Globals['z'] = max(min(GL.Globals['z'] + GL.Globals['D_z'] * D_t, GL.Globals['Upper_Limit_z']), GL.Globals['Lower_Limit_z'])
GL.Globals['x_p'] = GL.Globals['x_p'] + GL.Globals['D_x_p'] * D_t
GL.Globals['y_p'] = GL.Globals['y_p'] + GL.Globals['D_y_p'] * D_t
GL.Globals['z_p'] = GL.Globals['z_p'] + GL.Globals['D_z_p'] * D_t
GL.Globals['phi_x'] = max(min(GL.Globals['phi_x'] + GL.Globals['D_phi_x'] * D_t, GL.Globals['Upper_Limit_phi_x']), GL.Globals['Lower_Limit_phi_x'])
GL.Globals['phi_y'] = max(min(GL.Globals['phi_y'] + GL.Globals['D_phi_y'] * D_t, GL.Globals['Upper_Limit_phi_y']), GL.Globals['Lower_Limit_phi_y'])
GL.Globals['phi_x_p'] = GL.Globals['phi_x_p'] + GL.Globals['D_phi_x_p'] * D_t
GL.Globals['phi_y_p'] = GL.Globals['phi_y_p'] + GL.Globals['D_phi_y_p'] * D_t
GL.Globals['phi_z_p'] = GL.Globals['phi_z_p'] + GL.Globals['D_phi_z_p'] * D_t
GL.Globals['omega_1'] = GL.Globals['omega_1'] + GL.Globals['D_omega_1'] * D_t
GL.Globals['omega_2'] = GL.Globals['omega_2'] + GL.Globals['D_omega_2'] * D_t
GL.Globals['omega_3'] = GL.Globals['omega_3'] + GL.Globals['D_omega_3'] * D_t
GL.Globals['omega_4'] = GL.Globals['omega_4'] + GL.Globals['D_omega_4'] * D_t

# Check for limits
if GL.Globals['z'] == GL.Globals['Upper_Limit_z']:
	GL.Globals['z_p'] = min(GL.Globals['z_p'], 0)
elif GL.Globals['z'] == GL.Globals['Lower_Limit_z']:
	GL.Globals['z_p'] = max(GL.Globals['z_p'], 0)

if GL.Globals['phi_x'] == GL.Globals['Upper_Limit_phi_x']:
	GL.Globals['phi_x_p'] = min(GL.Globals['phi_x_p'], 0)
elif GL.Globals['phi_x'] == GL.Globals['Lower_Limit_phi_x']:
	GL.Globals['phi_x_p'] = max(GL.Globals['phi_x_p'], 0)
	
if GL.Globals['phi_y'] == GL.Globals['Upper_Limit_phi_y']:
	GL.Globals['phi_y_p'] = min(GL.Globals['phi_y_p'], 0)
elif GL.Globals['phi_y'] == GL.Globals['Lower_Limit_phi_y']:
	GL.Globals['phi_y_p'] = max(GL.Globals['phi_y_p'], 0)

# Set speed and rotation for the body
GL.Globals['Motion_Actuator_Body_Point'].setDLoc(Blender_Factor * GL.Globals['x_p'],Blender_Factor * GL.Globals['y_p'],Blender_Factor * GL.Globals['z_p'],1)
GL.Globals['Motion_Actuator_Body_Point'].setDRot(0,0,-Blender_Factor * GL.Globals['phi_z_p'],0)
GL.Globals['Motion_Actuator_Body'].setDRot(-Blender_Factor * GL.Globals['phi_x_p'],-Blender_Factor * GL.Globals['phi_y_p'],0,1)
GL.addActiveActuator(GL.Globals['Motion_Actuator_Body_Point'],1)
GL.addActiveActuator(GL.Globals['Motion_Actuator_Body'],1)

# Set rotation for the wheels
GL.Globals['Rotation_Actuator_Wheel_1'].setDRot(0,-Blender_Factor * GL.Globals['omega_1'],0,1)
GL.addActiveActuator(GL.Globals['Rotation_Actuator_Wheel_1'],1)
GL.Globals['Rotation_Actuator_Wheel_2'].setDRot(0,-Blender_Factor * GL.Globals['omega_2'],0,1)
GL.addActiveActuator(GL.Globals['Rotation_Actuator_Wheel_2'],1)
GL.Globals['Rotation_Actuator_Wheel_3'].setDRot(0,-Blender_Factor * GL.Globals['omega_3'],0,1)
GL.addActiveActuator(GL.Globals['Rotation_Actuator_Wheel_3'],1)
GL.Globals['Rotation_Actuator_Wheel_4'].setDRot(0,-Blender_Factor * GL.Globals['omega_4'],0,1)
GL.addActiveActuator(GL.Globals['Rotation_Actuator_Wheel_4'],1)

# Get inputs
Cont = GL.getCurrentController()
Left = Cont.getSensor("Left")
Right = Cont.getSensor("Right")
Forward = Cont.getSensor("Forward")

if GL.Globals['ManualSteering'] == 1:
	if Left.isPositive() and not Right.isPositive():
		GL.Globals['delta_f'] = 0.1
	elif Right.isPositive() and not Left.isPositive():
		GL.Globals['delta_f'] = -0.1
	else:
		GL.Globals['delta_f'] = 0.0

if GL.Globals['ManualSpeedControl'] == 1:
	if Forward.isPositive():
		GL.Globals['M_a_f'] = 1.0
	else:
		GL.Globals['M_a_f'] = 0.0

# Calculate current counters
z_C = int(round((GL.Globals['z_Mesh'] * max(min(GL.Globals['z'] - GL.Globals['z_Min'], GL.Globals['z_Range']), 0)) + 1, 0))
x_p_C = int(round((GL.Globals['x_p_Mesh'] * max(min(GL.Globals['x_p'] - GL.Globals['x_p_Min'], GL.Globals['x_p_Range']), 0)) + 1, 0))
y_p_C = int(round((GL.Globals['y_p_Mesh'] * max(min(GL.Globals['y_p'] - GL.Globals['y_p_Min'], GL.Globals['y_p_Range']), 0)) + 1, 0))
z_p_C = int(round((GL.Globals['z_p_Mesh'] * max(min(GL.Globals['z_p'] - GL.Globals['z_p_Min'], GL.Globals['z_p_Range']), 0)) + 1, 0))
phi_x_C = int(round((GL.Globals['phi_x_Mesh'] * max(min(GL.Globals['phi_x'] - GL.Globals['phi_x_Min'], GL.Globals['phi_x_Range']), 0)) + 1, 0))
phi_y_C = int(round((GL.Globals['phi_y_Mesh'] * max(min(GL.Globals['phi_y'] - GL.Globals['phi_y_Min'], GL.Globals['phi_y_Range']), 0)) + 1, 0))
phi_x_p_C = int(round((GL.Globals['phi_x_p_Mesh'] * max(min(GL.Globals['phi_x_p'] - GL.Globals['phi_x_p_Min'], GL.Globals['phi_x_p_Range']), 0)) + 1, 0))
phi_y_p_C = int(round((GL.Globals['phi_y_p_Mesh'] * max(min(GL.Globals['phi_y_p'] - GL.Globals['phi_y_p_Min'], GL.Globals['phi_y_p_Range']), 0)) + 1, 0))
phi_z_p_C = int(round((GL.Globals['phi_z_p_Mesh'] * max(min(GL.Globals['phi_z_p'] - GL.Globals['phi_z_p_Min'], GL.Globals['phi_z_p_Range']), 0)) + 1, 0))
omega_1_C = int(round((GL.Globals['omega_1_Mesh'] * max(min(GL.Globals['omega_1'] - GL.Globals['omega_1_Min'], GL.Globals['omega_1_Range']), 0)) + 1, 0))
omega_2_C = int(round((GL.Globals['omega_2_Mesh'] * max(min(GL.Globals['omega_2'] - GL.Globals['omega_2_Min'], GL.Globals['omega_2_Range']), 0)) + 1, 0))
omega_3_C = int(round((GL.Globals['omega_3_Mesh'] * max(min(GL.Globals['omega_3'] - GL.Globals['omega_3_Min'], GL.Globals['omega_3_Range']), 0)) + 1, 0))
omega_4_C = int(round((GL.Globals['omega_4_Mesh'] * max(min(GL.Globals['omega_4'] - GL.Globals['omega_4_Min'], GL.Globals['omega_4_Range']), 0)) + 1, 0))
delta_f_C = int(round((GL.Globals['delta_f_Mesh'] * max(min(GL.Globals['delta_f'] - GL.Globals['delta_f_Min'], GL.Globals['delta_f_Range']), 0)) + 1, 0))
M_a_f_C = int(round((GL.Globals['M_a_f_Mesh'] * max(min(GL.Globals['M_a_f'] - GL.Globals['M_a_f_Min'], GL.Globals['M_a_f_Range']), 0)) + 1, 0))

# Get filename of the current dynamic matrix
Filename = "Systemmatrizen/" + "-".join([str(z_C), str(x_p_C), str(y_p_C), str(z_p_C), str(phi_x_C), str(phi_y_C), str(phi_x_p_C), str(phi_y_p_C), str(phi_z_p_C), str(omega_1_C), str(omega_2_C), str(omega_3_C), str(omega_4_C), str(delta_f_C), str(M_a_f_C)]) + ".txt"

# Get current dynamic matrix
File = open(Filename)
Matrix = File.readlines()
File.close()

# Calculate new dynamics

# -> z <-
Koeff_A = Matrix[0].split()
Koeff_B = Matrix[13].split()
GL.Globals['D_z'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> x_p <-
Koeff_A = Matrix[1].split()
Koeff_B = Matrix[14].split()
GL.Globals['D_x_p'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> y_p <-
Koeff_A = Matrix[2].split()
Koeff_B = Matrix[15].split()
GL.Globals['D_y_p'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> z_p <-
Koeff_A = Matrix[3].split()
Koeff_B = Matrix[16].split()
GL.Globals['D_z_p'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> phi_x <-
Koeff_A = Matrix[4].split()
Koeff_B = Matrix[17].split()
GL.Globals['D_phi_x'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> phi_y <-
Koeff_A = Matrix[5].split()
Koeff_B = Matrix[18].split()
GL.Globals['D_phi_y'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> phi_x_p <-
Koeff_A = Matrix[6].split()
Koeff_B = Matrix[19].split()
GL.Globals['D_phi_x_p'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> phi_y_p <-
Koeff_A = Matrix[7].split()
Koeff_B = Matrix[20].split()
GL.Globals['D_phi_y_p'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> phi_z_p <-
Koeff_A = Matrix[8].split()
Koeff_B = Matrix[21].split()
GL.Globals['D_phi_z_p'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> omega_1 <-
Koeff_A = Matrix[9].split()
Koeff_B = Matrix[22].split()
GL.Globals['D_omega_1'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> omega_2 <-
Koeff_A = Matrix[10].split()
Koeff_B = Matrix[23].split()
GL.Globals['D_omega_2'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> omega_3 <-
Koeff_A = Matrix[11].split()
Koeff_B = Matrix[24].split()
GL.Globals['D_omega_3'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

# -> omega_4 <-
Koeff_A = Matrix[12].split()
Koeff_B = Matrix[25].split()
GL.Globals['D_omega_4'] = float(Koeff_A[0]) * GL.Globals['z'] + float(Koeff_A[1]) * GL.Globals['x_p']  + float(Koeff_A[2]) * GL.Globals['y_p'] + float(Koeff_A[3]) * GL.Globals['z_p'] + float(Koeff_A[4]) * GL.Globals['phi_x'] + float(Koeff_A[5]) * GL.Globals['phi_y'] + float(Koeff_A[6]) * GL.Globals['phi_x_p'] + float(Koeff_A[7]) * GL.Globals['phi_y_p'] + float(Koeff_A[8]) * GL.Globals['phi_z_p'] + float(Koeff_A[9]) * GL.Globals['omega_1'] + float(Koeff_A[10]) * GL.Globals['omega_2'] + float(Koeff_A[11]) * GL.Globals['omega_3'] + float(Koeff_A[12]) * GL.Globals['omega_4'] + float(Koeff_B[0]) * GL.Globals['delta_f'] + float(Koeff_B[1]) * GL.Globals['M_a_f']

#GL.Globals['z'] = 0.0
#GL.Globals['x_p'] = 0.0
#GL.Globals['y_p'] = 0.0
#GL.Globals['z_p'] = 0.0
#GL.Globals['phi_x'] = 0.0
#GL.Globals['phi_y'] = 0.0
#GL.Globals['phi_x_p'] = 0.0
#GL.Globals['phi_y_p'] = 0.0
#GL.Globals['phi_z_p'] = 0.0
#GL.Globals['omega_1'] = 0.0
#GL.Globals['omega_2'] = 0.0
#GL.Globals['omega_3'] = 0.0
#GL.Globals['omega_4'] = 0.0
