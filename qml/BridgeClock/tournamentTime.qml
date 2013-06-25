import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0

Item {
    anchors.fill: parent
    Item {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: view.left
    }


    TableView {
        id: view
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 3
        width: 165
        model: timeController.getModel()
        TableViewColumn { role: "start"; title: "Alku"; width: 68 }
        TableViewColumn { role: "name"; title: "Tapahtuma"; width: 78 }
    }
}
