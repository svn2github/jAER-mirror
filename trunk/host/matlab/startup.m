%function startup
% on startup setup the java class path for the stuff here

% sets up path to use usb2 java classes
disp 'setting up java classpath for jAER interfacing'
here=fileparts(mfilename('fullpath'));
% jars are up and down from us
p=[here,'\..\java\'];
javaaddpath([p,'jars\swing-layout-0.9.jar']);
javaaddpath([p,'jars\UsbIoJava.jar']);
javaaddpath([p,'dist\jAER.jar']);
%javaaddpath([p,'jars\jogl.jar']);  % if you get complaint here, remove the jogl in matlab's static classpath.txt

% global factory
% factory = ch.unizh.ini.caviar.hardwareinterface.usb.CypressFX2Factory.instance()