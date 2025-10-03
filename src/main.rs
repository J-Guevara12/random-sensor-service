mod sensor;
mod logger;

use std::thread;
use std::time::Duration;
use std::process::exit;
use signal_hook::consts::SIGTERM;
use signal_hook::iterator::Signals;
use chrono::Utc;
use std::io::Write;

fn main() {
    let mut signals = Signals::new(&[SIGTERM]).expect("Failed to create signal handler");
    let mut log_writer = logger::setup_logger();

    loop {
        if signals.pending().next().is_some() {
            let _ = writeln!(&mut log_writer, "Received SIGTERM, exiting gracefully.");
            let _ = log_writer.flush();
            break;
        }

        let now = Utc::now();
        let timestamp = now.to_rfc3339_opts(chrono::SecondsFormat::Nanos, true);

        match sensor::read_sensor("/dev/urandom") {
            Ok(value) => {
                let msg = format!("{} | 0x{:08X}", timestamp, value);
                if let Err(e) = logger::log_message(&mut log_writer, &msg) {
                    eprintln!("Log write error: {}", e);
                }
                let _ = log_writer.flush();
            }
            Err(e) => {
                eprintln!("Error reading sensor: {}", e);
                let _ = log_writer.flush();
                exit(66);
            }
        }

        thread::sleep(Duration::from_millis(500));
    }
    let _ = log_writer.flush();  // Final flush on exit
}