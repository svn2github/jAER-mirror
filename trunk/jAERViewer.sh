# this script starts JAERViewer under linux if it is run from the root folder of jAER

# cd to the root folder of jAER

cd `dirname $0`

#cd to host/java so that relative paths work
cd host/java

# run main class using paths relative to this path
java -DJOGL_SINGLE_THREADED_WORKAROUND=false -Djava.library.path=JNI -Dsun.java2d.opengl=false -Dsun.java2d.noddraw=true -cp dist/jAER.jar:jars/spread.jar:jars/UsbIoJava.jar:jars/swing-layout-0.9.jar:jars/jogl.jar ch.unizh.ini.caviar.JAERViewer 
