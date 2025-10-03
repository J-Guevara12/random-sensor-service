# Random Sensor Service

## Overview
This is a systemd service implemented in Rust that periodically reads random u32 values from a device (default: /dev/urandom), logs them with ISO-8601 timestamps in uppercase hex to /tmp/sensor.log (with fallback to /var/tmp if unwritable), and handles SIGTERM gracefully. On sensor read failure, exits with code 66 (triggers restart if configured).

Sample log output:
```
2025-10-03T04:16:45.125651336Z | 0x233EE044
2025-10-03T04:16:51.264068578Z | 0xB72ED7AB
Received SIGTERM, exiting gracefully.
```

Service status (via `systemctl status random-sensor.service`):
```
random-sensor.service - Random Sensor Logging Service
     Loaded: loaded (/etc/systemd/system/random-sensor.service; enabled; preset: disabled)
     Active: active (running) since Fri 2025-10-03 01:15:39 -05; 1min 0s ago
   Main PID: 558826 (random-sensor-s)
      Tasks: 1 (limit: 23970)
     Memory: 1.6M (peak: 1.7M)
        CPU: 10ms
     CGroup: /system.slice/random-sensor.service
             └─558826 /usr/local/bin/random-sensor-service --interval 5 --logfile /tmp/sensor.log --device /dev/urandom
```

## Prereqs
- Rust toolchain (stable): Install via `rustup` (https://rustup.rs/)
- systemd (for service management)
- Basic CLI tools (e.g., `cargo`, `systemctl`)
- Sudo access for installation

## Clone & Build
```bash
git clone https://github.com/J-Guevara12/random-sensor-service
cd random-sensor-service
cargo build --release
```
- Binary: `target/release/random-sensor-service`
- For dev: `cargo build`

## Install & Enable
Use the provided script:
```bash
./install.sh
```
- Builds release binary, copies to `/usr/local/bin/random-sensor-service` (sudo required).
- Copies unit file to `/etc/systemd/system/random-sensor.service`.
- Enables and starts the service.
- Service runs with default: 5s interval, /tmp/sensor.log, /dev/urandom.

Manual steps (if preferred):
1. `sudo cp target/release/random-sensor-service /usr/local/bin/random-sensor-service && sudo chmod +x /usr/local/bin/random-sensor-service`
2. `sudo cp systemd/assignment-sensor.service /etc/systemd/system/random-sensor.service` (rename to match)
3. `sudo systemctl daemon-reload`
4. `sudo systemctl enable --now random-sensor.service`

## Configuration
Edit `/etc/systemd/system/random-sensor.service` (ExecStart line):
- `--interval <seconds>`: Sampling rate (default: 5; must >0)
- `--logfile <path>`: Log destination (default: /tmp/sensor.log; fallback to /var/tmp if unwritable)
- `--device <path>`: Input device (default: /dev/urandom; must be readable, >=4 bytes)

After changes: `sudo systemctl daemon-reload && sudo systemctl restart random-sensor.service`

Run manually: `./target/release/random-sensor-service --interval 10 --logfile /var/tmp/sensor.log --device /dev/urandom`

Help: `./target/release/random-sensor-service --help`

## Service Management
- Status: `sudo systemctl status random-sensor.service`
- Logs (systemd): `journalctl -u random-sensor.service -f`
- Logs (file): `tail -f /tmp/sensor.log`
- Restart: `sudo systemctl restart random-sensor.service`
- Stop: `sudo systemctl stop random-sensor.service`
- Disable: `sudo systemctl disable random-sensor.service`

On sensor error (e.g., invalid device), exits 66; service restarts due to `Restart=on-failure` (after 5s).

## Testing
### Unit Tests
`cargo test` - Covers sensor read (happy/unhappy paths), logging, CLI validation, signal handling (6 tests).

### Integration Tests
Scripts in `tests/`:
- `sigterm_test.sh`: Graceful SIGTERM, at least one read + exit message.
- `output_format_test.sh`: Validates timestamp + hex format in log file.
- `logger_edge_test.sh`: Writable/fallback logging, invalid paths (stderr).
- `interval_test.sh`: Varies --interval, counts log entries (~ proportional to 1/interval).
- `device_test.sh`: Valid device (logs values), errors (non-existing: "No such file or directory", unreadable: "Permission denied", short: "failed to fill whole buffer"; exit 66, empty log).

Run all: `./test.sh` (in project root; runs all .sh in tests/, reports PASS/FAIL).

Manual: Simulate failure by editing service device to invalid path, restart, check journalctl for exit 66 + restart.

## Uninstall
```bash
sudo systemctl stop random-sensor.service
sudo systemctl disable random-sensor.service
sudo rm /etc/systemd/system/random-sensor.service /usr/local/bin/random-sensor-service
sudo systemctl daemon-reload
```
- Cleans up; service logs persist in /tmp/sensor.log (manual rm if needed).

## Implementation Roadmap
See `roadmap.sh` for stages (completed: setup, sampler, logging, CLI; current: systemd; pending: full testing, polish).

## Additional Notes
- Security: Runs as root; consider `User=nobody` in service for non-privileged (ensure log/device access).
- Fallback: If /tmp unwritable, logs to /var/tmp/sensor.log; if both fail, stderr (view via journalctl).
- Mock sensor: 4 bytes u32 from device, little-endian hex.
- Timestamps: UTC ISO-8601 with nanoseconds (Z offset).
- Evidence: AI interactions in `ai/prompt-log.md`; reflection in `ai/reflection.md`.

See `roadmap.md` for details; run `./test.sh` to verify core functionality.
