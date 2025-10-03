#!/bin/bash

set -e

# Install script for Random Sensor Service

echo "Building and installing..."

# Build release binary
cargo build --release

# Copy binary to /usr/local/bin (requires sudo)
sudo cp target/release/random-sensor-service /usr/local/bin/
sudo chmod +x /usr/local/bin/random-sensor-service

# Copy service file
sudo cp systemd/random-sensor.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable random-sensor.service
sudo systemctl start random-sensor.service

echo "Installation complete! Service enabled and started."
echo "Check status: sudo systemctl status random-sensor.service"
echo "Logs: tail -f /tmp/sensor.log"
echo "To stop/uninstall: sudo systemctl stop random-sensor.service && sudo systemctl disable random-sensor.service && sudo rm /usr/local/bin/random-sensor-service /etc/systemd/system/random-sensor.service && sudo systemctl daemon-reload"
