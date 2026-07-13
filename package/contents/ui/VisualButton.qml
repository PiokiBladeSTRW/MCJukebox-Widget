import QtQuick

// Clicakble Button with Graphics
Image {
    property bool active: true
    property string graphic: "mud"

    property bool detectHover: false
    property bool hovered: false
    signal click

    source: "../images/" + graphic + ".png"
    fillMode: Image.Stretch
    smooth: false

    width: 20 * Singleton.scaleFactor
    height: 20 * Singleton.scaleFactor

    MouseArea{
        visible: active
        hoverEnabled: detectHover
        anchors.fill: parent

        onClicked: parent.click()

        onEntered: parent.hovered = true
        onExited: parent.hovered = false
    }
}
