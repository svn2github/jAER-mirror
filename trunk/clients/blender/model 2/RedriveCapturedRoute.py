# ************************************************************
# * Python Script to follow the same path as captured before *
# ************************************************************

# Author: Robin Ritz

# Import modules
import GameLogic as GL
import math as M

# Check settings
if GL.Globals['RedriveCapturedRoute'] == 1:
	
	# Get target position
	TargetPosition = GL.Globals['Route'][GL.Globals['RedriveRouteIndex']].split()
	
	# Set the position of the body point
	GL.Globals['Body_Point'].setPosition([TargetPosition[0],TargetPosition[1],0])
	
	
	
	
	
	# Update counter
	GL.Globals['RedriveRouteIndex'] = GL.Globals['RedriveRouteIndex'] + 1