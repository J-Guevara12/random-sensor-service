use std::io::{self, BufWriter, LineWriter, Write};
use std::io::stderr;
use std::fs::OpenOptions;
use std::path::Path;

pub type LogWriter = LineWriter<BufWriter<Box<dyn Write + Send>>>;

pub fn setup_logger(logfile: &str) -> LogWriter {
    let primary_path = Path::new(logfile);
    let fallback_path = primary_path.to_str().unwrap().replace("/tmp/", "/var/tmp/");

    let paths = vec![primary_path.to_str().unwrap(), &fallback_path];

    for path_str in paths.iter() {
        if let Ok(file) = OpenOptions::new()
            .append(true)
            .create(true)
            .write(true)
            .open(path_str) {
            let writer: Box<dyn Write + Send> = Box::new(file);
            return LineWriter::new(BufWriter::new(writer));
        }
    }

    // Fallback to stderr
    let stderr_writer: Box<dyn Write + Send> = Box::new(stderr());
    LineWriter::new(BufWriter::new(stderr_writer))
}

pub fn log_message(writer: &mut LogWriter, msg: &str) -> io::Result<()> {
    writeln!(writer, "{}", msg)?;
    writer.flush()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn test_log_message_basic() {
        let inner = Box::new(Cursor::new(Vec::<u8>::new())) as Box<dyn Write + Send>;
        let mut writer = LineWriter::new(BufWriter::new(inner));
        let result = log_message(&mut writer, "test message");
        assert!(result.is_ok());
    }

    #[test]
    fn test_setup_logger_returns_valid_writer() {
        let mut writer = setup_logger("/tmp/test.log");
        let result = log_message(&mut writer, "test setup");
        assert!(result.is_ok());
    }
}
