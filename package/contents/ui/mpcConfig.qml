import QtQuick
import org.kde.plasma.components 3.0 as PC

// MPC Directory Edit
Image {
    id: root
    anchors.fill: parent

    z:2
    source: "../images/background/settings_bg_4.png"
    // visible: playlistRoot.settingsPage === 4 ? 1 : 0
    // opacity: visible ? 1 : 0
    //
    // Behavior on opacity {
    //     NumberAnimation {
    //         duration: 500
    //         easing.type: Easing.Linear
    //     }
    // }

    //signal settingsPageChanged(int newPage)

    //This needs more work to be secure
    PC.Label {
        text: "⚠️ Be Careful Editing These"
        font.pixelSize: 15
        font.family: "Minecraft"
        color: "white"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -40
    }

    // Warning Popup
    PC.Popup {
        id: warnPopup
        anchors.centerIn: parent
        width: 260 * Singleton.scaleFactor
        height: 140 * Singleton.scaleFactor
        modal: true
        focus: true

        closePolicy: PC.Popup.CloseOnEscape | PC.Popup.CloseOnPressOutside

        background: Rectangle {
            color: "black"
            radius: 5
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 12
            padding: 10

            PC.Label {
                text: "⚠️ WARNING"
                font.bold: true
                color: "red"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PC.Label {
                text: "This is an Advanced Setting."
                anchors.horizontalCenter: parent.horizontalCenter
            }
            PC.Label {
                text: "Change Cautiously!"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10
        spacing: 5

        Repeater {
            model: ["MPC Config Music Directory (Optional): ", "MPC Config Host (Optional; Default: 127.0.0.1) ", "MPC Config Port (Optional; Default: 6600) "]

            VisualTextField {
                height: 20 * Singleton.scaleFactor
                width: 300 * Singleton.scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter

                placeholderText: modelData

                onAccepted: {
                    warnPopup.open()
                    switch(index) {
                        case 0:
                            plasmoid.configuration.musicPath = text;
                            break;

                        case 1:
                            plasmoid.configuration.mpdHost = text;
                            break;

                        case 2:
                            plasmoid.configuration.mpdPort = parseInt(text, 10);
                            break;
                    }

                    console.log(plasmoid.configuration.musicPath, plasmoid.configuration.mpdHost, plasmoid.configuration.mpdPort)
                    //root.settingsPageChanged(1)
                }
            }
        }
    }

}
