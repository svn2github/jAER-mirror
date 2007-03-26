%function startup
% on startup setup the java class path for the stuff here

% sets up path to use usb2 java classes
disp 'setting up java classpath for usb ae/bias interfacing'
here=fileparts(mfilename('fullpath'));
% jars are up and down from us
p=[here,'\..\java\'];
javaaddpath([p,'dist\usb2aemon.jar']);
javaaddpath([p,'jars\usbiojava.jar']);
%javaaddpath([p,'jars\jogl.jar']);  % if you get complaint here, remove the jogl in matlab's static classpath.txt

global factory
factory = ch.unizh.ini.caviar.hardwareinterface.usb.CypressFX2Factory.instance()