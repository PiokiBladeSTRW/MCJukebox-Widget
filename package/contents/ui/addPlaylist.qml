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

    // Animation handler
    signal fadeOutComplete

    opacity: 0
    Behavior on opacity { FadeAnim{} }
    visible : opacity > 0

    function changeOpacity(value) {
        opacity = value
    }

    onVisibleChanged: {
        if( !visible ) {
            fadeOutComplete()
        }
    }



    // Add Songs and Album Art Buttons

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 15 * Singleton.scaleFactor
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
    VisualTextField {
        id: namePlaylist

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30 * Singleton.scaleFactor

        placeholderText: "Enter Playlist Name: "

        onTextChanged: {
            parent.playlistName = text
        }
    }


    // Accept Button
    VisualButton {
        width: 30 * Singleton.scaleFactor
        height: 30 * Singleton.scaleFactor

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15 * Singleton.scaleFactor
        anchors.rightMargin: 15 * Singleton.scaleFactor

        graphic: "playlistMenu_icons/enter"

        onClick: {
            root.playlistAdded(parent.playlistName, parent.playlistFolders, parent.albumArt)
            root.settingsPageChanged(1)
        }

        detectHover: true
        PC.ToolTip.visible: hovered
        PC.ToolTip.text: "Confirm"
    }
}
