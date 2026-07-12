import QtQuick
import org.kde.plasma.components 3.0 as PC

// Text Field with Background
PC.TextField {
    height: 25
    width: 250
    //anchors.horizontalCenter: parent.horizontalCenter

    //placeholderText: modelData

    background: Image {
        anchors.fill: parent
        source: parent.activeFocus ? "../images/text_field_highlighted.png" : "../images/text_field.png"
    }
}
