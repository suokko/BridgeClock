import QtQuick 2.0

MouseArea {
    id: resizer
    anchors.margins: 10
    enabled: clockWindow.visibility != Qt.WindowFullScreen
    property variant startPosition
    property string direction: ""

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
    }
    Component.onCompleted: {
        mover.windowState.connect(setCursor)
        setCursor();
    }
}
