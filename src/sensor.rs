use std::fs::{File};
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{ErrorKind, Write};
    use tempfile::NamedTempFile;

    #[test]
    fn test_read_sensor_nonexistent() {
        let result = read_sensor("/nonexistent/12345");
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.kind(), ErrorKind::NotFound);
    }

    #[test]
    fn test_read_sensor_directory() {
        let dir = tempfile::TempDir::new().unwrap();
        let path = dir.path().to_str().unwrap();
        let result = read_sensor(path);
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.kind(), ErrorKind::IsADirectory);
    }

    #[test]
    fn test_read_sensor_happy_path() {
        let mut temp_file = NamedTempFile::new().unwrap();
        let test_bytes = [0x01u8, 0x02u8, 0x03u8, 0x04u8];
        temp_file.write_all(&test_bytes).unwrap();
        let path = temp_file.path().to_str().unwrap();
        let result = read_sensor(path);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), u32::from_le_bytes(test_bytes));
    }

    #[test]
    fn test_read_sensor_short_file() {
        let dir = tempfile::TempDir::new().unwrap();
        let file_path = dir.path().join("short.bin");
        std::fs::write(&file_path, [0x01u8, 0x02u8]).unwrap();  // Only 2 bytes

        let result = read_sensor(file_path.to_str().unwrap());
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert_eq!(err.kind(), ErrorKind::UnexpectedEof);
    }
}
