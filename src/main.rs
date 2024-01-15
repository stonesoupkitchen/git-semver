fn main() {
    if let Err(e) = git_semver::cli::get_args().and_then(git_semver::cli::run) {
        eprintln!("{}", e);
        std::process::exit(1);
    }
}
