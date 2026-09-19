import QtQuick
import Quickshell

Item {
  id: root

  // One shared timer service keeps every monitor in sync.

  property var shell: null
  property string phase: "focus"
  property bool running: false
  property int remainingSeconds: 25 * 60
  property double endTimeMs: 0
  property int completedFocusSessions: 0
  property bool restored: false

  readonly property bool isBreak: phase !== "focus"
  readonly property string phaseLabel: phase === "focus"
    ? "Focus"
    : (phase === "longBreak" ? "Long break" : "Short break")

  function widgetEntry() {
    var config = shell ? shell.shellConfig : null
    var layout = config && config.bar ? config.bar.layout : null
    if (!layout) return ({})
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var entries = layout[sections[s]] || []
      for (var i = 0; i < entries.length; i++) {
        if (entries[i] && entries[i].id === "local.pomodoro") return entries[i]
      }
    }
    return ({})
  }

  function positiveInt(value, fallback) {
    var parsed = Math.round(Number(value))
    return isFinite(parsed) && parsed > 0 ? parsed : fallback
  }

  function minutesFor(targetPhase) {
    var entry = widgetEntry()
    if (targetPhase === "focus") return positiveInt(entry.focusMinutes, 25)
    if (targetPhase === "longBreak") return positiveInt(entry.longBreakMinutes, 15)
    return positiveInt(entry.shortBreakMinutes, 5)
  }

  function durationSeconds(targetPhase) {
    return minutesFor(targetPhase) * 60
  }

  function persist() {
    if (!shell || typeof shell.updateEntryInline !== "function") return
    var entry = widgetEntry()
    var next = { id: "local.pomodoro" }
    for (var key in entry) {
      if (key !== "id" && ["phase", "running", "remainingSeconds", "endTimeMs", "completedFocusSessions"].indexOf(key) === -1)
        next[key] = entry[key]
    }
    next.phase = phase
    next.running = running
    next.remainingSeconds = remainingSeconds
    next.endTimeMs = endTimeMs
    next.completedFocusSessions = completedFocusSessions
    shell.updateEntryInline("local.pomodoro", next)
  }

  function restore() {
    if (restored || !shell) return
    var entry = widgetEntry()
    phase = ["focus", "shortBreak", "longBreak"].indexOf(String(entry.phase)) >= 0
      ? String(entry.phase) : "focus"
    completedFocusSessions = Math.max(0, Math.round(Number(entry.completedFocusSessions) || 0))
    running = entry.running === true
    endTimeMs = Number(entry.endTimeMs) || 0

    if (running && endTimeMs > Date.now()) {
      remainingSeconds = Math.max(1, Math.ceil((endTimeMs - Date.now()) / 1000))
    } else if (running) {
      running = false
      endTimeMs = 0
      remainingSeconds = durationSeconds(phase)
      Qt.callLater(function() { root.finishPhase(true, true) })
    } else {
      var saved = Math.round(Number(entry.remainingSeconds))
      remainingSeconds = isFinite(saved) && saved > 0 ? saved : durationSeconds(phase)
    }
    restored = true
  }

  function start() {
    if (running) return
    if (remainingSeconds <= 0) remainingSeconds = durationSeconds(phase)
    endTimeMs = Date.now() + remainingSeconds * 1000
    running = true
    persist()
  }

  function pause() {
    if (!running) return
    remainingSeconds = Math.max(1, Math.ceil((endTimeMs - Date.now()) / 1000))
    running = false
    endTimeMs = 0
    persist()
  }

  function toggle() {
    if (running) pause()
    else start()
  }

  function reset() {
    running = false
    endTimeMs = 0
    remainingSeconds = durationSeconds(phase)
    persist()
  }

  function selectPhase(targetPhase) {
    if (["focus", "shortBreak", "longBreak"].indexOf(targetPhase) < 0) return
    phase = targetPhase
    running = false
    endTimeMs = 0
    remainingSeconds = durationSeconds(phase)
    persist()
  }

  function skip() {
    finishPhase(false, false)
  }

  function finishPhase(showNotification, completedNaturally) {
    var finishedFocus = phase === "focus"
    if (finishedFocus) {
      completedFocusSessions += 1
      phase = completedFocusSessions % 4 === 0 ? "longBreak" : "shortBreak"
    } else {
      phase = "focus"
    }

    remainingSeconds = durationSeconds(phase)
    running = finishedFocus && completedNaturally === true
    endTimeMs = running ? Date.now() + remainingSeconds * 1000 : 0
    persist()

    if (showNotification !== false) {
      var headline = finishedFocus ? "Focus session complete" : "Break complete"
      var body = finishedFocus ? phaseLabel + " started automatically." : "Ready for another focus session?"
      Quickshell.execDetached([
        "omarchy-notification-send", "--app-name", "Pomodoro", "-g", "󰔟",
        "-u", "normal", headline, body
      ])
    }
  }

  Timer {
    interval: 250
    running: root.running
    repeat: true
    onTriggered: {
      var left = Math.ceil((root.endTimeMs - Date.now()) / 1000)
      if (left <= 0) root.finishPhase(true, true)
      else root.remainingSeconds = left
    }
  }

  onShellChanged: Qt.callLater(root.restore)
  Component.onCompleted: Qt.callLater(root.restore)
}
