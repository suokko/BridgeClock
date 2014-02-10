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

import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0

Item {
    anchors.fill: parent
    property var settingsUrl: timeController.resultUrl
    property var settingsZoomLimit: timeController.zoomLimit
    property bool initialLoad: true
    Component.onCompleted: {
        settingsUrl = timeController.resultUrl
        settingsZoomLimit = timeController.zoomLimit
    }
    Item {
        id: resultSelector
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        height: 50

        CheckBox {
            anchors.top: parent.top
            id: showResults
            checked: timeController.showResults
            text: "Näytä tulokset"
        }

        Text {
            anchors.top: showResults.bottom
            anchors.left: parent.left
            opacity: showResults.checked ? 1 : 0.5
            id: head
            text: "Tulokset: "
            font.pixelSize: 16
        }
        Button {
            id: resultButton
            text: "Selaa tiedostoja"
            anchors.top: showResults.bottom
            anchors.left: head.right
            onClicked: loadResults.open()
        }

        TextField {
            id: resultFile
            anchors.right: parent.right
            anchors.top: resultButton.bottom
            anchors.left: parent.left
            font.pixelSize: 16
            text: timeController.resultUrl

            onTextChanged: {
                if (settingsUrl !== undefined && text != settingsUrl)
                    initialLoad = false;
            }

            Component.onCompleted: {text = timeController.resultUrl}
        }
        WebView {
            anchors.fill: resultLimiter
            id: view
            clip: true
            pixelAligned: false
            interactive: false
            opacity: showResults.checked ? 1 : 0.5
            visible: true
            z: -1
            url: resultFile.text
            function setSize() {
                var scale = view.experimental.test.contentsScale;
                if (initialLoad && settingsZoomLimit.x != -1) {
                    resultLimiterBorder.x = settingsZoomLimit.x * scale
                    resultLimiterBorder.y = settingsZoomLimit.y * scale
                    resultLimiterBorder.width = settingsZoomLimit.width * scale
                    resultLimiterBorder.height = settingsZoomLimit.height * scale
                    return;
                }
                resultLimiterBorder.x = 0
                resultLimiterBorder.y = 0
                resultLimiterBorder.height = view.contentHeight
                resultLimiterBorder.width = view.contentWidth
                timeController.zoomLimit = Qt.rect(
                    (resultLimiterBorder.x + view.contentX)/scale,
                    (resultLimiterBorder.y + view.contentY)/scale,
                    resultLimiterBorder.width/scale,
                    resultLimiterBorder.height/scale);
            }
            onContentHeightChanged: setSize()
            onContentWidthChanged: setSize()
            Component.onCompleted: {
                view.experimental.preferences.javascriptEnabled = false;
            }
        }
        MouseArea {
            anchors.top: resultFile.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            id: resultLimiter
            hoverEnabled: true
            property string direction: ""
            property variant panstart: Qt.point(0, 0)
            property bool directionLock: false

            Rectangle {
                id: resultLimiterBorder
                x: timeController.zoomLimit.x
                y: timeController.zoomLimit.y
                width: timeController.zoomLimit.width
                height: timeController.zoomLimit.height
                opacity: showResults.checked ? 1 : 0.5
                border.width: 2
                border.color: "black"
                color: "transparent"

                Component.onCompleted: {
                    x = timeController.zoomLimit.x
                    y = timeController.zoomLimit.y
                    width = timeController.zoomLimit.width
                    height = timeController.zoomLimit.height
                }
            }

            onPressed: {
                if (mouse.buttons == Qt.LeftButton) {
                    directionLock = true;
                    panstart = Qt.point(mouse.x + view.contentX, mouse.y + view.contentY);
                }
            }

            onReleased: {
                if (mouse.buttons != Qt.LeftButton) {
                    directionLock = false;
                    var scale = view.experimental.test.contentsScale;
                    if (direction != "") {
                        timeController.zoomLimit = Qt.rect(
                            (resultLimiterBorder.x + view.contentX)/scale,
                            (resultLimiterBorder.y + view.contentY)/scale,
                            resultLimiterBorder.width/scale,
                            resultLimiterBorder.height/scale);
                    }
                }
            }

            onPositionChanged: {
                var dir = "";
                /* Either border of mouse area or limit is active zone */
                var rx = resultLimiterBorder.x > 0 ? resultLimiterBorder.x : 0;
                var ry = resultLimiterBorder.y > 0 ? resultLimiterBorder.y : 0;
                var rw = resultLimiterBorder.x + resultLimiterBorder.width < width ?
                    resultLimiterBorder.x + resultLimiterBorder.width : width;
                var rh = resultLimiterBorder.y + resultLimiterBorder.height < height ?
                    resultLimiterBorder.y + resultLimiterBorder.height : height;
                var left = Math.abs(mouse.x - rx);
                var right = Math.abs(mouse.x - rw);
                var top = Math.abs(mouse.y - ry);
                var bottom = Math.abs(mouse.y - rh);
                var activeArea = 30;
                if (top < bottom && top < activeArea) {
                    dir = dir + "T";
                } else if (top > bottom && bottom < activeArea) {
                    dir = dir + "B";
                }
                if ( left < right && left < activeArea) {
                    dir = dir + "L";
                } else if ( left > right && right < activeArea) {
                    dir = dir + "R";
                }
                if (dir != direction && !directionLock) {
                    direction = dir;
                    timeController.setItemCursor(resultLimiter, direction);
                    if (direction != "")
                        resultLimiterBorder.border.color = "blue"
                    else
                        resultLimiterBorder.border.color = "black"
                } else if (directionLock && direction == "") {
                    var dy = panstart.y - (mouse.y + view.contentY)
                    if (dy < -view.contentY)
                        dy = -view.contentY;
                    else if (view.contentY + dy > view.contentHeight - view.height)
                        dy = (view.contentHeight - view.height) - view.contentY;
                    view.contentY += dy;
                    resultLimiterBorder.y -= dy;

                    var dx = panstart.x - (mouse.x + view.contentX)
                    if (dx < -view.contentX)
                        dx = -view.contentX;
                    else if (view.contentX + dx > view.contentWidth - view.width)
                        dx = (view.contentWidth - view.width) - view.contentX;
                    view.contentX += dx;
                    resultLimiterBorder.x -= dx;
                } else if (directionLock) {
                    var y = mouse.y;
                    var x = mouse.x;
                    /* Clip to mousearea */
                    if (y < -view.contentY)
                        y = -view.contentY
                    else if (y > view.contentHeight - view.contentY)
                        y = view.contentHeight - view.contentY
                    if (x < -view.contentX)
                        x = -view.contentX
                    else if (x > view.contentWidth - view.contentX)
                        x = view.contentWidth - view.contentX
                    var change;
                    if (direction.indexOf("T") >= 0) {
                        change = y - resultLimiterBorder.y;
                        resultLimiterBorder.y += change
                        resultLimiterBorder.height -= change
                    } else if (direction.indexOf("B") >= 0) {
                        change = y - resultLimiterBorder.y - resultLimiterBorder.height;
                        resultLimiterBorder.height += change;
                    }
                    if (direction.indexOf("L") >= 0) {
                        change = x - resultLimiterBorder.x;
                        resultLimiterBorder.x += change
                        resultLimiterBorder.width -= change
                    } else if (direction.indexOf("R") >= 0) {
                        change = x - resultLimiterBorder.x - resultLimiterBorder.width;
                        resultLimiterBorder.width += change;
                    }
                }
            }
        }
    }

    Binding {
        target: timeController
        property: "resultUrl"
        value: resultFile.text
    }

    Binding {
        target: timeController
        property: "showResults"
        value: showResults.checked
    }

    FileDialog {
        id: loadResults
        /*        folder: "/tmp"*/
        title: "Valitse tulokset näytettäväksi"
        selectMultiple: false
        nameFilters: [ "HTML-tiedostot (*.htm *.html)", "Kaikki (*)" ]

        onAccepted: { resultFile.text = fileUrl }
    }

}
