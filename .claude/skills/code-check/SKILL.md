---
description: |
  Validates all code changes in your branch against Nubank's Clojure Style Guide and 
  Diplomat Architecture. Performs comprehensive analysis of Clojure code including SRP 
  compliance, naming conventions, function design, and anti-patterns. Works offline with 
  local git diff analysis. Complete validation from repository context detection through 
  detailed findings with actionable fixes.

tags:
  - validation
  - code-quality
  - clojure
  - diplomat
  - style-check
  - architecture
  - pre-commit

category: code-quality

invocation-triggers:
  - "validate my code"
  - "check my changes"
  - "review my code"
  - "code quality check"
  - "validate branch"
  - "check style"
  - "check architecture"

allowed-tools:
  - Shell
  - Read
  - Grep
  - Glob

model: claude-sonnet-4-5-20250929
---

# Code Validation Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Ask to validate or check your code
- Want to review changes before committing
- Need architecture or style validation
- Request code quality analysis
- Mention checking your branch

## What I Do

Fast local validation of code changes:
- ✅ **Diplomat Architecture**: SRP, component boundaries, dependencies
- ✅ **Clojure Style**: Naming, formatting, idioms, anti-patterns
- ✅ **Comprehensive**: Checks all branch commits + working changes
- ✅ **Fast**: ~2-5 seconds, no network required
- ✅ **Actionable**: Specific findings with file:line and fixes

## Validation Process

### Phase 1: Repository Context Detection

**CRITICAL**: Always establish repository context FIRST.

1. Detect current working directory
2. Verify this is a git repository (exit with error if not)
3. Get git repository root path
4. Get repository name from directory
5. Get current branch name
6. Detect base branch (main or master)
7. Count commits ahead of base branch
8. Display repository context
9. Change working directory to git root

**Variables to establish:**
- `GIT_ROOT`: Repository root path
- `REPO_NAME`: Repository name
- `CURRENT_BRANCH`: Current branch name
- `BASE_BRANCH`: Base branch (main or master)
- `COMMIT_COUNT`: Number of commits ahead

**Why this matters:**
- Prevents confusion in multi-repository workspaces
- Ensures all git operations use correct repository
- Provides clear context about what's being validated

### Phase 2: Determine Validation Scope

**Default behavior (no arguments):**
- ✅ ALL commits in current branch (since diverged from main/master)
- ✅ + Uncommitted changes (working directory + staged)
- ✅ = Complete branch validation!

**Available scopes:**

| Scope | What it checks | Use case |
|-------|----------------|----------|
| *(default)* | **All branch commits + working changes** | **Pre-PR** - Complete validation |
| `--only-commits` | All branch commits (no working changes) | Pre-push check |
| `--only-working` | Only working + staged changes | Pre-commit check |
| `--last-commit` | Most recent commit only | Quick post-commit |
| `--commits N` | Last N commits only | Recent work validation |

**Available focus:**

| Focus | What it checks |
|-------|----------------|
| *(default)* | All checks |
| `--focus architecture` | Only Diplomat/SRP |
| `--focus style` | Only Clojure style |

### Phase 3: Identify Changed Files

Based on scope, identify Clojure files to validate:

**For branch-full (default):**
```bash
# Get all files changed in branch + working
BRANCH_FILES=$(git diff --name-only --diff-filter=ACM $BASE_BRANCH...HEAD | grep '\.clj$')
WORKING_FILES=$(git diff --name-only HEAD | grep '\.clj$')
CHANGED_FILES=$(echo -e "$BRANCH_FILES\n$WORKING_FILES" | sort -u | grep -v '^$')
```

**For only-working:**
```bash
# Get unstaged + staged changes
UNSTAGED=$(git diff --name-only --diff-filter=ACM | grep '\.clj$')
STAGED=$(git diff --cached --name-only --diff-filter=ACM | grep '\.clj$')
CHANGED_FILES=$(echo -e "$UNSTAGED\n$STAGED" | sort -u | grep -v '^$')
```

### Phase 4: Get Diffs for Analysis

For each changed file, get the actual diff:

```bash
for file in $CHANGED_FILES; do
  # Get appropriate diff based on scope
  case $SCOPE in
    "branch-full")
      git diff $BASE_BRANCH...HEAD -- "$file"
      git diff HEAD -- "$file"
      ;;
    "only-working")
      git diff HEAD -- "$file"
      ;;
    "last-commit")
      git diff-tree --no-commit-id -r HEAD -- "$file"
      ;;
  esac
  
  # Also read full file for context
  if [ -f "$file" ]; then
    Read "$file"
  fi
done
```

### Phase 5: Architectural Review (Diplomat Guidelines)

**Load conventions:**
- `@../../conventions/severity.md` - MUST/SHOULD/COULD definitions
- `@../../conventions/diplomat-guidelines.md` - Architecture rules

#### Component Boundary Violations (CRITICAL - SRP)

Check each component against allowed dependencies:

**Controllers** - Must ONLY know:
- ✅ ALLOWED: logic, models, diplomat/http_client, diplomat/producer, db/datomic, components, config
- ❌ FORBIDDEN: adapters, wire, diplomat/consumer

**Logic** - Must ONLY know:
- ✅ ALLOWED: models, other logic
- ❌ FORBIDDEN: components, side effects (functions with !), adapters, wire

**Adapters** - Must ONLY know:
- ✅ ALLOWED: wire, models
- ❌ FORBIDDEN: logic, controllers, components

**HTTP-Client** - Must ONLY know:
- ✅ ALLOWED: wire.in, wire.out, adapters, models, components, config
- ✅ REQUIREMENT: Functions must end with exclamation mark

**Producers** - Must receive models (NOT wire):
- ✅ ALLOWED: models, adapters, wire.out, components, config
- ❌ FORBIDDEN: Never receive wire.in directly

Flag violations with:
- File and line reference
- Actual dependency found
- Why it violates SRP
- Suggested refactoring

#### Schema & Skeleton Patterns

Verify:
- **Naming**: UpperCamelCase for schemas, kebab-case for skeletons
- **Documentation**: `:doc` attributes present and meaningful
- **Schema strictness**:
  - Use strict-schema for wire.out and models
  - Use loose schemas for wire.in
- **Skeleton notation**: Prefer skeleton over skeleton+select when possible
- **Ad-hoc schemas**: Flag inline map schemas and enums (should be named)

#### Wire Pattern Compliance

**wire.in (Tolerance):**
- Should use loose schemas
- Should only declare attributes actually used
- Should be defensive about missing/malformed data

**wire.out (Strictness):**
- Must use strict schemas
- Must specify all outgoing attributes
- Must validate data before sending

### Phase 6: Code Style Review (Clojure Style Guide)

**Load convention:**
- `@../../conventions/clojure-style.md`

#### Formatting & Indentation
- 2-space indentation for body forms
- Proper vertical alignment
- Threading macro usage (arrow operators)
- No deeply nested forms (more than 3 levels)

#### Function Design
- Function length at most 10 lines of code (ideally 5 or less)
- Parameter count 3-4 maximum for positional params
- Use of variadic parameters when appropriate
- Proper use of destructuring

#### Naming Conventions
- **lisp-case** for functions and vars: `calculate-total`
- **Predicates** end with question mark (?): `valid?`
- **Side-effect functions** end with exclamation mark (!): `save-record!`
- **Conversion functions** use arrow notation: `wire-to-model`, `model-to-docstore-entry`
- **Underscore** for unused bindings: `_`
- **No shadowing** of clojure.core names
- **Constants**: SCREAMING_SNAKE_CASE: `MAX_RETRIES`
- **Schemas**: UpperCamelCase: `PaymentRequest`

#### Idiomatic Patterns
- `when` instead of `if` with do block
- `if-let`, `when-let`, `if-some`, `when-some` where appropriate
- Higher-order functions over loop/recur
- Threading macros for nil-safe navigation
- Appropriate use of let bindings (descriptive names, logical grouping)

#### Anti-Patterns to Flag
- Vars defined inside functions
- Using delay or future in logic layer
- Multiple return types from same function
- God functions (too many responsibilities)
- Magic numbers or strings (should be named constants)
- Deep nesting (>3 levels)
- Long argument lists (>4 parameters)

### Phase 7: Severity Assignment

Use `@../../conventions/severity.md` rules:

**MUST**: Unrecoverable consequences
- Violates SRP (knowledge loss, future maintainers can't understand)
- Silent data loss (errors not handled)
- Security issues (PII exposure)
- Schema violations that cause runtime errors

**SHOULD**: Standards violations, maintainability debt
- Style guide violations (naming, formatting)
- Missing documentation
- Non-idiomatic patterns
- Technical debt

**COULD**: Auto-fixable, stylistic preferences
- Minor style improvements
- Optional optimizations
- Preference-based suggestions

**Dual-Path Verification for MUST findings:**

Before flagging any MUST severity issue, verify via two independent paths:
1. **Forward reasoning**: "If X happens, then Y, therefore Z (unrecoverable consequence)"
2. **Backward reasoning**: "For Z (unrecoverable consequence) to occur, Y must happen, which requires X"

If both paths arrive at the same unrecoverable consequence → Flag as MUST
If paths diverge → Downgrade to SHOULD and note uncertainty

### Phase 8: Generate Report

Structure the report as:

```markdown
# Code Validation Report

**Branch**: {branch-name} ({commit-count} commits since {base-branch})
**Scope**: {scope-description}
**Files Analyzed**: {count}
**Focus**: {focus-type}

---

## Summary

**Verdict**: ✅ PASS | ⚠️ WARNINGS | ❌ ISSUES

**Counts**:
- MUST issues: {count}
- SHOULD issues: {count}
- COULD improvements: {count}

---

## Changed Files

- ✅ `file1.clj` - No issues
- ⚠️ `file2.clj` - 2 SHOULD issues
- ❌ `file3.clj` - 1 MUST issue

---

## Findings

### [CATEGORY SEVERITY]: Title

**File**: `path/to/file.clj:line`

**Issue**: What is wrong (semantic description)

**Impact**: Specific unrecoverable consequence (for MUST findings)

**Guideline**: Specific section reference (e.g., "Diplomat Guidelines § Component Boundaries")

**Fix**: Concrete actionable fix with code example

**Confidence**: HIGH | MEDIUM | LOW

[Repeat for each finding, ordered by severity (MUST, SHOULD, COULD) then alphabetically]

---

## Considered But Not Flagged

[Patterns examined but determined to be non-issues, with rationale]

Examples:
- Long function in notification handler: Permitted per project pattern
- Multiple return types: Both are error types, semantically consistent

---

## Positive Observations

[Highlight good practices used in the code]

Examples:
- ✅ Clean function decomposition
- ✅ Excellent use of threading macros
- ✅ Comprehensive schema validation

---

## Recommendations

### Fix Before Commit (MUST issues):
1. [Fix critical issue 1]
2. [Fix critical issue 2]

### Fix Before Push (SHOULD issues):
1. [Refactor suggested in issue 1]
2. [Add missing tests]

### Optional Improvements (COULD):
1. [Consider architectural changes]
2. [Performance optimizations]

---

✅ **Overall**: [One sentence summary]
```

## Examples

### Natural Language Invocation

```
"Can you validate my code?"
"Check my changes before I commit"
"Review my branch for issues"
"Is my code following the style guide?"
```

### With Context

```
User: "I just refactored payment.clj"
You: [Notes the file]
User: "Check if it's okay"
You: [Automatically invokes this Skill]
```

### Combined with Other Skills

```
"Validate my code and then create commits"
→ Invokes code-check Skill + smart-commit Skill
```

## Success Criteria

A successful validation provides:
- ✅ Clear verdict (PASS/WARNINGS/ISSUES)
- ✅ Severity levels (MUST/SHOULD/COULD) correctly assigned
- ✅ Specific findings with file:line references
- ✅ Code examples showing fixes
- ✅ "Positive Observations" showing good practices
- ✅ "Considered But Not Flagged" transparency

## See Examples

- **Good Code**: `examples/good-code-example.md`
- **Issues Found**: `examples/issues-found-example.md`

---

**For developers**: This Skill validates code locally with complete logic. Fast offline validation in 2-5 seconds.
