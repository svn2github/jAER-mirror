# ****************************************
# * Python Script to change the settings *
# ****************************************

# Author: Robin Ritz

# Import modules
import GameLogic as GL

# Get Sensors
Cont = GL.getCurrentController()
A = Cont.getSensor("A")
S = Cont.getSensor("S")
C = Cont.getSensor("C")

# Change between manual and automatic control
if A.isPositive():
	if GL.Globals['ManualSpeedControl'] == 0:
		GL.Globals['ManualSpeedControl'] = 1
		print "Automatic speed control is off"
	else:
		GL.Globals['ManualSpeedControl'] = 0
		print "Automatic speed control is on"
		
if S.isPositive():
	if GL.Globals['ManualSteering'] == 0:
		GL.Globals['ManualSteering'] = 1
		print "Automatic steering is off"
	else:
		GL.Globals['ManualSteering'] = 0
		print "Automatic steering is on"

# Change route capturing
if C.isPositive():
	if GL.Globals['CaptureRoute'] == 0:
		GL.Globals['CaptureRoute'] = 1
		print "Route capturing activated"
	else:
		GL.Globals['CaptureRoute'] = 0
		print "Route capturing deactivated"