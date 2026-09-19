import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.pomodoro"

  readonly property var pomodoro: bar && bar.shell
    ? bar.shell.serviceFor("local.pomodoro") : null
  readonly property int secondsLeft: pomodoro ? pomodoro.remainingSeconds : 25 * 60
  readonly property int minutesPart: Math.floor(secondsLeft / 60)
  readonly property int secondsPart: secondsLeft % 60
  readonly property string countdown: String(minutesPart).padStart(2, "0")
    + ":" + String(secondsPart).padStart(2, "0")
  readonly property string phaseIcon: pomodoro && pomodoro.isBreak ? "☕" : "󰔟"
  readonly property string statusText: pomodoro && pomodoro.running ? "running" : "paused"
  readonly property int totalSeconds: pomodoro ? pomodoro.durationSeconds(pomodoro.phase) : 25 * 60
  readonly property real progress: totalSeconds > 0
    ? Math.max(0, Math.min(1, 1 - secondsLeft / totalSeconds)) : 0

  property bool popupOpen: false

  readonly property bool opened: popupOpen

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function togglePanel() { popupOpen = !popupOpen }
  function closeForPopoutSwitch() { close() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.phaseIcon + " " + root.countdown
    horizontalMargin: 8.75
    verticalPadding: 8.75
    active: !!root.pomodoro && root.pomodoro.running
    activeColor: root.pomodoro && root.pomodoro.isBreak
      ? Color.accent
      : (root.bar ? root.bar.urgent : Color.urgent)
    dimmed: !!root.pomodoro && !root.pomodoro.running
    tooltipText: root.pomodoro
      ? root.pomodoro.phaseLabel + " · " + root.statusText
        + "\nClick for controls · Right-click to reset"
      : "Pomodoro timer is loading"

    onPressed: function(b) {
      if (!root.pomodoro) return
      if (b === Qt.RightButton) root.pomodoro.reset()
      else if (b === Qt.MiddleButton) root.pomodoro.toggle()
      else root.togglePanel()
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: fittedContentWidth(Style.space(280))
    contentHeight: fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(12)

      Row {
        width: parent.width
        spacing: Style.space(8)

        Column {
          width: parent.width - resetCountButton.width - parent.spacing
          spacing: Style.space(2)

          Text {
            text: "Pomodoro"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            text: root.pomodoro
              ? root.pomodoro.completedFocusSessions + (root.pomodoro.completedFocusSessions === 1 ? " focus session" : " focus sessions")
              : "Loading timer"
            color: Qt.darker(root.bar.foreground, 1.35)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Button {
          id: resetCountButton
          width: Style.space(96)
          text: "Reset count"
          foreground: root.bar.foreground
          fontSize: Style.font.caption
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.resetSessionCount()
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(4)

        Button {
          width: (parent.width - parent.spacing * 2) / 3
          text: "Focus"
          foreground: root.bar.foreground
          accent: Color.accent
          selected: !!root.pomodoro && root.pomodoro.phase === "focus"
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.selectPhase("focus")
        }

        Button {
          width: (parent.width - parent.spacing * 2) / 3
          text: "Short break"
          foreground: root.bar.foreground
          accent: Color.accent
          selected: !!root.pomodoro && root.pomodoro.phase === "shortBreak"
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.selectPhase("shortBreak")
        }

        Button {
          width: (parent.width - parent.spacing * 2) / 3
          text: "Long break"
          foreground: root.bar.foreground
          accent: Color.accent
          selected: !!root.pomodoro && root.pomodoro.phase === "longBreak"
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.selectPhase("longBreak")
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(8)

        Text {
          width: parent.width
          text: root.pomodoro ? root.pomodoro.phaseLabel : "Focus"
          color: Qt.darker(root.bar.foreground, 1.25)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: parent.width
          text: root.countdown
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.displayLarge
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
          width: parent.width
          height: Style.space(5)
          radius: height / 2
          color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.14)

          Rectangle {
            width: parent.width * root.progress
            height: parent.height
            radius: parent.radius
            color: root.pomodoro && root.pomodoro.isBreak ? Color.accent : root.bar.urgent

            Behavior on width {
              NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
          }
        }
      }

      PanelSeparator {
        foreground: root.bar.foreground
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Button {
          width: (parent.width - parent.spacing * 2) / 3
          text: "Reset"
          iconText: "󰑓"
          foreground: root.bar.foreground
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.reset()
        }

        Button {
          width: (parent.width - parent.spacing * 2) / 3
          text: root.pomodoro && root.pomodoro.running ? "Pause" : "Start"
          iconText: root.pomodoro && root.pomodoro.running ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          accent: Color.accent
          selected: !!root.pomodoro && root.pomodoro.running
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.toggle()
        }

        Button {
          width: (parent.width - parent.spacing * 2) / 3
          text: "Next"
          iconText: "󰒭"
          foreground: root.bar.foreground
          fontSize: Style.font.bodySmall
          horizontalPadding: Style.space(4)
          onClicked: if (root.pomodoro) root.pomodoro.skip()
        }
      }
    }
  }
}
