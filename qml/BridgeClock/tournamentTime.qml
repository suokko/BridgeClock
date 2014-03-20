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
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import org.bridgeClock 1.0

Item {
    anchors.fill: parent

    property int __updatingUI: 0

    Item {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: view.left

        Text {
            id: header
            text: (timeController.roundInfo.playing === 0 ?
            //: Arrow between break and next round name in time settings tab.
                      (timeController.roundInfo.name + qsTr(" -> ") +
                       timeController.roundInfo.nextName) :
                      timeController.roundInfo.name) + lang.lang
            font.pixelSize: timeController.roundInfo.playing === 0 ? 18 : 24
            height: 24
            anchors.top: parent.top
            anchors.margins: 5
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Label {
            id: timeLeftLabel
            anchors.margins: 5
            anchors.verticalCenter: timeLeft.verticalCenter
            anchors.left: parent.left
            visible: timeController.roundInfo.playing < 2
            //: Label before count down to the end of current round or break
            text: qsTr("Remaining:") + lang.lang
        }
        Text {
            id: timeLeft
            anchors.top: header.bottom
            anchors.left: timeLeftLabel.right
            visible: timeController.roundInfo.playing < 2
            anchors.margins: 3
            text: timeController.roundInfo.timeLeft
            font.pointSize: 14
        }
        CheckBox {
            anchors.top: header.bottom
            anchors.right: parent.right
            anchors.margins: 5
            visible: timeController.roundInfo.playing < 2
            id: pause
            //: The label for checkbox that stops count down in time settings tab.
            text: qsTr("Stop the clock") + lang.lang
            checked: false
            style: CheckBoxStyle {
                label: Text {
                    text: control.text
                    font.pointSize: 14
                }
            }
        }

        Binding {
            target: timeController
            property: "paused"
            value: pause.checked
        }

        GridLayout {
            id: roundGrid
            columns: 3
            anchors.top: timeLeft.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 5
            enabled: timeController.roundInfo.playing < 2
            function appendTime(time) {
                if (__updatingUI > 0)
                    return;
                var info = timeController.roundInfo;
                var end = new Date();
                end.setTime(info.end*1000 + time);
                view.model.changeEnd(info.row, end);
            }

            Button {
                //: The text for button that adds ten seconds to current round or break in time settings tab.
                text: qsTr("+10s") + lang.lang
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(10*1000);
            }
            Button {
                //: The text for button that adds a minute to current round or break in time settings tab.
                text: qsTr("+1m") + lang.lang
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(60*1000);
            }
            Button {
                //: The text for button that adds five minutes to current round or break in time settings tab.
                text: qsTr("+5m") + lang.lang
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(5*60*1000);
            }
            Button {
                //: The text for button that subtracts ten seconds from current round or break in time settings tab.
                text: qsTr("-10s") + lang.lang
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(-10*1000);
            }
            Button {
                //: The text for button that subtracts a minute from current round or break in time settings tab.
                text: qsTr("-1m") + lang.lang
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(-60*1000);
            }
            Button {
                //: The text for button that subtracts five minutes from current round or break in time settings tab.
                text: qsTr("-5m") + lang.lang
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(-5*60*1000);
            }
        }
        Rectangle {
            id: splitLine
            color: "black"
            height: 3
            radius: 10
            anchors.margins: 5
            anchors.topMargin: 5
            anchors.top: roundGrid.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Text {
            id: selectionHeader
            anchors.top: splitLine.bottom
            anchors.topMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            visible: view.currentRow != -1
            font.pixelSize: 20
            text: (view.currentRow != -1 ?
                      view.model.qmlData(view.currentRow, "name").value :
                      //: Place holder text that shouldn't ever be visible to user
                      qsTr("No choice")) + lang.lang
        }
        Label {
            id: startLabel
            anchors.margins: 3
            anchors.top: selectionHeader.bottom
            anchors.left: parent.left
            visible: view.currentRow != -1
            //: The label before the begin time of round or break in time settings tab
            text: qsTr("Begin:") + lang.lang
        }
        Text {
            id: start
            anchors.verticalCenter: startLabel.verticalCenter
            anchors.left: startLabel.right
            anchors.margins: 3
            visible: view.currentRow != -1
            text: (view.currentRow != -1 ?
                      view.model.qmlData(view.currentRow, "start").value :
                      //: Place holder text that shouldn't ever be visible to user
                      qsTr("No choice")) + lang.lang
        }
        Label {
            id: endLabel
            anchors.margins: 3
            anchors.top: startLabel.bottom
            anchors.left: parent.left
            visible: view.currentRow != -1
            //: The label before the end time of round or break in time settings tab
            text: qsTr("End:") + lang.lang
        }
        Text {
            id: end
            anchors.verticalCenter: endLabel.verticalCenter
            anchors.left: endLabel.right
            anchors.margins: 3
            visible: view.currentRow != -1
            text: (view.currentRow != -1 ?
                      view.model.qmlData(view.currentRow, "end").value :
                      //: Place holder text that shouldn't ever be visible to user
                      qsTr("No choice")) + lang.lang
        }
        Label {
            id: timeLabel
            anchors.margins: 3
            anchors.top: selectionHeader.bottom
            x: parent.width/2
            visible: view.currentRow != -1
            //: The label before the length of round or break in hours and minutes
            text: qsTr("Length:") + lang.lang
        }
        Text {
            id: time
            anchors.verticalCenter: timeLabel.verticalCenter
            anchors.left: timeLabel.right
            anchors.margins: 3
            visible: view.currentRow != -1
            text: (view.currentRow != -1 ?
                      view.model.qmlData(view.currentRow, "length").value :
                      //: Place holder text that shouldn't ever be visible to user
                      qsTr("No choice")) + lang.lang
        }
        Label {
            id: prevLabel
            anchors.margins: 3
            anchors.top: timeLabel.bottom
            x: parent.width/2
            visible: view.currentRow != -1
            //: Label before text showing the name of previous round or break in settings tab.
            text: qsTr("Previous:") + lang.lang
        }
        Text {
            id: prev
            anchors.verticalCenter: prevLabel.verticalCenter
            anchors.left: prevLabel.right
            anchors.margins: 3
            visible: view.currentRow != -1
            text: (view.currentRow != -1 ?
                      view.model.qmlData(view.currentRow, "previous").value :
                      //: Place holder text that shouldn't ever be visible to user
                      qsTr("No choice")) + lang.lang
        }

        GroupBox {
            id: itemTypeBox
            anchors.top: prev.bottom
            enabled: view.currentRow != -1 ?
                         view.model.qmlData(view.currentRow, "type").value === TimeModel.Break ||
                         view.model.qmlData(view.currentRow, "type").value === TimeModel.Change :
                         false
            visible: view.currentRow != -1
            width: parent.width - 6

            function updateSelection() {
                if (view.currentRow == -1 || view.currentRow >= view.rowCount)
                    return;
                __updatingUI++;
                if (itemType.current)
                    itemType.current.checked = false
                var model = view.model;
                var type = model.qmlData(view.currentRow, "type").value;
                var name = model.qmlData(view.currentRow, "nameRaw").value;
                breakEndTime.date = model.qmlData(view.currentRow, "endTime").value;
                customName.text = "";
                switch (type) {
                case TimeModel.Play:
                case TimeModel.End:
                    /* Nothing to select */
                    break;
                case TimeModel.Change:
                    change.checked = true;
                    break
                case TimeModel.Break:
                    if (name === QT_TRANSLATE_NOOP("Break","Lunch")) {
                        lunch.checked = true;
                    } else if (name === QT_TRANSLATE_NOOP("Break","Dinner")) {
                        dinner.checked = true;
                    } else if (name === QT_TRANSLATE_NOOP("Break","Coffee")) {
                        coffee.checked = true;
                    } else {
                        custom.checked = true;
                        customName.text = name;
                    }
                    break;
                }
                __updatingUI--;
            }

            ExclusiveGroup {
                id: itemType
                onCurrentChanged: breakChanged();

                function breakChanged()
                {
                    if (__updatingUI > 0)
                        return;
                    switch (itemType.current) {
                    case change:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Change,
                                              QT_TRANSLATE_NOOP("Break","Change"));
                        break;
                    case lunch:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Break,
                                              QT_TRANSLATE_NOOP("Break","Lunch"));
                        break;
                    case dinner:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Break,
                                              QT_TRANSLATE_NOOP("Break","Dinner"));
                        break;
                    case coffee:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Break,
                                              QT_TRANSLATE_NOOP("Break","Coffee"));
                        break;
                    case custom:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Break,
                                              customName.text);
                        break;
                    }
                }
            }
            RadioButton {
                id: change
                anchors.margins: 3
                //: A short text visible to players telling that now is a change between rounds
                text: qsTranslate("Break","Change") + lang.lang
                exclusiveGroup: itemType
            }
            RadioButton {
                id: lunch
                anchors.top: change.bottom
                anchors.margins: 3
                //: A short text visible to players telling that now or soon is a Lunch break 
                text: qsTranslate("Break","Lunch") + lang.lang
                exclusiveGroup: itemType
            }
            RadioButton {
                id: dinner
                anchors.top: lunch.bottom
                anchors.margins: 3
                //: A short text visible to players telling that now or soon is a Dinner break 
                text: qsTranslate("Break","Dinner") + lang.lang
                exclusiveGroup: itemType
            }
            RadioButton {
                id: coffee
                anchors.top: dinner.bottom
                anchors.margins: 3
                //: A short text visible to players telling that now or soon is a short coffee break 
                text: qsTranslate("Break","Coffee") + lang.lang
                exclusiveGroup: itemType
            }
            RadioButton {
                id: custom
                anchors.top: coffee.bottom
                anchors.margins: 3
                //: Label before text input for custom round break name 
                text: qsTr("Custom:") + lang.lang
                exclusiveGroup: itemType
            }
            TextField {
                id: customName
                anchors.verticalCenter: custom.verticalCenter
                anchors.left: custom.right
                enabled: custom.checked && parent.enabled
                width: parent.width - custom.width - 6
                onTextChanged: itemType.breakChanged();
            }
            DatePicker {
                id: breakEndTime
                anchors.margins: 5
                enabled: parent.enabled && !change.checked
                opacity: enabled ? 1 : 0.5
                anchors.top: custom.bottom
                height: Math.min(parent.width, itemTypeBox.parent.height - itemTypeBox.y - y - 22)
                minDate: view.currentRow != -1 ? view.model.qmlData(view.currentRow, "startTime").value :
                    new Date();

                onDateChanged: {
                    if (view.currentRow == -1 || __updatingUI > 0)
                        return;
                    var end = date;
                    end.setSeconds(0);
                    end.setMilliseconds(0);

                    view.model.changeEnd(view.currentRow, end);
                }
            }
        }
    }


    TableView {
        id: view
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 3
        width: 172
        model: timeController.model
        TableViewColumn {
            role: "start";
            //: The column header showing the begin time of round or break in time settings tab.
            title: qsTr("Begin") + lang.lang
            width: 70;
        }
        TableViewColumn {
            role: "name";
            //: The column header showing the name of round or break in time settings tab.
            title: qsTr("Happening") + lang.lang
            width: 83;
        }

        onCurrentRowChanged: itemTypeBox.updateSelection();
        Connections {
            target: view.model
            onDataChanged: {
                itemTypeBox.updateSelection();
            }
        }
    }
}
