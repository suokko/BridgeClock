
#include <QGuiApplication>

#include <QQmlApplicationEngine>
#include <QtQml>

#include "timecontroller.h"
#include "timemodel.h"
#include "roundinfo.h"

#ifndef WIN32
extern "C" {
    int XInitThreads();
}
#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
#ifndef WIN32
    XInitThreads();
#endif
    QScopedPointer<QGuiApplication> app(new QGuiApplication(argc, argv));
    qmlRegisterType<RoundInfo>();
    qmlRegisterType<TimeModel>();

    QQmlApplicationEngine eng;
    TimeController timeController;
    eng.rootContext()->setContextProperty("timeController", &timeController);
    eng.load("qml/BridgeClock/main.qml");

#if 0
    viewer.setStyleSheet("background:transparent");
    viewer.setAttribute(Qt::WA_TranslucentBackground);
    viewer.setWindowFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);

    viewer2.setFlags(Qt::FramelessWindowHint);
    viewer2.connect(&viewer, SIGNAL(closing(QQuickCloseEvent*)), SLOT(close()));
    viewer2.show();
    viewer.show();
#endif
    return app->exec();
}
