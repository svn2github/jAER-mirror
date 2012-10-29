#include <QApplication>

#include "dvs128interface.h"
#include "eventprocessor.h"
#include "camwidget.h"

int main(int argc, char **argv){
    QApplication app(argc,argv);
    EventProcessor ep;
    DVS128Interface dvs(&ep);
    CamWidget cw(ep.getImage());
    cw.show();

    dvs.startReading();
    return app.exec();
}
