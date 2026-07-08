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
            connectSource(cmd)

            if(callback) {
                callbackRegistry[cmd] = callback
            }
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
                    addPlaylist.playlistFolders.push(path)
                    break
                case 3:
                    editPlaylist.songsAdd.push(path)

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
                        let baseVal = Object.keys(editPlaylist.songsLookup).length + 1
                        for (let i = 0; i < songs.length ; i++){
                            editPlaylist.songsLookup[songs[i]] = baseVal + i
                        }

                        editPlaylist.songsList.push(...songs)})
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
                        addPlaylist.albumArt = path
                        break
                    case 3:
                        editPlaylist.newAlbumArt = path
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
                        editPlaylist.songsLookup[title[title.length - 1]] = Object.keys(editPlaylist.songsLookup).length + 1
                        editPlaylist.songsList.push(title[title.length - 1])
                        editPlaylist.songsAdd.push(path)
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
    Button {
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

            C.ScrollView {
                anchors.fill: parent
                clip:true

                ListView {
                    height: 60
                    width: parent.width
                    model: searchButton.searchResults
                    spacing: 2

                    bottomMargin: 10

                    // Text with onClick function
                    delegate: C.ItemDelegate {
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
    Button {
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

    Button {
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
            filePick.mode = 1
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
                    C.ToolTip.visible: hovered
                    C.ToolTip.text: modelData

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

            Button {
                width: 250
                height: 25

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: modelData

                graphic: "button"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: settingsMenu.displayTexts[index]
                    font.family: "Minecraft"
                    renderType: Text.NativeRendering
                    font.pixelSize: 14

                    color: "white"
                }

                onClick: {
                    // Index + 2 to Account for Page 0 and index starting at 0
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

        source: "../images/background/settings_bg_2.png"

        property string playlistName
        property string albumArt

        property list<string> playlistFolders
        property list<string> displayTexts: ["Add Songs", "Add Album Art [Optional]"]

        visible: playlistRoot.settingsPage === 2
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.Linear
            }
        }


        // Add Songs and Album Art Buttons
        Repeater {
            model: [0, 30]

            Button {
                width: 250
                height: 25

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: modelData

                graphic: "button"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: addPlaylist.displayTexts[index]
                    font.family: "Minecraft"
                    renderType: Text.NativeRendering
                    font.pixelSize: 14

                    color: "white"
                }

                onClick: {
                    switch(index) {
                        case 0:
                            folderPick.open()
                            break;
                        case 1:
                            filePick.mode = 0
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

            graphic: "playlistMenu_icons/enter"

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
        source: "../images/background/settings_bg_3.png"
        visible: playlistRoot.settingsPage === 3
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.Linear
            }
        }

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

            property list<string> displayGraphics: ["playlistMenu_icons/folder_pick", "playlistMenu_icons/music_pick", "playlistMenu_icons/enter"]

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
                                filePick.mode = 1
                                filePick.open();
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
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: editPlaylist.displayTexts[index]
                    font.family: "Minecraft"
                    renderType: Text.NativeRendering
                    font.pixelSize: 14

                    color: "white"
                }

                onClick: {
                    switch(index) {
                        case 0:
                            executable.exec("mpc playlist "+ editPlaylist.chosenPlaylist, function obtainSongsList(output) {
                                // Output Contans a List of Songs in the Given Playlist
                                let songsList = output.trim().split("\n")
                                let songsHashMap = {}

                                for (let i = 0 ; i < songsList.length ; i++) {
                                    songsHashMap[String(songsList[i])] = i + 1
                                }

                                editPlaylist.songsList = songsList
                                editPlaylist.songsLookup = songsHashMap
                            })

                            roasterEdit .visible = true
                            break
                        case 1:
                            filePick.mode = 0
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
        Button {
            width: 20
            height: 20
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 15
            anchors.rightMargin: 32.5

            graphic: "playlistMenu_icons/enter"

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

            graphic: "playlistMenu_icons/delete"

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
        source: "../images/background/settings_bg_4.png"
        visible: playlistRoot.settingsPage === 4 ? 1 : 0
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.Linear
            }
        }

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
