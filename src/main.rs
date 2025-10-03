mod sensor;

use std::thread;
use std::time::Duration;
use std::process::exit;
use signal_hook::consts::SIGTERM;
use signal_hook::iterator::Signals;

fn main() {
    let mut signals = Signals::new(&[SIGTERM]).expect("Failed to create signal handler");

    loop {
        // Check for signals before reading
        if signals.pending().next().is_some() {
            println!("Received SIGTERM, exiting gracefully.");
            break;
        }

        match sensor::read_sensor("/dev/urandoma") {
            Ok(value) => println!("Read sensor value: {}", value),
            Err(e) => {eprintln!("Error reading sensor: {}", e); exit(66)},
        }

        thread::sleep(Duration::from_millis(500));
    }
}
