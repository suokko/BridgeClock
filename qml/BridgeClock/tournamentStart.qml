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
import QtQuick.Controls 1.0

Item {
    anchors.fill: parent
    anchors.margins: 5

    Text {
        id: header
        anchors.margins: 5
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Kilpailun pituus"
        font.pixelSize: 20
    }

    Text {
        id: roundsHeader
        anchors.verticalCenter: roundsText.verticalCenter
        anchors.left: parent.left
        anchors.margins: 5
        text: "Kierroksia"
    }
    TextField {
        id: roundsText
        width: 50
        anchors.margins: 5
        anchors.top: header.bottom
        anchors.left: roundsHeader.right
        text: rounds.value
        validator: IntValidator {
            bottom: rounds.minimumValue;
            top: rounds.maximumValue;
        }
    }
    Slider {
        anchors.top: roundsText.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 10
        id: rounds
        value: timeController.rounds
        stepSize: 1
        minimumValue: 1
        maximumValue: 30
    }
    Binding {
        target: rounds
        property: "value"
        value: roundsText.text
    }

    Text {
        id: timeHeader
        anchors.verticalCenter: timeText.verticalCenter
        anchors.left: parent.left
        anchors.margins: 5
        text: "Kierrosaika"
    }
    TextField {
        id: timeText
        text: time.value
        width: 50
        anchors.margins: 5
        anchors.top: rounds.bottom
        anchors.left: timeHeader.right
        validator: DoubleValidator {
            bottom: rounds.minimumValue;
            top: rounds.maximumValue;
            decimals: 1;
        }
    }
    Text {
        anchors.verticalCenter: timeText.verticalCenter
        anchors.left: timeText.right
        anchors.margins: 5
        text: "minuuttia"
    }
    Slider {
        anchors.top: timeText.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 10
        id: time
        value: timeController.roundTime / 2
        stepSize: 0.5
        minimumValue: 1
        maximumValue: 130
    }
    Binding {
        target: time
        property: "value"
        value: timeText.text
    }


    Text {
        id: breaksHeader
        anchors.verticalCenter: breaksText.verticalCenter
        anchors.left: parent.left
        anchors.margins: 5
        text: "Vaihtoaika"
    }
    TextField {
        id: breaksText
        text: breaks.value
        width: 50
        anchors.margins: 5
        anchors.top: time.bottom
        anchors.left: breaksHeader.right
        validator: IntValidator {
            bottom: breaks.minimumValue;
            top: breaks.maximumValue;
        }
    }
    Text {
        anchors.verticalCenter: breaksText.verticalCenter
        anchors.left: breaksText.right
        anchors.margins: 5
        text: "minuuttia"
    }
    Slider {
        anchors.top: breaksText.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 10
        id: breaks
        value: timeController.roundBreak / 2
        stepSize: 0.5
        minimumValue: 0
        maximumValue: 20
   }
    Binding {
        target: breaks
        property: "value"
        value: breaksText.text
    }

    Row {
        id: startHeader
        anchors.top: breaks.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Alkamisaika"
            font.pixelSize: 16
        }
        Button {
            text: "Nyt"
            width: 30
            onClicked: {
                var time = new Date();
                startTime.hour = time.getHours();
                startTime.minute = time.getMinutes();
            }
        }
    }

    DatePicker {
        id: startTime
        anchors.top: startHeader.bottom
        height: Math.min(parent.width, resetTime.y - startTime.y - 5)
        anchors.margins: 5
        anchors.horizontalCenter: parent.horizontalCenter
        hour: timeController.startTime.getHours()
        minute: timeController.startTime.getMinutes()

        Component.onCompleted: {
            /* Break the bidning loop */
            hour = timeController.startTime.getHours()
            minute = timeController.startTime.getMinutes()
        }
    }

    Button {
        id: resetTime
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: "Poista aikataulu muokkaukset"
        onPressedChanged: if (pressed) timeController.resetModel();
    }

    Binding {
        target: timeController
        property: "rounds"
        value: rounds.value
    }

    Binding {
        target: timeController
        property: "roundTime"
        value: time.value * 2
    }

    Binding {
        target: timeController
        property: "roundBreak"
        value: breaks.value * 2
    }

    Binding {
        target: timeController
        property: "startTime"
        value: {
            var date = new Date();
            date.setHours(Math.floor(startTime.hour));
            date.setMinutes(Math.floor(startTime.minute));
            date.setSeconds(0);
            date.setMilliseconds(0);
            return date;
        }
    }
}
