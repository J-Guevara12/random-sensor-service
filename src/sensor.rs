use anyhow::{Context, Result};
use std::fs::File;
use std::io::Read;

pub fn read_sensor(device_path: &str) -> Result<u32> {
    let mut file = File::open(device_path)
        .context("Failed to open device")?;
    let mut buf = [0u8; 4];
    file.read_exact(&mut buf)
        .context("Failed to read 4 bytes from device")?;
    Ok(u32::from_le_bytes(buf))
}
