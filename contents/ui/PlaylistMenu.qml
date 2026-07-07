import QtQuick
import org.kde.plasma.plasma5support 2.0 as PS
import org.kde.plasma.components 3.0 as PC
import QtQuick.Dialogs
import QtQuick.Controls as C

Image {
    id: playlistRoot
    anchors.fill: parent
    property bool visibleCondn          // Boolean Assigned by ROOT

    property string homeDirPath
    property int settingsPage: 0        // 0: Disabled, 1: Selection, 2: Adding Playlist, 3: EditPlaylist, 4: MPC Modification
    property list<string> playlists
    property list<string> searchResults
    property list<string> searchResultsDir

    property list<string> supportedFormats: ["flac", "ogg", "mp3", "opus", "wav", "aac"]

    signal playlistChosen(string playlist)
    signal playlistAdded(string title, list<string> playlistFolders, string albumArt)
    signal playlistEdited(string chosenPlaylist, string newName, string albumArt, list<string> songsAdded, list<int> songsRemoved)
    signal playlistDelete(string chosenPlaylist)
    signal menuForceState(bool state)

    signal tempSong(string chosenDir)


    source: "../images/amethyst_block"
    fillMode: Image.Tile

    opacity: visibleCondn ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 500
            easing.type: Easing.Linear
        }
    }

    //Wrapper function
    function execute(cmd) {
        executable.exec(cmd)
    }


    // -----------------------------
    // UTILITIES
    // -----------------------------


    // Executing Terminal Commands
    PS.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) =>{

            if(sourceName === "mpc lsplaylists") {
                playlistRoot.playlists = data["stdout"].trim().split("\n")

            } else if(sourceName.startsWith("mpc search")) {

                if(sourceName.startsWith("mpc search -f '%title%'")){
                    playlistRoot.searchResults = data["stdout"].trim().split("\n")
                } else {
                    playlistRoot.searchResultsDir = data["stdout"].trim().split("\n")
                }

            } else if (sourceName === "ls /home") {
                playlistRoot.homeDirPath= "/home/"+ data["stdout"].trim()

                if(plasmoid.configuration.musicPath === "" ){
                    plasmoid.configuration.musicPath = playlistRoot.homeDirPath + "/Music/"
                }

            } else if (sourceName.startsWith("mpc playlist")) {
                let songsList = data["stdout"].trim().split("\n")
                let songsHashMap = {}

                for (let i = 0 ; i < songsList.length ; i++) {
                    songsHashMap[String(songsList[i])] = i + 1
                }

                editPlaylist.songsList = songsList
                editPlaylist.songsLookup = songsHashMap

            } else if (sourceName.startsWith("ls -p")) {

                let files = data["stdout"].trim().split("\n")
                let songs = []

                for (let i =0 ; i< files.length ; i++ ) {
                    let splitFile = String(files[i]).trim().split(".")

                    //Check for valid file format
                    if( playlistRoot.supportedFormats.includes( splitFile[splitFile.length - 1] )){
                        songs.push(files[i])
                    }
                }
                songs.sort()

                let baseVal = Object.keys(editPlaylist.songsLookup).length + 1
                for (let i = 0; i < songs.length ; i++){
                    editPlaylist.songsLookup[songs[i]] = baseVal + i
                }

                editPlaylist.songsList.push(...songs)
            }


            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        Component.onCompleted: {
            // Fetch Latest playlists List
            connectSource("mpc lsplaylists")
            connectSource("ls /home")
        }
    }

    // Wrong Directory File/Folder Picked Warning
    C.Popup {
        id: warnPopup
        anchors.centerIn: parent
        width: 260
        height: 140
        modal: true
        focus: true

        closePolicy: C.Popup.CloseOnEscape | C.Popup.CloseOnPressOutside

        background: Rectangle {
            color: "black"
            radius: 5
        }

        contentItem: Column {
            anchors.fill: parent
            spacing: 12
            padding: 10

            C.Label {
                text: "⚠️ WARNING"
                font.bold: true
                color: "red"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            C.Label {
                text: "Playlist/Music Directories should be in\n"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            C.Label {
                text: plasmoid.configuration.musicPath
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }


    // Folder Picker [Music Directories]
    FolderDialog {
        id : folderPick
        title: "Choose Music Folder"

        onAccepted: {
            let path = folderPick.selectedFolder.toString().replace("file://", "")

            // Return In-case the folder isn't in Music Directory
            if(! path.startsWith(plasmoid.configuration.musicPath)) {
                warnPopup.open()
                return
            }

            // Remove the Music Directory prefix for MPC
            path = path.replace(plasmoid.configuration.musicPath, "")

            if(playlistRoot.settingsPage === 0) {
                playlistRoot.tempSong(path)

            } else if(playlistRoot.settingsPage === 2) {
                addPlaylist.playlistFolders.push(path)

            } else {
                editPlaylist.songsAdd.push(path)
                executable.exec('ls -p "'+ plasmoid.configuration.musicPath + path +'" | grep -v /')
            }


            folderPick.currentFolder = ""
            folderPick.close()
        }

        onRejected: {
            folderPick.currentFolder = ""
            folderPick.close()
        }
    }

    // File Picker [ Album Art]
    FileDialog {
        id: filePick
        title: "Choose Album Art    "

        nameFilters: ["Image File (*.png *.jpg *.jpeg *.webp)"]
        fileMode: FileDialog.OpenFile

        onAccepted: {
            let path = filePick.selectedFile.toString().replace("file://", "")

            if(playlistRoot.settingsPage === 2) {
                addPlaylist.albumArt = path
            } else if(playlistRoot.settingsPage === 3) {
                editPlaylist.newAlbumArt = path
            }
            filePick.close()
        }
    }

    // File Picker [Songs]
    FileDialog {
        id: filePickMusic
        title: "Choose Music File    "

        nameFilters: ["Music File (*.flac *.ogg *.mp3 *.opus *.wav *.aac)"]
        fileMode: FileDialog.OpenFile

        onAccepted: {
            let path = filePickMusic.selectedFile.toString().replace("file://", "")

            if(! path.startsWith(plasmoid.configuration.musicPath)) {
                folderWarning.open()
                return
            }

            path = path.replace(plasmoid.configuration.musicPath, "")

            if(playlistRoot.settingsPage === 0) {
                playlistRoot.tempSong(path)

            } else if(playlistRoot.settingsPage === 3) {
                let title = path.split("/")
                editPlaylist.songsLookup[title[title.length - 1]] = Object.keys(editPlaylist.songsLookup).length + 1
                editPlaylist.songsList.push(title[title.length - 1])
                editPlaylist.songsAdd.push(path)
            }
            filePickMusic.close()
        }
    }

    // -----------------------------
    // Main Display
    // -----------------------------

    // Search Bar
    Button {
        z: 1
        height: 25
        width: 25
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 30

        graphic: "search"

        onClick: {
            searchBar.visible = true
            searchBar.width = 80
        }

        PC.TextField {
            id: searchBar
            height: 25
            width: 0

            visible: false
            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.Linear
                }
            }


            onTextChanged: {
                executable.exec("mpc search -f '%title%' title "+ text)
                executable.exec("mpc search -f '%file%' title "+ text)
            }
        }

        Rectangle {
            y: 25
            width: 80
            height: 60
            color: "black"

            visible: searchBar.visible

            C.ScrollView {
                anchors.fill: parent
                clip:true

                ListView {
                    height: 60
                    width: parent.width
                    model: playlistRoot.searchResults
                    spacing: 2

                    bottomMargin: 10

                    // Text with onClick function
                    delegate: C.ItemDelegate {
                        width: 70
                        height: 15
                        text: modelData

                        bottomPadding: 0

                        onClicked: {
                            tempSong(playlistRoot.searchResultsDir[index])
                        }
                    }
                }
            }
        }

        // Exit
        MouseArea {
            z: -1
            width: 500
            height: 150
            x:-30
            y:-25

            visible: searchBar.visible

            onClicked: {
                searchBar.width= 0
                searchBarOff.start()
            }
        }

        Timer {
            id: searchBarOff
            interval: 300
            onTriggered: {
                searchBar.visible = false
            }
        }
    }

    // Temporary Songs Options
    Button {
        height: 25
        width: 25
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 2

        graphic: "folder_pick"

        visible: settingsPage === 0 && visibleCondn

        onClick: {
            folderPick.open()
        }
    }

    Button {
        height: 25
        width: 25
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 35

        graphic: "music_pick"

        visible: settingsPage === 0 && visibleCondn

        onClick: {
            filePickMusic.open()
        }
    }


    // Playlist Display
    Flickable {
        id: scrollContainer
        width: 195
        height: 150

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 15

        z: 1
        visible: playlistRoot.visibleCondn && settingsPage === 0

        // MouseArea {
        //     z:2
        //     anchors.fill: parent
        //
        //     visible: settingsPage === 0 && visibleCondn
        //
        //     hoverEnabled: true
        //
        //     onEntered: {
        //         console.log("in")
        //         menuForced(true)
        //     }
        //     onExited: {
        //         console.log("out")
        //         menuForced(false)
        //     }
        // }

        clip: true
        contentWidth: playlistGrid.width
        contentHeight: playlistGrid.height

        C.ScrollBar.vertical: C.ScrollBar {
            visible: playlistRoot.visibleCondn
            policy: C.ScrollBar.AsNeeded
        }

        // Your Playlist Display remains almost identical inside
        Grid {
            id: playlistGrid
            columns: 3
            spacing: 10

            topPadding: 20
            bottomPadding: 20

            Repeater {
                model: playlistRoot.playlists

                Button {
                    height: 50
                    width: 50

                    //detectHover: true

                    source: "file://"+  playlistRoot.homeDirPath + "/.cache/jukebox_covers/"+modelData+".png"
                    opacity: index === plasmoid.configuration.playlistIndex ? 1 : 0.6
                    active: visibleCondn && settingsPage === 0

                    //C.ToolTip.visible: hovered
                    //C.ToolTip.text: modelData

                    onStatusChanged: {
                        if(playlistRoot.homeDirPath && status === 3) {
                            source= "../images/note_block.png"
                        }
                    }

                    onClick: {
                        plasmoid.configuration.playlistIndex = index
                        playlistChosen(modelData);
                    }
                }
            }
        }
    }


    // -----------------------------
    // SETTINGS
    // -----------------------------

    // Settings Toggle
    Button {
        id: settingsToggle

        width: 30
        height: 30
        anchors.top: playlistRoot.top
        anchors.right: playlistRoot.right

        anchors.topMargin: 15
        anchors.rightMargin: 15

        graphic: "settings"

        visible: visibleCondn

        z: 3

        onClick: {
            switch(playlistRoot.settingsPage) {

                // From Settings Selction
                case 1:
                    playlistRoot.settingsPage = 0;
                    menuForceState(false)
                    break

                // Anywhere Else
                default:
                    playlistRoot.settingsPage = 1;
                    menuForceState(true)
                    break
            }
        }
    }


    // Base Settings Menu
    Image {
        id: settingsMenu
        anchors.fill: parent

        z:1

        source: "../images/settings_bg_1.png"

        property list<string> displayTexts: ["Add Playlist", "Edit Playlist", "MPC Directory Config"]

        visible: playlistRoot.settingsPage === 1
        opacity: playlistRoot.settingsPage === 1

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.Linear
            }
        }

        // Settings Page Selection
        Repeater {
            model: [-30, 0, 30]

            Button {
                width: 250
                height: 25

                graphic: "button"

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: modelData

                Text {
                    text: settingsMenu.displayTexts[index]
                    font.family: "Minecraft"
                    renderType: Text.NativeRendering
                    font.pixelSize: 14

                    color: "white"

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                onClick: {
                    playlistRoot.settingsPage = index + 2
                }
            }
        }
    }


    // Add Playlist Menu
    Image {
        id: addPlaylist
        anchors.fill: parent

        z: 2

        source: "../images/settings_bg_2.png"

        property string playlistName
        property string albumArt

        property list<string> playlistFolders
        property list<string> displayTexts: ["Add Songs", "Add Album Art [Optional]"]

        visible: playlistRoot.settingsPage === 2


        // Add Songs and Album Art Buttons
        Repeater {
            model: [0, 30]

            Button {
                width: 250
                height: 25

                graphic: "button"

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: modelData

                Text {
                    text: addPlaylist.displayTexts[index]
                    font.family: "Minecraft"
                    renderType: Text.NativeRendering
                    font.pixelSize: 14

                    color: "white"

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                onClick: {
                    switch(index) {
                        case 0:
                            folderPick.open()
                            break;
                        case 1:
                            filePick.open();
                            break;
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
        Button {
            width: 30
            height: 30

            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 15
            anchors.rightMargin: 15

            graphic: "enter"

            onClick: {
                playlistRoot.settingsPage = 1
                playlistAdded(parent.playlistName, parent.playlistFolders, parent.albumArt)
            }
        }
    }


    // Edit Playlist Menu
    Image {
        id: editPlaylist
        anchors.fill: parent

        z:2
        source: "../images/settings_bg_3.png"
        visible: playlistRoot.settingsPage === 3

        property string chosenPlaylist: playlistRoot.playlists[0]
        property string playlistRename : ""
        property string newAlbumArt: ""

        property list<string> displayTexts: ["Edit Songs Roaster", "Change Album Art"]

        // Songs List to display on Roaster and a Dictionary to look up Indices of songs
        property list<string> songsList
        property var songsLookup

        // List of Songs Added / Removed
        property list<string> songsAdd
        property list<int> removalIndices

        signal reset

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

            property list<string> displayGraphics: ["folder_pick", "music_pick", "enter"]

            visible: false

            // List of Songs Displayed
            Rectangle {
                id: roasterDisplay
                width: roasterEdit.width
                height: 80
                radius: 10
                color: "#303030"

                C.ScrollView {
                    anchors.fill: parent
                    clip: true

                    ListView {
                        model: editPlaylist.songsList
                        spacing: 2

                        // Text with onClick function
                        delegate: C.ItemDelegate {
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
                                    text: modelData
                                    color: "white"
                                    font.pixelSize: 12
                                    anchors.left: parent.left
                                    elide: Text.ElideRight
                                }

                                Image {
                                    source: "../images/trash.svg"
                                    anchors.right: parent.right
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

                Button {
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
                                folderPick.open();
                                break;
                            case 1:
                                filePickMusic.open();
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
        Repeater {
            model: [0, 30]

            Button {
                width: 250
                height: 25

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenterOffset: 15
                anchors.verticalCenterOffset: modelData


                graphic: "button"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.

                    text: editPlaylist.displayTexts[index]
                    font.family: "Minecraft"
                    renderType: Text.NativeRendering
                    font.pixelSize: 14

                    color: "white"
                }

                onClick: {
                    switch(index) {
                        case 0:
                            executable.exec("mpc playlist "+ editPlaylist.chosenPlaylist)
                            roasterEdit .visible = true
                            break
                        case 1:
                            filePick.open();
                            break;
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

            model : playlistRoot.playlists

            Component.onCompleted: {
                popup.height = 120
            }

            background: Image{
                anchors.fill: parent
                source: "../images/checkbox.png"
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
        Button {
            width: 20
            height: 20
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 15
            anchors.rightMargin: 32.5

            graphic: "enter"

            onClick: {
                playlistRoot.settingsPage = 1
                parent.removalIndices.sort((a,b) => b-a)
                playlistEdited(parent.chosenPlaylist, parent.playlistRename, parent.newAlbumArt, parent.songsAdd, parent.removalIndices)
                parent.reset()
            }
        }

        // Delete Playlist
        Button {
            width: 20
            height: 20
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 15
            anchors.rightMargin: 7.5

            graphic: "delete"

            onClick: {
                playlistRoot.settingsPage = 1
                playlistDelete(parent.chosenPlaylist)
                parent.reset()
            }
        }
    }


    // MPC Directory Edit
    Image {
        id: mpcEdit
        anchors.fill: parent

        z:2
        source: "../images/settings_bg_4.png"
        visible: playlistRoot.settingsPage === 4 ? 1 : 0

        // This needs more work to be secure
        C.Label {
            text: "⚠️ Make sure you know what you are Doing"
            font.bold: true
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
                plasmoid.configuration.musicPath = text
                playlistRoot.settingsPage = 1
            }
        }
    }

}
