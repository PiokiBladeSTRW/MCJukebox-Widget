import QtQuick

Image {
    property bool active: true
    property string graphic: "button"
    property string text: ""
    property string textColor: "white"

    property bool detectHover: false
    property bool hovered: false
    signal click

    source: "../images/" + graphic + ".png"
    fillMode: Image.Stretch
    smooth: false

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

    MouseArea{
        visible: active
        hoverEnabled: detectHover
        anchors.fill: parent

        onClicked: parent.click()

        onEntered: parent.hovered = true
        onExited: parent.hovered = false
    }
}
