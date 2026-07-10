import QtQuick
import org.kde.plasma.components 3.0 as PC

// Add Playlist Menu
Image {
    id: root
    anchors.fill: parent

    z: 2

    source: "../images/background/settings_bg_2.png"

    property string playlistName
    property string albumArt

    property list<string> playlistFolders

    signal settingsPageChanged(int newPage)
    signal folderPickOpen()
    signal filePickOpen(bool artMode)

    signal playlistAdded(string playlistName, list<string> playlistFolders, string albumArt)

/*
    visible: playlistRoot.settingsPage === 2
    opacity: visible ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 500
            easing.type: Easing.Linear
        }
    }*/


    // Add Songs and Album Art Buttons

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 15
        spacing: 5

        Repeater {
            model: ["Add Songs", "Add Album Art [Optional]"]

            LabelledButton {
                text: modelData

                onClick: {
                    switch(index) {
                        case 0:
                            root.folderPickOpen()
                            break;
                        case 1:
                            root.filePickOpen(1)
                            break;
                    }
                }
            }
        }
    }


    // Playlist Name
    PC.TextField {
        id: namePlaylist
        height: 25
        width:250

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30

        placeholderText: "Enter Playlist Name: "

        background: Image {
            anchors.fill: parent
            source: namePlaylist.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
        }

        onTextChanged: {
            parent.playlistName = text
        }
    }

    // Accept Button
    VisualButton {
        width: 30
        height: 30

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 15

        graphic: "playlistMenu_icons/enter"

        onClick: {
            root.playlistAdded(parent.playlistName, parent.playlistFolders, parent.albumArt)
            root.settingsPageChanged(1)
        }
    }
}
