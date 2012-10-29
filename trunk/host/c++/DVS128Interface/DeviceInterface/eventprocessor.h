#ifndef EVENTPROCESSOR_H
#define EVENTPROCESSOR_H

#include "eventprocessorbase.h"
#include "event.h"
#include <QImage>

class EventProcessor : public EventProcessorBase
{
public:
    EventProcessor();
    ~EventProcessor();
    virtual void processEvent(Event e);
    QImage* getImage();

private:
    // Graphical output
    void updateImage(Event *e);
    QImage * img;
};

#endif // EVENTPROCESSOR_H
