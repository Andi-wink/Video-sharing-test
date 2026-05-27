#!/bin/bash
set -e
REPO="/home/user/Video-sharing-test"
BRANCH="claude/happy-goldberg-wnDXj"
LOG="$REPO/loop.log"
cd "$REPO"

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  OUTPUT=$(python3 "$REPO/hello_world.py" 2>&1)
  echo "[$TIMESTAMP] $OUTPUT" >> "$LOG"
  echo "[$TIMESTAMP] $OUTPUT"

  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "Loop run at $TIMESTAMP: logged hello_world output"
    git push -u origin "$BRANCH"
  else
    echo "[$TIMESTAMP] No changes to commit" >> "$LOG"
    echo "[$TIMESTAMP] No changes to commit"
  fi

  sleep 1800
done
