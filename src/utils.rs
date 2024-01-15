use semver::Version;

pub fn parse_semver_tag(s: &str) -> Result<Version, semver::Error> {
    let to_parse = s;
    let first_char = s.chars().next();
    match first_char {
        Some(c) => {
            if c == 'v' {
                Version::parse(&to_parse[1..])
            } else {
                Version::parse(to_parse)
            }
        }
        None => Version::parse(to_parse),
    }
}

#[cfg(test)]
#[path = "utils_test.rs"]
mod utils_test;
