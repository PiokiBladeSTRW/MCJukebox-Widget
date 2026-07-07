import QtQuick

Image {
    property bool active: true
    property bool detectHover: false
    property bool hovered: false
    property string graphic: "mud"
    signal click

    source: "../images/" + graphic + ".png"
    fillMode: Image.Stretch
    smooth: false

    width: 20
    height: 20

    MouseArea{
        visible: active
        hoverEnabled: detectHover
        anchors.fill: parent

        onClicked: parent.click()

        onEntered: parent.hovered = true
        onExited: parent.hovered = false
    }
}
