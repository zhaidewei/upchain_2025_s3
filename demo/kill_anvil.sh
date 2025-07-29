#!/bin/bash

echo "🔍 Finding and killing anvil processes..."

# Method 1: Kill by process name
echo "Method 1: Kill by process name"
pkill -f anvil
echo "✅ Killed anvil processes by name"

# Method 2: Kill by port (if anvil is running on default port 8545)
echo "Method 2: Kill by port"
lsof -ti:8545 | xargs kill -9
echo "✅ Killed processes on port 8545"

# Method 3: Kill by PID if you know it
echo "Method 3: Kill by PID (if known)"
# Replace 12345 with actual PID
# kill -9 12345

# Method 4: Find and kill all anvil processes
echo "Method 4: Find and kill all anvil processes"
ps aux | grep anvil | grep -v grep | awk '{print $2}' | xargs kill -9
echo "✅ Killed all anvil processes"

# Method 5: Graceful shutdown (SIGTERM first, then SIGKILL)
echo "Method 5: Graceful shutdown"
pkill -TERM -f anvil
sleep 2
pkill -KILL -f anvil
echo "✅ Graceful shutdown completed"

echo "🎯 All anvil processes should be terminated"
