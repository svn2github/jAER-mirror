rem runs the eeprom programming utility for the CypressFX2/LP boards

rem cd "C:\Documents and Settings\tobi\My Documents\avlsi-svn\CAVIAR\wp5\USBAER\INI-AE-Biasgen\host\java"
cd host\java

rem add the java native path components
PATH=%PATH%;%CD%\JNI;%CD%\JNI\SiLabsNativeWindows

java -Xms100m -Xmx400m -DJOGL_SINGLE_THREADED_WORKAROUND=true -Dsun.java2d.opengl=false -Dsun.java2d.noddraw=true -cp dist\jAER.jar;jars\usbiojava.jar;jars\swing-layout-0.9.jar;jars\jogl.jar ch.unizh.ini.caviar.hardwareinterface.usb.CypressFX2EEPROM
pause
