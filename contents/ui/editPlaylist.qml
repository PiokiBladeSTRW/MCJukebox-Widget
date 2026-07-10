import QtQuick
import org.kde.plasma.components 3.0 as PC

// Edit Playlist Menu
Image {
    id: editPlaylist
    anchors.fill: parent

    z:2
    source: "../images/background/settings_bg_3.png"
    // visible: playlistRoot.settingsPage === 3
    // opacity: visible ? 1 : 0
    //
    // Behavior on opacity {
    //     NumberAnimation {
    //         duration: 500
    //         easing.type: Easing.Linear
    //     }
    // }

    property list<string> playlists: []

    property string chosenPlaylist: playlists[0]
    property string playlistRename : ""
    property string newAlbumArt: ""

    // Songs List to display on Roaster and a Dictionary to look up Indices of songs
    property list<string> songsList
    property var songsLookup

    // List of Songs Added / Removed
    property list<string> songsAdd
    property list<int> removalIndices

    signal reset
    signal settingsPageChanged(int newPage)
    signal folderPickOpen()
    signal filePickOpen(bool artMode)
    signal songsListObtain(string chosenPlaylist)

    signal playlistEdited(string chosenPlaylist, string newName, string albumArt, list<string> songsAdded, list<int> songsRemoved)
    signal playlistDelete(string chosenPlaylist)

    onReset: {
        renamePlaylist.text = ""
        pickPlaylist.currentIndex = 0
    }


    // Modify List of Songs in a Given Playlist [AvailableSongsList = Roaster]
    Rectangle {
        id: roasterEdit
        width: 350
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -20
        z:3

        color: "#171616"
        radius: 10

        property list<string> displayGraphics: ["playlistMenu_icons/folder_pick", "playlistMenu_icons/music_pick", "playlistMenu_icons/enter"]

        visible: false

        // List of Songs Displayed
        Rectangle {
            id: roasterDisplay
            width: roasterEdit.width
            height: 80
            radius: 10

            color: "#303030"

            PC.ScrollView {
                anchors.fill: parent
                clip: true

                ListView {
                    model: editPlaylist.songsList
                    spacing: 2

                    // Text with onClick function
                    delegate: PC.ItemDelegate {
                        id: songItem
                        width: roasterDisplay.width
                        height: 24
                        text: ""

                        background: Rectangle {
                            anchors.fill: parent
                            radius: 10

                            color: parent.hovered ? "#80170f" : "#303030"
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            Text {
                                width: 300
                                anchors.left: parent.left

                                text: modelData
                                color: "white"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Image {
                                anchors.right: parent.right
                                source: "../images/playlistMenu_icons/trash.svg"
                                visible: songItem.hovered
                            }
                        }

                        onClicked: {
                            editPlaylist.removalIndices.push(editPlaylist.songsLookup[modelData])
                            editPlaylist.songsList.splice(index, 1)
                        }
                    }
                }
            }
        }

        // Addition and Confirmation Button
        Repeater {
            model: [20, 60, 320]

            VisualButton {
                width: 20
                height: 20

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: 10
                anchors.leftMargin: modelData

                graphic: roasterEdit.displayGraphics[index]

                onClick : {
                    switch(index) {
                        case 0:
                            folderPickOpen()
                            break;
                        case 1:
                            filePickOpen(0)
                            break;
                        case 2:
                            roasterEdit.visible = false;
                            break
                    }
                }
            }
        }

        // Area Outside for another Exit
        MouseArea {
            height: parent.height
            width: 50
            anchors.right: parent.right
            anchors.rightMargin: -50

            onClicked: {
                roasterEdit.visible = false
            }
        }
    }

    // Edit Roaster and Album Art Buttons
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 15
        anchors.verticalCenterOffset: 15
        spacing: 5

        Repeater {
            model: ["Edit Songs Roaster", "Change Album Art"]

            LabelledButton {
                text: modelData

                onClick: {
                    switch(index) {
                        case 0:
                            editPlaylist.songsListObtain(editPlaylist.chosenPlaylist)
                            roasterEdit .visible = true
                            break
                        case 1:
                            filePickOpen(1)
                            break;
                    }
                }
            }
        }
    }


    PC.ComboBox {
        id: pickPlaylist
        height: 25
        width: 60

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 15
        anchors.leftMargin: 15

        model : editPlaylist.playlists

        Component.onCompleted: {
            popup.height = 120
        }

        background: Image{
            anchors.fill: parent
            source: "../images/playlistMenu_icons/checkbox.png"
        }

        onActivated: {
            parent.chosenPlaylist = currentText
        }
    }

    PC.TextField {
        id: renamePlaylist
        height: 25
        width:250

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30
        anchors.horizontalCenterOffset: 15

        placeholderText: "Rename Playlist [Optional]: "

        background: Image {
            anchors.fill: parent
            source: renamePlaylist.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
        }

        onTextChanged: {
            parent.playlistRename = text
        }
    }

    // Confirmation
    VisualButton {
        width: 20
        height: 20
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 32.5

        graphic: "playlistMenu_icons/enter"

        onClick: {
            parent.removalIndices.sort((a,b) => b-a)
            editPlaylist.playlistEdited(parent.chosenPlaylist, parent.playlistRename, parent.newAlbumArt, parent.songsAdd, parent.removalIndices)
            parent.reset()
            editPlaylist.settingsPageChanged(1)
        }
    }

    // Delete Playlist
    VisualButton {
        width: 20
        height: 20
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 7.5

        graphic: "playlistMenu_icons/delete"

        onClick: {
            editPlaylist.playlistDelete(parent.chosenPlaylist)
            parent.reset()
            editPlaylist.settingsPageChanged(1)
        }
    }
}
