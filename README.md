# git-semver

A CLI tool for determining the latest tag on a Git repository.

## Usage

Print the current semantic version of the repository with:

    git semver

Increment and print the semantic version with:

    git semver [-x|--major]
    git semver [-y|--minor]
    git semver [-z|--patch]

Use this tool in tandem with other release tools to release new
git tags like so:

    git tag $(git semver --patch)

## Building

A Makefile is provided for convenience, but it's not strictly necessary.

Build a release binary with

    make

or

    cargo build --release


In the former, tests will also be run.

## License

See [LICENSE](./LICENSE).

