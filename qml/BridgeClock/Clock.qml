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

import QtQuick 2.0
import QtQuick.Window 2.0
import org.bridgeClock 1.0

Window {
    id: clockWindow
    property double zoomFactor: height/480
    width: 640
    height: 480
    visible: true
    title: "Aika näkymä"
    flags: Qt.FramelessWindowHint
    readonly property double scrollSpeed: 30
    property bool animationDown: true

    Rectangle {
        id: timeView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: time.font.pixelSize + 12*zoomFactor
        onHeightChanged: {
            results.doScale();
            resultsHidden.doScale();
        }

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 2*zoomFactor
            visible: timeController.roundInfo.playing < 2
            id: current
            text: timeController.roundInfo.name;
            font.pixelSize: 35*zoomFactor;
            font.weight: Font.DemiBold;
            transform: Scale {
                origin.x: 0;
                xScale: time.totalWidth <= clockWindow.width/2
                        ? 1 :
                          1 - (time.totalWidth - clockWindow.width/2)/(width / 2)/2;
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.margins: 3*zoomFactor
            id: time
            text: timeController.roundInfo.playing < 2 ?
                      timeController.roundInfo.timeLeft :
                      timeController.roundInfo.name;
            font.pixelSize: 120*zoomFactor;
            readonly property double totalWidth: width/2 + current.width;
            transform: Scale {
                origin.x: width/2;
                xScale: time.totalWidth <= clockWindow.width/2
                        ? 1 :
                          1 - (time.totalWidth - clockWindow.width/2)/(width / 2)/2;
            }
        }

        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 10*zoomFactor
            Text {
                id: nextHeading
                visible: timeController.roundInfo.playing < 2
                text: "Seuraavaksi:"
                font.pixelSize: 15*zoomFactor
                font.weight: Font.Light
            }

            Text {
                id: next
                visible: timeController.roundInfo.playing < 2
                text: timeController.roundInfo.nextName;
                font.pixelSize: 25*zoomFactor
                font.italic: true;
                font.weight: Font.Light;
            }
        }
    }

    Connections {
        target: timeController
        onUpdateResults: {
            if (resultsHidden.loadTarget)
                resultsHidden.url = url;
            else if (results.loadTarget)
                results.url = url;
            else
                console.log("NO LOAD TARGET")
        }
    }

    Timer {
         id: scrollTimer
         running: false
         repeat: false
         interval: 2000
         onTriggered: {
             if (!resultsHidden.loadTarget)
                 resultsHidden.animationSwitch();
             else
                 results.animationSwitch();
         }
    }

    ResultView {
        id: results
    }

    ResultView {
        id: resultsHidden
        loadTarget: true
    }

    GlobalMouseArea {
        id: mover
        anchors.fill: parent
        anchors.margins: 50*zoomFactor
        hoverEnabled: true
        property variant startPosition
        property variant windowPosition
        Rectangle {
            id: moverVisual
            anchors.fill: parent
            visible: resizeHelpVisible.running && mover.containsMouse
            border.width: 2
            border.color: "black"
            color: "transparent"
            radius: 5

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: fullScreenHelp.width + 10*zoomFactor
                height: fullScreenHelp.height + 10*zoomFactor
                color: "white"
                opacity: 0.90
                radius: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    id: fullScreenHelp
                    opacity: 1.0
                    font.pixelSize: 20*zoomFactor
                    text: clockWindow.visibility !== Qt.WindowFullScreen
                          ? "Kaksoisnäpäytyksellä täyttää ruudun" :
                            "Kaksoisnäpäytyksellä ikkunaksi";
                }
            }
        }

        Timer {
            id: resizeHelpVisible
            interval: 5000
            repeat: false
            running: false
        }

        signal windowState
        onDoubleClicked: {
            if (clockWindow.visibility == Qt.WindowFullScreen)
                clockWindow.visibility = Qt.WindowMaximized;
            else
                clockWindow.visibility = Qt.WindowFullScreen;
            mover.windowState();
        }
        onPressed: {
            startPosition = Qt.point(mouse.x, mouse.y)
            windowPosition = Qt.point(clockWindow.x, clockWindow.y);
        }
        onPositionChanged: {
            if (mouse.buttons == Qt.LeftButton) {
                var dx = mouse.x - startPosition.x
                var dy = mouse.y - startPosition.y
                clockWindow.x = windowPosition.x + dx;
                clockWindow.y = windowPosition.y + dy;
            }
            resizeHelpVisible.restart()
        }
        Component.onCompleted: {
            timeController.setItemCursor(mover, "move");
        }
    }

    onWidthChanged: {
        results.doScale();
        resultsHidden.doScale();
    }

    Resizer {
        anchors.top: parent.top
        anchors.bottom: mover.top
        anchors.left: mover.left
        anchors.right: mover.right
        direction: "T"
    }
    Resizer {
        anchors.top: mover.bottom
        anchors.bottom: parent.bottom
        anchors.left: mover.left
        anchors.right: mover.right
        direction: "B"
    }
    Resizer {
        anchors.top: mover.top
        anchors.bottom: mover.bottom
        anchors.left: parent.left
        anchors.right: mover.left
        direction: "L"
    }
    Resizer {
        anchors.top: mover.top
        anchors.bottom: mover.bottom
        anchors.left: mover.right
        anchors.right: parent.right
        direction: "R"
    }
    Resizer {
        anchors.top: parent.top
        anchors.bottom: mover.top
        anchors.left: parent.left
        anchors.right: mover.left
        direction: "TL"
    }
    Resizer {
        anchors.top: parent.top
        anchors.bottom: mover.top
        anchors.left: mover.right
        anchors.right: parent.right
        direction: "TR"
    }
    Resizer {
        anchors.top: mover.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: mover.left
        direction: "BL"
    }

    Resizer {
        anchors.top: mover.bottom
        anchors.bottom: parent.bottom
        anchors.left: mover.right
        anchors.right: parent.right
        direction: "BR"
    }
}
