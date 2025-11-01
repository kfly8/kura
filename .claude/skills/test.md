---
description: Run the full test suite for the Kura module
tags: [testing, perl, development]
---

# Run Kura Test Suite

Run the complete test suite for the Kura Perl module, including build setup and all tests.

## Instructions

1. Run `perl Build.PL` to generate the build configuration
2. Run `./Build` to build the module
3. Run `./Build test` to execute all tests
4. Report the test results to the user, including:
   - Number of tests run
   - Number of tests passed/failed
   - Any errors or warnings
   - Summary of test coverage

## Options

If the user specifies `--coverage` or mentions coverage:
1. Install Devel::Cover if needed: `cpm install -g Devel::Cover::Report::Coveralls`
2. Run tests with coverage: `cover -test -report html`
3. Report coverage statistics

If the user specifies `--integration` or mentions integration tests:
1. Install integration test dependencies: `cpm install -g Data::Checks Type::Tiny Moose Mouse Moo Specio MooseX::Types Exporter::Tiny Valiant Poz Data::Validator`
2. Run the full test suite including integration tests

## Expected Output

Provide a clear summary of:
- Build status
- Test results (pass/fail count)
- Any failures with details
- Performance metrics if available
