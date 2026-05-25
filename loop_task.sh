#!/bin/bash
set -e
REPO="/home/user/Video-sharing-test"
BRANCH="claude/happy-goldberg-x3frd"
LOG="$REPO/loop.log"
cd "$REPO"

# Ensure cron is running
service cron status > /dev/null 2>&1 || service cron start

# Run hello_world.py and log with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
OUTPUT=$(python3 "$REPO/hello_world.py" 2>&1)
echo "[$TIMESTAMP] $OUTPUT" >> "$LOG"

# Stage and commit any changes
git add -A
if ! git diff --cached --quiet; then
  git commit -m "Loop run at $TIMESTAMP: logged hello_world output"
  git push -u origin "$BRANCH"
else
  echo "[$TIMESTAMP] No changes to commit" >> "$LOG"
fi
