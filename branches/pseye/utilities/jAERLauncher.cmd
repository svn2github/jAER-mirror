rem runs the jaer launcher application to monitor the USB bus for plugged in devices, to launch jAERViewer automatically.
cd
echo %1
cd ..\host\java

rem the java native code MUST be on windows PATH, not just on java.library.path. The SiLabs JNI DLL wont find the SiUSBXp.dll if it is not on Windows PATH 
PATH=%PATH%;%CD%\JNI;%CD%\JNI\SiLabsNativeWindows

rem -Djava.library.path="%CD%\jars;%CD%\jars\SiLabsNativeWindows"

rem To use the server JVM 
rem (which takes a bit longer to start up and has some hotspot compilation hiccups but has significantly better performance), 
rem you must copy the "server" folder to the JRE you're using; it is e.g. here "C:\Program Files\Java\jdk1.5.0_06\jre\bin\server"
rem copy the server folder to your JRE, e.g. here "C:\Program Files\Java\jre1.5.0_08\bin"
rem Then if you want the server JVM by default, edit the file e.g. "C:\Program Files\Java\jdk1.5.0_06\jre\lib\i386\jvm.cfg" to make
rem the server the default JVM

start javaw -Xms100m -Xmx512m  -DJOGL_SINGLE_THREADED_WORKAROUND=false -Dsun.java2d.opengl=false -Dsun.java2d.noddraw=true -cp dist\jAER.jar;jars\usbiojava.jar;jars\swing-layout-0.9.jar;jars\jogl.jar;jars\spread.jar net.sf.jaer.JAERTrayLauncher %1