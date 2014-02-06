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
            checked: false
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
            enabled: showResults.checked
            anchors.top: showResults.bottom
            anchors.left: head.right
            onClicked: loadResults.open()
        }

        TextField {
            id: resultFile
            anchors.right: parent.right
            anchors.top: resultButton.bottom
            anchors.left: parent.left
            enabled: showResults.checked
            font.pixelSize: 16
            text: "http://www.bridgefinland.fi"
        }
        WebView {
            anchors.fill: resultLimiter
            id: view
            clip: true
            pixelAligned: false
            interactive: false
            opacity: 1.0
            visible: true
            z: -1
            url: resultFile.text
            onLoadingChanged: {
                if (loadRequest.status == WebView.LoadSucceededStatus) {
                    var scale = view.experimental.test.contentsScale;
                    timeController.zoomLimit = Qt.rect(resultLimiterBorder.x/scale, resultLimiterBorder.y/scale, resultLimiterBorder.width/scale, resultLimiter.height/scale);
                }
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
            property bool directionLock: false

            Rectangle {
                id: resultLimiterBorder
                x: 0
                y: 0
                width: parent.width
                height: parent.height
                border.width: 2
                border.color: "black"
                color: "transparent"
            }

            onPressed: {
                if (mouse.buttons == Qt.LeftButton)
                    directionLock = true;
            }

            onReleased: {
                if (mouse.buttons != Qt.LeftButton) {
                    directionLock = false;
                    var scale = view.experimental.test.contentsScale;
                    timeController.zoomLimit = Qt.rect(resultLimiterBorder.x/scale, resultLimiterBorder.y/scale, resultLimiterBorder.width/scale, resultLimiter.height/scale);
                }
            }

            onPositionChanged: {
                var dir = "";
                var left = Math.abs(mouse.x - resultLimiterBorder.x);
                var right = Math.abs(mouse.x - resultLimiterBorder.x - resultLimiterBorder.width);
                var top = Math.abs(mouse.y - resultLimiterBorder.y);
                var bottom = Math.abs(mouse.y - resultLimiterBorder.y - resultLimiterBorder.height);
                var activeArea = 15;
                if (top < bottom && top < activeArea) {
                    dir = dir + "T";
                } else if (top > bottom && bottom < activeArea) {
                    //dir = dir + "B";
                }
                if ( left < right && left < activeArea) {
                    dir = dir + "L";
                } else if ( left > right && right < activeArea) {
                    dir = dir + "R";
                }
                if (dir != direction && !directionLock) {
                    console.log(dir);
                    direction = dir;
                    timeController.setItemCursor(resultLimiter, direction);
                } else if (directionLock) {
                    var y = mouse.y;
                    var x = mouse.x;
                    /* Clip to mousearea */
                    if (y < 0)
                        y = 0
                    else if (y > height)
                        y = height
                    if (x < 0)
                        x = 0
                    else if (x > width)
                        x = width
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
