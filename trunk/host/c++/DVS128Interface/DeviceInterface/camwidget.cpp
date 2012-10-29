#include "camwidget.h"
#include <QPainter>
#include <QTimer>
#include <QColor>
#include <stdio.h>

CamWidget::CamWidget(QImage *i, QWidget *parent) : QWidget(parent)
{
    img = i;

    QTimer *timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(update()));
    timer->start(20);
    setWindowTitle(tr("DVS128"));
    resize(512,512);
    counter = 0;
}

void CamWidget::paintEvent(QPaintEvent *event){
    QPainter painter(this);
    QRect rect(0,0,512,512);
    QColor color = Qt::black;
    painter.drawImage(rect,*img);

    for(int x = 0; x < 128; x++){
        for(int y = 0; y < 128; y++){
            QRgb *pixel = (QRgb*)img->scanLine(y);
            pixel = &pixel[x];
            *pixel = color.rgb();
        }
    }
}

void CamWidget::setImage(QImage *i){
    img = i;
}


