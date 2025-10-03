mod sensor;

fn main() {
    // Basic main loop placeholder - to be expanded
    match sensor::read_sensor("/dev/urandom") {
        Ok(value) => println!("Read value: {}", value),
        Err(e) => eprintln!("Error: {}", e),
    }
}
