use super::*;

#[test]
fn test_parse_semver_tag_with_no_prefix() {
    let tag = "1.2.3";
    let expected = Version::parse(tag).unwrap();
    let actual = parse_semver_tag(tag).unwrap();
    assert_eq!(actual, expected);
}

#[test]
fn test_parse_semver_tag_with_v_prefix() {
    let tag = "v1.2.3";
    let expected = Version::parse("1.2.3").unwrap();
    let actual = parse_semver_tag(tag).unwrap();
    assert_eq!(actual, expected);
}

#[test]
fn test_parse_semver_tag_with_invalid_semver() {
    let tag = "a.b.3";
    let value = parse_semver_tag(tag);
    assert!(value.is_err());
}

#[test]
fn test_parse_semver_tag_with_empty_string() {
    let tag = "";
    let value = parse_semver_tag(tag);
    assert!(value.is_err());
}
