mod sensor;
mod logger;

use clap::Parser;
use std::thread;
use std::time::Duration;
use std::process::exit;
use signal_hook::consts::SIGTERM;
use signal_hook::iterator::Signals;
use chrono::Utc;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long, default_value = "5")]
    interval: u64,

    #[arg(long, default_value = "/tmp/random_sensor.log")]
    logfile: String,

    #[arg(long, default_value = "/dev/urandom")]
    device: String,
}

fn main() {
    let args = Args::parse();

    if args.interval == 0 {
        eprintln!("Error: --interval must be greater than 0");
        std::process::exit(1);
    }

    let mut signals = Signals::new(&[SIGTERM]).expect("Failed to create signal handler");
    let mut log_writer = logger::setup_logger(&args.logfile);

    loop {
        if signals.pending().next().is_some() {
            let _ = logger::log_message(&mut log_writer, "Received SIGTERM, exiting gracefully.");
            break;
        }

        let now = Utc::now();
        let timestamp = now.to_rfc3339_opts(chrono::SecondsFormat::Nanos, true);

        match sensor::read_sensor(&args.device) {
            Ok(value) => {
                let msg = format!("{} | 0x{:08X}", timestamp, value);
                let _ = logger::log_message(&mut log_writer, &msg);
            }
            Err(e) => {
                eprintln!("Error reading sensor: {}", e);
                let _ = logger::log_message(&mut log_writer, &format!("{} | Sensor error: {}", timestamp, e));
                exit(66);
            }
        }

        thread::sleep(Duration::from_secs(args.interval));
    }
}
