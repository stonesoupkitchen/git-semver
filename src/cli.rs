use std::env;

use anyhow::Result;
use clap::Parser;
use gix::commit::describe::SelectRef::AllTags;

use crate::utils::parse_semver_tag;

#[derive(Parser, Debug)]
#[command(name = "git-semver")]
#[command(version = env!("VERSION"))]
#[command(about = "Parse and print semantic version info from a Git repository.")]
pub struct Args {
    #[arg(short('x'), long("major"), help = "Increment major version.")]
    major: bool,

    #[arg(short('y'), long("minor"), help = "Increment minor version.")]
    minor: bool,

    #[arg(short('z'), long("patch"), help = "Increment patch version.")]
    patch: bool,
}

pub fn get_args() -> Result<Args> {
    let args = Args::parse();
    Ok(args)
}

pub fn run(args: Args) -> Result<()> {
    let curdir = env::current_dir().expect("failed to fetch current directory");
    let repo = gix::discover(curdir).expect("failed to locate git repo");
    let mut latest_tag = repo.head_commit()?.describe().names(AllTags);
    let mut version = parse_semver_tag(&latest_tag.format()?.to_string())?;

    if args.major {
        version = increment_major(version)
    }
    if args.minor {
        version = increment_minor(version)
    }
    if args.patch {
        version = increment_patch(version)
    }

    let major = version.major;
    let minor = version.minor;
    let patch = version.patch;

    println!("v{major}.{minor}.{patch}");
    Ok(())
}

fn increment_major(version: semver::Version) -> semver::Version {
    let mut clone = version.clone();
    clone.major += 1;
    clone.minor = 0;
    clone.patch = 0;
    clone
}

fn increment_minor(version: semver::Version) -> semver::Version {
    let mut clone = version.clone();
    clone.minor += 1;
    clone.patch = 0;
    clone
}

fn increment_patch(version: semver::Version) -> semver::Version {
    let mut clone = version.clone();
    clone.patch += 1;
    clone
}

#[cfg(test)]
#[path = "cli_test.rs"]
mod cli_test;
