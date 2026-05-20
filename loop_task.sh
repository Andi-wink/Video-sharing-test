#!/bin/bash
# Ensure cron is running
pgrep cron > /dev/null || cron

# Write hello world script
cat > /home/user/Video-sharing-test/hello_world.py << 'PYEOF'
print("Hello, World!")
PYEOF

echo "[$(date)] Loop ran: cron checked, hello_world.py written" >> /home/user/Video-sharing-test/loop.log
