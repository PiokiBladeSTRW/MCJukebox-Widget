import QtQuick
import org.kde.plasma.plasma5support 2.0 as PS
import org.kde.plasma.components 3.0 as PC
import QtQuick.Dialogs

Image {
    id: playlistRoot
    anchors.fill: parent


    property bool visibleCondn          // Boolean Assigned by ROOT

    property string homeDirPath
    property int settingsPage: 0        // 0: Disabled, 1: Selection, 2: Adding Playlist, 3: EditPlaylist, 4: MPC Modification
    property list<string> playlists

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

        property var callbackRegistry: ({})
        property int callbackUniqueID: 0

        onNewData: (sourceName, data) =>{

            // Fetch Latest Playlist Lists
            if(sourceName === "mpc lsplaylists") {
                playlistRoot.playlists = data["stdout"].trim().split("\n")

                // Fetch default Music Directory
            } else if (sourceName === "ls /home") {
                playlistRoot.homeDirPath= "/home/"+ data["stdout"].trim()

                if(plasmoid.configuration.musicPath === "" ){
                    plasmoid.configuration.musicPath = playlistRoot.homeDirPath + "/Music/"
                }


                // Siblings Called Command Execution
            } else if(callbackRegistry[sourceName]) {
                var callbackFunc = callbackRegistry[sourceName];

                callbackFunc(data["stdout"]);
                delete callbackRegistry[sourceName]
            }

            disconnectSource(sourceName)
        }

        function exec(cmd, callback) {
            if(callback) {
                let uniqueCommand = cmd + " #" + callbackUniqueID
                callbackUniqueID += 1

                callbackRegistry[uniqueCommand] = callback

                connectSource(uniqueCommand)
            } else {
                connectSource(cmd)
            }

        }

        Component.onCompleted: {
            // Fetch Latest playlists List
            connectSource("mpc lsplaylists")
            connectSource("ls /home")
        }
    }

    // Wrong Directory File/Folder Picked Warning
    PC.Popup {
        id: warnPopup
        anchors.centerIn: parent
        width: 260
        height: 140
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
                text: "Playlist/Music Directories should be in\n"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            PC.Label {
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

            // Ensure the Correct Music Directory
            if(! path.startsWith(plasmoid.configuration.musicPath)) {
                warnPopup.open()
                return
            }
            path = path.replace(plasmoid.configuration.musicPath, "")

            switch(playlistRoot.settingsPage) {
                case 0:
                    playlistRoot.menuForceState(false)
                    playlistRoot.tempSong(path)
                    break
                case 2:
                    settingMenus.item.playlistFolders.push(path)
                    break
                case 3:
                    settingMenus.item.songsAdd.push(path)

                    // Obtain songs in the Chosen Directory
                    executable.exec('ls -p "'+ plasmoid.configuration.musicPath + path +'" | grep -v /', function songsInDir(output) {

                        // Output contains a list of Songs in Chosen Folder
                        let files = output.trim().split("\n")
                        let songs = []

                        for (let i =0 ; i< files.length ; i++ ) {
                            let splitFile = String(files[i]).trim().split(".")

                            //Check for valid file format
                            if( playlistRoot.supportedFormats.includes( splitFile[splitFile.length - 1] )){
                                songs.push(files[i])
                            }
                        }
                        songs.sort()

                        // Obtain the next Index position for new Songs in Lookup hashmap
                        let baseVal = Object.keys(settingMenus.item.songsLookup).length + 1
                        for (let i = 0; i < songs.length ; i++){
                            settingMenus.item.songsLookup[songs[i]] = baseVal + i
                        }

                        settingMenus.item.songsList.push(...songs)})
                    break
            }

            folderPick.close()
        }

        onRejected: {
            folderPick.close()
            if(playlistRoot.settingsPage === 0) {
                playlistRoot.menuForceState(false)
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
                switch(playlistRoot.settingsPage) {
                    case 2:
                        settingMenus.item.albumArt = path
                        break
                    case 3:
                        settingMenus.item.newAlbumArt = path
                        break
                    default: break
                }

            // Music
            } else {

                // Ensure Correct Music Directory
                if(! path.startsWith(plasmoid.configuration.musicPath)) {
                    folderWarning.open()
                    return
                }
                path = path.replace(plasmoid.configuration.musicPath, "")

                switch(playlistRoot.settingsPage) {
                    case 0:
                        playlistRoot.menuForceState(false)
                        playlistRoot.tempSong(path)
                        break

                    case 3:
                        // Add the Song to the Editable Roaster, to the SongsAddition List for MPC and for Index Lookup
                        let title = path.split("/")
                        settingMenus.item.songsLookup[title[title.length - 1]] = Object.keys(settingMenus.item.songsLookup).length + 1
                        settingMenus.item.songsList.push(title[title.length - 1])
                        settingMenus.item.songsAdd.push(path)
                        break
                    default: break
                }

            }

        }

        onRejected:{
            filePick.close()
            if(playlistRoot.settingsPage === 0) {
                playlistRoot.menuForceState(false)
            }
        }

    }

    // -----------------------------
    // Main Display
    // -----------------------------

    // Search Bar
    VisualButton {
        id: searchButton
        height: 25
        width: 25
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 30

        property list<string> searchResults
        property list<string> searchResultsDir

        graphic: "playlistMenu_icons/search"

        onClick: {
            searchBar.visible = true
            searchBar.width = 80
            playlistRoot.menuForceState(true)
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

            // Slow Down Searches to Save CPU Cycle
            Timer {
                id: debounce
                interval: 300
                onTriggered: {
                    executable.exec("mpc search -f '%title%' title "+ parent.text, function handleSearchResults(output) {
                        searchButton.searchResults = output.trim().split("\n")
                    })

                    executable.exec("mpc search -f '%file%' title "+ parent.text, function handleSearchResults(output) {
                        searchButton.searchResultsDir = output.trim().split("\n")
                    })
                }
            }


            onTextChanged: {
                debounce.start()
            }
        }

        Rectangle {
            y: 25
            width: 80
            height: 60
            color: "black"

            visible: searchBar.visible

            PC.ScrollView {
                anchors.fill: parent
                clip:true

                ListView {
                    height: 60
                    width: parent.width
                    model: searchButton.searchResults
                    spacing: 2

                    bottomMargin: 10

                    // Text with onClick function
                    delegate: PC.ItemDelegate {
                        width: 70
                        height: 15
                        text: modelData

                        bottomPadding: 0

                        onClicked: {
                            tempSong(searchButton.searchResultsDir[index])
                            searchBar.width= 0
                            searchBarOff.start()
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
                playlistRoot.menuForceState(false)
                searchBar.visible = false
            }
        }
    }

    // Temporary Songs Options
    VisualButton {
        height: 25
        width: 25
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 2

        graphic: "playlistMenu_icons/folder_pick"

        visible: settingsPage === 0 && visibleCondn

        onClick: {
            playlistRoot.menuForceState(true)
            folderPick.open()
        }
    }

    VisualButton {
        height: 25
        width: 25
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 15
        anchors.rightMargin: 35

        graphic: "playlistMenu_icons/music_pick"

        visible: settingsPage === 0 && visibleCondn

        onClick: {
            playlistRoot.menuForceState(true)
            filePick.artMode = 1
            filePick.open()
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

        clip: true
        contentWidth: playlistGrid.width
        contentHeight: playlistGrid.height

        // Ensure Menu Stays Open
        HoverHandler {
            id: hoverer
            onHoveredChanged: {
                if(hovered) {
                    playlistRoot.menuForceState(true)
                } else {
                    playlistRoot.menuForceState(false)
                }
            }
        }

        PC.ScrollBar.vertical: PC.ScrollBar {
            visible: playlistRoot.visibleCondn
            policy: PC.ScrollBar.AsNeeded
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

                VisualButton {
                    height: 50
                    width: 50

                    // Try Set Album art from Cache, if Errors & properly initialized, Fallsback to Default
                    source: "file://"+  playlistRoot.homeDirPath + "/.cache/jukebox_covers/"+modelData+".png"
                    onStatusChanged: {
                        if(status === 3 && playlistRoot.homeDirPath) {
                            source= "../images/note_block.png"
                        }
                    }

                    opacity: index === plasmoid.configuration.playlistIndex ? 1 : 0.6
                    active: visibleCondn && settingsPage === 0

                    // Name of Playlist upon Hover
                    detectHover: true
                    PC.ToolTip.visible: hovered
                    PC.ToolTip.text: modelData

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
    VisualButton {
        id: settingsToggle

        width: 30
        height: 30
        anchors.top: playlistRoot.top
        anchors.right: playlistRoot.right
        anchors.topMargin: 15
        anchors.rightMargin: 15

        graphic: playlistRoot.settingsPage === 0 ? "playlistMenu_icons/settings" : "playlistMenu_icons/back"

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

        source: "../images/background/settings_bg_1.png"

        property list<string> displayTexts: ["Add Playlist", "Edit Playlist", "MPC Directory Config"]

        visible: playlistRoot.settingsPage === 1
        opacity: visible

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.Linear
            }
        }

        // Settings Page Selection
        Repeater {
            model: [-30, 0, 30]

            LabelledButton {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: modelData

                text: settingsMenu.displayTexts[index]

                onClick: {
                    // Index + 2 to Account for Page 0 and index starting at 0
                    playlistRoot.settingsPage = index + 2
                }
            }
        }
    }

    Loader {
        id: settingMenus
        anchors.fill: parent

        source: {
            switch(playlistRoot.settingsPage) {
                case 2: return "addPlaylist.qml"; break;
                case 3: return "editPlaylist.qml"; break;
                case 4: return "mpcConfig.qml"; break;
                default: return ""
            }
        }

        onLoaded: {
            switch(playlistRoot.settingsPage) {
                case 3:
                    item.playlists = playlistRoot.playlists
                    break
            }
        }

        Connections {
            target: settingMenus.item
            ignoreUnknownSignals: true

            function onSettingsPageChanged(newPage) {
                console.log("BOOM")
                playlistRoot.settingsPage = newPage
            }

            function onFolderPickOpen() {
                folderPick.open()
            }

            function onFilePickOpen(artMode) {
                filePick.artMode = artMode
                filePick.open()
            }

            function onPlaylistAdded(playlistName, playlistFolders, albumArt) {
                console.log('add')
                playlistRoot.playlistAdded(playlistName, playlistFolders, albumArt)
                executable.exec("mpc lsplaylists")
            }

            function onPlaylistEdited(chosenPlaylist, playlistRename, newAlbumArt, songsAdded, removalIndices) {
                console.log('edit')
                playlistRoot.playlistEdited(chosenPlaylist, playlistRename, newAlbumArt, songsAdded, removalIndices)
                executable.exec("mpc lsplaylists")
            }

            function onPlaylistDelete(chosenPlaylist) {
                console.log("del")
                playlistRoot.playlistDelete(chosenPlaylist)
                executable.exec("mpc lsplaylists")
            }
        }
    }

}





