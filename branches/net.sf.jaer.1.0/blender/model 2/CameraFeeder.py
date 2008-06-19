# Albert Cardona 2007 at Telluride
# This script is called every few game logic ticks for the camera object in a Blender scene
# The camera is mounted on top of a car.

# Continuous camera capture, sending events to jAER client through sockets

from Blender.BGL import *
import Rasterizer
import GameLogic
import socket
import threading
import time
import struct
import traceback

from math import log


def frange(start, size, inc):
	"""
	A range() for floats.
	"""
	lst = [start]
	val = start
	count = 1
	while 1:
		val += inc
		if size == count: #if val >= size:
			return lst
		count += 1
		lst.append(val)

# Note: I tried with NumPy, but the module fails to load after the second time (known bug)
def resize(list, width, height, w, h):
	"""
	Resize the image stored in the unidimensional list from width,height to w,h
	"""
	# Perform crude nearest neighbor without numpy, since the latter fails to load
	# indices on the x axis
	xi = [int(round(f)) for f in frange(0, w, float(width)/w)] # bigger divided by smaller, since it's the big list that has to be sampled
	if xi[-1] >= len(list):
		xi = xi[0:-1]
	# indices on the y axis
	yi = [int(round(f)) for f in frange(0, h, float(height)/h)]
	if yi[-1] >= len(list):
		yi = yi[0:-1]
	lst = []
	for y in yi:
		for x in xi:
			lst.append(list[y * width + x])
	return lst

def scaleImage128(a, width, height):
	global iframes
	"""
	Scale the given image, represented by the unidimensional array 'a'
	to a maximum of 128x128 but preserving the aspect ratio
	Returns a tuple with the resized array and the new width
	"""
	# resize to 128 max width or max height
	w = 0
	h = 0
	if width > 128:
		w = 128
		h = (128.0 / width) * height
		if h > 128:
			h = 128
			w = int((128.0 / height) * 128)
		else:
			h = int(h)
	elif height > 128:
		h = 128
		w = int((128.0 / height) * width)
	else:
		# untouched
		return a, width
	a = resize(a, width, height, w, h)
	return a, w


def createEvents(pix1, pix2, width, threshold):
	"""
	Takes two byte arrays and the width, and creates the events as x,y,log(pixdiff) 
	"""
	event = []
	if 0 == len(pix1) or 0 == len(pix2):
		return event
	# print len(pix1), len(pix2)
	i = -1
	for a, b in zip(pix1, pix2):
		i += 1
		if a == b:
			continue
		# handle logarithms of zero
		if 0 == a:
			a = 1
		elif 0 == b: # both can't be zero simultaneously
			b = 1
		val = log(a) - log(b)
		if abs(val) > threshold:
			# generate event. A jAER event is a 16 bit, with first bit zero, 7 bits for y, 7 bits for x and final bit for positive/negative change. The code below will NOT work as expected if the X and Y 's meaningful part is larger than 7-bit
			sign = 0
			if val > 0:
				sign = 1
			#              X                            Y
			event.append(((width - (i % width))<<1) + ((i / width)<<8) + sign);
	return event



# capture the bounding box just once, at startup, while not defined
try:
	b = Rasterizer.AB_bbox
except:
	# allocate 4 integers to capture the box (x,y,width,height) of the GL_FRONT
	b = Buffer(GL_INT, 4)
	# capture the GL_FRONT bounding box
	glGetIntegerv(GL_VIEWPORT, b)
	Rasterizer.AB_bbox = b

# the image will be scaled preserving aspect ratio to 128x128 or smaller

# select the front buffer (the game window)
glReadBuffer(GL_FRONT)
# allocate a buffer for the image
pix = Buffer(GL_BYTE, b[2] * b[3])
# fill the pix array taken from the box
glReadPixels(b[0], b[1], b[2], b[3], GL_LUMINANCE, GL_BYTE, pix)  # GL_COLOR_INDEX generates pixels with value zero ...

try:
	ma = Rasterizer.AB_frame
except:
	# if not defined, create it as the same
	if b[2] > 128 or b[3] > 128:
		# ensure maximum dimensions 128x128
		ma, width = scaleImage128(pix.list, b[2], b[3])
	else:
		ma = pix.list
	Rasterizer.AB_frame = ma

# on the C side, generate events and update the matrix
if b[2] > 128 or b[3] > 128:
	scaled_pix, width = scaleImage128(pix.list, b[2], b[3])
	events = createEvents(ma, scaled_pix, width, 0.08)
	Rasterizer.AB_frame = scaled_pix
else:
	events = createEvents(ma, pix.list, b[2], 0.08)
	Rasterizer.AB_frame = pix.list

# on the C side, the actual object AB_frame was being edite;d so now it needs to be assigned
# (done above)

# A server to send events to the jAER and receive commands from it
class Server(threading.Thread):
	def __init__(self):
		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.sock.settimeout(5) # two seconds
		self.client = None
		self.quit = 0
	def run(self):
		try:
			# setup
			self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
			print 'set binding...'
			self.sock.bind(('0.0.0.0', 8991)) # chosen one higher than jAERs server socket port of 8990
			print 'set listening...'
			self.sock.listen(5)
			print 'waiting for client to connect...'
			# serve until first client comes in
			count = 5
			while 1:
				if self.quit:
					break
				try:
					self.client, self.data = self.sock.accept()
					self.client.setblocking(0)
				except socket.timeout:
					print 'timed out', count
					count -= 1
					if 0 == count: break
					continue
				print "Connected to", self.data[0]
				break
		except:
			traceback.print_exc()
			self.sock.close()
	def doQuit(self):
		try:
			self.sock.shutdown()
			self.sock.close()
			self.quit = 1
		except:
			traceback.print_exc()
			print 'Could not quit server'

def setupServer():
	global server, start_time
	start_time = time.time()
	Rasterizer.AB_start_time = start_time
	server = Server()
	Rasterizer.AB_server = server
	#server.start() # fork
	print "Waiting for client connection..."
	server.run() # without forking, waiting (otherwise with start() it never works (?) )

def doSteer(steer, fwd):
	if GameLogic.Globals['ManualSteering'] == 0:
		GameLogic.Globals['delta_f'] = steer * 0.1
		
	if GameLogic.Globals['ManualSpeedControl'] == 0:
		GameLogic.Globals['delta_f'] = fwd - 0.5

# create a server, to keep around always as a global in the Rasterizer module
try:
	server = Rasterizer.AB_server
	start_time = Rasterizer.AB_start_time
except:
	traceback.print_exc()
	# doesn't exist yet, create
	setupServer()

# wait, sort of (go for the next game clock tick)
if server.client is None:
	print 'client not connected'
else:
	# send events to the client jAER
	now = int( (time.time() - start_time) * 1e6 ) # in microseconds
	packet = ""
	# create one compound packet with all events
	for e in events:
		# pack into a char string of 2 bytes (a short) and 4 bytes (a long)
		packet += struct.pack('!HL', e, now) # as standard, no byte padding
	try:
		# continuously send the packet until it's sent in full
		while packet:
			busy = False
			slen = 0
			try:
				slen = server.client.send(packet)
			except:
				pass
			if slen: busy = True
			packet = packet[slen:]

			# read incomming command packets until there are no more to read
			while 1:
				data = ""
				while len(data) < 12:
					try:
						data += server.client.recv(12 - len(data))
						#print "temp: ", `data`
					except: pass
					if not data or 0 == len(data): break
				if data:
					busy = True
					# parse data
					h, steer, fwd = struct.unpack('!fff', data)
					#print h, steer, fwd
					print "steer:", steer, "   fwd:", fwd
					doSteer(steer, fwd)
				break
			if not busy: time.sleep(1e-3) # to prevent too fast calls (-11 error) on the send
			#if data: print `data`
	except:
		traceback.print_exc()
		print 'connection is broken'
		server.doQuit()
		setupServer()