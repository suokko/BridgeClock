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

import QtQuick 2.2
import QtQuick.Controls 1.0
import QtQuick.Window 2.1

Window {
    id: controlView
    width: 480
    height: 640
    visible: true
    //: The window header including version number as parameter %1
    title: qsTr("Bridge clock %1").arg(timeController.version) + lang.lang
    readonly property string version: "$(VERSION)"
    property string newversion: ""
    property string versionurl: ""

    Component.onCompleted: timeController.version = version

    Rectangle {
        id: versiondlg

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.margins: 3
        antialiasing: true

        height: visible ? msg.height + msg.y*2 : 0
        visible: newversion != ""

        border.width: 1
        border.color: "black"
        color: "yellow"
        radius: 5

        clip: true

        Text {
            x: versiondlg.radius
            y: versiondlg.radius
            width: parent.width - parent.radius*2
            id: msg
            text: "<html><p style=\"font-size:large\">" +
                //: %1 is version number with downloadable link %2 & %3 html code for ignore link
                qsTr("A new version of bridge clock %1 is available for download.<br/>%2Ignore%3").arg(
                "<a href='" + versionurl +"'>" + newversion + "</a>").arg("<a href='#ignore'>").arg("</a>") + "</p>" +
                "\n<a href='" + versionurl + "' style=\"font-size:small\">" + versionurl + "</a></html>"  + lang.lang

            textFormat: Text.RichText
            wrapMode: Text.Wrap

            MouseArea {
                anchors.fill: parent

                cursorShape: parent.hoveredLink != "" ? Qt.PointingHandCursor : undefined
                propagateComposedEvents: true

                onPressed: mouse.accepted = false
            }

            onLinkActivated: {
                if (link != "#ignore") {
                    Qt.openUrlExternally(link)
                }
                versiondlg.height = 0
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 2000
                easing.type: Easing.InOutQuad

                onRunningChanged: {
                    if (!running && versiondlg.visible && versiondlg.height == 0) {
                        versiondlg.visible = false
                    }
                }
            }
        }
    }

    Connections {
        target: timeController
        onNewversion: {
            newversion = version
            versionurl = url
        }
    }

    TabView {
        anchors.top: versiondlg.visible ? versiondlg.bottom : parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left

        anchors.topMargin: versiondlg.visible ? versiondlg.anchors.margins : 0

        Tab {
            //: The title for initial setup tab with round number and length settings
            title: qsTr("Start") + lang.lang

                Loader {
                    anchors.fill: parent
                    source: "tournamentStart.qml"
                }
        }
        Tab {
            //: The title for time settings tab to setup breaks and modify length of rounds 
            title: qsTr("Time") + lang.lang

                Loader {
                    anchors.fill: parent
                    source: "tournamentTime.qml"
                }
        }
        Tab {
            //: The title for result view settings tab to select the visible result file and limit the visible area
            title: qsTr("Results") + lang.lang

                Loader {
                    anchors.fill: parent
                    source: "tournamentResults.qml"
                }
        }
    }
    Loader {
        asynchronous: true
        sourceComponent: clock
        x: controlView.x + controlView.width
    }
    Component {
        id: clock
        Clock {
            x: controlView.x + controlView.width
        }
    }

    onClosing: Qt.quit()
}
