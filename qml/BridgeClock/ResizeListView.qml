
import QtQuick 2.4
import QtQuick.Controls 1.1

ListView {
    id: view
    
    anchors.margins: 2

    Rectangle {
        id: background

        anchors.fill: parent
        radius: 5
        z: -3
        clip: true

        color: "white"
        border.width: 2
        border.color: "gray"
    }

    Item {
        id: reparent
        states: State {
            name: "reparent"
            ParentChange {
                target: view.contentItem
                parent: background
            }
        }
        Component.onCompleted: state = "reparent"
    }

    highlight: Rectangle {
        x: view.anchors.margins + 2
        color: "lightsteelblue";
        radius: 5;
        width: totalWidth

        onWidthChanged: width = Qt.binding(function() { return totalWidth; })
    }

    property variant widthList: []
    property int totalWidth: 0
    property bool __complete: false

    function columnWidth(col, width) {
        if (widthList[col] >= width)
            return;

        var cur = widthList[col] === undefined ? 0 : widthList[col];
        widthList[col] = width;
        totalWidth += width - cur;

        if (__complete) {
            view.widthListChanged();
            view.totalWidthChanged();
        }
    }

    Component.onCompleted: {
        __complete = true;
        view.widthListChanged();
        view.totalWidthChanged();
    }
}

