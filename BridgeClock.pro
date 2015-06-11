
TARGET = BridgeClock

linux: QMAKE_LFLAGS += -Wl,--rpath=\\\$\$ORIGIN/lib

QMAKE_CXXFLAGS += -std=c++11 -g

QT += quick webkit gui

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    timecontroller.cpp \
    timemodel.cpp \
    roundinfo.cpp \
    globalmousearea.cpp \
    mouseevent.cpp \
    versionchecker.cpp \
    languagemodel.cpp \
    iconprovider.cpp \
    compactmodel.cpp

lupdate_only {
SOURCES += qml/BridgeClock/*.qml
}

TRANSLATIONS = \
	locale/BridgeClock_da_DK.ts \
	locale/BridgeClock_de_DE.ts \
	locale/BridgeClock_cs_CZ.ts \
	locale/BridgeClock_en_US.ts \
	locale/BridgeClock_es_ES.ts \
	locale/BridgeClock_et_EE.ts \
	locale/BridgeClock_fi_FI.ts \
	locale/BridgeClock_fr_FR.ts \
	locale/BridgeClock_he_IL.ts \
	locale/BridgeClock_it_IT.ts \
	locale/BridgeClock_lv_LV.ts \
	locale/BridgeClock_nb_NO.ts \
	locale/BridgeClock_nl_NL.ts \
	locale/BridgeClock_pl_PL.ts \
	locale/BridgeClock_ru_RU.ts \
	locale/BridgeClock_sv_SE.ts \
	locale/BridgeClock_zh_CN.ts \
# End of list comment

lupdate.commands = lupdate $$PWD/BridgeClock.pro -locations absolute
lupdate.depends = $$SOURES $$HEADERS $$OTHER_FILES
lrelease.commands = cd $$PWD && lrelease BridgeClock.pro
lrelease.depends = $$join($$TRANSLATIONS, "", $$PWD)

QMAKE_EXTRA_TARGETS += lupdate lrelease


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
    qml/BridgeClock/VisibleText.qml

HEADERS += \
    timecontroller.h \
    timemodel.h \
    roundinfo.h \
    globalmousearea.h \
    mouseevent.h \
    versionchecker.h \
    languagemodel.h \
    iconprovider.h \
    compactmodel.h
