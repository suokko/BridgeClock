/*
Copyright (c) 2013 Pauli Nieminen <suokkos@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include <QGuiApplication>

#include <QQmlApplicationEngine>
#include <QtQml>

#include "timecontroller.h"
#include "timemodel.h"
#include "roundinfo.h"
#include "globalmousearea.h"
#include "mouseevent.h"
#include "languagemodel.h"
#include <stdlib.h>

#if defined(WIN32) || defined(__WIN32)
#include <stdio.h>
void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QByteArray localMsg = msg.toLocal8Bit();
    switch (type) {
        case QtDebugMsg:
            fprintf(stderr, "Debug: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
            break;
        case QtInfoMsg:
             fprintf(stderr, "Info: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
             break;
        case QtWarningMsg:
            fprintf(stderr, "Warning: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
            break;
        case QtCriticalMsg:
            fprintf(stderr, "Critical: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
            break;
        case QtFatalMsg:
            fprintf(stderr, "Fatal: %s (%s:%u, %s)\n", localMsg.constData(), context.file, context.line, context.function);
            abort();
    }
}
#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
#if defined(WIN32) || defined(__WIN32)
    qInstallMessageHandler(myMessageOutput);
#endif
    QGuiApplication app(argc, argv);

#if !defined(WIN32) && !defined(__WIN32)
    QByteArray arr = (QCoreApplication::applicationDirPath() + "/lib").toUtf8();
    const char *cur = getenv("LD_LIBRARY_PATH");
    if (cur) {
        arr = arr + ":" + cur;
    }
    const char *path = arr.data();
    setenv("LD_LIBRARY_PATH", path, 1);
#endif

    QCoreApplication::setOrganizationDomain("bridgefinland.fi");
    QCoreApplication::setOrganizationName("SBL");
    QCoreApplication::setApplicationName("BridgeClock");

    LanguageModel lang;

    qmlRegisterType<RoundInfo>();
    qmlRegisterType<TimeModel>("org.bridgeClock", 1, 0, "TimeModel");
    qmlRegisterType<GlobalMouseArea>("org.bridgeClock", 1, 0, "GlobalMouseArea");
    qmlRegisterType<MouseEvent>();
    qmlRegisterType<TimeModelVariant>();

    TimeController timeController;
    timeController.connect(&lang,SIGNAL(selectedChanged()),SLOT(languageChange()));

    QQmlApplicationEngine eng;
    eng.rootContext()->setContextProperty("timeController", &timeController);
    eng.rootContext()->setContextProperty("lang", &lang);
    eng.load("qml/BridgeClock/main.qml");

    return app.exec();
}
