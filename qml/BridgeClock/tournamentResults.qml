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
            //: The label text for checkbox that selects if results are shown under the clock
            text: qsTr("Show results") + lang.lang
        }

        Text {
            anchors.top: showResults.bottom
            anchors.left: parent.left
            opacity: showResults.checked ? 1 : 0.5
            id: head
            //: The label text above url text input for result file
            text: qsTr("Result address: ") + lang.lang
            font.pixelSize: 16
        }
        Button {
            id: resultButton
            //: Button to open file browser to find the results to be shown
            text: qsTr("Browse files") + lang.lang
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
                if (settingsUrl !== undefined && text != settingsUrl) {
                    initialLoad = false;
                }
                if (text != view.url) {
                    if (view.url == "") {
                        view.url = text
                    } else {
                        loadurltimer.restart()
                    }
                }
            }

            Component.onCompleted: {text = timeController.resultUrl}
        }
        Timer {
            id: loadurltimer
            running: false
            repeat: false
            interval: 1000
            onTriggered: {
                if (resultFile.text != view.url)
                    view.url = resultFile.text
            }
        }
        WebView {
            anchors.fill: resultLimiter
            id: view
            clip: true
            pixelAligned: false
            interactive: true
            opacity: showResults.checked ? 1 : 0.7
            visible: true
            z: -1
            function setSize() {
                var scale = view.experimental.test.contentsScale;
                if (initialLoad
                        && settingsZoomLimit.x > -1
                        && settingsZoomLimit.y > -1
                        && settingsZoomLimit.width > -1
                        && settingsZoomLimit.height > -1) {
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
            onLoadingChanged: {
                if (loadRequest.status == WebView.LoadSucceededStatus &&
                        resultFile.text != loadRequest.url) {
                    resultFile.text = loadRequest.url
                    loadurltimer.stop();
                }
            }
            Component.onCompleted: {
                view.experimental.preferences.javascriptEnabled = false;
            }
        }
        MouseArea {
            id: resultLimiter
            anchors.top: resultFile.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 5

            clip: true
            hoverEnabled: true
            property string direction: ""
            property variant panstart: Qt.point(0, 0)
            property variant pressloc: Qt.point(0, 0)
            property bool directionLock: false

            Rectangle {
                id: resultLimiterBorder
                x: timeController.zoomLimit.x
                y: timeController.zoomLimit.y
                width: timeController.zoomLimit.width
                height: timeController.zoomLimit.height
                opacity: showResults.checked ? 1 : 0.7
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
                    panstart = Qt.point(mouse.x, mouse.y);
                    pressloc = Qt.point(mouse.x, mouse.y);
                }
            }

            onReleased: {
                if (mouse.buttons != Qt.LeftButton) {
                    directionLock = false;
                    if (direction != "") {
                        var scale = view.experimental.test.contentsScale;
                        timeController.zoomLimit = Qt.rect(
                            (resultLimiterBorder.x + view.contentX)/scale,
                            (resultLimiterBorder.y + view.contentY)/scale,
                            resultLimiterBorder.width/scale,
                            resultLimiterBorder.height/scale);
                    } else {
                        var dx = pressloc.x - mouse.x;
                        var dy = pressloc.y - mouse.y;
                        dx = dx*dx;
                        dy = dy*dy;
                        /* Check if movement is less than 5 pixels */
                        if (dx+dy < 25) {
                            /* Simulate the click */
                            timeController.click(view, Qt.point(mouse.x, mouse.y));
                        }
                    }
                }
            }

            onWheel: {
                /* TODO: Use pixelDelta if available */
                pan(-wheel.angleDelta.x, -wheel.angleDelta.y);
            }

            function pan(dx, dy) {
                if (view.contentY + dy < 0) {
                    dy = -view.contentY
                } else if (view.contentHeight - view.contentY - dy < view.height)  {
                    dy = Math.floor(view.contentHeight - view.contentY - view.height);
                }

                view.contentY += dy;
                resultLimiterBorder.y -= dy;

                if (view.contentX + dx/scale < 0) {
                    dx = -view.contentX*scale
                } else if (view.contentWidth - view.contentX - dx < view.width)  {
                    dx = Math.floor(view.contentWidth - view.contentX - view.width);
                }
                view.contentX += dx;
                resultLimiterBorder.x -= dx;
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
                var activeArea = 15;
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
                    if (direction != "") {
                        resultLimiterBorder.border.color = "blue"
                    } else {
                        resultLimiterBorder.border.color = "black"
                    }
                } else if (!directionLock && dir != "") {
                    /* Mouse move simulation failing but why? */
                    //timeController.mmove(view, Qt.point(mouse.x, mouse.y));
                } else if (directionLock && direction == "") {
                    var dy = panstart.y - mouse.y;
                    var dx = panstart.x - mouse.x;

                    pan(dx, dy);
                    panstart.y = mouse.y
                    panstart.x = mouse.x
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
        //: File chooser dialog title shown when user is searching for a result file
        title: qsTr("Select a file to be shown in result view") + lang.lang
        selectMultiple: false
        //: File filter entry that lets users hide all files except html files
        nameFilters: [ qsTr("HTML-files (*.htm *.html)") + lang.lang,
        //: File filter entry that lets users to show all files
                       qsTr("All files (*)") + lang.lang ]

        onAccepted: { resultFile.text = fileUrl }
    }

}
