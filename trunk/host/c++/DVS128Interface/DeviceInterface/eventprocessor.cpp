#include "eventprocessor.h"
#include "stdio.h"
#include <math.h>
#include <QColor>

#define DVS_RES 128


EventProcessor::EventProcessor(){
    img = new QImage(DVS_RES,DVS_RES,QImage::Format_RGB32);
}

EventProcessor::~EventProcessor(){
    delete img;
}

QImage* EventProcessor::getImage(){
    return img;
}

void EventProcessor::processEvent(Event e){
    updateImage(&e);
}

void EventProcessor::updateImage(Event *e){
    int x = 127-e->posX;
    int y = 127-e->posY;
    int type = e->polarity;
    QColor color;
    if(type == 1)
        color = Qt::red;
    else
        color = Qt::blue;
    QRgb *pixel = (QRgb*)img->scanLine(y);
    pixel = &pixel[x];
    *pixel = color.rgb();
}
