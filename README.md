# Download Organizer for Windows — v3.1.2

A lightweight Windows 10/11 tool that watches your Downloads folder and asks where to move each new file **after the download finishes**. Written in PowerShell 5.1 and Windows Forms. No Chrome extension, Python installation or third-party dependencies are required.

## 🌐 Languages / Idiomas / Idiomas

The interface supports **English, Português (Brazil) and Español**. On the first run, the program starts in **English**. Select the language from the drop-down at the top of the main window; the main window and tray menu update immediately. The download destination dialog, notifications, and folder picker prompts use the chosen language. Your choice is saved in `%LOCALAPPDATA%\OrganizadorDeDownloads\config.json` alongside the existing settings. Upgrading from an older version does not delete your recent folder history.

The destination-selection window displays **developed by hmnd-team** in its native title bar, immediately after the translated title.

## Features

- Auto-detects the Windows Downloads known folder, including relocated folders. You can choose another folder to watch.
- Waits for the file size and modification time to stabilize and verifies it is no longer locked before offering to move it.
- Ignores incomplete files ending in `.crdownload`, `.download`, `.part`, `.partial`, `.tmp`, `.opdownload`, or `.aria2`.
- Shows **12 previously used destinations**. Each row has **X · number · editable folder path · OK**:
  - **OK** moves the current file to the chosen path and moves it to the top of the recent list.
  - **X** removes the path from history and shifts remaining entries up; **it never deletes a physical folder**.
- Browse for a new location, keep the file in Downloads, pause monitoring or minimize to the system tray.
- Avoids overwriting files by adding a suffix such as `photo (1).jpg`.
- Keeps preferences locally and does not send files or metadata over the internet.

## Installation

1. Download and extract the ZIP to a permanent folder.
2. Double-click **`Start_DownloadOrganizer.vbs`** to start the app without a console window.
3. Pick your preferred language from the **Language** drop-down (optional; default is English).
4. Download a new file. When it finishes, select a target folder in the pop-up window.
5. To close the app completely, choose **Exit** (English), **Encerrar** (Português), or **Salir** (Español), or use the system tray menu.

If the window fails to open, run `Troubleshoot_Console.bat` to see error messages. The launcher runs the included script using Windows PowerShell 5.1 with `-NoProfile -ExecutionPolicy Bypass -Sta`; check any downloaded script before executing. No administrator privileges are required for normal use.

## Português — resumo

O Organizador de Downloads monitora uma pasta e pergunta onde mover cada arquivo após o download terminar. Selecione **Português** no canto superior da janela; a preferência fica salva. Cada uma das 12 linhas recentes contém **X** (remove apenas do histórico) e **OK** (move o arquivo para aquele destino). Para outra pasta, use **Trocar pasta** na janela principal ou **Procurar...** na janela de destino.

## Español — resumen

El Organizador de Descargas vigila una carpeta y pregunta dónde mover cada archivo cuando termina la descarga. Seleccione **Español** en la parte superior; el idioma se guarda. Las 12 rutas recientes tienen **X** (quita solo del historial) y **OK** (mueve el archivo a esa carpeta). Use **Cambiar carpeta** para vigilar otra ubicación o **Examinar...** para elegir un destino nuevo.

## Important behavior

- Watches the selected folder only; it does **not** automatically watch subfolders.
- Files that were already in the folder at startup are skipped.
- Monitoring works only while the program is running. Closing/minimizing the main window hides it to the tray; it does not exit.
- When copying a large file across disks, leave the program running until the move is complete.
- The selected language is stored as the `idioma` value (`en`, `pt`, or `es`) in `config.json`. Older configuration files default to `en` until the user chooses otherwise.

## Project files

| File | Purpose |
| --- | --- |
| `DownloadOrganizer.ps1` | Main script: folder monitoring, history, translations, UI |
| `Start_DownloadOrganizer.vbs` | Hidden-window launcher |
| `Troubleshoot_Console.bat` | Launcher with console for troubleshooting |
| `QUICK_START.txt` | Quick start in English, Portuguese and Spanish |
| `CHANGELOG.md` | Release notes |

## Version

**v3.1.2** shows the developer credit in the title bar of the download destination window. **v3.1.1** adds internationalized UI and remembers the selected language. **v3** added per-row X buttons and history compaction; **v2** introduced 12 selectable destinations.

## License

MIT License — copyright (c) 2026 hmnd-team. Reuse, modifications and redistribution are permitted if the original copyright and license notice are kept. See [LICENSE](LICENSE).
