import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Window 2.0

Window {
    id: controlView
    width: 320
    height: 480
    visible: true

    TabView {
        anchors.fill: parent
        Tab {
            title: "Aloitus"
            Item {
                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    source: "tournamentStart.qml"
                }
            }
        }
        Tab {
            title: "Aika"
            Item {
                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    source: "tournamentTime.qml"
                }
            }
        }
        Tab {
            title: "Tulokset"
            Item {
                anchors.fill: parent

                Loader {
                    anchors.fill: parent
                    source: "tournamentResults.qml"
                }
            }
        }
    }
    Clock {

    }
}
