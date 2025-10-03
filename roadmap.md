# Roadmap for implementing the systemd service that logs mock sensor data.


## Stage 1: Project Setup
Acceptance Criteria:
- [X] Create Cargo.toml with dependencies (chrono for timestamps; clap for CLI).
- [X] Initialize src/main.rs with basic structure.
- [X] Create suggested directory structure: src/, systemd/, tests/, ai/, README.md.
- [X] Cargo.toml includes build scripts if needed.
- [X] run 'cargo build' succeeds with no errors.


## Stage 2: Core Sampler Implementation
Acceptance Criteria:
- [X] Function to read from mock sensor (e.g., /dev/urandom, read 4 bytes as u32).
- [X] Infinite loop that sleeps for configurable interval.
- [X] Handles graceful shutdown on SIGTERM (use signal-hook crate).
- [X] Exits non-zero on init errors (e.g., can't open device).


## Stage 3: Logging and Error Handling 
Acceptance Criteria:
- [X] Generate ISO-8601 timestamp using chrono.
- [X] Append log line: timestamp | value (hex or decimal).
- [X] Open log file in /tmp, fallback to /var/tmp if unwritable.
- [X] Line-buffered logging to avoid partial lines.
- [X] Handle file write errors gracefully.


## Stage 4: CLI Configuration 
Acceptance Criteria:
- [X] Use clap to parse flags: --interval <seconds> (default 5), --logfile <path> (default /tmp/sensor.log), --device <path> (default /dev/urandom).
- [X] Validate inputs (e.g., interval > 0).
- [X] Print usage/help on --help.


## Stage 5: Systemd Integration 
Acceptance Criteria:
- [X] Create systemd/assignment-sensor.service with correct ExecStart, Type=simple, Restart=on-failure.
- [X] After=multi-user.target, WantedBy=multi-user.target.
- [X] Install script or docs for copying binary and unit file.


## Stage 6: Testing 
Acceptance Criteria:
- [X] tests/ directory with scripts: happy path (start service, check logs), fallback (make /tmp unwritable), SIGTERM handling, failure (invalid device).
- [X] cargo test for unit tests if applicable (e.g., timestamp formatting, reading device).
- [X] Manual test instructions in README.


## Stage 7: Documentation and AI Evidence 
Acceptance Criteria:
- [X] README.md with prereqs, clone/build/install/uninstall/test steps.
- [ ] ai/ folder: prompt-log.md (this interaction), reflection.md, provenance.json.
- [X] Makefile or just cargo commands for one-command build.


## Stage 8: Final Polish 
Acceptance Criteria:
- [X] Run full tests.
- [X] Ensure reproducible build.
- [X] Commit to git and push.
- [X] Verify on fresh machine if possible.
