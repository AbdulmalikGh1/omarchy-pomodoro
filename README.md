# Pomodoro Timer for Omarchy

A compact Pomodoro timer that lives in the [Omarchy](https://omarchy.org/) bar. It keeps your focus timer within reach without opening another app.

## Features

- 25-minute focus sessions by default
- Short and long breaks
- Breaks start automatically when focus sessions finish
- Automatic long break after every four completed focus sessions
- Start, pause, reset, skip, and switch phases from the bar
- Desktop notifications when a session finishes
- Configurable focus and break durations
- Persistent timer state across shell reloads
- One synchronized timer across all monitors

## Installation

Install the plugin from its public GitHub repository:

```bash
omarchy plugin add https://github.com/AbdulmalikGh1/omarchy-pomodoro.git --enable
```

Omarchy validates the manifest before installing and asks you to confirm the
clone. Plugins run as code inside the Omarchy shell, so review the source and
install only a repository you trust.

The widget is placed in the center section by default. To move it:

```bash
omarchy bar move local.pomodoro --section right
```

To install from a local clone, copy the repository into the plugin directory:

```text
~/.config/omarchy/plugins/local.pomodoro/
```

Then enable it:

```bash
omarchy plugin enable local.pomodoro --section center
```

Changes under the plugins directory normally reload automatically. If the widget does not appear, run:

```bash
omarchy-shell shell rescanPlugins
```

## Usage

The bar displays the current phase icon and the time remaining.

| Action | Result |
| --- | --- |
| Left-click | Open or close the timer controls |
| Middle-click | Start or pause the timer |
| Right-click | Reset the current phase |

The popup lets you select **Focus**, **Short break**, or **Long break**, and provides controls to reset, start/pause, or skip the current phase. Use **Reset count** to set the completed focus-session count back to zero without changing the active timer or phase.

Finishing a focus session automatically starts a short break. Every fourth completed focus session automatically starts a long break. Finishing a break returns to focus mode and waits for you to start the next session. Using **Next** changes phases without automatically starting the next timer.

## Configuration

Use Omarchy's bar settings to change the durations, in minutes:

```bash
omarchy bar set local.pomodoro focusMinutes 25
omarchy bar set local.pomodoro shortBreakMinutes 5
omarchy bar set local.pomodoro longBreakMinutes 15
```

Supported ranges:

| Setting | Default | Range |
| --- | ---: | ---: |
| `focusMinutes` | 25 | 1–120 |
| `shortBreakMinutes` | 5 | 1–60 |
| `longBreakMinutes` | 15 | 1–90 |

Changing a duration affects newly selected or reset phases; it does not alter a timer already in progress.

## Updating

Plugins installed from Git can be updated with:

```bash
omarchy plugin update local.pomodoro
```

## Uninstalling

Remove the installed plugin with Omarchy. It asks for confirmation and unloads
the plugin if it is enabled:

```bash
omarchy plugin remove local.pomodoro
```

For a manually copied folder, Omarchy moves it to a hidden backup under the
plugins directory. For a Git-installed copy, it removes the local clone. In
both cases the command asks for confirmation; the upstream GitHub repository is
unaffected.

## Development

The plugin contains three files:

- `manifest.json` declares the service, bar widget, and configurable settings.
- `Service.qml` manages timer state, phase transitions, persistence, and notifications.
- `BarWidget.qml` provides the bar display and control popup.

Validate a local checkout with:

```bash
omarchy plugin validate .
```

The plugin uses the Omarchy shell's QML APIs and requires no additional dependencies beyond Omarchy itself.

## Contributing

Issues and pull requests are welcome. If you find a bug, please include your Omarchy version, the steps to reproduce it, and any relevant shell output.
