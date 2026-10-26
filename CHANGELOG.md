## v3.1.2 — 2026-10-26

- Added `developed by hmnd-team` to the destination dialog title bar, immediately after its translated title (English, Portuguese or Spanish).
- No changes to monitoring, recent destination history, saved preferences or launcher encoding.

## v3.1.1 - Correção de inicialização (26/10/2026)

- Iniciador `.vbs` salvo em ASCII sem BOM e com CRLF padrão, corrigindo o erro do Windows Script Host `800A0408` na primeira linha.
- Nenhuma alteração de comportamento, idioma ou histórico.

# Changelog

## v3.1.1 — 2026-10-26

- Added English, Portuguese and Spanish translations for the entire UI, warnings, destination dialog, folder pickers and tray menu.
- Added a visible language selector to the main window. The interface updates immediately when changed.
- English is the default when no language has been selected.
- Saves `idioma` in the existing `config.json`, preserving the watched folder and all 12 saved destinations.
- Initially kept the developer attribution in source code comments only (updated in v3.1.2 to show a title-bar credit).

## v3 — 2026-10-26

- Added an **X** next to each of the 12 recent destinations.
- Removing a saved path immediately shifts the other saved paths up.
- Removal persists in `config.json` and does not delete directories from disk.

## v2

- Added 12 editable recent folder paths, each with a dedicated OK button.

## v1

- Added download monitoring, temporary file filtering and destination history.
