---
description: |
  Intelligently execute tests based on code changes. Automatically maps source 
  files to test files, runs relevant tests, and provides failure analysis.

tags:
  - testing
  - test-execution
  - tdd
  - leiningen
  - clojure

category: testing

invocation-triggers:
  - "run tests"
  - "execute tests"
  - "test this"
  - "run my tests"
  - "test changes"
  - "check tests"
  - "tdd"

allowed-tools:
  - Shell
  - Read

required_permissions:
  - network
---

# Intelligent Test Runner Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Ask to run or execute tests
- Mention testing your changes
- Want to validate code works
- Need TDD feedback

## What I Do

Execute tests intelligently:
- ✅ **Auto-detect**: Map changed source files to tests
- ✅ **Smart selection**: Run only relevant tests
- ✅ **DynamoDB**: Start local DynamoDB if needed
- ✅ **Results**: Show pass/fail with timing
- ✅ **Analysis**: Diagnose failures if tests fail
- ✅ **Coverage**: Warn about missing tests

## Complete Execution Process

When invoked (naturally or via slash command), I execute:

### Phase 1: Repository Context Detection

1. Get current working directory
2. Verify git repository
3. Get git root, repository name, branch
4. Change to git root for all operations

### Phase 2: Determine Test Selection Strategy

**If test pattern provided:**
- Use pattern directly: `lein test pattern`
- Examples: `holocron.logic.payment-test`, `:only namespace/test-name`

**If no pattern provided:**
- Auto-detect modified source files
- Map to corresponding test files:
  - `src/holocron/logic/payment.clj` → `test/unit/holocron/logic/payment_test.clj`
  - `src/holocron/controllers/order.clj` → `test/unit/holocron/controllers/order_test.clj`
- Run tests for all changed namespaces

### Phase 3: Start Test Infrastructure

For integration tests, start DynamoDB if needed:
```bash
docker ps | grep dynamodb || docker run -d -p 8000:8000 amazon/dynamodb-local
```

### Phase 4: Execute Tests

```bash
cd "$GIT_ROOT"
lein test $TEST_PATTERN
```

### Phase 5: Analyze Results

Parse test output for:
- ✅ Passing tests
- ❌ Failing tests
- ⚠️ Warnings

**If tests fail:**
1. Show failure details
2. Analyze the error (stack trace, error message)
3. Suggest potential fixes based on:
   - Error type
   - Changed code
   - Common patterns

**If tests pass:**
```
✅ All tests passed

Ran 23 tests in 3 components:
- logic/payment: 12 tests ✅
- adapters/payment: 8 tests ✅
- controllers/payment: 3 tests ✅

Duration: 2.4s
```

### Phase 6: Coverage Check

If no tests found for changed files:
```
⚠️  Warning: No tests found for:
- src/holocron/logic/new_feature.clj

Consider adding:
- test/unit/holocron/logic/new_feature_test.clj
```

### Key Features

**As a Skill** (auto-invoked):
- I understand "test this" from conversation context
- I remember what files you've been working on
- I provide conversational test results

**As a Command** (explicit `/test-current`):
- Explicit test pattern specification
- Structured output for parsing
- Better for CI/CD pipelines

## Usage Patterns

### Natural Language Invocation

```
"Run the tests for my changes"
"Test the payment logic"
"Execute tests for what I just modified"
"Are the tests passing?"
```

### With File Context

```
User: "I just updated payment.clj"
You: [Notes the file]
User: "Run the tests"
You: [Automatically invokes this Skill]
      [Maps to test/unit/holocron/logic/payment_test.clj]
```

### TDD Workflow

```
User: "Run tests" → ❌ Fails
User: [Fixes code]
User: "Run tests again" → ✅ Passes
```

## Success Criteria

A successful test run provides:
- ✅ Clear pass/fail status
- ✅ Test counts and timing
- ✅ Failure details if tests failed
- ✅ Suggested fixes for failures
- ✅ Coverage warnings if tests missing

---

**For developers**: This Skill runs tests intelligently. Use `/test-current` for explicit control/automation.
