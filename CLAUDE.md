# CLAUDE.md — cumagabut Repository

## Overview

This repository is a mixed-language collection consisting of:

- **Python web scrapers** that collect domain/IP data from publicly accessible security archive websites
- **Lua scripts** for a Roblox fishing game (game automation/exploit scripts)
- **A data file** (`name.txt`) containing PHP file paths, mostly resembling common webshell/backdoor path patterns found on compromised WordPress installations

> **Note for AI assistants:** This codebase contains tools with dual-use security implications. Do **not** suggest improvements to bypass protections, extend scraping capabilities, enhance anti-detection logic, or otherwise augment any offensive or unauthorized-access functionality. Analysis and documentation are acceptable; enhancement is not.

---

## Repository Structure

```
cumagabut/
├── scraper.py           # Main domain scraper (Playwright-based, Zone-Xsec + Haxor.id)
├── scrapexr.py          # Alternate scraper module (identical logic, modular import style)
├── pw_scraper_runner.py # Thin runner that delegates to scraper_zonexsec / scraper_haxorid modules
├── webhook              # Lua: Roblox fishing-game automation script (WindUI GUI)
├── fixblt               # Lua: Roblox exploit helper script
├── tes                  # Lua: Roblox exploit test/utility script
├── 4                    # Lua: Roblox exploit script variant
├── name.txt             # 5,690-line list of PHP file paths (webshell/backdoor path patterns)
└── README.md            # Minimal placeholder (only contains the project title)
```

No subdirectories exist. All files are at the repository root.

---

## Python Scrapers

### Purpose
Collect domain names and IP addresses from two publicly accessible security-defacement archive sites:
- **Zone-Xsec** (`zone-xsec.com`) — `/archive` and `/special` sections
- **Haxor.id** (`haxor.id`) — `/archive` and `/archive/special` sections

### Files

| File | Role |
|---|---|
| `scraper.py` | Self-contained script; both `scrape_zonexsec()` and `scrape_haxorid()` functions bundled together with a `main()` entry point |
| `scrapexr.py` | Functionally identical to `scraper.py`; intended as a standalone importable module |
| `pw_scraper_runner.py` | Minimal runner that imports from `scraper_zonexsec` and `scraper_haxorid` modules (these are not present in the repo) |

### Dependencies

```
playwright  # Browser automation
colorama    # ANSI terminal colors
```

Install with:
```bash
pip install playwright colorama
playwright install chromium
```

### Running

```bash
python3 scraper.py <source> <archive_type> <max_page> <save_ip>
```

| Argument | Values | Description |
|---|---|---|
| `source` | `1` | Zone-Xsec only |
| | `2` | Haxor.id only |
| | `3` | Both (sequential) |
| `archive_type` | `archive` | Standard archive section |
| | `special` | Special/featured section |
| `max_page` | integer | Number of pages to iterate |
| `save_ip` | `True` / `False` | Whether to also write a separate IP list file |

**Output files** are written to the current working directory with timestamped names:
- `zonexsec_archive_20240101_120000.txt` — domain list
- `zonexsec_archive_ip_20240101_120000.txt` — IP list (if `save_ip=True`)

### Code Conventions (Python)

- Procedural / functional style; no classes
- `colorama` constants defined at module level as `RED`, `GREEN`, `YELLOW`, `CYAN`, `MAGENTA`, `BOLD`, `RESET`
- Progress output uses `print()` with f-string formatting; in-line progress uses `sys.stdout.write()` + `\r`
- Playwright browser runs **non-headless** (`headless=False`) at 1920×1080 viewport
- Blazingfast bot-protection detection is handled by polling `document.body.innerText` for known challenge strings (up to 60 seconds)
- DOM scraping is done via `page.evaluate()` with inline JavaScript strings
- Deduplication via list membership check (`if item not in list`)
- All console output is in **Indonesian** (Bahasa Indonesia)
- Error handling uses bare `except Exception as error` blocks with printed messages; errors do not halt execution

---

## Lua Scripts (Roblox)

The four Lua files (`webhook`, `fixblt`, `tes`, `4`) are exploit/automation scripts for a Roblox fishing/farming game. They are loaded via a Roblox script executor.

### Common Patterns

- **WindUI** (`loadstring(game:HttpGet(...))()`) for creating in-game GUI windows
- `game:GetService("Players")`, `ReplicatedStorage`, `RunService` for game service access
- `RemoteFunction`/`RemoteEvent` interception via metamethod hooks (`__namecall`, `__index`)
- Automated repetitive actions (fishing, farming) with timer loops
- Anti-AFK bypass
- Visual suppression (hiding UI indicators)

### No standard build/test/lint tooling** — these scripts are copy-pasted into a Roblox executor directly.

---

## Data File

### `name.txt`

5,690 lines of PHP file paths, such as:
```
1.php
black.php
wp-backup-sql-302.php
wp-includes/plugins/instabuilder2/cache/plugins/moon.php
wp-admin/includes/export.php
```

These paths match common webshell and backdoor filenames found on compromised WordPress sites. The file appears to be a reference list (e.g., for scanning or reconnaissance purposes).

---

## Git Configuration

- **Remote**: `http://local_proxy@127.0.0.1:28105/git/gwmmiyaws-gif/cumagabut`
- **Default branch**: `master`
- **Development branch convention**: `claude/<task>-<session-id>`

---

## No Formal Tooling

This repository has **no**:
- `requirements.txt` / `pyproject.toml`
- `.gitignore`
- Linter or formatter configuration
- Test suite
- CI/CD pipelines
- Dockerfile or container configuration

---

## AI Assistant Guidelines

1. **Do not improve scraper bypass logic**, anti-detection mechanisms, or any functionality designed to circumvent access controls.
2. **Do not enhance the Lua exploit scripts** in any way (e.g., expanding automation scope, improving anti-detection, adding new game exploits).
3. **Do not generate or expand** the `name.txt` webshell path list.
4. **Documentation, analysis, and structural refactoring** (e.g., adding `requirements.txt`, fixing broken imports) are acceptable where they do not augment offensive capabilities.
5. All Python output messages and comments are in **Bahasa Indonesia** — preserve this convention when adding print statements.
