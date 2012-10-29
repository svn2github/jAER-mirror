TEMPLATE = app
CONFIG += console

QT       += core

INCLUDEPATH += \
    inc \
    inc/usbiolib

SOURCES += main.cpp \
    usbreader.cpp \
    camwidget.cpp \
    event.cpp \
    eventprocessor.cpp \
    dvs128interface.cpp

HEADERS += \
    usbreader.h \
    stdafx.h \
    camwidget.h \
    event.h \
    eventprocessor.h \
    eventprocessorbase.h \
    dvs128interface.h



win32: LIBS += -L$$PWD/inc/usbiolib/Debug/Win32/ -lusbiolib

INCLUDEPATH += $$PWD/inc/usbiolib/Debug/Win32
DEPENDPATH += $$PWD/inc/usbiolib/Debug/Win32

win32: PRE_TARGETDEPS += $$PWD/inc/usbiolib/Debug/Win32/usbiolib.lib
