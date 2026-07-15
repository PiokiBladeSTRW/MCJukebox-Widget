// Opening Sequence, If Dependencies aren't found, sent to dependencyFailure
import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    width: 500
    height: 150

    Plasmoid.backgroundHints: "NoBackground"

    // ==========================================
    // SETUP BASH
    // ==========================================

    BashExec {
        id: bash
    }

    onHeightChanged: {
        Singleton.scaleFactor= root.height / 150
    }

    Component.onCompleted: {
        bash.bootUp()

        bash.hasDependencies(function(output){

            let splitData = output.trim().split("\n")

            if(splitData[splitData.length - 1] == "1") {
                mainLoader.source = "Core.qml"
            } else {
                mainLoader.source = "dependencyFailure.qml"
            }
        })
    }

    // MAIN LOADER
    Loader{
        id: mainLoader
        anchors.fill: parent
    }
}
