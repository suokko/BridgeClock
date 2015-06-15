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
import QtQuick.Window 2.2
import org.bridgeClock 1.0

GlobalMouseArea {
    id: resizer
    anchors.margins: 3
    hoverEnabled: true
    enabled: clockWindow.visibility != Window.FullScreen
    property string direction: ""
    property variant startPosition
    property variant windowPosition

    Rectangle {
        id: visual
        anchors.fill: parent
        visible: helpVisible.running && resizer.containsMouse
        border.width: 2
        border.color: "black"
        color: "transparent"
        radius: 5
    }

    Timer {
        id: helpVisible
        interval: 5000
        repeat: false
        running: false
    }


    function setCursor() {
        timeController.setItemCursor(resizer,
                                     clockWindow.visibility == Window.FullScreen ?
                                         "" : direction);
    }

    onPressed: {
        startPosition = Qt.point(mouse.x, mouse.y)
        windowPosition = Qt.rect(clockWindow.x, clockWindow.y, clockWindow.width, clockWindow.height);
    }
    onPositionChanged: {
        if (mouse.buttons === Qt.LeftButton && !parent.fullScreen) {
            var dx = mouse.x - startPosition.x
            var dy = mouse.y - startPosition.y

            if (direction.indexOf("T") >= 0) {
                clockWindow.y = windowPosition.y + dy
                clockWindow.height = windowPosition.height - dy
            } else if (direction.indexOf("B") >= 0) {
                clockWindow.height = windowPosition.height + dy
            }
            if (direction.indexOf("L") >= 0) {
                clockWindow.x = windowPosition.x + dx
                clockWindow.width = windowPosition.width - dx
            } else if (direction.indexOf("R") >= 0) {
                clockWindow.width = windowPosition.width + dx
            }
        }
        helpVisible.restart()
    }
    Component.onCompleted: {
        mover.windowState.connect(setCursor)
        setCursor();
    }
}
