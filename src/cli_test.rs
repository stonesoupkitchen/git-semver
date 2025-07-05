use super::*;

struct TestCase {
    input: String,
    expected: String,
}

#[test]
fn test_increment_major() {
    let test_cases = vec![
        TestCase {
            input: String::from("1.2.3"),
            expected: String::from("2.0.0"),
        },
        TestCase {
            input: String::from("0.1.0"),
            expected: String::from("1.0.0"),
        },
        TestCase {
            input: String::from("99.0.0"),
            expected: String::from("100.0.0"),
        },
    ];

    for case in test_cases {
        let input = semver::Version::parse(case.input.as_str()).expect("failed to parse version");
        let expected = semver::Version::parse(case.expected.as_str()).expect("failed to parse version");
        let result = increment_major(input);
        assert_eq!(result, expected)
    }
}

#[test]
fn test_increment_minor() {
    let test_cases = vec![
        TestCase {
            input: String::from("1.2.3"),
            expected: String::from("1.3.0"),
        },
        TestCase {
            input: String::from("0.1.0"),
            expected: String::from("0.2.0"),
        },
        TestCase {
            input: String::from("99.0.0"),
            expected: String::from("99.1.0"),
        },
    ];

    for case in test_cases {
        let input = semver::Version::parse(case.input.as_str()).expect("failed to parse version");
        let expected = semver::Version::parse(case.expected.as_str()).expect("failed to parse version");
        let result = increment_minor(input);
        assert_eq!(result, expected)
    }
}

#[test]
fn test_increment_patch() {
    let test_cases = vec![
        TestCase {
            input: String::from("1.2.3"),
            expected: String::from("1.2.4"),
        },
        TestCase {
            input: String::from("0.1.0"),
            expected: String::from("0.1.1"),
        },
        TestCase {
            input: String::from("99.0.0"),
            expected: String::from("99.0.1"),
        },
    ];

    for case in test_cases {
        let input = semver::Version::parse(case.input.as_str()).expect("failed to parse version");
        let expected = semver::Version::parse(case.expected.as_str()).expect("failed to parse version");
        let result = increment_patch(input);
        assert_eq!(result, expected)
    }
}
