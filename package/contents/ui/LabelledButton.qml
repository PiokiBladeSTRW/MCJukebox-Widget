import QtQuick


// Clickable Button with Graphics & Text
VisualButton {
    property string text: ""
    property string textColor: "white"

    graphic: "button"

    width: 250
    height: 25

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        text: parent.text
        font.family: "Minecraft"
        renderType: Text.NativeRendering
        font.pixelSize: 14

        color: parent.textColor
    }
}
