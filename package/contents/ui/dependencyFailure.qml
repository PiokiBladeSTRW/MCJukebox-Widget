// What shows Instead of the MainJukebox panel if lacking MPC / MPD
import QtQuick
import org.kde.plasma.plasmoid

// Main Component
Item {
    id: root
    height: 150
    width: 500
    clip: true

    property bool menuOpen: false


    // Warning Menu
    Image {
        id: menu
        width: 400 * Singleton.scaleFactor
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: root.menuOpen ? 0 : -340 * Singleton.scaleFactor

        property bool menuCloseTimed: false

        source: "../images/background/warning.png"
        fillMode: Image.Stretch

        // Menu Pop Out/In Animation
        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: root.menuOpen ? Easing.InCubic : Easing.OutBack
            }
        }

        // Handle Menu Open & Close States based on Mouse
        MouseArea{
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                // Open Menu
                if( !root.menuOpen) {

                    root.menuOpen = true
                    parent.source = "../images/background/menu.png"
                }
            }

            onEntered: {
                // Stop Menu From Closing if Menu is Open but about to Close
                if( parent.menuCloseTimed ) {
                    parent.menuCloseTimed = false
                }
            }

            onExited: {
                // Start Counting for Menu Close
                if(root.menuOpen) {
                    parent.menuCloseTimed = true
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
                parent.source= "../images/background/warning.png"
                root.menuOpen = false

            }
        }

    }
}
