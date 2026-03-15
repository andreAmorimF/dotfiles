---
description: |
  Generates comprehensive unit tests for Clojure code following Nubank's patterns 
  from cardway-client and juan-bolsa projects. Creates schema-validated tests with 
  property-based testing, realistic test data, and complete edge case coverage. 
  Analyzes existing tests to avoid duplication and generates only missing scenarios.

tags:
  - testing
  - test-generation
  - unit-tests
  - clojure
  - schema-test
  - property-based-testing
  - tdd

category: testing

invocation-triggers:
  - "generate tests"
  - "create unit tests"
  - "write tests for"
  - "need tests"
  - "test this code"
  - "add test coverage"
  - "generate test cases"

allowed-tools:
  - Shell
  - Read
  - Grep
  - Glob
  - Write

model: claude-sonnet-4-5-20250929
---

# Unit Test Generator Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Implement new logic or adapter functions
- Modify existing business logic
- Ask for test generation or coverage
- Mention needing tests
- Want to improve test coverage

## What I Do

Generate comprehensive unit tests:
- ✅ **Nubank Patterns**: Follows cardway-client/juan-bolsa conventions exactly
- ✅ **Smart Analysis**: Analyzes existing tests to avoid duplication
- ✅ **Schema Validation**: Always uses `st/deftest`, never plain `deftest`
- ✅ **Edge Cases**: Nil, empty, boundaries, invalid inputs
- ✅ **Property-Based**: Generates `defspec` tests when appropriate
- ✅ **Incremental**: Only generates missing scenarios

## Critical Nubank Patterns

### 1. Namespace Convention (MANDATORY)

**Unit test namespace does NOT include project prefix:**

```clojure
;; Source: src/holocron/logic/payment.clj
;; Test:   test/unit/logic/payment_test.clj

(ns logic.payment-test  ; ← NO holocron prefix!
  (:require [holocron.logic.payment :as logic.payment]))  ; ← Full path in require
```

### 2. Test Data as Defs (MANDATORY)

**Define test data at file top, NOT inside tests:**

```clojure
;; ✅ CORRECT - At file top
(def sample-payment
  {:id          #uuid "d963b21f-7408-42dc-b8d9-2d599fd0893b"
   :customer-id #uuid "72977038-6584-4a8f-b738-f28d79b2f086"
   :amount      10000M          ; ← BigDecimal with M
   :currency    :brl             ; ← Keyword
   :status      "pending"})      ; ← String

;; ❌ WRONG - Inside test
(deftest some-test
  (let [sample-payment {...}]  ; Don't define here!
    ...))
```

### 3. Schema Test (st/deftest) - MANDATORY

**ALWAYS use `st/deftest`, never plain `deftest`:**

```clojure
(st/deftest calculate-total-test  ; ← st/deftest!
  (testing "should calculate correct total"
    (is (= 600M result))))
```

### 4. Multiple Testing Blocks

**Group scenarios in ONE deftest with multiple testing blocks:**

```clojure
(st/deftest calculate-total-test
  (testing "should calculate correct total for valid items"
    ...)
  (testing "should return zero for empty list"
    ...)
  (testing "should handle nil input gracefully"
    ...))
```

### 5. Assertion Order

**Expected value FIRST, actual SECOND:**

```clojure
(is (= 600M result))  ; ← (= expected actual)
```

### 6. Property-Based Tests

**Use when testing pure functions:**

```clojure
(defspec calculate-total-generative-test {:num-tests 20 :max-size 5}
  (test.schema/fn-output-check-property logic.payment/calculate-total))
```

## Generation Process

### Phase 1: Establish Repository Context

1. Detect current working directory
2. Verify git repository
3. Get git repository root
4. Get repository name and branch
5. Change to git root

### Phase 2: Analyze Source File

1. **Read source file** and extract metadata
2. **Identify component type**: logic, adapter, controller, model, etc.
3. **Extract public functions** to test
4. **Analyze dependencies** for mocking strategy
5. **Identify edge cases** to cover

### Phase 3: Check for Existing Tests

1. **Determine test file path**:
   ```
   src/holocron/logic/payment.clj → test/unit/holocron/logic/payment_test.clj
   ```

2. **If test file exists**, analyze coverage:
   - Parse existing test file
   - Identify tested functions
   - Map existing test scenarios
   - Identify coverage gaps

3. **Generate gap report**:
   ```
   📊 Test Coverage Analysis
   
   Functions with Partial Coverage:
     ⚠️  calculate-total (2 tests, 4 scenarios missing)
        Missing: nil input, invalid types, boundaries
        
   Functions with No Coverage:
     ❌ process-refund (0 tests)
   ```

### Phase 4: Generate Test Code

**Generation Mode:**

**Mode A: Complete Generation** (no existing file)
- Generate full test file with all scenarios
- Include all imports, fixtures, and helpers

**Mode B: Incremental Generation** (existing file)
- Generate ONLY missing test scenarios
- Match existing code style
- Provide tests to append

**Test Structure Template:**

```clojure
(ns logic.payment-test
  (:require [clojure.test :refer [is testing]]
            [schema.test :as st]
            [matcher-combinators.test :refer [match?]]
            [holocron.logic.payment :as logic.payment]
            [clojure.test.check.clojure-test :refer [defspec]]
            [common-test.schema :as test.schema]))

;; Test Data at top
(def sample-payment {...})
(def sample-payments [...])
(def empty-payments [])

;; Tests for each function
(st/deftest function-name-test
  (testing "should {expected behavior}"
    (let [result (logic.payment/function-name input)]
      (is (= expected result))))
      
  (testing "should handle edge case"
    ...))

;; Property-based test
(defspec function-name-generative-test {:num-tests 20}
  (test.schema/fn-output-check-property logic.payment/function-name))
```

### Phase 5: Edge Cases Coverage

Generate tests for:

**Boundary Values:**
```clojure
(testing "should handle minimum value"
  (is (= expected (sut/calculate {:amount 0.01M}))))

(testing "should handle maximum value"
  (is (= expected (sut/calculate {:amount 999999999.99M}))))

(testing "should handle zero value"
  (is (= 0M (sut/calculate {:amount 0M}))))
```

**Nil/Empty Handling:**
```clojure
(testing "should handle nil input"
  (is (nil? (sut/process nil))))

(testing "should handle empty collection"
  (is (empty? (sut/process []))))
```

**Type Coercion:**
```clojure
(testing "should coerce string numbers to BigDecimal"
  (is (= 10.50M (sut/parse-amount "10.50"))))
```

### Phase 6: Output Report

**Complete Generation:**
```
✅ Unit Tests Generated (Complete Suite)

File: test/unit/logic/payment_test.clj (NEW FILE)

Coverage:
- calculate-total: 7 tests (happy path + 6 edge cases)
- valid-payment?: 5 tests (validation scenarios)

Total: 12 tests + 2 property-based tests

Edge Cases Covered:
✅ Nil/empty inputs
✅ Boundary values
✅ Type validation
✅ Invalid input handling

Next Steps:
1. Review generated tests
2. Run: lein test logic.payment-test
3. Verify all tests pass
```

**Incremental Generation:**
```
✅ Unit Tests Generated (Incremental)

File: test/unit/logic/payment_test.clj (UPDATED)

Existing Coverage Preserved:
  ✓ calculate-total: 2 tests (kept)
  ✓ valid-payment?: 1 test (kept)

New Tests Added:
  + calculate-total: 5 additional edge case tests
  + valid-payment?: 4 additional validation tests
  + process-refund: 8 tests (NEW function)

Coverage Improvement:
  Before: 3 tests covering 2 functions (37%)
  After: 20 tests covering 3 functions (94%)

Total Added: 17 new tests
```

## Test Naming Conventions

**Test names**: `{function-name}-test`
```clojure
(st/deftest calculate-total-test ...)
(st/deftest valid-payment?-test ...)
```

**Testing descriptions**: "should {expected behavior} [when {condition}]"
```clojure
(testing "should calculate correct total for valid items" ...)
(testing "should return zero for empty list" ...)
(testing "should handle nil input gracefully" ...)
```

## Common Assertion Patterns

```clojure
;; Exact match
(is (= expected actual))

;; Partial match
(match? {:key value} actual)

;; Type check
(is (uuid? result))
(is (instance? BigDecimal result))

;; Exception
(is (thrown? Exception (function-call)))

;; Collection
(is (empty? result))
(is (= 3 (count result)))
```

## Examples

### Natural Language Invocation

```
"Generate tests for payment.clj"
"I need tests for the new validation logic"
"Create test cases for my adapter"
"Add test coverage for this function"
```

### With File Context

```
User: "I just implemented calculate-discount in payment.clj"
You: [Notes the implementation]
User: "Generate tests for it"
You: [Automatically invokes this Skill]
```

## Success Criteria

Generated tests include:
- ✅ All public functions covered
- ✅ Happy path + edge cases
- ✅ Schema validation with `st/deftest`
- ✅ Property-based tests for pure functions
- ✅ Clear test descriptions ("should...")
- ✅ No duplication of existing tests

## See Examples

- **Unit Test Generation**: `examples/unit-test-example.md`

---

**For developers**: This Skill generates unit tests following Nubank patterns exactly. Complete generation with smart duplication avoidance.
