// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 2.0
import "fn.js" as FN

BorderImage {
    source: "circularSlider.png"
    property int numberOfSteps : (maximumValue - minimumValue + 1) / rounds
    property int rounds : 1
    property int currentRound : Math.floor((value - minimumValue) / (maximumValue - minimumValue + 1) * rounds)
    property real minimumValue: 0
    property variant maximumValue : 12
    property variant value : topValueMax?maximumValue:minimumValue
    property variant pressed : handle.pressed
    width: 350
    height: 350

    BorderImage {
        id: rect
        width: parent.width*0.2; height: parent.height*0.2
        source: "circularSliderHandle.png"
        x: -(Math.sin((value - minimumValue - currentRound/rounds*(maximumValue - minimumValue + 1))/
                      (maximumValue-minimumValue+1)*rounds*-2*Math.PI)*
             (parent.width-width)/2)+parent.width/2-width/2
        y: -(Math.cos((value - minimumValue - currentRound/rounds*(maximumValue - minimumValue + 1))/
                      (maximumValue-minimumValue+1)*rounds*-2*Math.PI)*
             (parent.height-height)/2)+parent.height/2-height/2
        Text {
            id: val
            anchors.centerIn: parent;
            text: Math.floor(value)
            font.pixelSize: parent.width*0.5
        }
    }

    MouseArea{
        id: handle
        property int center: parent.width/2
        property int clickpointX
        property int clickpointY
        property bool isIn
        anchors.fill: parent
        onPressed: {
            if (mouseX>rect.x&&mouseX<rect.x+rect.width&&mouseY>rect.y&&mouseY<rect.y+rect.height){
                isIn = true;
                clickpointX =  mouseX - rect.x -rect.width/2
                clickpointY =  mouseY - rect.y - rect.height/2
            } else {
                clickpointX = 0
                clickpointY = 0
                isIn = false
            }
            mouse.accepted = contains(mouseX, mouseY);
        }
        onMouseXChanged: {
            if (mouse.accepted){
                var res = FN.nearestPointOnCircle(mouseX - center - clickpointX, mouseY - center - clickpointY, center, center, center-rect.width/2)
                if (numberOfSteps>0){
                    res = FN.findNearestSlice(mouseX,mouseY, numberOfSteps, center)
                }
                var range = (maximumValue-minimumValue + 1) / rounds
                var max = Math.floor(range * (currentRound + 1) + minimumValue - 1)
                var min = Math.floor(range * currentRound + minimumValue)

                // about 45 decrees (12.5%) away from top is round change zone
                var zoneIn = 0;
                var zoneOut = 0;
                if ((value-min) < range*0.125)
                    zoneIn = 1;
                else if ((max - value) < range*0.125)
                    zoneIn = -1;

                var currentAngle = (Math.atan2(res.x -center, res.y -center)+Math.PI)/(2*Math.PI)
                if (1 - currentAngle < 0.125)
                    zoneOut = 1
                else if (currentAngle < 0.125)
                    zoneOut = -1

                if (zoneIn * zoneOut == -1) {
                    currentRound += zoneIn < 0 ? 1 : -1;
                    if (currentRound == rounds)
                        currentRound = 0;
                    else if (currentRound == -1)
                        currentRound = rounds - 1;
                }

                max = Math.floor(range * (currentRound + 1) + minimumValue - 1)
                min = Math.floor(range * currentRound + minimumValue)

                value = max - currentAngle* range + 1;
            }
        }
        function contains(x, y) {
            var d = (width / 2);
            var ds = width/2-rect.width
            var dx = (x - width / 2);
            var dy = (y - height / 2);
            return (d * d > dx * dx + dy * dy)&&(ds * ds < dx * dx + dy * dy);
        }


    }


}
