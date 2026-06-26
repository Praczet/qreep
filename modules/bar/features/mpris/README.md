# MPRIS Feature

## What It Does

Shows current media playback next to the clock. The pill is four columns:

```text
state icon | album | title | artists
```

Left click toggles play/pause. Right click opens a small player popup. Hover
shows a richer preview tooltip with album art, source/player info, and controls.
Animated notes float from the state icon while music is playing. Tastefully, or
at least that is the working theory.

## Files

* `MprisService.qml` - selects the active player and exposes derived state.
* `MprisButton.qml` - bar pill and animated notes.
* `MprisTooltip.qml` - preview tooltip.
* `MprisPanel.qml` - right-click player popup.
* `MprisControlButton.qml` - shared media control button.
* `MprisTheme.qml` - sizes, timings, and feature toggles.

## Where To Change Things

Change column widths, note animation, popup sizes, and control sizes in
`MprisTheme.qml`.

Change active-player choice, title/album/artist fallback logic, art URL
normalization, or player source text in `MprisService.qml`.

Change pill layout in `MprisButton.qml`. Change popup/tooltip layout in
`MprisPanel.qml` and `MprisTooltip.qml`.

## Wiring

`panels/Bar.qml` creates `MprisService`, places `MprisButton` in the center slot,
and hosts `MprisTooltip` plus `MprisPanel`.

Theme is exposed through:

```qml
readonly property QtObject mpris: MprisFeature.MprisTheme {}
```

## Service Notes

The service uses:

```qml
import Quickshell.Services.Mpris
```

It reads `Mpris.players.values`, prefers a currently playing player, and falls
back to the first available player. Controls check capability flags such as
`canTogglePlaying`, `canGoNext`, and `canGoPrevious`.

MPRIS can tell Qreep the player identity, desktop entry, DBus name, metadata,
and album art URL. It does not reliably tell Qreep which PipeWire output device
is receiving the audio. That is a separate feature, because of course it is.
