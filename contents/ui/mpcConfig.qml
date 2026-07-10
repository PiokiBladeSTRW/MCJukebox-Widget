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

    signal settingsPageChanged(int newPage)

    // This needs more work to be secure
    PC.Label {
        text: "⚠️ Make sure you know what you are Doing"
        font.pixelSize: 16
        font.family: "Minecraft"
        color: "orange"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 30
    }

    PC.TextField {
        id: entryField
        height: 25
        width: 250
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        placeholderText: "MPC Config Music Directory: "


        background: Image {
            anchors.fill: parent
            source: entryField.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
        }

        onAccepted: {
            plasmoid.configuration.musicPath = newPath
            root.settingsPageChanged(1)
        }
    }
}
