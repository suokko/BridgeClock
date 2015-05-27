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
        //: The header text for initial setup
        text: qsTr("Tournament time") + lang.lang
        font.pointSize: 20
    }

    Text {
        id: roundsHeader
        anchors.verticalCenter: roundsText.verticalCenter
        anchors.left: parent.left
        anchors.margins: 5
        //: Label for number of rounds slider and input box
        text: qsTr("Number of rounds") + lang.lang
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
        //: Label for length of round in minutes
        text: qsTr("Round time") + lang.lang
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
        //: Label after input box accepting minutes
        text: qsTr("minute(s)","", time.value) + lang.lang
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
        //: Label before slider and text input for length of change between round in minutest
        text: qsTr("Change time") + lang.lang
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
        //: Label after input box accepting minutes
        text: qsTr("minute(s)","", breaks.value) + lang.lang
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

    Text {
        id: startHeader
        anchors.top: breaks.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        //: Subheader before the tournament start time selector
        text: qsTr("Start time") + lang.lang
        font.pointSize: 16
    }
    Button {
        anchors.top: startHeader.top
        anchors.left: startHeader.right
        anchors.leftMargin: 20
        //: The button text that sets tournament start time to be now
        text: qsTr("Now") + lang.lang
        onClicked: {
            var now = new Date();
            startTime.date = now;
            timeController.startTime = now;
        }
    }

    DatePicker {
        id: startTime
        anchors.top: startHeader.bottom
        height: Math.min(parent.width, resetTime.y - startTime.y - 5)
        anchors.margins: 5
        anchors.horizontalCenter: parent.horizontalCenter
        date: timeController.startTime

        Component.onCompleted: {
            /* Break the binding loop */
            date = timeController.startTime
        }
    }

    Button {
        id: resetTime
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 3
        //: The button text that resets round and break modifications to start a new tournament
        text: qsTr("Start a new tournament") + lang.lang
        onPressedChanged: if (pressed) timeController.resetModel();
    }

    Rectangle {
        id: langSelector
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 3
        radius: 5

        width: languages.contentItem.childrenRect.width
        height: languages.currentItem ? languages.currentItem.height : 20

        states: State {
            name: "open"
            PropertyChanges {
                target: languages
                visible: true
                contentY: languages.currentItem ? Math.min(Math.max(languages.currentItem.y - (langSelector.height - languages.currentItem.height)/2, 0),
                                   languages.contentItem.childrenRect.height - langSelector.height) : 0;
            }

            PropertyChanges {
                target: langSelector
                height: parent.height
            }
        }

        transitions: [
            Transition {
                ParallelAnimation {
                    PropertyAnimation {
                        target: langSelector
                        properties: "height"
                        duration: 800
                        easing.type: Easing.InOutCubic
                    }
                    PropertyAnimation {
                        target: languages
                        properties: "contentY"
                        duration: 1500
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        ]

        ListView {
            id: languages
            anchors.fill: parent
            visible: true
            clip: true

            height: parent.height
            width: parent.width

            currentIndex: lang.selectedId

            contentY: currentItem ? currentItem.y : 0

            focus: true

            model: lang
            highlight: Rectangle { color: "lightsteelblue"; radius: 5; width: languages.width }
            delegate: Item {
                height: langText.height + 6
                width: langText.width + 6

                visible: languages.visible

                MouseArea {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom

                    width: languages.width

                    onClicked: {
                        if (langSelector.state == "") {
                            langSelector.state = "open"
                        } else {
                            lang.selectedId = index
                            langSelector.state = ""
                        }
                    }
                }

                Text {
                    y: 3
                    x: 3
                    id: langText
                    text: name
                    font.pointSize: 14
                }
            }
        }
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
            var date = startTime.date;
            date.setSeconds(0);
            date.setMilliseconds(0);
            return date;
        }
    }
}
