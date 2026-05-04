#!/usr/bin/env bash
# mac_analyzer.sh - Read-only Mac system analysis
# This script NEVER modifies, deletes, or moves any files.
# All commands are read-only (du, df, ls, find, etc.)

# Don't exit on errors - we want to collect as much data as possible
set +e

# --- Helpers ---
section_start() {
    echo ""
    echo "=== SECTION: $1 ==="
}

section_end() {
    echo "=== END SECTION ==="
}

size_of() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "NOT_FOUND"
    fi
}

command_exists() {
    command -v "$1" &>/dev/null
}

# Detect architecture and set paths
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# ============================================================
# Section 1: System Info
# ============================================================
section_start "System Info"

echo "MACOS_VERSION: $(sw_vers -productVersion 2>/dev/null)"
echo "BUILD: $(sw_vers -buildVersion 2>/dev/null)"
echo "ARCH: $ARCH"

# Model info
MODEL=$(sysctl -n hw.model 2>/dev/null)
echo "MODEL_ID: $MODEL"

# Friendly model name
MODEL_NAME=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" | sed 's/.*: //')
echo "MODEL_NAME: $MODEL_NAME"

# Chip
CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Chip" | sed 's/.*: //')
if [ -n "$CHIP" ]; then
    echo "CHIP: $CHIP"
else
    CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
    echo "CHIP: $CPU"
fi

# Memory
MEM=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Memory" | sed 's/.*: //')
echo "MEMORY: $MEM"

# Disk usage
echo ""
echo "DISK_USAGE:"
df -h / 2>/dev/null

echo ""
echo "DISK_INFO:"
diskutil info / 2>/dev/null | grep -E "Volume Name|Volume Free Space|Volume Used Space|Container Total|Container Free|File System Personality"

section_end

# ============================================================
# Section 2: Homebrew
# ============================================================
section_start "Homebrew"

if command_exists brew; then
    echo "BREW_PATH: $(which brew)"
    echo "BREW_VERSION: $(brew --version 2>/dev/null | head -1)"

    FORMULA_COUNT=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    CASK_COUNT=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    echo "FORMULA_COUNT: $FORMULA_COUNT"
    echo "CASK_COUNT: $CASK_COUNT"

    echo ""
    echo "BREW_CACHE_SIZE: $(size_of "$(brew --cache 2>/dev/null)")"
    echo "BREW_CACHE_PATH: $(brew --cache 2>/dev/null)"

    echo ""
    echo "BREW_CLEANUP_DRY_RUN:"
    brew cleanup -n 2>/dev/null | tail -20

    echo ""
    echo "BREW_AUTOREMOVE_DRY_RUN:"
    brew autoremove --dry-run 2>/dev/null

    echo ""
    echo "BREW_DOCTOR_WARNINGS:"
    brew doctor 2>/dev/null | head -20
else
    echo "STATUS: NOT_INSTALLED"
fi

section_end

# ============================================================
# Section 3: Xcode / Developer Tools
# ============================================================
section_start "Developer Tools"

XCODE_DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
XCODE_ARCHIVES="$HOME/Library/Developer/Xcode/Archives"
XCODE_IOS_SUPPORT="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
XCODE_WATCHOS_SUPPORT="$HOME/Library/Developer/Xcode/watchOS DeviceSupport"
CORE_SIMULATOR="$HOME/Library/Developer/CoreSimulator"

echo "DERIVED_DATA_SIZE: $(size_of "$XCODE_DERIVED")"
echo "ARCHIVES_SIZE: $(size_of "$XCODE_ARCHIVES")"
echo "IOS_DEVICE_SUPPORT_SIZE: $(size_of "$XCODE_IOS_SUPPORT")"
echo "WATCHOS_DEVICE_SUPPORT_SIZE: $(size_of "$XCODE_WATCHOS_SUPPORT")"
echo "CORE_SIMULATOR_SIZE: $(size_of "$CORE_SIMULATOR")"
echo "DEVELOPER_DIR_TOTAL: $(size_of "$HOME/Library/Developer")"

if command_exists xcrun; then
    UNAVAIL_SIMS=$(xcrun simctl list devices unavailable 2>/dev/null | grep -c "unavailable" || echo "0")
    echo "UNAVAILABLE_SIMULATORS: $UNAVAIL_SIMS"

    SHUTDOWN_SIMS=$(xcrun simctl list devices 2>/dev/null | grep -c "Shutdown" || echo "0")
    echo "SHUTDOWN_SIMULATORS: $SHUTDOWN_SIMS"
else
    echo "XCODE_CLI: NOT_INSTALLED"
fi

# Swift Package Manager cache
SPM_CACHE="$HOME/Library/Caches/org.swift.swiftpm"
echo "SPM_CACHE_SIZE: $(size_of "$SPM_CACHE")"

# CocoaPods cache
PODS_CACHE="$HOME/Library/Caches/CocoaPods"
echo "COCOAPODS_CACHE_SIZE: $(size_of "$PODS_CACHE")"

section_end

# ============================================================
# Section 4: Package Managers (npm, pip, gem)
# ============================================================
section_start "Package Managers"

# --- npm ---
echo "--- npm ---"
if command_exists npm; then
    echo "NPM_VERSION: $(npm --version 2>/dev/null)"
    echo "NPM_GLOBAL_PACKAGES:"
    npm list -g --depth=0 2>/dev/null | tail -n +2
    echo "NPM_CACHE_SIZE: $(size_of "$HOME/.npm")"
else
    echo "NPM: NOT_INSTALLED"
fi

# --- pip ---
echo ""
echo "--- pip ---"
if command_exists pip3; then
    echo "PIP_VERSION: $(pip3 --version 2>/dev/null)"
    echo "PIP_CACHE_SIZE: $(size_of "$HOME/Library/Caches/pip")"
    echo "PIP_CACHE_INFO:"
    pip3 cache info 2>/dev/null
elif command_exists pip; then
    echo "PIP_VERSION: $(pip --version 2>/dev/null)"
    echo "PIP_CACHE_SIZE: $(size_of "$HOME/Library/Caches/pip")"
else
    echo "PIP: NOT_INSTALLED"
fi

# --- gem ---
echo ""
echo "--- gem ---"
if command_exists gem; then
    echo "GEM_DIR_SIZE: $(size_of "$HOME/.gem")"
else
    echo "GEM: NOT_INSTALLED"
fi

# --- yarn ---
echo ""
echo "--- yarn ---"
if command_exists yarn; then
    YARN_CACHE=$(yarn cache dir 2>/dev/null)
    echo "YARN_CACHE_SIZE: $(size_of "$YARN_CACHE")"
    echo "YARN_CACHE_PATH: $YARN_CACHE"
else
    echo "YARN: NOT_INSTALLED"
fi

# --- node_modules ---
echo ""
echo "NODE_MODULES_DIRS:"
echo "(Searching for node_modules in home directory, max depth 5...)"
find "$HOME" -name "node_modules" -type d -maxdepth 5 -prune 2>/dev/null | while read -r dir; do
    echo "  $(du -sh "$dir" 2>/dev/null)"
done

section_end

# ============================================================
# Section 5: Docker
# ============================================================
section_start "Docker"

if command_exists docker; then
    echo "DOCKER_VERSION: $(docker --version 2>/dev/null)"

    # Check if Docker daemon is running
    if docker info &>/dev/null; then
        echo "DOCKER_RUNNING: true"

        echo ""
        echo "DOCKER_DISK_USAGE:"
        docker system df 2>/dev/null

        echo ""
        echo "DOCKER_IMAGES:"
        docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null

        echo ""
        echo "DOCKER_CONTAINERS:"
        docker container ls -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" 2>/dev/null

        echo ""
        echo "DOCKER_VOLUMES:"
        docker volume ls 2>/dev/null

        DANGLING=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ')
        echo "DANGLING_IMAGES: $DANGLING"
    else
        echo "DOCKER_RUNNING: false (daemon not running)"
    fi
else
    echo "STATUS: NOT_INSTALLED"
fi

# Docker Desktop disk image
DOCKER_DATA="$HOME/Library/Containers/com.docker.docker/Data"
echo "DOCKER_DATA_SIZE: $(size_of "$DOCKER_DATA")"

section_end

# ============================================================
# Section 6: Caches & Logs
# ============================================================
section_start "Caches and Logs"

echo "USER_CACHES_TOTAL: $(size_of "$HOME/Library/Caches")"
echo ""
echo "TOP_CACHES_BY_SIZE:"
if [ -d "$HOME/Library/Caches" ]; then
    du -sh "$HOME/Library/Caches"/* 2>/dev/null | sort -rh | head -15
fi

echo ""
echo "USER_LOGS_TOTAL: $(size_of "$HOME/Library/Logs")"
echo ""
echo "TOP_LOGS_BY_SIZE:"
if [ -d "$HOME/Library/Logs" ]; then
    du -sh "$HOME/Library/Logs"/* 2>/dev/null | sort -rh | head -10
fi

echo ""
echo "CRASH_REPORTS_SIZE: $(size_of "$HOME/Library/Logs/DiagnosticReports")"
echo "SYSTEM_LOGS_SIZE: $(size_of "/Library/Logs")"

section_end

# ============================================================
# Section 7: Mail & Messages
# ============================================================
section_start "Mail and Messages"

echo "MAIL_SIZE: $(size_of "$HOME/Library/Mail")"
echo "MAIL_DOWNLOADS_SIZE: $(size_of "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads")"
echo "MESSAGES_SIZE: $(size_of "$HOME/Library/Messages")"

section_end

# ============================================================
# Section 8: Downloads & Trash
# ============================================================
section_start "Downloads and Trash"

echo "DOWNLOADS_SIZE: $(size_of "$HOME/Downloads")"
echo "TRASH_SIZE: $(size_of "$HOME/.Trash")"

echo ""
OLD_DOWNLOADS=$(find "$HOME/Downloads" -maxdepth 1 -type f -mtime +90 2>/dev/null | wc -l | tr -d ' ')
echo "OLD_DOWNLOADS_COUNT (>90 days): $OLD_DOWNLOADS"

echo ""
echo "OLD_DOWNLOADS_TOP10 (>90 days, largest first):"
find "$HOME/Downloads" -maxdepth 1 -type f -mtime +90 -exec du -sh {} + 2>/dev/null | sort -rh | head -10

echo ""
echo "DOWNLOADS_TOP10 (largest files):"
find "$HOME/Downloads" -maxdepth 1 -type f -exec du -sh {} + 2>/dev/null | sort -rh | head -10

section_end

# ============================================================
# Section 9: Large Files
# ============================================================
section_start "Large Files"

echo "FILES_OVER_500MB:"
echo "(Searching home directory, max depth 6, excluding known non-actionable paths...)"
find "$HOME" -type f -size +500M -maxdepth 6 \
    -not -path "*/Library/Mail/*" \
    -not -path "*/.Trash/*" \
    -not -path "*/Photos Library.photoslibrary/*" \
    -not -path "*/Music/Music/*" \
    -not -path "*/.git/objects/*" \
    -not -path "*/Library/Application Support/MobileSync/*" \
    2>/dev/null | while read -r f; do
    echo "  $(du -sh "$f" 2>/dev/null)"
done

echo ""
echo "FILES_OVER_1GB:"
find "$HOME" -type f -size +1G -maxdepth 6 \
    -not -path "*/Library/Mail/*" \
    -not -path "*/.Trash/*" \
    -not -path "*/Photos Library.photoslibrary/*" \
    -not -path "*/Music/Music/*" \
    -not -path "*/.git/objects/*" \
    -not -path "*/Library/Application Support/MobileSync/*" \
    2>/dev/null | while read -r f; do
    echo "  $(du -sh "$f" 2>/dev/null)"
done

section_end

# ============================================================
# Section 10: Time Machine
# ============================================================
section_start "Time Machine"

if command_exists tmutil; then
    echo "LOCAL_SNAPSHOTS:"
    tmutil listlocalsnapshotdates 2>/dev/null

    SNAPSHOT_COUNT=$(tmutil listlocalsnapshotdates 2>/dev/null | grep -c "^[0-9]" || echo "0")
    echo "SNAPSHOT_COUNT: $SNAPSHOT_COUNT"
else
    echo "TMUTIL: NOT_AVAILABLE"
fi

section_end

# ============================================================
# Section 11: Launch Agents & Daemons
# ============================================================
section_start "Launch Agents and Daemons"

echo "--- User Launch Agents (~/Library/LaunchAgents) ---"
if [ -d "$HOME/Library/LaunchAgents" ]; then
    for plist in "$HOME/Library/LaunchAgents"/*.plist; do
        if [ -f "$plist" ]; then
            LABEL=$(/usr/libexec/PlistBuddy -c "Print :Label" "$plist" 2>/dev/null || basename "$plist" .plist)
            PROGRAM=$(/usr/libexec/PlistBuddy -c "Print :Program" "$plist" 2>/dev/null || \
                      /usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist" 2>/dev/null || \
                      echo "unknown")
            echo "  AGENT: $LABEL | PROGRAM: $PROGRAM"
        fi
    done
else
    echo "  (directory not found)"
fi

echo ""
echo "--- System Launch Agents (/Library/LaunchAgents) ---"
if [ -d "/Library/LaunchAgents" ]; then
    for plist in /Library/LaunchAgents/*.plist; do
        if [ -f "$plist" ]; then
            LABEL=$(/usr/libexec/PlistBuddy -c "Print :Label" "$plist" 2>/dev/null || basename "$plist" .plist)
            PROGRAM=$(/usr/libexec/PlistBuddy -c "Print :Program" "$plist" 2>/dev/null || \
                      /usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist" 2>/dev/null || \
                      echo "unknown")
            echo "  AGENT: $LABEL | PROGRAM: $PROGRAM"
        fi
    done
else
    echo "  (directory not found)"
fi

echo ""
echo "--- System Launch Daemons (/Library/LaunchDaemons) ---"
if [ -d "/Library/LaunchDaemons" ]; then
    for plist in /Library/LaunchDaemons/*.plist; do
        if [ -f "$plist" ]; then
            LABEL=$(/usr/libexec/PlistBuddy -c "Print :Label" "$plist" 2>/dev/null || basename "$plist" .plist)
            PROGRAM=$(/usr/libexec/PlistBuddy -c "Print :Program" "$plist" 2>/dev/null || \
                      /usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist" 2>/dev/null || \
                      echo "unknown")
            echo "  DAEMON: $LABEL | PROGRAM: $PROGRAM"
        fi
    done
else
    echo "  (directory not found)"
fi

section_end

# ============================================================
# Section 12: Login Items
# ============================================================
section_start "Login Items"

echo "LOGIN_ITEMS:"
osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || echo "  (unable to query login items)"

section_end

# ============================================================
# Section 13: Orphaned App Data
# ============================================================
section_start "Orphaned App Data"

echo "Collecting installed app bundle IDs..."

# Collect bundle IDs from /Applications
INSTALLED_IDS=()
for app in /Applications/*.app ~/Applications/*.app; do
    if [ -d "$app" ]; then
        BID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null)
        if [ -n "$BID" ]; then
            INSTALLED_IDS+=("$BID")
        fi
    fi
done

# Also check subdirectories (e.g., /Applications/Utilities)
for app in /Applications/*/*.app; do
    if [ -d "$app" ]; then
        BID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null)
        if [ -n "$BID" ]; then
            INSTALLED_IDS+=("$BID")
        fi
    fi
done

echo "INSTALLED_APP_COUNT: ${#INSTALLED_IDS[@]}"

# Check for orphaned data in key Library directories
echo ""
echo "POTENTIALLY_ORPHANED:"

check_orphaned() {
    local dir="$1"
    local label="$2"
    if [ -d "$dir" ]; then
        for entry in "$dir"/com.*; do
            if [ -e "$entry" ]; then
                ENTRY_NAME=$(basename "$entry")
                # Check if this bundle ID matches any installed app (exact or dotted-prefix match)
                FOUND=false
                for bid in "${INSTALLED_IDS[@]}"; do
                    if [ "$ENTRY_NAME" = "$bid" ] || [[ "$ENTRY_NAME" == "${bid}."* ]]; then
                        FOUND=true
                        break
                    fi
                done
                if [ "$FOUND" = false ]; then
                    # Skip known Apple system bundle IDs
                    if ! echo "$ENTRY_NAME" | grep -qE "^com\.apple\." 2>/dev/null; then
                        SIZE=$(du -sh "$entry" 2>/dev/null | cut -f1)
                        echo "  [$label] $ENTRY_NAME ($SIZE)"
                    fi
                fi
            fi
        done
    fi
}

check_orphaned "$HOME/Library/Application Support" "App Support"
check_orphaned "$HOME/Library/Preferences" "Preferences"
check_orphaned "$HOME/Library/Containers" "Containers"
check_orphaned "$HOME/Library/Group Containers" "Group Containers"
check_orphaned "$HOME/Library/Saved Application State" "Saved State"

section_end

# ============================================================
# Summary
# ============================================================
section_start "Summary"

echo "TOTAL_HOME_DIR_SIZE: $(du -sh "$HOME" 2>/dev/null | cut -f1)"
echo ""
echo "KEY_DIRECTORY_SIZES:"
echo "  ~/Library:                $(size_of "$HOME/Library")"
echo "  ~/Library/Caches:         $(size_of "$HOME/Library/Caches")"
echo "  ~/Library/Developer:      $(size_of "$HOME/Library/Developer")"
echo "  ~/Library/Application Support: $(size_of "$HOME/Library/Application Support")"
echo "  ~/Library/Containers:     $(size_of "$HOME/Library/Containers")"
echo "  ~/Library/Mail:           $(size_of "$HOME/Library/Mail")"
echo "  ~/Downloads:              $(size_of "$HOME/Downloads")"
echo "  ~/.Trash:                 $(size_of "$HOME/.Trash")"
echo ""
echo "DISK_FREE:"
df -h / 2>/dev/null | tail -1

section_end

echo ""
echo "=== ANALYSIS COMPLETE ==="
