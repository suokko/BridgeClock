import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.0

Item {
    anchors.fill: parent
    Item {
        id: resultSelector
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: 50
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            id: head
            text: "Tulokset: "
            font.pixelSize: 16
        }
        Button {
            id: resultButton
            text: "Selaa tiedostoja"
            anchors.top: parent.top
            anchors.left: head.right
            onClicked: loadResults.open()
        }

        TextField {
            id: resultFile
            anchors.right: parent.right
            anchors.top: resultButton.bottom
            anchors.left: parent.left
            font.pixelSize: 16
            text: "http://www.bridgefinland.fi"
        }
    }

    Binding {
        target: timeController
        property: "resultUrl"
        value: resultFile.text
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
