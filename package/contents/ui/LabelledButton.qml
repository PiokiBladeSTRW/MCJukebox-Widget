import QtQuick


// Clickable Button with Graphics & Text
VisualButton {
    property string text: ""
    property string textColor: "white"
    property string font: Singleton.minecraftFont.name

    graphic: "button"

    width: 250 * Singleton.scaleFactor
    height: 25 * Singleton.scaleFactor

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        text: parent.text
        font.family: parent.font
        renderType: Text.NativeRendering
        font.pixelSize: 14

        color: parent.textColor
    }
}
