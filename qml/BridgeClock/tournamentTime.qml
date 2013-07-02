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
import org.bridgeClock.TimeModel 1.0

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
            text: timeController.roundInfo.playing === 0 ?
                      (timeController.roundInfo.name + " -> " +
                       timeController.roundInfo.nextName) :
                      timeController.roundInfo.name
            font.pixelSize: timeController.roundInfo.playing === 0 ? 14 : 20
            height: 24
            anchors.top: parent.top
            anchors.margins: 5
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Label {
            id: timeLeftLabel
            anchors.margins: 5
            anchors.top: header.bottom
            anchors.left: parent.left
            visible: timeController.roundInfo.playing < 2
            text: "Jäljellä:"
        }
        Text {
            id: timeLeft
            anchors.verticalCenter: timeLeftLabel.verticalCenter
            anchors.left: timeLeftLabel.right
            visible: timeController.roundInfo.playing < 2
            anchors.margins: 3
            text: timeController.roundInfo.timeLeft
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
                text: "+10s"
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(10*1000);
            }
            Button {
                text: "+1m"
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(60*1000);
            }
            Button {
                text: "+5m"
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(5*60*1000);
            }
            Button {
                text: "-10s"
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(-10*1000);
            }
            Button {
                text: "-1m"
                Layout.fillWidth: true
                onPressedChanged: if (pressed) roundGrid.appendTime(-60*1000);
            }
            Button {
                text: "-5m"
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
            visible: view.currentRow >= 0
            font.pixelSize: 20
            text: view.contentItem.currentItem && view.contentItem.currentItem.itemModel ?
                      view.contentItem.currentItem.itemModel["name"] :
                      "Ei valintaa"
        }
        Label {
            id: startLabel
            anchors.margins: 3
            anchors.top: selectionHeader.bottom
            anchors.left: parent.left
            visible: view.currentRow >= 0
            text: "Alku:"
        }
        Text {
            id: start
            anchors.verticalCenter: startLabel.verticalCenter
            anchors.left: startLabel.right
            anchors.margins: 3
            visible: view.currentRow >= 0
            text: view.contentItem.currentItem && view.contentItem.currentItem.itemModel ?
                      view.contentItem.currentItem.itemModel["start"] :
                      "Ei valintaa"
        }
        Label {
            id: endLabel
            anchors.margins: 3
            anchors.top: startLabel.bottom
            anchors.left: parent.left
            visible: view.currentRow >= 0
            text: "Loppu:"
        }
        Text {
            id: end
            anchors.verticalCenter: endLabel.verticalCenter
            anchors.left: endLabel.right
            anchors.margins: 3
            visible: view.currentRow >= 0
            text: view.contentItem.currentItem && view.contentItem.currentItem.itemModel ?
                      view.contentItem.currentItem.itemModel["end"] :
                      "Ei valintaa"
        }
        Label {
            id: prevLabel
            anchors.margins: 3
            anchors.top: endLabel.bottom
            anchors.left: parent.left
            visible: view.currentRow >= 0
            text: "Edellinen:"
        }
        Text {
            id: prev
            anchors.verticalCenter: prevLabel.verticalCenter
            anchors.left: prevLabel.right
            anchors.margins: 3
            visible: view.currentRow >= 0
            text: view.contentItem.currentItem && view.contentItem.currentItem.itemModel ?
                      view.contentItem.currentItem.itemModel["previous"] :
                      "Ei valintaa"
        }

        GroupBox {
            id: itemTypeBox
            anchors.top: prev.bottom
            enabled: view.contentItem.currentItem && view.contentItem.currentItem.itemModel ?
                         view.contentItem.currentItem.itemModel["type"] === TimeModel.Break ||
                         view.contentItem.currentItem.itemModel["type"] === TimeModel.Change :
                         false
            visible: view.currentRow >= 0
            width: parent.width - 6

            function updateSelection() {
                if (!view.contentItem.currentItem ||
                        !view.contentItem.currentItem.itemModel)
                    return;
                __updatingUI++;
                if (itemType.current)
                    itemType.current.checked = false
                var item = view.contentItem.currentItem.itemModel;
                var type = item["type"];
                var name = item["name"];
                breakEndTime.hour = item["endHour"];
                breakEndTime.minute = item ["endMinute"];
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
                    if (name === "Ruokatauko") {
                        food.checked = true;
                    } else if (name === "Kahvitauko") {
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
                                              "Vaihto");
                        break;
                    case food:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Break,
                                              "Ruokatauko");
                        break;
                    case coffee:
                        view.model.changeType(view.currentRow,
                                              TimeModel.Break,
                                              "Kahvitauko");
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
                text: "Vaihto"
                exclusiveGroup: itemType
            }
            RadioButton {
                id: food
                anchors.top: change.bottom
                anchors.margins: 3
                text: "Ruokatauko"
                exclusiveGroup: itemType
            }
            RadioButton {
                id: coffee
                anchors.top: food.bottom
                anchors.margins: 3
                text: "Kahvitauko"
                exclusiveGroup: itemType
            }
            RadioButton {
                id: custom
                anchors.top: coffee.bottom
                anchors.margins: 3
                text: "Muu:"
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

                function updateEnd() {
                    if (!view.contentItem.currentItem || __updatingUI > 0)
                        return;
                    var startSecs = view.contentItem.currentItem.itemModel["startTime"];
                    var end = new Date();
                    var start = new Date();
                    start.setTime(startSecs);
                    end.setHours(breakEndTime.hour);
                    end.setMinutes(breakEndTime.minute);
                    end.setSeconds(0);
                    end.setMilliseconds(0);

                    if (end.getTime() < start.getTime()) {
                        if (start.getTime() - end.getTime() < 3600*1000)
                            end.setTime(end.getTime() + 3600*1000);
                        else if (start.getTime() - end.getTime() < 6*3600*1000)
                            end = start;
                        else
                            end.setTime(end.getTime() + 24*3600*1000);
                    }
                    view.model.changeEnd(view.currentRow, end);
                }

                onHourChanged: updateEnd();
                onMinuteChanged: updateEnd();
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
            title: "Alku";
            width: 70;
        }
        TableViewColumn {
            role: "name";
            title: "Tapahtuma";
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
