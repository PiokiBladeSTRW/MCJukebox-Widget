// Imports
import QtQuick
import QtQuick.Effects
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support 2.0 as PS

import "../code/timeData.js" as TimeData
import "../code/titles.js" as Titles


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
    property bool keepMenuOpen: false

    // Music Player
    PS.DataSource {
        id: player
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) =>{

            if( sourceName === "mpc status" ) {
                     root.elapsedTime = TimeData.main(data) ;

            } else if (sourceName.startsWith("mpc -f")) {
                [root.trackTitle, root.trackArtist] = Titles.main(data)
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        Component.onCompleted: {
            connectSource("mkdir ~/.cache/jukebox_covers")
            connectSource("mpc update")
        }
    }

    // Sound Effect
    SoundEffect {
        id: clickSound
        source: "../sounds/insert.wav"
        volume: 0.5
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
        id: noteParticles

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 100

        visible: plasmoid.configuration.playStatus && !root.menuOpen

        property list<color> colors: ["lime", "yellow", "red", "magenta", "blue"]
        property int noteIndex : 0
        property int colorIndex: 0
        property int baseOffset: 75
        property int topOffset: 0

        Timer {
            id: noteTimer
            interval: 700
            repeat: true
            running: plasmoid.configuration.playStatus

            onTriggered: {
                parent.noteIndex += 1;
                if(parent.noteIndex === 3) {
                    parent.noteIndex = 0;
                }

                parent.colorIndex += 1
                if(parent.colorIndex === 4) {
                    parent.colorIndex = 0
                }
            }
        }

        Repeater {
            id: notes
            model: [-32, 0, 32]

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenterOffset: modelData
                anchors.verticalCenterOffset: index === parent.noteIndex ? parent.topOffset : parent.baseOffset

                visible: index === parent.noteIndex
                source: "../images/note.png"

                Behavior on anchors.verticalCenterOffset {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.InOutQuad
                    }
                }

                // Different Colors of Notes
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: parent.colors[parent.colorIndex]
                }

            }
        }
    }


    // Menu
    Image {
        id: menu
        width: 400
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: root.menuOpen ? 0 : -340

        property string sourceFile : "out"
        property bool menuCloseTimed: false

        source: "../images/background/" + sourceFile + ".png"
        fillMode: Image.Stretch

        // Menu Pop Animation
        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: root.menuOpen ? Easing.InCubic : Easing.OutBack
            }
        }


        MouseArea{
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                // Open Menu
                if( !root.menuOpen) {
                    clickSound.play()
                    parrotAnim.stop()

                    root.menuOpen = true
                    parent.sourceFile = "menu"
                }
            }

            onEntered: {
                // Stop Menu From Closing if Menu is Open but about to Close
                if( parent.menuCloseTimed ) {
                    parent.menuCloseTimed = false

                // Highlight Jukebox
                } else if (!plasmoid.configuration.playStatus) {
                    parent.sourceFile = "out_highlight"
                }
            }

            onExited: {
                if(root.keepMenuOpen) {
                    return
                }

                // Start Counting for Menu Close
                if(root.menuOpen) {
                    parent.menuCloseTimed = true

                // Remove Highlight Jukebox
                } else if (!plasmoid.configuration.playStatus) {
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
            id: slowdown
            interval: 300

            onTriggered: {
                // Disable PlaylistMenu if Open
                if(root.playlistMenuOpen) {
                    root.playlistMenuOpen = false
                }

                // Either Set Menu to be Jukebox or Parrot Animation
                if(!plasmoid.configuration.playStatus) {
                    parent.sourceFile = "out"
                } else {
                    parrotAnim.start()
                }
            }
        }

        Timer {
            id: parrotAnim
            interval: 50
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

        // Song Title
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

                // Text Scroll Animation
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

            onMenuForceState: (state) => {
                root.keepMenuOpen = state
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

            property int playButtonIndex: 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.Linear
                }
            }

            Repeater {
                model: ["prev", 0, "next"]
                Button {
                    width: 25
                    height: 25

                    graphic: index === parent.playButtonIndex ?  plasmoid.configuration.playStatus ? "pause" : "play" : modelData

                    onClick: {
                        switch(index) {
                            case 0:
                                if(root.elapsedTime < 0.05) {
                                    player.exec("mpc prev")
                                } else {
                                    player.exec("mpc seek 0")
                                }
                                break

                            case 1:
                                player.exec("mpc toggle")
                                plasmoid.configuration.playStatus = !plasmoid.configuration.playStatus
                                break

                            case 2:
                                player.exec("mpc next")
                                break
                        }
                    }
                }
            }
        }
    }
}
