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

Item {
    anchors.fill: parent
    Item {
        id: resultSelector
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: 50
        CheckBox {
            anchors.top: parent.top
            id: showResults
            checked: true
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
