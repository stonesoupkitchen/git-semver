use std::env;

fn main() {
    let git_commit = env::var("GIT_COMMIT").unwrap_or("".into());
    let git_sha = env::var("GIT_SHA").unwrap_or("".into());
    let git_branch = env::var("GIT_BRANCH").unwrap_or("".into());
    let version = env::var("BINARY_VERSION").unwrap_or(env!("CARGO_PKG_VERSION").into());
    println!("cargo:rustc-env=GIT_COMMIT={}", git_commit);
    println!("cargo:rustc-env=GIT_SHA={}", git_sha);
    println!("cargo:rustc-env=GIT_BRANCH={}", git_branch);
    println!("cargo:rustc-env=VERSION={}", version);
}
