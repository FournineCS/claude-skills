# Cleanup Commands Reference

Detailed commands for each cleanup category. Always show the dry-run/preview first, get user approval, then execute the cleanup command.

## Table of Contents
1. [Homebrew](#1-homebrew)
2. [npm](#2-npm)
3. [pip](#3-pip)
4. [gem](#4-gem)
5. [yarn](#5-yarn)
6. [Docker](#6-docker)
7. [Xcode DerivedData](#7-xcode-deriveddata)
8. [Xcode Archives](#8-xcode-archives)
9. [iOS Simulators](#9-ios-simulators)
10. [System Caches](#10-system-caches)
11. [System Logs](#11-system-logs)
12. [Crash Reports](#12-crash-reports)
13. [Trash](#13-trash)
14. [Old Downloads](#14-old-downloads)
15. [Large Files](#15-large-files)
16. [Orphaned App Data](#16-orphaned-app-data)
17. [Time Machine Snapshots](#17-time-machine-snapshots)
18. [Launch Agents](#18-launch-agents)
19. [node_modules](#19-node_modules)

---

## 1. Homebrew

### Preview
```bash
brew cleanup -n          # Shows what would be removed
brew autoremove --dry-run  # Shows orphaned dependencies
du -sh "$(brew --cache)" # Cache size
```

### Cleanup
```bash
brew cleanup             # Remove old versions and cached downloads (>120 days)
brew autoremove          # Remove packages installed only as dependencies that are no longer needed
```

### Deep clean (more aggressive)
```bash
brew cleanup -s          # Also remove cache for latest versions
rm -rf "$(brew --cache)" # Remove entire Homebrew cache
```

### Notes
- `brew autoremove` only removes packages that were installed as dependencies and are no longer required. Explicitly installed packages are safe.
- Running `brew doctor` afterward confirms nothing is broken.
- Reversible: packages can be reinstalled with `brew install`.

---

## 2. npm

### Preview
```bash
npm cache ls 2>/dev/null | wc -l    # Count cached items
du -sh ~/.npm                        # Cache size
npm list -g --depth=0                # Global packages
```

### Cleanup
```bash
npm cache clean --force    # Clear the npm cache
```

### Notes
- The npm cache is self-healing; clearing it is safe and npm will re-download as needed.
- Global packages should be reviewed individually — only remove ones you recognize and no longer need.
- Reversible: cache rebuilds automatically on next install.

---

## 3. pip

### Preview
```bash
pip3 cache info           # Cache summary
pip3 cache list           # List cached packages
du -sh ~/Library/Caches/pip  # Cache size
```

### Cleanup
```bash
pip3 cache purge          # Clear all cached packages
```

### Notes
- Clearing pip cache is safe; packages are re-downloaded on next install.
- Reversible.

---

## 4. gem

### Preview
```bash
gem list                  # List installed gems
du -sh ~/.gem             # Gem directory size
gem cleanup --dryrun      # Preview old version removal
```

### Cleanup
```bash
gem cleanup               # Remove old versions of gems
```

### Notes
- Only removes outdated versions, keeps the latest of each gem.
- Reversible: old versions can be reinstalled.

---

## 5. yarn

### Preview
```bash
yarn cache dir            # Show cache path
du -sh $(yarn cache dir)  # Cache size
```

### Cleanup
```bash
yarn cache clean          # Clear entire yarn cache
```

### Notes
- Safe to clear; packages are re-downloaded on next install.

---

## 6. Docker

### Preview
```bash
docker system df                    # Disk usage overview
docker system df -v                 # Detailed breakdown
docker images -f "dangling=true"    # Dangling images
docker container ls -a              # All containers (including stopped)
docker volume ls -f dangling=true   # Unused volumes
```

### Cleanup (progressive)
```bash
# Level 1: Safe cleanup (stopped containers, unused networks, dangling images)
docker system prune

# Level 2: Also remove unused images (not just dangling)
docker system prune -a

# Level 3: Also remove unused volumes (data may be lost)
docker system prune -a --volumes
```

### Targeted cleanup
```bash
docker container prune     # Remove stopped containers only
docker image prune         # Remove dangling images only
docker image prune -a      # Remove all unused images
docker volume prune        # Remove unused volumes
docker builder prune       # Remove build cache
```

### Notes
- Level 1 is generally safe for development machines.
- Level 2 removes images not associated with a container — some may need to be pulled again.
- Level 3 removes volume data which may not be recoverable.
- Always confirm which containers/images are actually in use before pruning.

---

## 7. Xcode DerivedData

### Preview
```bash
du -sh ~/Library/Developer/Xcode/DerivedData
ls ~/Library/Developer/Xcode/DerivedData/  # List projects
```

### Cleanup
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Notes
- DerivedData contains build artifacts, indexes, and logs. It is rebuilt automatically when you next open a project in Xcode.
- Completely safe to delete. The only cost is a longer initial build next time.
- Can grow to 20-50 GB+ on active development machines.

---

## 8. Xcode Archives

### Preview
```bash
du -sh ~/Library/Developer/Xcode/Archives
ls ~/Library/Developer/Xcode/Archives/     # List by date
```

### Cleanup
```bash
# Remove all archives
rm -rf ~/Library/Developer/Xcode/Archives/*

# Or remove selectively by date
rm -rf ~/Library/Developer/Xcode/Archives/2024-*
```

### Notes
- Archives are used for App Store submissions and ad-hoc distribution. If you no longer need to distribute old builds, they can be safely deleted.
- NOT automatically rebuilt — once deleted, you'd need to re-archive from source.
- Recommend keeping recent archives if actively publishing to App Store.

---

## 9. iOS Simulators

### Preview
```bash
xcrun simctl list devices              # List all simulators
xcrun simctl list devices unavailable  # Unavailable ones
du -sh ~/Library/Developer/CoreSimulator  # Total size
```

### Cleanup
```bash
xcrun simctl delete unavailable   # Delete simulators for uninstalled runtimes
```

### Notes
- "Unavailable" simulators are for iOS/watchOS versions you no longer have SDKs for. Safe to delete.
- Active simulators can be recreated from Xcode.

---

## 10. System Caches

### Preview
```bash
du -sh ~/Library/Caches
du -sh ~/Library/Caches/* | sort -rh | head -20
```

### Cleanup
```bash
# Remove all user caches (apps will rebuild them)
rm -rf ~/Library/Caches/*

# Or target specific large caches
rm -rf ~/Library/Caches/com.spotify.client/
rm -rf ~/Library/Caches/com.google.Chrome/
rm -rf ~/Library/Caches/com.microsoft.VSCode/
```

### Notes
- User caches (~/Library/Caches) are safe to delete. Apps recreate them as needed.
- Do NOT delete system caches at /Library/Caches or /System/Library/Caches.
- Some apps may take longer to launch the first time after clearing their cache.

---

## 11. System Logs

### Preview
```bash
du -sh ~/Library/Logs
du -sh ~/Library/Logs/* | sort -rh | head -10
```

### Cleanup
```bash
rm -rf ~/Library/Logs/*
```

### Notes
- User logs are safe to delete. macOS and apps recreate log files as needed.
- Useful for freeing space but you lose historical diagnostic info.
- Do NOT delete /Library/Logs or /var/log — those are system-managed.

---

## 12. Crash Reports

### Preview
```bash
du -sh ~/Library/Logs/DiagnosticReports
ls ~/Library/Logs/DiagnosticReports/ | wc -l
```

### Cleanup
```bash
rm -rf ~/Library/Logs/DiagnosticReports/*
```

### Notes
- Crash reports are informational only. Deleting them does not affect system stability.
- If you've already reported bugs related to crashes, these are safe to remove.

---

## 13. Trash

### Preview
```bash
du -sh ~/.Trash
ls ~/.Trash/ | wc -l
```

### Cleanup
```bash
rm -rf ~/.Trash/*
```

### Notes
- This is the same as "Empty Trash" in Finder.
- Irreversible — files in Trash are your last chance to recover them.
- Ask the user to confirm they don't need anything in Trash.

---

## 14. Old Downloads

### Preview
```bash
# Count files older than 90 days
find ~/Downloads -maxdepth 1 -type f -mtime +90 | wc -l

# List largest old files
find ~/Downloads -maxdepth 1 -type f -mtime +90 -exec du -sh {} + | sort -rh | head -10
```

### Cleanup
```bash
# Move to Trash instead of permanent delete (safer)
find ~/Downloads -maxdepth 1 -type f -mtime +90 -exec mv {} ~/.Trash/ \;

# Or permanently delete
find ~/Downloads -maxdepth 1 -type f -mtime +90 -exec rm {} \;
```

### Notes
- Always show the user the file list before deleting.
- Moving to Trash is preferred over permanent deletion — gives a recovery window.
- Some users keep important files in Downloads indefinitely.

---

## 15. Large Files

### Preview
```bash
find ~ -type f -size +500M -maxdepth 6 \
    -not -path "*/Library/Mail/*" \
    -not -path "*/.Trash/*" \
    -not -path "*/Photos Library.photoslibrary/*" \
    -not -path "*/Music/Music/*" \
    2>/dev/null -exec du -sh {} + | sort -rh
```

### Cleanup
- Large files must be reviewed individually by the user.
- Present each file with its path and size.
- The user decides which ones to delete.

### Notes
- Never auto-delete large files — they could be important data, VMs, or media.
- Common space wasters: .dmg installers, .iso files, VM disk images, old backups.

---

## 16. Orphaned App Data

### Preview
The analyzer script identifies directories in ~/Library subdirectories that don't match any installed app's bundle ID.

### Cleanup
```bash
# Remove specific orphaned directory
rm -rf ~/Library/Application\ Support/com.example.removed-app
rm -rf ~/Library/Preferences/com.example.removed-app.plist
rm -rf ~/Library/Containers/com.example.removed-app
rm -rf ~/Library/Saved\ Application\ State/com.example.removed-app.savedState
```

### Notes
- Orphan detection is heuristic. Some directories belong to system services or CLI tools that don't live in /Applications.
- Always show the list to the user and let them confirm which ones to remove.
- When in doubt, skip it — orphaned preferences are tiny and harmless.

---

## 17. Time Machine Snapshots

### Preview
```bash
tmutil listlocalsnapshotdates
tmutil listlocalsnapshotdates | grep -c "^[0-9]"
```

### Cleanup
```bash
# Delete specific snapshot
sudo tmutil deletelocalsnapshots [date-string]

# Delete all local snapshots
for d in $(tmutil listlocalsnapshotdates | grep "^[0-9]"); do
    sudo tmutil deletelocalsnapshots "$d"
done
```

### Notes
- Requires sudo. Explain this to the user.
- Local snapshots are automatically managed by macOS — they're deleted when space is needed.
- Manual deletion is useful when you need space immediately.
- Disabling Time Machine also clears local snapshots, but this is not recommended.

---

## 18. Launch Agents

### Preview
```bash
ls ~/Library/LaunchAgents/
ls /Library/LaunchAgents/
ls /Library/LaunchDaemons/
```

### Disable (preferred over delete)
```bash
launchctl unload ~/Library/LaunchAgents/com.example.agent.plist
```

### Remove
```bash
launchctl unload ~/Library/LaunchAgents/com.example.agent.plist
rm ~/Library/LaunchAgents/com.example.agent.plist
```

### Notes
- Disabling is safer than deleting — you can re-enable if something breaks.
- Only modify user-level agents (~/Library/LaunchAgents) and third-party agents (/Library/LaunchAgents, /Library/LaunchDaemons).
- Never modify /System/Library/LaunchAgents or /System/Library/LaunchDaemons.
- If unsure about an agent, research its Label before removing it.

---

## 19. node_modules

### Preview
```bash
find ~ -name "node_modules" -type d -maxdepth 5 -prune -exec du -sh {} + | sort -rh
```

### Cleanup
```bash
# Remove specific node_modules (can be restored with npm install)
rm -rf /path/to/project/node_modules

# Remove all node_modules in inactive projects
# (user should confirm which projects are inactive)
```

### Notes
- node_modules can be fully restored by running `npm install` or `yarn install` in the project directory.
- Only remove from projects the user confirms are not actively in use.
- Can recover significant space — individual node_modules folders can be 500 MB+.
