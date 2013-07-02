# Add more folders to ship with the application, here
# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=

# Speed up launching on MeeGo/Harmattan when using applauncherd daemon
# CONFIG += qdeclarative-boostable

TARGET = BridgeClock

linux {

	QMAKE_LFLAGS += -Wl,--rpath=\\\$\$ORIGIN/lib
}

QT += quick widgets

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    timecontroller.cpp \
    timemodel.cpp \
    roundinfo.cpp

# Installation path
# target.path =

# Please do not modify the following two lines. Required for deployment.

OTHER_FILES += \
    qml/BridgeClock/* \
    LICENSE

HEADERS += \
    timecontroller.h \
    timemodel.h \
    roundinfo.h
