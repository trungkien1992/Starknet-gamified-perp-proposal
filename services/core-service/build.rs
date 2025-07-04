use std::env;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // ---
    // PROTO PATH CONVENTION:
    // - Set PROTO_DIR env var to the directory containing your proto files.
    //   - In Docker: ENV PROTO_DIR=/app/proto
    //   - Locally: defaults to "proto" (relative to crate root)
    // - This avoids fragile relative paths and works in all environments.
    // ---
    let proto_dir = env::var("PROTO_DIR").unwrap_or_else(|_| "../../proto".to_string());
    println!("[build.rs] Raw proto_dir: {}", proto_dir);
    let proto_dir_abs = match PathBuf::from(&proto_dir).canonicalize() {
        Ok(path) => {
            println!("[build.rs] Canonicalized proto_dir: {:?}", path);
            path
        },
        Err(e) => {
            eprintln!("[build.rs] Failed to canonicalize proto_dir: {} | Error: {}", proto_dir, e);
            return Err(Box::new(e));
        }
    };
    let proto_file_abs = proto_dir_abs.join("core.proto");
    println!("[build.rs] Using proto_file_abs: {:?}", proto_file_abs);
    if !proto_file_abs.exists() {
        eprintln!("[build.rs] ERROR: proto_file_abs does not exist: {:?}", proto_file_abs);
        return Err(From::from("core.proto file does not exist at expected location"));
    }
    match tonic_build::configure()
        .build_server(true)
        .out_dir(env::var("OUT_DIR")?)
        .compile(&[proto_file_abs.clone()], &[proto_dir_abs.clone()]) {
        Ok(_) => println!("[build.rs] tonic_build completed successfully."),
        Err(e) => {
            eprintln!("[build.rs] tonic_build failed. proto_file_abs: {:?}, proto_dir_abs: {:?}", proto_file_abs, proto_dir_abs);
            eprintln!("[build.rs] Error: {}", e);
            return Err(e.into());
        }
    }
    Ok(())
}