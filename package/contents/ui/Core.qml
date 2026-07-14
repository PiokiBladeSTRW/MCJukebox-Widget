// Imports
import QtQuick
import QtQuick.Effects
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PC

import "../code/timeData.js" as TimeData
import "../code/titles.js" as Titles

// Main Component
Item {
    id: root
    height: 150
    width: 500
    clip: true

    property real elapsedTime
    property string trackTitle
    property string trackArtist

    property bool menuOpen: false
    property bool keepMenuOpen: Singleton.menuForceCount > 0
    property bool playlistMenuOpen : false


    // ==========================================
    // COMMANDS
    // ==========================================

    // Update track Title and artist Title
    function titleUpdate(output) {
        [root.trackTitle, root.trackArtist] = Titles.handleTrackTitles(output)
    }

    // Update Time Elapsed
    function timeUpdate(output) {
        root.elapsedTime = TimeData.handleElapsedTime(output);
    }

    // Timer to Poll for Updates on elapsedTime
    Timer {
        interval: 1000
        repeat: true
        running: plasmoid.configuration.playStatus && root.menuOpen

        onTriggered: {
            bash.statusUpdate(timeUpdate)
        }
    }

    // Set directories and data up upon Opening of Widget
    Component.onCompleted: {
        bash.titleUpdateCallback = titleUpdate
        bash.titlesUpdate(titleUpdate)
        bash.statusUpdate(timeUpdate)
    }



    // ==========================================
    // VISUAL PARTICLES
    // ==========================================

    // Note Block Particles for Playing [Perhaps Optimize?]
    Item {
        id: noteParticles

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: 100 * Singleton.scaleFactor

        visible: plasmoid.configuration.playStatus && !root.menuOpen

        property list<color> colors: ["lime", "yellow", "red", "magenta", "blue"]
        property list<int> positions: [-32 * Singleton.scaleFactor, 0, 32 * Singleton.scaleFactor]
        property int posIndex : 0
        property int colorIndex: 0
        property int baseOffset: 75 * Singleton.scaleFactor
        property int topOffset: 0

        Image {
            id: noteImage
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            property int vOffset: parent.baseOffset

            anchors.horizontalCenterOffset: parent.positions[parent.posIndex]
            anchors.verticalCenterOffset: vOffset

            source: "../images/note.png"


            SequentialAnimation {
                id: verticalAnimation

                running: noteParticles.visible
                loops: Animation.Infinite

                NumberAnimation {
                    target: noteImage
                    property: "anchors.verticalCenterOffset"
                    from: noteParticles.baseOffset
                    to: noteParticles.topOffset
                    duration: 600
                    easing.type: Easing.InOutQuad
                }


                PauseAnimation{duration: 99}

                PropertyAction {
                    target: noteImage
                    property: "anchors.verticalCenterOffset"
                    value: noteParticles.baseOffset
                }

                ScriptAction {
                    script: {
                        noteParticles.posIndex = noteParticles.posIndex < 2 ? noteParticles.posIndex + 1 : 0
                        noteParticles.colorIndex = noteParticles.colorIndex < 4 ? noteParticles.colorIndex + 1 : 0
                    }
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



    // ==========================================
    // MAIN MENU
    // ==========================================


    // Song Playing Menu
    Image {
        id: menu
        width: 400 * Singleton.scaleFactor
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: root.menuOpen ? 0 : -340 * Singleton.scaleFactor

        property string sourceFile : plasmoid.configuration.playStatus ? "empty" : "out"        // If Playing, keeps BG empty for ParrotAni
        property bool menuCloseTimed: false
        property bool menuFullyClosed: true                                                     // Ensure Parrot Anim only plays upon full Menu Close

        source: "../images/background/" + sourceFile + ".png"
        fillMode: Image.Stretch

        // Menu Pop Out/In Animation
        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: root.menuOpen ? Easing.InCubic : Easing.OutBack
            }
        }

        // Sound Effect for Opening Menu
        SoundEffect {
            id: openSound
            source: "../sounds/insert.wav"
            volume: 0.5
        }

        // Handle Menu Open & Close States based on Mouse
        MouseArea{
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                // Open Menu
                if( !root.menuOpen) {
                    openSound.play()

                    root.menuOpen = true
                    parent.menuFullyClosed = false
                    parent.sourceFile = "menu"
                }
            }

            onEntered: {
                if(root.keepMenuOpen) {
                    return
                }

                // Stop Menu From Closing if Menu is Open but about to Close
                if( parent.menuCloseTimed ) {
                    parent.menuCloseTimed = false

                // Highlight Jukebox    [menuOpen in condition to handle Edge Cases]
                } else if (!plasmoid.configuration.playStatus && !root.menuOpen) {
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

        // Grace Period Timer to ensure Mouse Leaving doesn't Insta-Shut menu
        Timer {
            id: menuCloseTimer
            interval: 600
            running: parent.menuCloseTimed

            onTriggered: {
                parent.menuCloseTimed = false
                root.menuOpen = false
                fullyCloseWait.start()
            }
        }

        // Let Menu Close Animation Finish before Changing Background
        Timer {
            id: fullyCloseWait
            interval: 300

            onTriggered: {
                // Disable PlaylistMenu if Open
                if(root.playlistMenuOpen) {
                    root.playlistMenuOpen = false
                }

                parent.menuFullyClosed = true

                // Either Set Menu to be Jukebox or Parrot Animation
                if(!plasmoid.configuration.playStatus) {
                    parent.sourceFile = "out"
                } else {
                    parent.sourceFile = "empty"
                }
            }
        }

        // If Menu Closed & Song Playing, Dancing parrot
        AnimatedSprite {
            id: parentAnim
            anchors.fill: parent

            source: "../images/background/out_play.png"

            frameWidth: 450
            frameHeight: 120

            frameCount: 12
            frameRate: 20

            visible: parent.menuFullyClosed && plasmoid.configuration.playStatus
            running: visible
            loops: Animation.Infinite

            smooth: false
        }


        // ==========================================
        // TITLES
        // ==========================================


        // Song Title
        Item {
            id: textContainer
            width: 300 * Singleton.scaleFactor      // The visible viewport window width
            height: 20 * Singleton.scaleFactor
            clip: true

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: -30 * Singleton.scaleFactor

            opacity: root.menuOpen && !root.playlistMenuOpen ? 1 : 0
            Behavior on opacity { FadeAnim{} }
            visible: opacity > 0

            // Let the Text Animate
            Text {
                id: scrollingText
                text: root.trackTitle

                font.family: Singleton.minecraftFont.name
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
            id: artist_title
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: -5 * Singleton.scaleFactor

            font.family: Singleton.minecraftFont.name
            renderType: Text.NativeRendering
            font.pixelSize: 16

            opacity: root.menuOpen && !root.playlistMenuOpen ? 1 : 0
            Behavior on opacity { FadeAnim{} }
            visible: opacity > 0

            text: root.trackArtist
        }


        // ==========================================
        // PLAYLISTS
        // ==========================================


        // Playlist Menu Toggle
        VisualButton {
            id: playlist_menu_toggle

            height: 100 * Singleton.scaleFactor
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            source: "../images/playlist.png"

            opacity: root.menuOpen ? 1 : 0
            Behavior on opacity { FadeAnim{} }
            visible: opacity > 0

            onClick: root.playlistMenuOpen = !root.playlistMenuOpen

            detectHover: true
            PC.ToolTip.visible: hovered
            PC.ToolTip.text: "Toggle Playlist Menu"
        }

        Loader {
            id: playlistMenu
            anchors.fill: parent

            onLoaded: {item.changeOpacity(1)}

            // Animation
            Connections {
                target: root

                function onPlaylistMenuOpenChanged() {
                    if(playlistMenu.source != "") {
                        playlistMenu.item.changeOpacity(0)
                    } else {
                        playlistMenu.source = "PlaylistMenu.qml"
                    }
                }
            }

            // Signals Connections
            Connections {
                target: playlistMenu.item
                ignoreUnknownSignals: true

                function onFadeOutComplete(){
                    playlistMenu.source = ""
                }
            }
        }


        // ==========================================
        // BOTTOM ROW [SHUFFLE, REPEAT, BACKWARD, FORWARD, TIME ELAPSED]
        // ==========================================

        // Bottom Row
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenterOffset: 30 * Singleton.scaleFactor
            spacing: 15

            opacity: root.menuOpen && !root.playlistMenuOpen ? 1 : 0
            Behavior on opacity { FadeAnim{} }
            visible: opacity > 0

            // Shuffle Songs
            VisualButton {
                graphic: "main_icons/shuffle"
                onClick: {
                    bash.shuffleToggle()
                    plasmoid.configuration.shuffle = !plasmoid.configuration.shuffle
                }

                detectHover: true
                PC.ToolTip.visible: hovered
                PC.ToolTip.text: "Shuffle"
            }

            // Backward 10s
            VisualButton {
                graphic: "main_icons/backward"
                onClick: {
                    bash.seekPosition("-10")
                    bash.statusUpdate(timeUpdate)
                }

                detectHover: true
                PC.ToolTip.visible: hovered
                PC.ToolTip.text: "Backward 10s"
            }

            // Progress Bar
            Image {
                id: duration_t
                height: 10 * Singleton.scaleFactor
                width: 120 * Singleton.scaleFactor
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.Stretch
                source: "../images/white_background"
                smooth: false

                Image {
                    id: duration_e
                    height: 12 * Singleton.scaleFactor
                    width: parent.width * root.elapsedTime
                    fillMode: Image.Stretch
                    source: "../images/white_progress"
                    smooth: false

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                }
            }

            // Forward 10s
            VisualButton {
                graphic: "main_icons/forward"
                onClick: {
                    bash.seekPosition("+10")
                    bash.statusUpdate(timeUpdate)
                }

                detectHover: true
                PC.ToolTip.visible: hovered
                PC.ToolTip.text: "Forward 10s"

            }

            // Loop Song
            VisualButton {
                graphic: "main_icons/loop"
                onClick: bash.repeatToggle()

                detectHover: true
                PC.ToolTip.visible: hovered
                PC.ToolTip.text: "Repeat"
            }
        }


        // ==========================================
        // RIGHT COLUMN [PLAY, PAUSE, NEXT, PREV]
        // ==========================================

        // Right Column
        Column{
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10 * Singleton.scaleFactor
            spacing: 10

            property int playButtonIndex: 1

            opacity: root.menuOpen && !root.playlistMenuOpen ? 1 : 0
            Behavior on opacity { FadeAnim{} }
            visible: opacity > 0

            property list<string> tooltips: ["Previous", "Play/Pause", "Next"]

            Repeater {
                model: ["main_icons/prev", 0, "main_icons/next"]
                VisualButton {
                    width: 25 * Singleton.scaleFactor
                    height: 25 * Singleton.scaleFactor

                    graphic: index === parent.playButtonIndex ?  plasmoid.configuration.playStatus ? "main_icons/pause" : "main_icons/play" : modelData

                    detectHover: true
                    PC.ToolTip.visible: hovered
                    PC.ToolTip.text: parent.tooltips[index]

                    onClick: {
                        switch(index) {
                            case 0:
                                if(root.elapsedTime < 0.05) {
                                    bash.changeSong(-1)
                                } else {
                                    bash.seekPosition("0")
                                }
                                break

                            case 1:
                                bash.playToggle()
                                break

                            case 2:
                                bash.changeSong(1)
                                break
                        }
                    }
                }
            }
        }
    }
}
