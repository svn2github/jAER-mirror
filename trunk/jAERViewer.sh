#!/bin/bash

# this script starts JAERViewer under linux

# cd to the root folder of jAER
cd `dirname $0`

echo "checking driver..."
if [ ! -r /dev/retina0 ] ; then \
	echo "building driver..."; \
	cd drivers/driverRetinaLinux; \
	make; \
	echo "installing driver..."; \
	echo "please plug in a retina device..."; \
	sudo make install; \
	cd ../..
fi;
	
echo startup jAER...
#cd to host/java so that relative paths work
cd host/java
# -DJOGL_SINGLE_THREADED_WORKAROUND=false
# run main class using paths relative to this path
java -Xms160m -Xmx320m -Djava.util.logging.config.file=conf/Logging.properties -Djava.library.path=jars:jars/SiLabsNativeWindows -Dsun.java2d.opengl=false -Dsun.java2d.noddraw=true -cp dist/jAER.jar:jars/spread.jar:jars/UsbIoJava.jar:jars/swing-layout-0.9.jar:jars/jogl.jar:jars/comm.jar:jars/gluegen-rt.jar:jars/jsr80-1.0.1.jar:jars/jsr80_linux-1.0.1.jar:jars/jsr80_ri-1.0.1.jar:jars net.sf.jaer.JAERViewer


