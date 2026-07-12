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
        text: "⚠️ Make sure you know what you are Doing"
        font.pixelSize: 15
        font.family: "Minecraft"
        color: "white"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -45
    }

    PC.TextField {
        id: directoryField
        height: 20
        width: 300
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -15

        placeholderText: "MPC Config Music Directory (Optional): "


        background: Image {
            anchors.fill: parent
            source: directoryField.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
        }

        onAccepted: {
            plasmoid.configuration.musicPath = text
            //root.settingsPageChanged(1)
        }
    }

    PC.TextField {
        id: hostField
        height: 20
        width: 300
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 10

        placeholderText: "MPC Config Host (Optional; Default: 127.0.0.1) "


        background: Image {
            anchors.fill: parent
            source: hostField.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
        }

        onAccepted: {
            plasmoid.configuration.mpdHost = text
            //root.settingsPageChanged(1)
        }
    }

    PC.TextField {
        id: portField
        height: 20
        width: 300
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 35

        placeholderText: "MPC Config Port (Optional; Default: 6600) "


        background: Image {
            anchors.fill: parent
            source: portField.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
        }

        onAccepted: {
            plasmoid.configuration.mpdPort = text
            //root.settingsPageChanged(1)
        }
    }
}
