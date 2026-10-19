# S2CE ModManager

**A lightweight AutoIt GUI for managing local `.pack` mods for _Total War: SHOGUN 2 – Complete Edition_.**

[![English](https://img.shields.io/badge/Language-English-blue)](README.md) [![简体中文](https://img.shields.io/badge/语言-简体中文-orange)](README_zh.md)

S2CE ModManager scans the game's `data` directory and a `Disabled_Mods` directory, then lets you activate, deactivate, and reorder local PACK mods by moving files and updating `user.script.txt`.

> **Language:** English is the default. Click **简体中文** above to read the Chinese version. GitHub README files cannot safely run scripts to switch text in place, so the language links open the corresponding README file.

## Features

- **Bilingual interface:** English by default, with an in-app English / 中文 switch.
- **Scan local PACK files:** Lists `.pack` files found directly in the game `data` and `Disabled_Mods` directories.
- **Batch activation:** Check the mods you want to activate. Eligible files are moved from `Disabled_Mods` to `data`, and `user.script.txt` is updated.
- **Batch deactivation:** Check the mods you want to deactivate. Eligible files are moved from `data` to `Disabled_Mods`, and their script entries are removed.
- **Load-order controls:** Select an active PACK row and use **Up** / **Down** to change its order and update `user.script.txt`.
- **Standard script entries:** Managed entries use the format `mod "example.pack";`.
- **Embedded banner data:** The banner's Base64 data is stored in `S2CE_BannerData.au3`; no separate JPG is needed.
- **Native AutoIt GUI:** Uses AutoIt's native GUI controls.
- **Directory settings:** Stores the configured game and script directories in an INI file.

## Repository files

```text
S2CE-ModManager/
├── README.md                  # English documentation (default)
├── README_zh.md               # Simplified Chinese documentation
├── S2CE_ModManager_11.au3     # Main AutoIt source
└── S2CE_BannerData.au3        # Embedded banner image data
```

`S2CE_ModManager_11.au3` includes `S2CE_BannerData.au3`. **Keep both AU3 files in the same directory when running or compiling the source.** When compiled, the included data is compiled into the executable.

## Requirements

- Windows 10 version 1703 or later.
- AutoIt v3 to run or compile the source.
- _Total War: SHOGUN 2 – Complete Edition_ installed locally, with access to its game directory.

This repository does not currently include a prebuilt executable.

## Run from source

1. Clone or download this repository.
2. Keep `S2CE_ModManager_11.au3` and `S2CE_BannerData.au3` in the same folder.
3. Run `S2CE_ModManager_11.au3` with AutoIt.

## Compile to an executable

1. Install AutoIt v3 and SciTE for AutoIt3.
2. Open `S2CE_ModManager_11.au3` in SciTE.
3. Press **F7** to compile.
4. Run the generated executable.

The compiled executable includes the banner data, so `S2CE_BannerData.au3` is not needed alongside the EXE. Keep the include file available while compiling.

## First-time setup

1. Launch the application and review the configured game and script directories.
2. If the game directory is not detected, choose **Set game folder** and select the game root directory containing `data`.
3. If necessary, choose **Set script folder** to set the directory containing `user.script.txt`.
4. Click **Rescan** to read PACK files from the supported directories.
5. Check the PACK entries you want to change, then click **Activate** or **Deactivate**.
6. To change load order, select one active PACK row and click **Up** or **Down**.
7. Close and restart the game before checking the results in-game.

## How it works

### Activation and deactivation

- Checkboxes specify targets for the current batch operation; unchecked items should not be processed.
- Activation moves eligible PACK files from `<GameFolder>\Disabled_Mods\` to `<GameFolder>\data\`.
- Deactivation moves eligible PACK files in the opposite direction.
- The tool updates the corresponding entries in `user.script.txt`.
- If a file with the same name already exists in the destination directory, the tool does not overwrite it.

### Load order

- Select a single active PACK row and click **Up** or **Down**.
- The order is reflected in `user.script.txt`.
- Disabled PACKs must be activated before their load order can be adjusted.

### Script format

Managed entries use this format:

```text
mod "example.pack";
```

The tool attempts to preserve unrelated script lines and comments. The script file is written as UTF-16 LE.

## Configuration and temporary files

- `S2CE_ModManager.ini` is stored beside the main program and saves the configured game and script directories.
- Operation messages are session-only; the application does not create a persistent log file.
- The embedded banner is decoded to a temporary image file at startup and the program attempts to remove it on normal exit.
- The application does not automatically back up PACK files or `user.script.txt`. Consider making your own backup before large changes.

## Known limitations and cautions

- The tool relies on the traditional workflow of moving `.pack` files and editing `user.script.txt`. Compatibility depends on the specific game version.
- If a PACK file is moved but the script update fails, check the file location and `user.script.txt` manually.
- The tool scans direct child `*.pack` files only; it does not recursively scan subdirectories.
- Some official PACK files may be filtered out of the user MOD list by filename.
- Close the game before making changes, and ensure that other applications are not using the target files.
- Compile and test on your target Windows system before relying on the tool for important changes.

## License

The source metadata identifies the program as freeware, but this repository does not currently include a separate `LICENSE` file. Add a license that reflects the author's intended permissions before inviting redistribution or modification.

---

[简体中文 / Chinese](README_zh.md)
