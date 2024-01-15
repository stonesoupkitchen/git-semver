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
    let curdir = env::current_dir()?;
    let repo = gix::discover(curdir)?;
    let mut latest_tag = repo.head_commit()?.describe().names(AllTags);
    let version = parse_semver_tag(&latest_tag.format()?.to_string())?;

    let major = if args.major {
        version.major + 1
    } else {
        version.major
    };
    let minor = if args.minor {
        version.minor + 1
    } else {
        version.minor
    };
    let patch = if args.patch {
        version.patch + 1
    } else {
        version.patch
    };

    println!("v{}.{}.{}", major, minor, patch);
    Ok(())
}
