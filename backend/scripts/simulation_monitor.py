#!/usr/bin/env python3
"""
Simulation monitor - runs every 30 minutes via cron
Checks simulation status and logs progress with ETA
"""
import json
import sys
import subprocess
import time
from datetime import datetime

SIM_ID = "sim_8ce2d60344c4"
API_URL = f"http://localhost:5001/api/simulation/{SIM_ID}/run-status"
LOG_FILE = "/home/manitouabe8ich/MiroFish/backend/logs/simulation_monitor.log"
TOTAL_ROUNDS = 168

def fetch_status():
    """Fetch simulation status from API."""
    try:
        result = subprocess.run(
            ["curl", "-s", "-m", "10", f"http://localhost:5001/api/simulation/sim_8ce2d60344c4/run-status"],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0:
            return None
        return json.loads(result.stdout)
    except (json.JSONDecodeError, subprocess.TimeoutExpired, Exception):
        return None

def log_progress(data):
    """Log progress with ETA calculation."""
    if not data or "data" not in data:
        return
    
    data = data.get("data", {})
    current_round = data.get("current_round", 0)
    twitter_round = data.get("twitter_current_round", 0)
    reddit_round = data.get("reddit_current_round", 0)
    twitter_actions = data.get("twitter_actions_count", 0)
    reddit_actions = data.get("reddit_actions_count", 0)
    total_actions = data.get("total_actions_count", 0)
    progress = data.get("progress_percent", 0)
    started_at = data.get("started_at", "")
    
    TOTAL_ROUNDS = 168
    
    # Calculate elapsed minutes
    elapsed = 0
    if started_at:
        try:
            start_dt = datetime.fromisoformat(started_at.replace('Z', '+00:00'))
            now = datetime.now()
            elapsed = (now - start_dt).total_seconds() / 60
        except:
            elapsed = 0
    
    # Calculate ETA
    if current_round > 0 and elapsed > 0:
        pace = elapsed / current_round
        remaining_rounds = TOTAL_ROUNDS - current_round
        remaining_min = pace * remaining_rounds
        eta_ts = time.time() + (remaining_min * 60)
        eta_str = datetime.fromtimestamp(eta_ts).strftime('%H:%M')
        pace_str = f"{pace:.1f} min/round"
        remaining_str = f"{remaining_min:.0f} min"
        eta_display = f"{pace_str} | {remaining_str} remaining | ETA: {eta_str}"
    else:
        eta_display = "calculating..."
    
    # Log entry
    log_entry = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Round: {current_round}/168 ({progress:.1f}%) | Twitter: {data.get('twitter_current_round', 0)} | Reddit: {data.get('reddit_current_round', 0)} | Actions: {data.get('total_actions_count', 0)} | Pace: {eta_display}"
    
    with open("/home/manitouabe8ich/MiroFish/backend/logs/simulation_monitor.log", "a") as f:
        f.write(log_entry + "\n")
    
    print(log_entry)

def main():
    data = fetch_status()
    if data and data.get("success"):
        log_progress(data)
    else:
        with open("/home/manitouabe8ich/MiroFish/backend/logs/simulation_monitor.log", "a") as f:
            f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - ERROR: Failed to fetch simulation status\n")
        sys.exit(1)

if __name__ == "__main__":
    main()