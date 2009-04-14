# ********************************************
# * Python Script to capture the drive route *
# ********************************************

# Author: Robin Ritz

# Import modules
import GameLogic as GL

# Check settings
If GL.Globals['CaptureRoute'] == 1:
	
	# Delete file if existing
	Filename = "Routes/CapturedRoute.txt"
	delete(Filename)
	