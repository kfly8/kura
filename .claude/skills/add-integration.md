---
description: Add integration test support for a new constraint library
tags: [testing, integration, perl, development]
---

# Add Integration Test for New Constraint Library

Add integration test support for a new type constraint library to the Kura module.

## Instructions

The user will specify the name of the constraint library to add support for.

1. **Examine existing integration tests** in `t/10-integration/` to understand the pattern:
   - Look at an existing integration directory (e.g., `Type-Tiny/`, `Moose/`)
   - Each integration has a Test module and a basic.t test file

2. **Create directory structure**:
   - Create `t/10-integration/[LibraryName]/`
   - Replace `[LibraryName]` with the appropriate directory name (using hyphens for separators)

3. **Create Test module** (`Test[LibraryName].pm`):
   - Define constraint declarations using the library
   - Use `kura` to manage the constraints
   - Include example constraints that demonstrate library features
   - Follow the pattern from existing integrations

4. **Create basic test** (`basic.t`):
   - Import and test the constraints defined in Test module
   - Test constraint validation (both valid and invalid inputs)
   - Use Test2::V0 for test framework
   - Include proper test plan and structure

5. **Verify the integration**:
   - Ensure the library is available (check with `perl -M[LibraryName] -e 1`)
   - Run the new integration test
   - Fix any issues that arise

6. **Update documentation** if needed:
   - Add the library to README.md integration list
   - Update any relevant documentation

## Pattern to Follow

Based on existing integrations, create files matching this structure:

```
t/10-integration/[LibraryName]/
├── Test[LibraryName].pm    # Constraint definitions
└── basic.t                 # Test cases
```

Example Test module structure:
```perl
package Test[LibraryName];
use strict;
use warnings;
use kura;

# Define constraints here
kura Constraint1 => ...;
kura Constraint2 => ...;

1;
```

Example basic.t structure:
```perl
use Test2::V0;

BEGIN {
    eval { require [LibraryName]; 1 }
        or plan skip_all => '[LibraryName] required';
}

use Test[LibraryName] qw(Constraint1 Constraint2);

# Test valid inputs
ok Constraint1->check($valid_input);

# Test invalid inputs
ok !Constraint1->check($invalid_input);

done_testing;
```

## Expected Output

- New integration test directory created
- Test module implemented
- Basic test file created
- Tests pass successfully
- Summary of what was created
