---
name: mac-cleanup
description: "Comprehensive MacBook cleanup, disk analysis, and system health audit. Use this skill whenever the user mentions freeing up disk space, cleaning their Mac, finding large files, checking for orphaned or unused apps, clearing caches, auditing launch agents or login items, cleaning Homebrew/npm/pip/Docker/Xcode waste, running a system health check, or investigating why their Mac is slow or running out of storage. Trigger on phrases like 'my Mac is full', 'clean up my laptop', 'what is using all my disk', 'find junk files', 'free up space', 'unused packages', 'Mac maintenance', 'disk audit', 'orphaned apps', 'system cleanup', or 'storage report'. Works on both Intel and Apple Silicon Macs."
---

# Mac Cleanup & Health Analysis

Perform comprehensive MacBook disk analysis and guided cleanup. The workflow has two phases: a read-only analysis phase that produces a structured report, followed by an interactive cleanup phase where every destructive action requires explicit user approval.

## Safety Rules

These rules protect the user's system and data:

1. **Analysis is read-only.** The analysis phase never modifies, moves, or deletes anything. It only reads sizes, lists files, and checks configurations.
2. **Never touch SIP-protected paths.** Do not modify anything under `/System`, `/usr` (except `/usr/local`), `/bin`, or `/sbin`.
3. **Never delete without explicit approval.** Before any cleanup action, show the user exactly what will be deleted, how much space it recovers, and wait for confirmation. Treat silence or ambiguity as "no."
4. **Preserve user data.** Never delete documents, photos, or source code in ~/Documents, ~/Desktop, ~/Pictures unless the user identifies specific items.
5. **Dry-run first.** For package manager cleanup (brew, npm, pip), always show dry-run output before executing the real command.

## Phase 1: Analysis

### Step 1: Run the Analyzer Script

Execute the bundled analyzer script to collect system data in a single pass:

```bash
bash <skill-path>/scripts/mac_analyzer.sh
```

This script runs ~30 read-only commands and outputs structured data with section markers. It collects:
- System info (macOS version, chip, model, disk usage)
- Directory sizes for known space consumers
- Package manager inventories (Homebrew, npm, pip, gem)
- Docker artifact sizes
- Xcode artifacts (DerivedData, Archives, Simulators)
- Cache, log, and crash report sizes
- Time Machine local snapshot info
- Launch agents and daemons inventory
- Large files (>500MB)
- Old downloads (>90 days)
- Orphaned app support directories

If specific tools aren't installed (no Docker, no Homebrew), the script gracefully skips those sections.

### Step 2: Detect Orphaned App Data

The analyzer script compares bundle identifiers found in these Library locations against apps in /Applications and ~/Applications:

- `~/Library/Application Support/`
- `~/Library/Preferences/`
- `~/Library/Containers/`
- `~/Library/Group Containers/`
- `~/Library/Caches/`
- `~/Library/Saved Application State/`

An entry is "orphaned" if it references a bundle ID (e.g., `com.example.app`) for which no matching `.app` bundle exists. This is heuristic — some directories belong to system services, so use judgment when presenting results.

### Step 3: Build the Report

Present findings using this report template:

```
# Mac Cleanup Report - [YYYY-MM-DD]

## System Overview
| Property        | Value                              |
|----------------|------------------------------------|
| macOS Version  | [version + build]                  |
| Mac Model      | [model identifier]                 |
| Chip           | [Apple M-series or Intel]          |
| Total Disk     | [size]                             |
| Used           | [size] ([percentage]%)             |
| Available      | [size] ([percentage]%)             |

## Critical - Immediate Attention Needed

Items where recoverable space exceeds 5 GB or disk usage is above 90%.

### [Category Name]
- **Location:** [path]
- **Current Size:** [size]
- **What it contains:** [brief description]
- **Recommendation:** [what to do]
- **Recoverable:** ~[estimated size]

## Warning - Worth Cleaning

Items where recoverable space is between 500 MB and 5 GB.

### [Category Name]
- **Location:** [path]
- **Current Size:** [size]
- **What it contains:** [brief description]
- **Recommendation:** [what to do]
- **Recoverable:** ~[estimated size]

## Info - Maintenance Suggestions

Items under 500 MB or informational findings (login items, launch agents, etc.).

### [Category Name]
- **Finding:** [description]
- **Recommendation:** [what to do]

## Summary

| Category                    | Recoverable Space |
|----------------------------|-------------------|
| [category 1]               | ~[size]           |
| [category 2]               | ~[size]           |
| **Total Estimated**        | **~[total size]** |

### Top 5 Quick Wins
1. [action] - saves ~[size]
2. [action] - saves ~[size]
3. [action] - saves ~[size]
4. [action] - saves ~[size]
5. [action] - saves ~[size]
```

**Severity classification:**
- **Critical**: >5 GB recoverable, or disk usage >90%, or system stability risk
- **Warning**: 500 MB - 5 GB recoverable
- **Info**: <500 MB, or informational findings (audit items, suggestions)

### Analysis-Only Mode

If the user explicitly says they only want a report or health check (not cleanup), present the full report and stop. Do not offer cleanup unless the user later asks.

## Phase 2: Cleanup

After presenting the report, ask which categories the user wants to clean. Present categories as a numbered list. The user might say "clean everything", "just 1 and 3", or ask about a specific category.

### Cleanup Protocol

For each category the user approves:

1. **Show exactly what will happen.** List specific files/directories to be deleted, or show the exact command (including dry-run output for package managers).
2. **Show estimated space recovery.**
3. **Ask for confirmation:**
   ```
   This will delete [N items / specific paths] and free approximately [size].
   Proceed? (yes/no)
   ```
4. **Execute only after explicit "yes."**
5. **Report the result.** After cleanup, show what was deleted and actual space freed.

### Cleanup Categories

| Category | Approach |
|----------|----------|
| Homebrew | `brew cleanup`, `brew autoremove` (show dry-run first) |
| npm cache | `npm cache clean --force` |
| pip cache | `pip cache purge` |
| gem cache | `gem cleanup` |
| Docker | `docker system prune`, `docker image prune` |
| Xcode DerivedData | `rm -rf ~/Library/Developer/Xcode/DerivedData/*` |
| Xcode Archives | Remove selected archives |
| iOS Simulators | `xcrun simctl delete unavailable` |
| System Caches | Remove specific app caches from ~/Library/Caches |
| System Logs | Remove old logs from ~/Library/Logs |
| Crash Reports | Clear ~/Library/Logs/DiagnosticReports |
| Trash | `rm -rf ~/.Trash/*` |
| Old Downloads | Move or delete files older than 90 days |
| Large Files | User selects individual files to remove |
| Orphaned App Data | Remove specific orphaned directories |
| Time Machine Snapshots | `tmutil deletelocalsnapshots [date]` |
| Launch Agents | Disable or remove specific agents |
| node_modules | Remove orphaned node_modules directories |

For detailed commands for each category, read `references/cleanup-commands.md`.

### What NOT to Clean

Even if asked, warn and discourage cleaning:
- `/System/` or any SIP-protected path
- `~/Library/Keychains/` — credential data
- `~/Library/Mail/` — suggest reviewing in Mail.app instead
- Active Docker containers or images currently in use
- Homebrew packages that are dependencies of other installed packages
- Any file the user has not explicitly approved for deletion

## Architecture Notes

The skill works on both Intel and Apple Silicon Macs. The analyzer script detects architecture via `uname -m` and adjusts Homebrew paths accordingly (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel).
