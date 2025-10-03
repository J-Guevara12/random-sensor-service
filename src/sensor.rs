use std::fs::File;
use std::io::{self, Read};

pub fn read_sensor(device_path: &str) -> Result<u32, io::Error> {
    let mut file = match File::open(device_path) {
        Ok(file) => file,
        Err(err) => return Err(err),
    };
    let mut buf = [0u8; 4];


    match file.read_exact(&mut buf) {
        Ok(_) => {},
        Err(err) => return Err(err),
    }

    Ok(u32::from_le_bytes(buf))
}
