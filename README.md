# LoudMic

<img src="loudmic.png" width="128" alt="App icon">

A tiny macOS menu bar app that keeps your microphone volume where you want it.

Some apps and system events love to quietly reset your mic input level. LoudMic fights back by re-applying your chosen volume (100% or 80%) every few seconds, so your calls and recordings stay consistent.

**Requires macOS 15 (Sequoia) or later.**

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/vladstudio/loudmic/main/install.sh | bash
```

This downloads the latest release and drops it into `/Applications`.

## Features

- Lives in the menu bar -- no dock icon, no windows
- Choose between 100% and 80% mic volume
- Enforces your choice continuously so nothing can silently change it
- Optional start-on-login
- Auto-update from GitHub releases

## Build from source

```sh
./build.sh
```

Depends on the sibling [MacAppKit](../app-kit) package.

## Author

[Vlad Gerasimov](https://vlad.studio) -- [loudmic.vlad.studio](https://apps.vlad.studio/loudmic)

## License

MIT -- see [LICENSE](LICENSE).
