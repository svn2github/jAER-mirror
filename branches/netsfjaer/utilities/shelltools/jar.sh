# Albert Cardona 2007 at Telluride
WD=`pwd`
cd ../../host/java/src
cd mybuild
jar cf jAER.jar ch
mv -f jAER.jar ../
cd $WD
sh clean.sh
