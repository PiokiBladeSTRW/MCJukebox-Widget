import QtQuick
import org.kde.plasma.components 3.0 as PC
import QtQuick.Dialogs

import "../code/binarySearch.js" as BinSearch

Image {
    id: root

    property string homeDirPath
    property int settingsPage: 0        // 0: Disabled, 1: Selection, 2: Adding Playlist, 3: EditPlaylist, 4: MPC Modification
    property list<string> playlists

    signal menuForceState(bool state)


    source: "../images/amethyst_block"
    fillMode: Image.Tile


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


    // ==========================================
    // COMMANDS HANDLER
    // ==========================================

    // Update Playlists List
    function playlistsListUpdate(output) {
        root.playlists = output.trim().split("\n")
        console.log(root.playlists)
    }

    // Set HomeDirectory [and Maybe musicPath]
    function handleHomeDir(output) {
        root.homeDirPath = "/home/"+ output.trim()

        if( !plasmoid.configuration.musicPath) {
            plasmoid.configuration.musicPath = root.homeDirPath + "/Music/"
        }
    }

    // Call the above mentioned functions upon Boot
    Component.onCompleted: {
        bash.playlistUpdateCallback = playlistsListUpdate;
        bash.playlistsListUpdate(playlistsListUpdate)
        bash.homeRegister(handleHomeDir)
    }



    // ==========================================
    // MAIN PLAYLIST MENU
    // ==========================================

    // Search Bar
    VisualButton {
        id: searchButton
        height: 25 * Singleton.scaleFactor
        width: 25 * Singleton.scaleFactor

        anchors.top: parent.top
        anchors.topMargin: 10 * Singleton.scaleFactor
        anchors.left: parent.left
        anchors.leftMargin: 30 * Singleton.scaleFactor

        property list<string> searchResults
        property list<string> searchResultsDir

        graphic: "playlistMenu_icons/search"

        onClick: {
            searchBar.visible = true
            searchBar.width = 80 * Singleton.scaleFactor
            root.menuForceState(true)
        }

        // Search Field
        PC.TextField {
            id: searchBar
            height: 25 * Singleton.scaleFactor
            width: 0

            visible: false
            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.Linear
                }
            }

            // Slow Down Searches to Save CPU Cycle
            Timer {
                id: debounce
                interval: 300
                onTriggered: {
                    // The Second Argument Boolean is whether we are searching Title or File
                    bash.search(parent.text, true, function(output) {
                        searchButton.searchResults = output.trim().split("\n")
                    })

                    bash.search(parent.text, false, function(output) {
                        searchButton.searchResultsDir = output.trim().split("\n")
                    })
                }
            }

            onTextChanged: {
                debounce.start()
            }
        }

        // Search Results
        Rectangle {
            y: 25 * Singleton.scaleFactor
            width: 80 * Singleton.scaleFactor
            height: 60 * Singleton.scaleFactor
            color: "black"

            visible: searchBar.visible

            PC.ScrollView {
                anchors.fill: parent
                clip:true

                ListView {
                    height: 60 * Singleton.scaleFactor
                    width: parent.width
                    model: searchButton.searchResults
                    spacing: 2

                    bottomMargin: 10

                    // Text with onClick function
                    delegate: PC.ItemDelegate {
                        width: 70 * Singleton.scaleFactor
                        height: 15 * Singleton.scaleFactor
                        text: modelData

                        contentItem: Text {
                            text: modelData
                            color: "white"
                            elide: Text.ElideRight
                        }

                        bottomPadding: 0
                        topPadding: 0

                        onClicked: {
                            bash.tempSong(searchButton.searchResultsDir[index])
                            searchBar.width= 0
                            searchBarOff.start()
                        }
                    }
                }
            }
        }

        // Exit from Search Bar
        MouseArea {
            z: -1
            width: 500 * Singleton.scaleFactor
            height: 150 * Singleton.scaleFactor
            x:-30 * Singleton.scaleFactor
            y:-25 * Singleton.scaleFactor

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
                root.menuForceState(false)
                searchBar.visible = false
            }
        }
    }


    // Temporary Song File Play
    VisualButton {
        height: 25 * Singleton.scaleFactor
        width: 25 * Singleton.scaleFactor
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15 * Singleton.scaleFactor
        anchors.rightMargin: 2 * Singleton.scaleFactor

        graphic: "playlistMenu_icons/folder_pick"

        visible: settingsPage === 0

        onClick: {
            root.menuForceState(true)
            folderPick.open()
        }
    }

    // Temporary Song Folder Play
    VisualButton {
        height: 25 * Singleton.scaleFactor
        width: 25 * Singleton.scaleFactor
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15 * Singleton.scaleFactor
        anchors.rightMargin: 35 * Singleton.scaleFactor

        graphic: "playlistMenu_icons/music_pick"

        visible: settingsPage === 0

        onClick: {
            root.menuForceState(true)
            filePick.artMode = 1
            filePick.open()
        }
    }


    // Playlists Choice Menu
    Flickable {
        id: scrollContainer
        width: 195 * Singleton.scaleFactor
        height: 150 * Singleton.scaleFactor

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 15 * Singleton.scaleFactor

        z: 1
        visible: settingsPage === 0

        clip: true
        contentWidth: playlistGrid.width
        contentHeight: playlistGrid.height

        // Ensure Menu Stays Open
        HoverHandler {
            id: hoverer
            onHoveredChanged: {
                if(hovered) {
                    root.menuForceState(true)
                } else {
                    root.menuForceState(false)
                }
            }
        }

        PC.ScrollBar.vertical: PC.ScrollBar {
            visible: true
            policy: PC.ScrollBar.AsNeeded
        }

        // Playlists List
        Grid {
            id: playlistGrid
            columns: 3
            spacing: 10

            topPadding: 20
            bottomPadding: 20

            Repeater {
                id: playlistGridRepeater
                model: root.playlists

                VisualButton {
                    height: 50 * Singleton.scaleFactor
                    width: 50 * Singleton.scaleFactor

                    // Try Set Album art from Cache, if Errors & properly initialized, Fallsback to Default
                    source: "file://"+  root.homeDirPath + "/.cache/jukebox_covers/"+modelData+".png"
                    onStatusChanged: {
                        if(status === 3 && root.homeDirPath) {
                            source= "../images/note_block.png"
                        }
                    }

                    opacity: index === plasmoid.configuration.playlistIndex ? 1 : 0.6
                    active: settingsPage === 0

                    // Name of Playlist upon Hover
                    detectHover: true
                    PC.ToolTip.visible: hovered
                    PC.ToolTip.text: modelData

                    onClick: {
                        plasmoid.configuration.playlistIndex = index
                        bash.chosenPlaylist(modelData);
                    }
                }
            }
        }
    }


    // ==========================================
    // SETTINGS
    // ==========================================

    // Settings Toggle
    VisualButton {
        id: settingsToggle

        width: 30 * Singleton.scaleFactor
        height: 30 * Singleton.scaleFactor
        anchors.top: root.top
        anchors.right: root.right
        anchors.topMargin: 15 * Singleton.scaleFactor
        anchors.rightMargin: 15 * Singleton.scaleFactor

        graphic: root.settingsPage === 0 ? "playlistMenu_icons/settings" : "playlistMenu_icons/back"

        visible: true

        z: 3

        onClick: {
            switch(root.settingsPage) {

                // From Settings Selction
                case 1:
                    root.settingsPage = 0;
                    menuForceState(false)
                    break

                // Anywhere Else
                default:
                    root.settingsPage = 1;
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

        source: "../images/background/settings_bg_1.png"

        opacity: root.settingsPage === 1 ? 1 : 0
        Behavior on opacity { FadeAnim{} }
        visible: opacity > 0

        // Settings Page
        Column {
            anchors.centerIn: parent
            spacing: 5

            Repeater {
                model: ["Add Playlist", "Edit Playlist", "MPC Directory Config"]

                LabelledButton {
                    text: modelData

                    onClick: {
                        // Index + 2 to Account for Page 0 and index starting at 0
                        root.settingsPage = index + 2
                    }
                }
            }
        }

    }

    // Settings Menu Loader
    Loader {
        id: settingMenuLoader
        anchors.fill: parent

        source: ""

        function setSource() {
            switch(root.settingsPage) {
                case 2: settingMenuLoader.source = "addPlaylist.qml"; break;
                case 3: settingMenuLoader.source =  "editPlaylist.qml"; break;
                case 4: settingMenuLoader.source =  "mpcConfig.qml"; break;
                default: settingMenuLoader.source =  ""
            }
        }

        onLoaded: {
            settingMenuLoader.item.changeOpacity(1)

            switch(root.settingsPage) {
                case 3:
                    item.playlists = root.playlists
                    break
            }
        }

        // Since albumArt isn't linked to MPC, the changes aren't detected, hence Manual timer to ensure Command runs first
        Timer {
            id: albumArtUpdate
            interval: 700

            onTriggered: {
                playlistGridRepeater.model = []
                playlistGridRepeater.model = root.playlists
            }
        }

        // Allow Elements to Fade Out
        Connections {
            target: root

            onSettingsPageChanged() {

                if(settingMenuLoader.source != "") {
                    settingMenuLoader.item.changeOpacity(0)
                } else {
                    settingMenuLoader.setSource()
                }
            }
        }

        // Signals Connections
        Connections {
            target: settingMenuLoader.item
            ignoreUnknownSignals: true

            function onFadeOutComplete() {
                settingMenuLoader.setSource()
            }

            function onSettingsPageChanged(newPage) {
                root.settingsPage = newPage
            }

            function onFolderPickOpen() {
                folderPick.open()
            }

            function onFilePickOpen(artMode) {
                filePick.artMode = artMode
                filePick.open()
            }

            function onPlaylistAdded(playlistName, playlistFolders, albumArt) {

                // Ensure playlist of Name doesn't exist'
                if(BinSearch.existsInArray(playlistName, root.playlists)) {
                    warnPopup.dirWarn = false
                    warnPopup.open()
                    return
                }

                bash.addPlaylist(playlistName, playlistFolders, albumArt)
            }

            function onPlaylistEdited(chosenPlaylist, playlistRename, newAlbumArt, songsAdded, removalIndices) {
                // Ensure playlist of Name doesn't exist
                if(BinSearch.existsInArray(playlistRename, root.playlists)) {
                    warnPopup.dirWarn = false
                    warnPopup.open()
                    return
                }

                bash.editPlaylist(chosenPlaylist, playlistRename, newAlbumArt, songsAdded, removalIndices)

                // Force grid model Update to update Album Arts
                if(newAlbumArt) {
                    albumArtUpdate.start()
                }
            }

        }
    }


    // ==========================================
    // UTILITIES    [Popup, FolderDialog, FileDialog]
    // ==========================================

    // POPUP: Wrong Directory File/Folder Picked Warning
    PC.Popup {
        id: warnPopup
        anchors.centerIn: parent
        width: 260 * Singleton.scaleFactor
        height: 140 * Singleton.scaleFactor
        modal: true
        focus: true

        property bool dirWarn: true      // true: Directory Warning / false: Duplicate Name Warning

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
                text: parent.dirWarn ? "⚠️ WARNING" : "🚫 ERROR"
                font.bold: true
                color: "red"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PC.Label {
                text: parent.dirWarn ? "Playlist/Music Directories should be in\n" : "A Playlist by that name Exists Already"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            PC.Label {
                text: parent.dirWarn ? plasmoid.configuration.musicPath : ""
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }


    // Folder Picker [Music Directories]
    FolderDialog {
        id : folderPick
        title: "Choose Music Folder"

        property list<string> supportedFormats: ["flac", "ogg", "mp3", "opus", "wav", "aac"]

        // When EditPlaylist Adds a Folder to Roaster, Arrange the obtained list of Songs in given Directory
        function inputSongsInDir(output) {

            // Output contains a list of Files in Chosen Folder
            let files = output.trim().split("\n")
            let songs = []

            // Add the File to the songs list if of Suitable file Format and sorts
            for (let i =0 ; i< files.length ; i++ ) {
                let splitFile = String(files[i]).trim().split(".")

                //Check for valid file format
                if( supportedFormats.includes( splitFile[splitFile.length - 1] )){
                    songs.push(files[i])
                }
            }
            songs.sort()

            // Obtain the next Index position for new Songs in Lookup hashmap and Add the songs to Lookup
            let baseVal = Object.keys(settingMenuLoader.item.songsLookup).length + 1
            for (let i = 0; i < songs.length ; i++){
                settingMenuLoader.item.songsLookup[songs[i]] = baseVal + i
            }

            settingMenuLoader.item.songsList.push(...songs)
        }


        onAccepted: {
            let path = folderPick.selectedFolder.toString().replace("file://", "")

            // Ensure the Correct Music Directory
            if(! path.startsWith(plasmoid.configuration.musicPath)) {
                warnPopup.dirWarn = true
                warnPopup.open()
                return
            }
            path = path.replace(plasmoid.configuration.musicPath, "")

            switch(root.settingsPage) {
                case 0:
                    root.menuForceState(false)
                    bash.tempSong(path)
                    break
                case 2:
                    settingMenuLoader.item.playlistFolders.push(path)
                    break
                case 3:
                    settingMenuLoader.item.songsAdd.push(path)
                    bash.obtainSongsDirectory(path, folderPick.inputSongsInDir)
                    break
            }

            folderPick.close()
        }

        onRejected: {
            folderPick.close()
            if(root.settingsPage === 0) {
                root.menuForceState(false)
            }
        }
    }

    // File Picker [Album Art & Music]
    FileDialog {
        id: filePick

        property bool artMode: true      // true: Album Art ; false : Music

        fileMode: FileDialog.OpenFile
        title: artMode ? "Choose Album Art " : "Choose Music File"
        nameFilters: artMode ? ["Image File (*.png *.jpg *.jpeg *.webp)"] : ["Music File (*.flac *.ogg *.mp3 *.opus *.wav *.aac)"]

        onAccepted: {
            let path = filePick.selectedFile.toString().replace("file://", "")

            // Album Art
            if(artMode) {
                switch(root.settingsPage) {
                    case 2:
                        settingMenuLoader.item.albumArt = path
                        break
                    case 3:
                        settingMenuLoader.item.newAlbumArt = path
                        break
                    default: break
                }

                // Music
            } else {

                // Ensure Correct Music Directory
                if(! path.startsWith(plasmoid.configuration.musicPath)) {
                    warnPopup.dirWarn = true
                    warnPopup.open()
                    return
                }
                path = path.replace(plasmoid.configuration.musicPath, "")

                switch(root.settingsPage) {
                    case 0:
                        root.menuForceState(false)
                        bash.tempSong(path)
                        break

                    case 3:
                        // Add the Song to the Editable Roaster, to the SongsAddition List for MPC and for Index Lookup
                        let title = path.split("/")
                        settingMenuLoader.item.songsLookup[title[title.length - 1]] = Object.keys(settingMenuLoader.item.songsLookup).length + 1
                        settingMenuLoader.item.songsList.push(title[title.length - 1])
                        settingMenuLoader.item.songsAdd.push(path)
                        break
                    default: break
                }

            }

        }

        onRejected:{
            filePick.close()
            if(root.settingsPage === 0) {
                root.menuForceState(false)
            }
        }

    }

}





