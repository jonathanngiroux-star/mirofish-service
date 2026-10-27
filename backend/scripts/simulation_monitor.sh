#!/bin/bash
# Simulation monitor - runs every 30 minutes via cron
# Checks simulation status and logs progress with ETA

SIM_ID="sim_8ce2d60344c4"
API_URL="http://localhost:5001/api/simulation/${SIM_ID}/run-status"
LOG_FILE="/home/manitouabe8ich/MiroFish/backend/logs/simulation_monitor.log"
START_TIME="2026-10-20T14:46:55.516678"
TOTAL_ROUNDS=168

# Function to calculate ETA
calculate_eta() {
    local current_round=$1
    local elapsed_minutes=$2
    local total_rounds=$3
    
    if [ "$current_round" -gt 0 ]; then
        local pace=$(echo "scale=2; $elapsed_minutes / $current_round" | bc -l)
        local remaining=$((TOTAL_ROUNDS - current_round))
        local remaining_minutes=$(echo "scale=0; $pace * $remaining" | bc -l)
        local eta_epoch=$(date -d "+ ${remaining_minutes} minutes" +%s 2>/dev/null || date -v+${remaining_minutes}M +%s 2>/dev/null)
        local eta_str=$(date -d "@${eta_epoch}" "+%H:%M" 2>/dev/null || date -r "${eta_epoch}" "+%H:%M" 2>/dev/null)
        echo "${pace} min/round | ${remaining_minutes} min remaining | ETA: ${eta_str}"
    else
        echo "calculating..."
    fi
}

# Fetch status
RESPONSE=$(curl -s -m 10 "http://localhost:5001/api/simulation/sim_8ce2d60344c4/run-status" 2>/dev/null)

if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | grep -q "success.*true"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Failed to fetch simulation status" >> "$LOG_FILE"
    exit 1
fi

# Parse JSON (using python for reliable parsing)
python3 << 'EOF'
import json
import sys
from datetime import datetime

response = json.loads("""$RESPONSE""")
data = response.get("data", {})

current_round = data.get("current_round", 0)
twitter_round = data.get("twitter_current_round", 0)
reddit_round = data.get("reddit_current_round", 0)
twitter_actions = data.get("twitter_actions_count", 0)
reddit_actions = data.get("reddit_actions_count", 0)
total_actions = data.get("total_actions_count", 0)
progress = data.get("progress_percent", 0)
started_at = data.get("started_at", "")
updated_at = data.get("updated_at", "")

total_rounds = 168
remaining = 168 - round(current_round)

# Calculate elapsed minutes
if started_at:
    try:
        start_dt = datetime.fromisoformat(started_at.replace('Z', '+00:00'))
        now = datetime.now()
        elapsed = (now - start_dt).total_seconds() / 60
    except:
        elapsed = 0
else:
    elapsed = 0

# Calculate ETA
if current_round > 0 and elapsed > 0:
    pace = elapsed / current_round
    remaining_rounds = 168 - current_round
    remaining_min = pace * remaining_rounds
    import time
    eta_ts = time.time() + (remaining_min * 60)
    eta_str = datetime.fromtimestamp(eta_ts).strftime('%H:%M')
    pace_str = f"{pace:.1f} min/round"
    remaining_str = f"{remaining_min:.0f} min"
    eta_display = f"{pace_str} | {remaining_str} remaining | ETA: {eta_str}"
else:
    eta_display = "calculating..."

# Log entry
log_entry = f"$(date '+%Y-%m-%d %H:%M:%S') | Round: {current_round}/168 ({progress:.1f}%) | Twitter: {twitter_round} | Reddit: {reddit_round} | Actions: {total_actions} | Pace: {eta_display}"

with open("/home/manitouabe8ich/MiroFish/backend/logs/simulation_monitor.log", "a") as f:
    f.write(log_entry + "\n")

print(log_entry)
EOF