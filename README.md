# Random Sensor Service README

## Prereqs
- Rust toolchain (stable): Install via `rustup` (https://rustup.rs/)
- systemd (for service management)
- Basic CLI tools (e.g., `cargo`, `systemctl`)

## Clone & Build
```bash
git clone <repo-url>
cd 3-random-sensor-service
cargo build --release
```
- Produces binary: `target/release/assignment-sensor`
- For development: `cargo build`

## Install & Enable
1. Copy binary: `sudo cp target/release/assignment-sensor /usr/local/bin/`
2. Copy unit: `sudo cp systemd/assignment-sensor.service /etc/systemd/system/`
3. Reload: `sudo systemctl daemon-reload`
4. Enable & start: `sudo systemctl enable --now assignment-sensor.service`

## Configuration
CLI flags (via ExecStart in service file):
- `--interval <seconds>`: Sampling interval (default: 5)
- `--logfile <path>`: Log path (default: /tmp/assignment_sensor.log; fallback: /var/tmp/assignment_sensor.log)
- `--device <path>`: Sensor device (default: /dev/urandom)

Example: `./assignment-sensor --interval 10 --logfile /var/tmp/sensor.log`

## Testing
### Unit Tests (Native Rust Tooling)
- Run: `cargo test`
- Covers: sensor reading, timestamp formatting, CLI parsing, error handling.
- To run a single test: `cargo test test_name -- --exact` (e.g., `cargo test timestamp_format -- --exact`)

### Integration & Manual Tests
Use scripts in `tests/`:
1. **Happy Path**: `./tests/happy_path.sh` - Starts service, checks logs after intervals.
   Expected: Lines like `2025-10-02T12:00:00Z | 0x12345678` in log file.
2. **Fallback**: `./tests/fallback.sh` - Simulates unwritable /tmp, verifies fallback log.
3. **SIGTERM**: `./tests/sigterm.sh` - Stops service, confirms clean exit, no partial lines.
4. **Failure**: `./tests/failure.sh` - Invalid device, expects non-zero exit and error message.
5. **Restart**: Kill process; systemd should restart (if Restart=on-failure configured).

Verify service: `systemctl status assignment-sensor.service` and `journalctl -u assignment-sensor.service`

## Uninstall
1. Stop & disable: `sudo systemctl disable --now assignment-sensor.service`
2. Remove unit: `sudo rm /etc/systemd/system/assignment-sensor.service`
3. Reload: `sudo systemctl daemon-reload`
4. Remove binary: `sudo rm /usr/local/bin/assignment-sensor`

## Additional Notes
- Mock sensor: Reads 4 bytes from /dev/urandom as u32, hex-encoded.
- Logging: Line-buffered, ISO-8601 timestamps.
- Runs as root by default; adjust User= in service for non-root.
- AI-assisted: See `ai/` folder.
- Project structure: See `project_structure.md` for details.

