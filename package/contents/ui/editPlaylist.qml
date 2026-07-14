import QtQuick
import org.kde.plasma.components 3.0 as PC

// Edit Playlist Menu
Image {
    id: root
    anchors.fill: parent

    z:2
    source: "../images/background/settings_bg_3.png"

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

    signal playlistEdited(string chosenPlaylist, string playlistRename, string newAlbumArt, list<string> songsAdd, list<int> removalIndices)

    onReset: {
        renamePlaylist.text = ""
        pickPlaylist.currentIndex = 0
    }


    // ==========================================
    // ROASTER EDIT
    // ==========================================


    // Modify List of Songs in a Given Playlist [AvailableSongsList = Roaster]
    Rectangle {
        id: roasterEdit
        width: 350 * Singleton.scaleFactor
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -20 * Singleton.scaleFactor
        z:3

        color: "#171616"
        radius: 10

        property list<string> displayGraphics: ["playlistMenu_icons/folder_pick", "playlistMenu_icons/music_pick", "playlistMenu_icons/enter"]

        visible: false

        // List of Songs Displayed
        Rectangle {
            id: roasterDisplay
            width: roasterEdit.width
            height: 80 * Singleton.scaleFactor
            radius: 10 * Singleton.scaleFactor

            color: "#303030"

            PC.ScrollView {
                anchors.fill: parent
                clip: true

                ListView {
                    model: root.songsList
                    spacing: 2

                    // Text with onClick function
                    delegate: PC.ItemDelegate {
                        id: songItem
                        width: roasterDisplay.width
                        height: 24 * Singleton.scaleFactor
                        text: ""

                        background: Rectangle {
                            anchors.fill: parent
                            radius: 10

                            color: parent.hovered ? "#80170f" : "#303030"
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            Text {
                                width: 300 * Singleton.scaleFactor
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
                            root.removalIndices.push(root.songsLookup[modelData])
                            root.songsList.splice(index, 1)
                        }
                    }
                }
            }
        }

        // Addition and Confirmation Button
        Repeater {
            model: [20, 60, 320]

            VisualButton {
                width: 20 * Singleton.scaleFactor
                height: 20 * Singleton.scaleFactor

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: 10 * Singleton.scaleFactor
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
                            Singleton.menuForceCount -= 1
                            break
                    }
                }
            }
        }

        // Area Outside for another Exit
        MouseArea {
            height: parent.height
            width: 50 * Singleton.scaleFactor
            anchors.right: parent.right
            anchors.rightMargin: -50 * Singleton.scaleFactor

            onClicked: {
                roasterEdit.visible = false
                Singleton.menuForceCount -= 1
            }
        }
    }

    // ==========================================
    // OTHER BUTTONS
    // ==========================================

    PC.ComboBox {
        id: pickPlaylist
        height: 25 * Singleton.scaleFactor
        width: 60 * Singleton.scaleFactor

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 15 * Singleton.scaleFactor
        anchors.leftMargin: 15 * Singleton.scaleFactor

        model : root.playlists

        Component.onCompleted: {
            popup.height = 120 * Singleton.scaleFactor
        }

        background: Image{
            anchors.fill: parent
            source: "../images/playlistMenu_icons/checkbox.png"
        }

        onActivated: {
            parent.chosenPlaylist = currentText
        }

        hoverEnabled: true
        onHoveredChanged: {
            Singleton.menuForceCount += hovered ? 1 : -1
        }
    }

    VisualTextField {
        id: renamePlaylist

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30 * Singleton.scaleFactor
        anchors.horizontalCenterOffset: 15 * Singleton.scaleFactor

        placeholderText: "Rename Playlist [Optional]: "

        onTextChanged: {
            parent.playlistRename = text
        }
    }

    // Edit Roaster and Album Art Buttons
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 15 * Singleton.scaleFactor
        anchors.verticalCenterOffset: 15 * Singleton.scaleFactor
        spacing: 5

        Repeater {
            model: ["Edit Songs Roaster", "Change Album Art"]

            LabelledButton {
                text: modelData

                onClick: {
                    switch(index) {
                        case 0:
                            bash.obtainSongsPlaylist(root.chosenPlaylist, function(output){
                                // Output Contans a List of Songs in the Given Playlist
                                let songsList = output.trim().split("\n")
                                let songsHashMap = {}

                                for (let i = 0 ; i < songsList.length ; i++) {
                                    songsHashMap[String(songsList[i])] = i + 1
                                }

                                root.songsList = songsList
                                root.songsLookup = songsHashMap
                            })
                            roasterEdit .visible = true

                            Singleton.menuForceCount += 1

                            break
                        case 1:
                            filePickOpen(1)
                            break;
                    }
                }
            }
        }
    }


    // ==========================================
    // CONFIRMATION & DELETION
    // ==========================================


    // Confirmation
    VisualButton {
        width: 20 * Singleton.scaleFactor
        height: 20 * Singleton.scaleFactor
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15 * Singleton.scaleFactor
        anchors.rightMargin: 32.5 * Singleton.scaleFactor

        graphic: "playlistMenu_icons/enter"

        onClick: {
            parent.removalIndices.sort((a,b) => b-a)
            root.playlistEdited(parent.chosenPlaylist, parent.playlistRename, parent.newAlbumArt, parent.songsAdd, parent.removalIndices)
            parent.reset()
            root.settingsPageChanged(1)
        }
    }

    // Delete Playlist
    VisualButton {
        width: 20 * Singleton.scaleFactor
        height: 20 * Singleton.scaleFactor
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15 * Singleton.scaleFactor
        anchors.rightMargin: 7.5 * Singleton.scaleFactor

        graphic: "playlistMenu_icons/delete"

        onClick: {
            bash.deletePlaylist(parent.chosenPlaylist)
            parent.reset()
            root.settingsPageChanged(1)
        }
    }
}
