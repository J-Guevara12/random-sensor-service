mod sensor;

use std::thread;
use std::time::Duration;
use std::process::exit;
use signal_hook::consts::SIGTERM;
use signal_hook::iterator::Signals;
use chrono::{Utc};

fn main() {
    let mut signals = Signals::new(&[SIGTERM]).expect("Failed to create signal handler");

    loop {
        // Check for signals before reading
        if signals.pending().next().is_some() {
            println!("Received SIGTERM, exiting gracefully.");
            break;
        }

        let now = Utc::now();
        let timestamp = now.to_rfc3339();


        match sensor::read_sensor("/dev/urandom") {
            Ok(value) => println!("{} | 0x{:X}", timestamp, value),
            Err(e) => {eprintln!("Error reading sensor: {}", e); exit(66)},
        }

        thread::sleep(Duration::from_millis(500));
    }
}
