// Singleton to share value across everywhere
// qmldir exists to define this as a singleton everywhere
pragma Singleton
import QtQuick

QtObject {
    property real scaleFactor: 1.0  //Scaling Factor

    property int menuForceCount: 0
    onMenuForceCountChanged: {
        if(menuForceCount<0) {menuForceCount = 0}
    }

    property var thickMinecraftFont: FontLoader {
        source: "../fonts/Minecrafter.ttf"
    }

    property var minecraftFont: FontLoader {
        source: "../fonts/Minecraft.ttf"
    }
}
