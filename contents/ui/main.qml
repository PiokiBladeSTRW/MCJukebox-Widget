// Imports
import QtQuick
import QtQuick.Effects
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support 2.0 as PS


// Main Component
PlasmoidItem {
    id: root
    height: 150
    width: 500
    clip: true

    property real elapsedTime
    property string trackTitle
    property string trackArtist

    property bool menuOpen: false
    property bool playlistMenuOpen : false
    property bool forceMenuOpen: false

    onMenuOpenChanged : {
        if(menuOpen === false && playlistMenuOpen) {
            playlistMenuOpen = false
        }
    }


    // Music Player
    PS.DataSource {
        id: player
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) =>{
            if(sourceName === "mpc status"){
                let x = data["stdout"].split("\n")

                if(!x[0].startsWith("volume")) {
                    let timeMatch = x[1].match(/(\d+:\d+)\/(\d+:\d+)/);

                    let current_time = timeMatch[1].split(":")
                    let total_time = timeMatch[2].split(":")

                    let current_sec = parseInt(current_time[0]*60) + parseInt(current_time[1])
                    let total_sec = parseInt(total_time[0]*60 + parseInt(total_time[1]))

                    elapsedTime = current_sec/total_sec
                }
            } else if (sourceName.startsWith("mpc -f")) {
                let x = data["stdout"].split("\x1f")

                root.trackArtist = x[0]

                if(x[1]) {
                    root.trackTitle = x[1]
                } else {
                    root.trackTitle = x[2]
                }
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        Component.onCompleted: {
            exec("mkdir ~/.cache/jukebox_covers")
            exec("mpc update")
        }
    }

    // Sound Effect
    SoundEffect {
        id: clickSound
        source: "file:///home/pioki/P-PF/Leftover/PlasmaDev/com.pioki.jukebox/contents/sounds/insert.wav"
        volume: 0.3
    }

    // Status Timer
    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            player.exec("mpc status")
            player.exec("mpc -f '%artist%\x1f%title%\x1f%file%' current")
        }
    }

    // Note Block Particles
    Item {
        id: note_block_particle

        visible: !root.menuOpen && plasmoid.configuration.playStatus ? true : false

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 100
        anchors.verticalCenter: parent.verticalCenter

        property list<color> colors: ["lime", "yellow", "red", "magenta", "blue"]
        property int def_margin: 75
        property int top_margin: 0
        property int anim_index : 0
        property int color_index: 0

        Timer {
            id: note_timer
            interval: 700
            repeat: true
            running: plasmoid.configuration.playStatus

            onTriggered: {

                parent.anim_index += 1;
                if(parent.anim_index === 3) {
                    parent.anim_index = 0;
                }

                if(parent.color_index <= 3) {
                    parent.color_index += 1
                } else {
                    parent.color_index = 0
                }
            }
        }

        Image {
            id: note1
            property int index: 0
            source: "../images/note.png"

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -32

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: index === parent.anim_index ? parent.top_margin : parent.def_margin

            visible: index === parent.anim_index ? true : false

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: parent.colors[parent.color_index]
            }

        }
        Image {
            id: note2
            property int index: 1
            source: "../images/note.png"

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 0

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: index === parent.anim_index ? parent.top_margin : parent.def_margin

            visible: index === parent.anim_index ? true : false

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: parent.colors[parent.color_index]
            }
        }
        Image {
            id: note3
            property int index: 2
            source: "../images/note.png"

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 32

            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: index === parent.anim_index ? parent.top_margin : parent.def_margin

            visible: index === parent.anim_index ? true : false

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: parent.colors[parent.color_index]
            }
        }


    }

    // Menu
    Image {
        id: menu
        width: 400
        height: parent.height
        fillMode: Image.Stretch

        property string sourceFile : "out"
        property bool playBG: false
        property bool menuCloseTimed: false

        source: "../images/background/" + sourceFile + ".png"

        Timer {
            id: slowdown
            interval: 300

            onTriggered: {
                if(plasmoid.configuration.playStatus) {
                    parent.playBG = true
                } else {
                    parent.sourceFile = "out"
                }
            }
        }

        Timer {
            id: menuCloseTimer
            interval: 600
            running: parent.menuCloseTimed

            onTriggered: {
                parent.menuCloseTimed = false
                root.menuOpen = false
                slowdown.start()
            }
        }

        Timer {
            id: parrotAnim
            interval: 50
            running: parent.playBG
            repeat: true

            property int anim_index: 0

            onTriggered: {
                if(anim_index<=10) {
                    anim_index += 1
                } else {
                    anim_index = 0
                }

                parent.sourceFile= "playing/" + anim_index
            }
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                if( !root.menuOpen ) {
                    root.menuOpen = true
                    parent.playBG = false
                    parent.sourceFile = "menu"
                }
            }

            onEntered: {
                if( parent.menuCloseTimed ) {
                    parent.menuCloseTimed = false
                } else if( !parent.playBG ) {
                    parent.sourceFile = "out_highlight"
                }
            }

            onExited: {
                if( root.menuOpen && !root.forceMenuOpen) {
                    parent.menuCloseTimed = true
                } else if( !parent.playBG) {
                    parent.sourceFile = "out"
                }
            }
        }


        anchors.right: parent.right
        anchors.rightMargin: root.menuOpen ? 0 : -340

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: root.menuOpen ? Easing.InCubic : Easing.OutBack
            }
        }

        Item {
            id: textContainer
            width: 300 // The visible viewport window width
            height: 20
            clip: true

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: -30

            visible: root.menuOpen? 1 : 0
            opacity:!root.playlistMenuOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            Text {
                id: scrollingText
                text: root.trackTitle

                font.family: "Minecraft"
                renderType: Text.NativeRendering
                font.pixelSize: 16

                anchors.horizontalCenter: scrollingText.width <= textContainer.width ? parent.horizontalCenter : undefined

                // implicitWidth is the Default width of text/image if not constraint by width
                width: implicitWidth

                SequentialAnimation on x {
                    running: scrollingText.width > textContainer.width
                    loops: Animation.Infinite

                    PauseAnimation {duration: 1000 }

                    NumberAnimation {
                        from: 10
                        to: - (scrollingText.width - textContainer.width) - 10
                        duration: 4000
                    }

                    PauseAnimation {duration: 1000}

                    NumberAnimation {
                        from: - (scrollingText.width - textContainer.width) - 10
                        to: 10
                        duration: 4000
                    }
                }
            }
        }


        // Artist Title
        Text {
            id: title_text
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: -5

            font.family: "Minecraft"
            renderType: Text.NativeRendering
            font.pixelSize: 16

            visible: root.menuOpen? 1 : 0
            opacity:!root.playlistMenuOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            text: root.trackArtist
        }

        // Playlist Choice Menu Toggle
        Button {
            id: playlist_menu_toggle

            height: 100
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            source: "../images/playlist.png"

            visible: root.menuOpen ? 1 : 0
            opacity: root.menuOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            onClick: root.playlistMenuOpen = !root.playlistMenuOpen
        }


        // Playlist Menu
        PlaylistMenu {
            visibleCondn: root.playlistMenuOpen

            onPlaylistChosen: (playlist) => {
                player.exec("mpc clear")
                player.exec("mpc load "+ playlist)
                player.exec("mpc toggle")
                plasmoid.configuration.playStatus =  true
            }

            onMenuForced: (state) => {
                root.forceMenuOpen = state
            }

            onTempSong: (dir) => {
                player.exec("mpc clear")
                player.exec("mpc add '"+ dir +"'")
                player.exec("mpc toggle")
                console.log(dir)
            }

            onPlaylistAdded: (title, playlistFolders, albumArt) => {
                player.exec("mpc update")
                player.exec("mpc save "+ title)
                player.exec("mpc clearplaylist "+ title)
                player.exec("cp "+ albumArt + " ~/.cache/jukebox_covers/"+title+".png")

                for (let i = 0; i <= playlistFolders.length; i++) {
                    let folderPath = '"' + playlistFolders[i] + '"';
                    player.exec("mpc addplaylist "+ title + " " + folderPath);
                }

                execute("mpc lsplaylists")
            }

            onPlaylistEdited: (playlist, newName, albumArt, songsAdded, songsRemoval) => {
                if(newName) {
                    player.exec("mpc renplaylist "+ playlist +" "+ newName)
                } else {
                    newName = playlist
                }

                if(albumArt) {
                    player.exec("rm ~/.cache/jukebox_covers/"+playlist+".png")
                    player.exec("cp '"+ albumArt + "' ~/.cache/jukebox_covers/"+newName+".png")
                }

                for (let i = 0; i<songsAdded.length; i++) {
                    player.exec("mpc addplaylist "+ newName+ " '"+ songsAdded[i] +"'")
                }

                for (let i =0; i<songsRemoval.length ; i++) {
                    player.exec("mpc delplaylist "+ newName+" "+ songsRemoval[i])
                }

                execute("mpc lsplaylists")
            }

            onPlaylistDelete: (playlist) => {
                player.exec("mpc rm "+ playlist)

                execute("mpc lsplaylists")
            }
        }


        // Seconds Forward/Backward and Progress Bar
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: 30
            spacing: 15

            opacity: root.menuOpen ? 1 : 0
            visible: root.playlistMenuOpen ? false : true
            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            // Shuffle Songs
            Button {
                graphic: "shuffle"
                onClick: player.exec("mpc shuffle")
            }

            // Backward 10s
            Button {
                graphic: "backward"
                onClick: player.exec("mpc seek -10")
            }

            // Progress Bar
            Image {
                id: duration_t
                height: 10
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.Stretch
                source: "../images/white_background"
                smooth: false

                Image {
                    id: duration_e
                    height: 12
                    width: parent.width * root.elapsedTime
                    fillMode: Image.Stretch
                    source: "../images/white_progress"
                    smooth: false

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                }
            }

            // Forward 10s
            Button {
                graphic: "forward"
                onClick: player.exec("mpc seek +10")
            }

            // Loop Song
            Button {
                graphic: "loop"
                onClick: {
                    player.exec("mpc single")
                    player.exec("mpc repeat")
                }
            }
        }




        // Play/Pause & Forward/Backward
        Column{
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            spacing: 10

            visible: root.playlistMenuOpen? false : true
            opacity: root.menuOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            // Previous
            Button {

                width: 25
                height: 25
                graphic: "prev"
                onClick: {
                    if(root.elapsedTime < 0.05) {
                        player.exec("mpc prev")
                    } else {
                        player.exec("mpc seek 0")
                    }
                }
            }

            // Play Pause Level
            Button {
                width: 25
                height: 25
                graphic: plasmoid.configuration.playStatus ? "pause" : "play"
                onClick:  {
                    player.exec("mpc toggle")
                    plasmoid.configuration.playStatus = !plasmoid.configuration.playStatus
                }
            }

            // Next
            Button {

                width: 25
                height: 25
                graphic: "next"
                onClick: player.exec("mpc next")
            }

        }
    }
}
