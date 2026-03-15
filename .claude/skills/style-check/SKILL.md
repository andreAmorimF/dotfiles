---
description: |
  Validate Clojure code style against Nubank's standards and community best 
  practices. Checks naming, formatting, idioms, and flags auto-fixable issues.

tags:
  - code-style
  - clojure
  - formatting
  - linting
  - idioms

category: code-quality

invocation-triggers:
  - "check style"
  - "validate style"
  - "code style"
  - "formatting issues"
  - "clojure style"
  - "style violations"
  - "lint this"

allowed-tools:
  - Read
  - Grep
---

# Clojure Code Style Check Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Ask about code style or formatting
- Mention Clojure idioms or conventions
- Want to validate naming or structure
- Need quick style feedback

## What I Do

Validate Clojure code for:
- ✅ **Naming**: lisp-case, predicates with question mark (?), side-effects with exclamation mark (!)
- ✅ **Formatting**: Indentation, alignment, threading macros
- ✅ **Idioms**: when vs if, let bindings, higher-order functions
- ✅ **Anti-patterns**: God functions, magic numbers, deep nesting
- ✅ **Auto-fixable**: Mark COULD severity for auto-fixable issues

## Complete Check Process

When invoked (naturally or via `/style-check`), I execute:

### Phase 1: Load Convention
- **Load**: `@../../conventions/clojure-style.md` - Nubank Clojure style guide

### Phase 2: Identify Files to Check
- If file specified: Check that file
- If no args: Check all modified Clojure files

### Phase 3: Validate Code Style

**Naming Conventions:**
- ✅ Functions: lisp-case (`calculate-total`)
- ✅ Predicates: end with question mark (?) (`valid?`)
- ✅ Side-effects: end with exclamation mark (!) (`save-record!`)
- ✅ Constants: SCREAMING_SNAKE_CASE (`MAX_RETRIES`)
- ✅ Schemas: UpperCamelCase (`PaymentRequest`)
- ✅ Conversion: arrow notation (`wire-to-model`)

**Formatting:**
- 2-space indentation for body forms
- Proper vertical alignment
- Threading macro usage
- No deeply nested forms (>3 levels)

**Function Design:**
- Length ≤10 lines (ideally ≤5)
- Parameters ≤4 for positional
- Proper destructuring
- No vars inside functions

**Idiomatic Patterns:**
- `when` instead of `if` with do block
- `if-let`, `when-let`, `if-some`, `when-some`
- Higher-order functions over loop/recur
- Threading macros for transformations

**Anti-Patterns:**
- God functions (too many responsibilities)
- Magic numbers/strings (should be named constants)
- Deep nesting
- Shadowing clojure.core names

### Phase 4: Report Issues

For each issue:
- **File and line** reference
- **Current code** (wrong)
- **Suggested fix** (correct)
- **Why it matters**
- **Severity**: SHOULD (style) or COULD (auto-fixable)

### Key Features

**As a Skill** (auto-invoked):
- I understand "this file" from context
- I provide educational feedback
- I suggest improvements naturally

**As a Command** (explicit `/style-check`):
- Explicit file path specification
- Terse, structured output
- Better for pre-commit hooks

## Usage Patterns

### Natural Language Invocation

```
"Is this code style ok?"
"Check the style of payment.clj"
"Any formatting issues here?"
"Does this follow Clojure conventions?"
```

### With Code Context

```
User: [Pastes code snippet]
User: "Is this idiomatic Clojure?"
You: [Automatically invokes this Skill]
```

## Success Criteria

A successful style check provides:
- ✅ Clear PASS or ISSUES_FOUND verdict
- ✅ Specific issues with line numbers
- ✅ Before/after code examples
- ✅ Auto-fixable issues marked as COULD
- ✅ Fast execution (< 3 seconds)

---

**For developers**: This Skill provides style feedback. Use `/style-check` for automation/CI integration.
