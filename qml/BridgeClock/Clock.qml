import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import QtQuick.Window 2.0

Window {
    id: clockWindow
    property double zoomFactor: height/480
    width: 640
    height: 480
    visible: true
    flags: Qt.FramelessWindowHint

    Rectangle {
        id: timeView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: current.font.pixelSize + time.font.pixelSize + 12*zoomFactor

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.margins: 3*zoomFactor
            id: current
            text: "Kierros 1";
            font.pixelSize: 40*zoomFactor;
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: current.bottom
            anchors.margins: 3*zoomFactor
            id: time
            text: "13:40";
            font.pixelSize: 90*zoomFactor;
        }

        Column {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 10*zoomFactor
            Text {
                id: nextHeading
                text: "Seuraavaksi:"
                font.pixelSize: 18*zoomFactor
            }

            Text {
                id: next
                text: "Kierros 2";
                font.pixelSize: 30*zoomFactor
            }
        }
    }
    WebView {
        id: results
        anchors.top: timeView.bottom
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true
        pixelAligned: true
        interactive: true
        url: "http://www.bridgefinland.fi"
        property bool animationDown: true
        Connections {
            target: timeController
            onUpdateResults: {
                console.log(url)
                if (results.url == url) {
                    results.reload.trigger();
                } else {
                    results.url = url;
                }
            }
        }

        onLoadingChanged: {
            switch (loadRequest.status)
            {
            case WebView.LoadSucceededStatus:
                var size = results.experimental.test.contentsSize;
                results.width = clockWindow.width < size.width ? clockWindow.width : size.width
                if (contentY != 0)
                    fixAnimation();
                else
                    scrollTimer.running = true
                break
            case WebView.LoadStartedStatus:
            case WebView.LoadStoppedStatus:
                break
            case WebView.LoadFailedStatus:
                console.log("Failed to load " + url);
                break
            }
        }

       Timer {
            id: scrollTimer
            running: false
            repeat: false
            interval: 2000
            onTriggered: {
                if (results.contentY == 0) {
                    if (results.contentHeight > results.height) {
                        results.animationDown = true
                        results.contentY = results.contentHeight - results.height
                    }
                } else {
                    results.animationDown = false
                    results.contentY = 0;
                }
            }
        }
        function fixAnimation() {
            if (results.animationDown && !scrollTimer.running) {
                results.contentY = results.contentHeight - results.height
            }
        }

        onHeightChanged: fixAnimation();

        Behavior on contentY {
            NumberAnimation {
                duration: results.animationDown ?
                              results.contentHeight > results.height ?
                                  (results.contentHeight - results.height) * 20 :
                                  0 :
                              200
                easing.type: Easing.Linear
                onRunningChanged: {
                    if (!running)
                        scrollTimer.running = true
                }
            }
        }
    }

    MouseArea {
        id: mover
        anchors.fill: parent
        anchors.margins: 50
        property variant startPosition

        signal windowState
        onDoubleClicked: {
            if (clockWindow.visibility == Qt.WindowFullScreen)
                clockWindow.visibility = Qt.WindowMaximized;
            else
                clockWindow.visibility = Qt.WindowFullScreen;
            mover.windowState();
        }
        onPressed: {
            startPosition = Qt.point(mouseX, mouseY)
        }
        onPositionChanged: {
            if (pressedButtons == Qt.LeftButton) {
                var dx = mouseX - startPosition.x
                var dy = mouseY - startPosition.y
                timeController.moveWindow(clockWindow, dx, dy)
            }
        }
        Component.onCompleted: {
            timeController.setItemCursor(mover, "move");
        }
    }

    onWidthChanged: {
        var size = results.experimental.test.contentsSize;
        results.width = clockWindow.width < size.width ? clockWindow.width : size.width
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


    Timer {
        interval: 1000;
        repeat: true;
        running: true;
        onTriggered: {
            var info = timeController.getRoundInfo();
            var date = new Date();
            if (info.playing == 2) {
                time.text = info.name;
                current.text = "";
                next.text = "";
                nextHeading.opacity = 0
            } else {
                nextHeading.opacity = 1

                var t = info.end - date.getTime() / 1000;
                var diff = "";
                var hours = Math.floor(t/3600);
                var mins = Math.floor((t - hours*3600)/60);
                var secs = Math.floor(t - hours*3600 - mins*60);
                if (hours >= 1)
                    diff = diff + hours + ":";
                if (mins > 9)
                    diff = diff + mins + ":";
                else
                    diff = diff + "0" + mins + ":";
                if (secs > 9)
                    diff = diff + secs;
                else
                    diff = diff + "0" + secs;
                time.text = diff
                current.text = info.name
                next.text = info.nextName
            }
            interval = 1050 - date.getMilliseconds();
        }
    }
}
