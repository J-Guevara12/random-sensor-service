use std::io::{self, BufWriter, LineWriter, Write};
use std::io::stderr;
use std::fs::OpenOptions;

pub type LogWriter = LineWriter<BufWriter<Box<dyn Write + Send>>>;

pub fn setup_logger() -> LogWriter {
    let paths = ["/tmp/random_sensor.log", "/var/tmp/random_sensor.log"];

    for path in paths.iter() {
        if let Ok(file) = OpenOptions::new()
            .append(true)
            .create(true)
            .write(true)
            .open(path) {
            let writer: Box<dyn Write + Send> = Box::new(file);
            return LineWriter::new(BufWriter::new(writer));
        }
    }

    // Fallback to stderr
    let stderr_writer: Box<dyn Write + Send> = Box::new(stderr());
    LineWriter::new(BufWriter::new(stderr_writer))
}

pub fn log_message(writer: &mut LogWriter, msg: &str) -> io::Result<()> {
    writeln!(writer, "{}", msg)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn test_log_message_basic() {
        let inner_vec: Vec<u8> = Vec::new();
        let inner = Box::new(Cursor::new(inner_vec)) as Box<dyn Write + Send>;
        let mut writer = LineWriter::new(BufWriter::new(inner));

        let result = log_message(&mut writer, "test message");
        assert!(result.is_ok());

        // To verify, we'd need to extract the buffer, but for unit test, check no error
        // Actual output verification can be in integration tests
    }

    #[test]
    fn test_setup_logger_returns_valid_writer() {
        let mut writer = setup_logger();
        let result = log_message(&mut writer, "test setup");
        assert!(result.is_ok(), "Setup logger should provide writable output");
    }
}
