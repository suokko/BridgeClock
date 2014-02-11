
TARGET = BridgeClock

linux: QMAKE_LFLAGS += -Wl,--rpath=\\\$\$ORIGIN/lib

QMAKE_CXXFLAGS += -std=c++11 -g

QT += quick webkit

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    timecontroller.cpp \
    timemodel.cpp \
    roundinfo.cpp \
    globalmousearea.cpp \
    mouseevent.cpp \
    versionchecker.cpp

lupdate_only {
SOURCES += qml/BridgeClock/*.qml
}

TRANSLATIONS = locale/BridgeClock_en.ts \
	locale/BridgeClock_fi.ts \
	locale/BridgeClock_sv.ts

update.commands = lupdate $$PWD/BridgeClock.pro -locations relative
update.depends = $$SOURES $$HEADERS $$OTHER_FILES
release.commands = cd $$PWD && lrelease BridgeClock.pro
release.depends = $$join($$TRANSLATIONS, "", $$PWD)

QMAKE_EXTRA_TARGETS += update release


# Installation path
# target.path =

# Please do not modify the following two lines. Required for deployment.

OTHER_FILES += \
    bonjour/LICENSE.bonjour.helper \
    LICENSE \
    qml/BridgeClock/ResultView.qml \
    qml/BridgeClock/fn.js \
    qml/BridgeClock/circularSliderHandle.png \
    qml/BridgeClock/circularSlider.png \
    qml/BridgeClock/tournamentTime.qml \
    qml/BridgeClock/tournamentStart.qml \
    qml/BridgeClock/tournamentResults.qml \
    qml/BridgeClock/Resizer.qml \
    qml/BridgeClock/PseudoTime.qml \
    qml/BridgeClock/main.qml \
    qml/BridgeClock/DatePicker.qml \
    qml/BridgeClock/Clock.qml \
    qml/BridgeClock/CircularSlider.qml \
    user.settings.pri

HEADERS += \
    timecontroller.h \
    timemodel.h \
    roundinfo.h \
    globalmousearea.h \
    mouseevent.h \
    versionchecker.h
