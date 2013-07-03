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

MouseArea {
    id: resizer
    anchors.margins: 3
    hoverEnabled: true
    enabled: clockWindow.visibility != Qt.WindowFullScreen
    property variant startPosition
    property string direction: ""

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
                                     clockWindow.visibility == Qt.WindowFullScreen ?
                                         "" : direction);
    }

    onPressed: {
        startPosition = Qt.point(mouseX, mouseY)
        timeController.startResize(clockWindow, resizer, mouseX, mouseY);
    }
    onPositionChanged: {
        if (pressedButtons == Qt.LeftButton && !parent.fullScreen) {
            timeController.resizeWindow(clockWindow, resizer, mouseX, mouseY, direction)
        }
        helpVisible.restart()
    }
    Component.onCompleted: {
        mover.windowState.connect(setCursor)
        setCursor();
    }
}
