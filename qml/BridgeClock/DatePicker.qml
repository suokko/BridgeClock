// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 2.0

Rectangle {
    width: height
    color: "transparent"
    property variant date : new Date()
    property variant minDate : null
    property int __DPupdatingUI : 0

    onDateChanged: {
            if (__DPupdatingUI) {
                return;
            }
            __DPupdatingUI++;
            cs.value = date.getMinutes();
            csH.value = date.getHours();
            __DPupdatingUI--;
    }

    CircularSlider {
        id: cs
        minimumValue: 0
        maximumValue: 59
        value: date.getMinutes()
        width: parent.width
        height: parent.height
        onValueChanged: {
            if (__DPupdatingUI) {
                return;
            }
            __DPupdatingUI++;
            var newDate = date;
            if (date.getMinutes() <= 10 && value >= 50) {
                newDate.setTime(newDate.getTime() - 1000 * 3600);
            } else if (date.getMinutes() >= 50 && value <= 10) {
                newDate.setTime(newDate.getTime() + 1000 * 3600);
            }
            newDate.setMinutes(value);
            if (minDate != null) {
                while (minDate > newDate) {
                    newDate.setTime(newDate.getTime() + 1000 * 60);
                }
            }
            date = newDate;
            cs.value = date.getMinutes();
            csH.value = date.getHours();
            __DPupdatingUI--;
        }
    }
    CircularSlider {
        id: csH
        rounds: 2
        minimumValue: 0
        maximumValue: 23
        value: date.getHours()
        width: parent.width*0.6
        height: parent.width*0.6
        anchors.centerIn: parent
        onValueChanged: {
            if (__DPupdatingUI) {
                return;
            }
            __DPupdatingUI++;
            var newDate = date;
            if (date.getHours() < 3 && value > 9) {
                newDate.setTime(newDate.getTime() - 1000 * 3600 * 24);
            } else if (date.getHours() > 9 && value < 3) {
                newDate.setTime(newDate.getTime() + 1000 * 3600 * 24);
            }
            newDate.setHours(value);
            if (minDate != null) {
                while (minDate > newDate) {
                    newDate.setTime(newDate.getTime() + 1000 * 3600);
                }
            }
            date = newDate;
            cs.value = date.getMinutes();
            csH.value = date.getHours();
            __DPupdatingUI--;
        }
    }
    Row {
        anchors.centerIn: parent
        Text{
            text: Math.round(csH.value)
            font.pixelSize: parent.parent.width*0.1
            color: csH.pressed?"orange":"black"
        }
        Text{
            text: ":"
            font.pixelSize: parent.parent.width*0.1
        }
        Text{
            text: Math.round(cs.value).toString().length==1?"0"+Math.round(cs.value):Math.round(cs.value)
            font.pixelSize: parent.parent.width*0.1
            color: cs.pressed?"orange":"black"
        }
    }




}
