# Albert Cardona 2007 at Telluride
cd ../../host/java/src
mkdir -p mybuild
javac -d mybuild -classpath $(echo $(JARS=$(find ../jars/ -name "*jar"); echo $JARS | sed -e 's/ /:/g')) $(find . -name "*java")
