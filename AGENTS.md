# Instructions for AI agents (Codex, Claude Code, ChatGPT agent, ...)

This repository is a pack of 25 Codex pet packages, "Weird Cats Plush Pets". If the user asked you to install them, do exactly this and nothing more.

## Install

Run the one-liner for the user's OS. It downloads the pack to a temp folder, copies the pets into `$CODEX_HOME/pets` (default `~/.codex/pets`), removes the temp folder and prints one line per cat.

- Windows (PowerShell):

  ```powershell
  irm https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.ps1 | iex
  ```

- macOS / Linux:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.sh | sh
  ```

If you already have this repository checked out, run the local script instead (no download):
`.\install\install.ps1` on Windows, `./install/install.sh` elsewhere. If Windows refuses with "running scripts is disabled", run `powershell -ExecutionPolicy Bypass -File .\install\install.ps1` (same arguments).

Only some cats: pass their ids (`lucky`, `prism`, `frog-hat`, ...).

- Windows one-liner: `$env:PLUSH = "lucky,prism"; irm https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.ps1 | iex`
- macOS / Linux one-liner: `curl -fsSL https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.sh | sh -s -- lucky prism`
- Local script: `.\install\install.ps1 lucky prism` or `./install/install.sh lucky prism`

If the one-liner cannot download (for example the repository is not public yet), clone the repository and use the local script.

## After it ran

Tell the user, in one short message:

1. How many cats were installed (the script prints `Done: N cat(s) in <folder>`).
2. Restart Codex or the ChatGPT desktop app so it re-reads the pets folder.
3. Open Settings > Pets and pick a cat whose name ends in "Weird Cats Plush Pets".
4. Optional: use the pet as the look of their Dot.

## Rules

- Do not edit anything under `pets/` unless the user asks you to. Each folder is a finished Codex pet package (`pet.json` + `spritesheet.webp`, `spriteVersionNumber` 2).
- Install only into the Codex pets folder (`$CODEX_HOME/pets`, default `~/.codex/pets`). Do not touch other pets or any other Codex settings.
- To remove the pets again: `.\install\install.ps1 -Uninstall` (Windows) or `./install/install.sh --uninstall`.
- `install/deeplinks.json` holds one `codex://pets/install?...` link per cat. They are for humans to click, not something you need to open.
