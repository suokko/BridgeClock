// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 2.0

Rectangle {
    width: height
    color: "transparent"
    property alias hour : csH.value
    property alias minute : cs.value
    property int prevMinutes : -1
    CircularSlider {
        id: cs
        minimumValue: 0
        maximumValue: 59
        value: new Date().getMinutes()
        width: parent.width
        height: parent.height
        onValueChanged: {
            if (prevMinutes == -1 ||
                (prevMinutes > 10 && prevMinutes < 50)) {
                prevMinutes = value
                return;
            }
            if (prevMinutes >= 50 && value <= 10) {
                var hour = csH.value + 1;
                if (hour > csH.maximumValue)
                    hour = csH.minimumValue;
                csH.value = hour;
            } else if (prevMinutes <= 10 && value >= 50) {
                var hour = csH.value - 1;
                if (hour < csH.minimumValue)
                    hour = csH.maximumValue;
                csH.value = hour;
            }
            prevMinutes = value

        }
    }
    CircularSlider {
        id: csH
        rounds: 2
        minimumValue: 0
        maximumValue: 23
        value: new Date().getHours()
        width: parent.width*0.6
        height: parent.width*0.6
        anchors.centerIn: parent
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
