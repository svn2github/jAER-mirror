rem runs the CaviarViewer application to monitor/log/playback AE events using USB2 interface
cd
echo %1
cd host\java

rem the java native code MUST be on windows PATH, not just on java.library.path. The SiLabs JNI DLL wont find the SiUSBXp.dll if it is not on Windows PATH 
PATH=%PATH%;%CD%\JNI;%CD%\JNI\SiLabsNativeWindows

rem -Djava.library.path="%CD%\JNI;%CD%\JNI\SiLabsNativeWindows"

java -Xms100m -Xmx512m  -DJOGL_SINGLE_THREADED_WORKAROUND=false -Dsun.java2d.opengl=false -Dsun.java2d.noddraw=true -cp dist\jAER.jar;jars\usbiojava.jar;jars\swing-layout-0.9.jar;jars\jogl.jar ch.unizh.ini.caviar.hardwareinterface.usb.ServoTest %1
pause
