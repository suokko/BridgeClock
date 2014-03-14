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
    //: The tile of window that shows the time and result information for players.
    title: qsTr("The time view") + lang.lang
    flags: Qt.WindowStaysOnTopHint + Qt.CustomizeWindowHint /*+ Qt.FramelessWindowHint + Qt.X11BypassWindowManagerHint */

    /* The state of scrolling animation */
    readonly property double msForAPixel: 45
    property bool animationDown: true
    property double ypos: -1
    property bool firstLoad: true

    /* Calculate initial position */
    function pageLoaded(view) {
        if (!firstLoad) {
            return;
        }
        firstLoad = false;
        ypos = view.zoomLimity();
        view.contentY = view.zoomLimity();
        calculateAnimation();
    }

    /* Do a linear animation */
    NumberAnimation on ypos {
        id: scroller
        running: false
        easing.type: Easing.Linear

        onRunningChanged: {
            if (!running) {
                switchAnimationDirection();
            }
        }
    }

    onYposChanged: {
        /* Forward ypos to the visible webview(s) */
        if (!results.loadTarget || results.getHide().running) {
            results.contentY = ypos;
        }
        if (!resultsHidden.loadTarget || resultsHidden.getHide().running) {
            resultsHidden.contentY = ypos;
        }
    }

    Timer {
        id: scrollTimer
        running: true
        repeat: false
        interval: clockWindow.animationDown ? 10000 : 5000;
        onTriggered: {
            calculateAnimation();
        }
    }

    /* Helper to return correct active result view */
    function chooseVisibleResults()
    {
        if (!resultsHidden.loadTarget) {
            return resultsHidden;
        }
        return results;
    }

    function calculateAnimation()
    {
        if (scrollTimer.running) {
            return;
        }
        var view = chooseVisibleResults();


        if (animationDown) {
            /* Check if we need to scroll or not */
            if (view.zoomLimitheight() <= view.height) {
                return;
            }
            var scale = view.experimental.test.contentsScale;
            /* Calculate pixels to score and multiply that with scroll speed constant */
            var duration = (view.zoomLimity() + view.zoomLimitheight() - view.height - view.contentY) /
            view.getScaler().xScale * msForAPixel / scale;
            /* set scrolling target */
            scroller.to = view.zoomLimity() + view.zoomLimitheight() - view.height;
            /* We scroll from current position */
            scroller.from = ypos;
            /* Don't allow duration to be below 10 milliseconds */
            if (duration <= 10) {
                duration = 10;
            }
            scroller.duration = duration;
            /* The animation is ready to roll */
            scroller.start();
        } else {
            /* Up going is a simple jump */
            ypos = view.zoomLimity();
            switchAnimationDirection();
            /* After jump we have to start the timer for next animation stage */
            scrollTimer.restart();
        }
    }

    function switchAnimationDirection()
    {
        animationDown = !animationDown
        /* Always wait timer after moving */
        scrollTimer.restart();
    }

    readonly property int transduration: 5000
    readonly property var transtype: Easing.InOutQuad

    Rectangle {
        id: timeView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        z: 2
        height: clockWindow.height

        states: State {
            name: "showRes"; when: timeController.showResults && timeView.width > 0
            PropertyChanges {
                target: timeView
                height: time.font.pixelSize + 12*zoomFactor
            }
            AnchorChanges {
                target: current
                anchors.horizontalCenter: undefined
                anchors.left: parent.left
            }
            PropertyChanges {
                target: current
                anchors.leftMargin: 2*zoomFactor
                anchors.topMargin: (parent.height - (height + endHeading.height +  end.height))/2
                font.pixelSize: 35*zoomFactor
            }
            PropertyChanges {
                target: currentScale;
                origin.x: 0;
                xScale: (time.totalWidth <= clockWindow.width/2 ? 1 : (current.width - (time.totalWidth - clockWindow.width/2)/2)/current.width)
            }
            PropertyChanges { target: endHeading; font.pixelSize: 15*zoomFactor; }
            AnchorChanges {
                target: end
                anchors.top: endHeading.bottom
                anchors.left: current.left
            }
            PropertyChanges { target: end; font.pixelSize: 25*zoomFactor; }
            PropertyChanges {
                target: time
                font.pixelSize: 120*zoomFactor
            }
            PropertyChanges {
                target: timeScale;
                xScale: (time.totalWidth <= clockWindow.width/2 ? 1 : (time.width/2 - (time.totalWidth - clockWindow.width/2)/2)/(time.width/2))
            }
            AnchorChanges {
                target: nextHeading
                anchors.bottom: undefined
                anchors.top: parent.top
                anchors.left: undefined
                anchors.right: parent.right
            }
            PropertyChanges {
                target: nextHeading
                font.pixelSize: 15*zoomFactor

                anchors.bottomMargin: undefined
                anchors.leftMargin: undefined
                anchors.topMargin: (parent.height - (height + next.height + nextBreakEnd.height))/2
                anchors.rightMargin: 3*zoomFactor + Math.max(Math.max(next.width - width, nextBreakEnd.width - width), 0);
            }
            AnchorChanges {
                target: next
                anchors.top: nextHeading.bottom
                anchors.left: nextHeading.left
            }
            PropertyChanges {
                target: next
                font.pixelSize: 25*zoomFactor
                anchors.topMargin: undefined
            }
            PropertyChanges {
                target: nextBreakEnd
                font.pixelSize: 20*zoomFactor
            }
        }
        transitions: [
            Transition {
                to: "showRes"
                SequentialAnimation {
                    PropertyAction { target: currentScale; property: "origin.x" }
                    ParallelShowRes {}
                }
            },
            Transition {
                from: "showRes"
                SequentialAnimation {
                    ParallelShowRes {}
                    PropertyAction { target: currentScale; property: "origin.x" }
                }
            }
        ]

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: (time.y - height - Math.max(endHeading.height, end.height))/2
            anchors.top: parent.top

            visible: timeController.roundInfo.playing < 2
            id: current
            text: timeController.roundInfo.name;
            font.pixelSize: 55*zoomFactor;
            font.weight: Font.DemiBold;
            transform: Scale {
                id: currentScale
                origin.x: current.width;
                xScale: clockWindow.width - 5*zoomFactor < current.width
                ? (clockWindow.width - 5*zoomFactor) / current.width
                : 1;
            }
        }
        Text {
            anchors.top: current.bottom
            anchors.left: current.left
            id: endHeading
            visible: timeController.roundInfo.playing < 2
            //: Label visible to players before or above the tournament end time
            text: qsTr("Tournament will end: ") + lang.lang
            font.pixelSize: 25*zoomFactor
            font.weight: Font.Light
        }

        Text {
            anchors.top: current.bottom
            anchors.left: endHeading.right
            id: end
            visible: timeController.roundInfo.playing < 2
            text: timeController.tournamentEnd.replace(/:[^:]*$/,'')
            font.pixelSize: 30*zoomFactor
            font.weight: Font.Light;
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 3*zoomFactor
            id: time
            text: timeController.roundInfo.playing < 2 ?
            timeController.roundInfo.timeLeft :
            timeController.roundInfo.name;
            font.pixelSize: 240*zoomFactor;
            readonly property double totalWidth: width/2 + current.width;
            transform: Scale {
                id: timeScale
                origin.x: time.width/2;
                xScale: (clockWindow.width - 10*zoomFactor) / time.width ;
            }
        }


        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (clockWindow.height - (time.y + time.height) - Math.max(height, next.height + nextBreakEnd.height))/2 +
            nextBreakEnd.height + (next.height - nextHeading.height)/2
            anchors.left: parent.left
            anchors.leftMargin: (clockWindow.width - (width + Math.max(next.width, nextBreakEnd.width)))/2

            id: nextHeading
            visible: timeController.roundInfo.playing < 2
            //: The player visible label before or above next break name, start time and end time
            text: qsTr("The next break: ") + lang.lang
            font.pixelSize: 25*zoomFactor
            font.weight: Font.Light
        }
        Text {
            anchors.top: nextHeading.top
            anchors.topMargin: -(height - nextHeading.height)/2
            anchors.left: nextHeading.right

            id: next
            visible: timeController.roundInfo.playing < 2
            text: timeController.roundInfo.nextBreakName;
            font.pixelSize: 40*zoomFactor
            font.italic: true;
            font.weight: Font.Light;
        }

        Text {
            anchors.top: next.bottom
            anchors.left: next.left
            id: nextBreakEnd
            visible: timeController.roundInfo.playing < 2 &&
            timeController.roundInfo.nextBreakStart != ""
            text: timeController.roundInfo.nextBreakStart.replace(/:[^:]*$/,'') + 
            //: A character between start and end time of the next break (visible to players)
            (timeController.roundInfo.nextBreakEnd != "" ? qsTr(" - ") + 
            timeController.roundInfo.nextBreakEnd.replace(/:[^:]*$/,'') : "") + lang.lang;
            font.pixelSize: 40*zoomFactor
            font.weight: Font.Light;
        }
    }

    function setUrl(url) {
        if (resultsHidden.loadTarget) {
            resultsHidden.url = url;
        } else if (results.loadTarget) {
            results.url = url;
        } else {
            console.log("NO LOAD TARGET")
        }
    }

    Connections {
        target: timeController
        onUpdateResults: setUrl(url)
    }

    Component.onCompleted: setUrl(timeController.resultUrl)

    Connections {
        target: timeController
        onZoomLimitChanged: {
            if (!resultsHidden.loadTarget)
                resultsHidden.doScale();
            else
                results.doScale();
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
        z: 3
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
                    text: (clockWindow.visibility !== Qt.WindowFullScreen
                    //: Tooltip help telling to double click the player visible window to make it fullscreen 
                          ? qsTr("Double click to make fullscreen") :
                    //: Tooltip help telling to double click the player visible window to restore window from fullscreen mode
                            qsTr("Double click to restore back to window"))  + lang.lang;
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
        z: 3
        anchors.top: parent.top
        anchors.bottom: mover.top
        anchors.left: mover.left
        anchors.right: mover.right
        direction: "T"
    }
    Resizer {
        z: 3
        anchors.top: mover.bottom
        anchors.bottom: parent.bottom
        anchors.left: mover.left
        anchors.right: mover.right
        direction: "B"
    }
    Resizer {
        z: 3
        anchors.top: mover.top
        anchors.bottom: mover.bottom
        anchors.left: parent.left
        anchors.right: mover.left
        direction: "L"
    }
    Resizer {
        z: 3
        anchors.top: mover.top
        anchors.bottom: mover.bottom
        anchors.left: mover.right
        anchors.right: parent.right
        direction: "R"
    }
    Resizer {
        z: 3
        anchors.top: parent.top
        anchors.bottom: mover.top
        anchors.left: parent.left
        anchors.right: mover.left
        direction: "TL"
    }
    Resizer {
        z: 3
        anchors.top: parent.top
        anchors.bottom: mover.top
        anchors.left: mover.right
        anchors.right: parent.right
        direction: "TR"
    }
    Resizer {
        z: 3
        anchors.top: mover.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: mover.left
        direction: "BL"
    }

    Resizer {
        z: 3
        anchors.top: mover.bottom
        anchors.bottom: parent.bottom
        anchors.left: mover.right
        anchors.right: parent.right
        direction: "BR"
    }
}
