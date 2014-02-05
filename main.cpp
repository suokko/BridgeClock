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
#include <stdlib.h>

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

#ifndef WIN32
    QByteArray arr = (QCoreApplication::applicationDirPath() + "/lib").toUtf8();
    const char *cur = getenv("LD_LIBRARY_PATH");
    if (cur) {
        arr = arr + ":" + cur;
    }
    const char *path = arr.data();
    setenv("LD_LIBRARY_PATH", path, 1);
#endif
    qmlRegisterType<RoundInfo>();
    qmlRegisterType<TimeModel>("org.bridgeClock", 1, 0, "TimeModel");
    qmlRegisterType<GlobalMouseArea>("org.bridgeClock", 1, 0, "GlobalMouseArea");
    qmlRegisterType<MouseEvent>();

    QQmlApplicationEngine eng;
    TimeController timeController;
    eng.rootContext()->setContextProperty("timeController", &timeController);
    eng.load("qml/BridgeClock/main.qml");

    return app.exec();
}
