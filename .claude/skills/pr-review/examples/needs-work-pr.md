## Example: PR Needing Improvements

This example shows what a review looks like when issues are found and how they're communicated.

## PR Context

**URL**: https://github.com/nubank/holocron/pull/789  
**Title**: Process scheduled payments  
**Changes**: +180, -25 (5 files)

**Files Changed**:
- `src/holocron/controllers/payment.clj` (+120, -15)
- `src/holocron/adapters/payment.clj` (+30 lines)
- `src/holocron/models/payment.clj` (+15 lines)
- `src/holocron/wire/out.clj` (+15, -10)
- `test/unit/holocron/controllers/payment_test.clj` (+20 lines)

---

## Review Output

```markdown
## PR Summary

**Title**: Process scheduled payments  
**Author**: developer@nubank.com.br  
**Status**: Open  
**Changes**: +200 -50 (5 files)  
**Branch**: feature/scheduled-payments to main

**Description**:
Implements scheduled payment processing for automatic debits.

---

## Structural Analysis

### Changed Components:
- **Controllers**: payment.clj (heavily modified)
- **Adapters**: payment.clj (modified)
- **Models**: payment.clj (modified)
- **Wire**: out.clj (modified)
- **Tests**: payment_test.clj (limited new tests)

### Change Type:
New Feature

### Impact Level:
High - Payment processing critical path, multiple components touched

---

## Findings

### [CONTROLLER_LOGIC MUST]: Business logic in controller

- **Location**: controllers/payment.clj:45-78
- **Issue**: 35 lines of complex validation and calculation logic directly in controller
- **Impact**: 
  - **Unrecoverable**: Logic cannot be unit-tested without full component stack
  - **Knowledge loss**: Future maintainers cannot understand business rules from reading logic layer
  - **Brittleness**: Cannot reuse validation logic elsewhere (e.g., ETL, backfill scripts)
- **Guideline**: Diplomat Guidelines § Controllers - "Controllers must NOT contain business logic"
- **Fix**:
  ```clojure
  ;; Current (WRONG) - in controllers/payment.clj
  (defn process-payment! [components payment]
    (let [amount (:amount payment)
          tax (if (> amount 1000) (* amount 0.05) 0)
          total (+ amount tax)
          validated? (and (pos? amount) 
                         (< amount 100000)
                         (valid-account? (:account payment)))]
      (if validated?
        (db/insert! components {:amount total ...})
        (throw (ex-info "Invalid payment" {...})))))
  
  ;; Fixed - Extract to logic layer
  ;; logic/payment_validation.clj (NEW)
  (defn calculate-payment-total [payment]
    (let [amount (:amount payment)
          tax (calculate-tax amount)]
      (+ amount tax)))
  
  (defn calculate-tax [amount]
    (if (> amount 1000)
      (* amount 0.05)
      0))
  
  (defn validate-payment [payment]
    (and (pos? (:amount payment))
         (< (:amount payment) 100000)
         (valid-account? (:account payment))))
  
  ;; controllers/payment.clj (FIXED)
  (defn process-payment! [components payment]
    (if (logic/validate-payment payment)
      (let [total (logic/calculate-payment-total payment)]
        (db/insert! components (assoc payment :total total)))
      (throw (ex-info "Invalid payment" {:payment payment}))))
  ```
- **Confidence**: HIGH

---

### [SRP_VIOLATION MUST]: Controller importing adapter directly

- **Location**: controllers/payment.clj:8
- **Issue**: `(:require [holocron.adapters.payment :as payment-adapter])`
- **Impact**:
  - **Unrecoverable**: Breaks layer architecture, creates tight coupling
  - **Knowledge loss**: SRP violations compound over time as pattern spreads
  - **Brittleness**: Cannot change wire format without touching controller
- **Guideline**: Diplomat Guidelines § Component Boundaries - "Controllers MUST NOT depend on adapters"
- **Dual-Path Verification**:
  - Forward: Controller→Adapter coupling → Cannot test controller with fake wire → Brittle tests
  - Backward: For brittle tests to occur → Controller must know wire format → Requires adapter import
  - ✅ Both paths arrive at same conclusion
- **Fix**:
  ```clojure
  ;; Current (WRONG)
  (ns holocron.controllers.payment
    (:require [holocron.adapters.payment :as payment-adapter]))  ← WRONG
  
  (defn handle-payment-event! [components wire-data]
    (let [payment (payment-adapter/wire->model wire-data)]  ← WRONG
      (process-payment! components payment)))
  
  ;; Fixed - Move to consumer
  (ns holocron.diplomat.consumer
    (:require [holocron.adapters.payment :as adapters]
              [holocron.controllers.payment :as controllers]))
  
  (defn handle-payment-message [components wire-data]
    (let [payment-model (adapters/wire->model wire-data)]  ← Adapter call here
      (controllers/process-payment! components payment-model)))  ← Controller gets model
  
  ;; controllers/payment.clj (FIXED)
  (ns holocron.controllers.payment
    (:require [holocron.logic.payment-validation :as logic]))  ← No adapter import
  
  (defn process-payment! [components payment]  ← Receives model, not wire
    (if (logic/validate-payment payment)
      (save-payment! components payment)
      (throw (ex-info "Invalid payment" {:payment payment}))))
  ```
- **Confidence**: HIGH

---

### [GOD_FUNCTION SHOULD]: Function exceeds complexity limit

- **Location**: controllers/payment.clj:45-78
- **Issue**: process-payment! is 34 LOC with 7 responsibilities
- **Rule**: Functions should be ≤10 LOC (Clojure Style § Function Design)
- **Impact**: Hard to test, difficult to understand flow, violates SRP
- **Fix**: Extract smaller functions
  ```clojure
  ;; Current: One giant function (34 LOC)
  (defn process-payment! [components payment] ...)
  
  ;; Fixed: Decomposed
  (defn validate-payment! [payment] ...)      ;; 5 LOC
  (defn calculate-totals [payment] ...)       ;; 4 LOC
  (defn save-payment! [components payment] ...)  ;; 3 LOC
  (defn notify-success! [components payment] ...)  ;; 3 LOC
  
  (defn process-payment! [components payment]
    (validate-payment! payment)
    (let [totals (calculate-totals payment)]
      (-> (save-payment! components totals)
          (notify-success! components))))      ;; 4 LOC total
  ```
- **Confidence**: HIGH

---

### [INSUFFICIENT_TESTS SHOULD]: Missing test coverage for new logic

- **Location**: test/unit/holocron/controllers/payment_test.clj
- **Issue**: Only 1 test added (happy path), no edge case coverage
- **Impact**: Complex validation logic untested, regressions likely
- **Required tests**:
  ```clojure
  ;; Missing tests:
  (deftest validate-payment-test
    (testing "invalid amount - zero"
      (is (not (logic/validate-payment {:amount 0}))))
    
    (testing "invalid amount - negative"
      (is (not (logic/validate-payment {:amount -100}))))
    
    (testing "invalid amount - exceeds max"
      (is (not (logic/validate-payment {:amount 200000}))))
    
    (testing "invalid account"
      (is (not (logic/validate-payment {:amount 100 :account "invalid"})))))
  
  (deftest calculate-tax-test
    (testing "no tax for amounts ≤ 1000"
      (is (= 0 (logic/calculate-tax 1000))))
    
    (testing "5% tax for amounts > 1000"
      (is (= 50.0 (logic/calculate-tax 2000)))))
  ```
- **Confidence**: HIGH

---

### [MAGIC_NUMBER COULD]: Magic numbers without explanation

- **Location**: controllers/payment.clj:52, 54
- **Issue**: Hardcoded `1000` and `0.05` without named constants
- **Impact**: Readability, maintainability
- **Fix**:
  ```clojure
  ;; Current
  (if (> amount 1000) (* amount 0.05) 0)
  
  ;; Fixed
  (def tax-threshold-brl 1000)
  (def tax-rate 0.05)
  
  (if (> amount tax-threshold-brl)
    (* amount tax-rate)
    0)
  ```
- **Confidence**: MEDIUM

---

## Considered But Not Flagged

- **Wire schema changes in out.clj**: Appropriate - adding new fields for scheduled payments
- **Model additions**: Correct location for domain entities
- **Function naming**: Consistent with existing codebase patterns

---

## Positive Observations

✅ Clear PR description  
✅ Appropriate wire schema updates  
✅ New models in correct location  
✅ Basic happy-path test exists

---

## Recommendations

### Immediate Actions (before merge):
1. **Extract business logic to logic layer** (MUST)
2. **Remove adapter import from controller** (MUST)
3. **Decompose god function into smaller functions** (SHOULD)
4. **Add comprehensive test coverage** (SHOULD)

### Follow-up Actions (can be done after merge):
1. Replace magic numbers with named constants (COULD)
2. Add integration tests for full flow

---

## Review Verdict

**Status**: ❌ **MUST_ISSUES**

**Summary**: Found 2 MUST, 2 SHOULD, 1 COULD issues. Main concerns: 
business logic in controller (breaks testability), adapter import violates SRP 
(breaks layer separation), insufficient tests. Need changes before merge.

---

## For the Author

**Good news**: The core feature implementation is sound! The issues are architectural and refactoring-focused, not fundamental logic problems.

**Action plan**:
1. Start by extracting the validation and calculation logic to `logic/payment_validation.clj`
2. Move the adapter call from controller to consumer
3. Add the missing test cases
4. The decomposition and magic numbers can be follow-up improvements

**Expected time**: ~2-3 hours to fix MUST/SHOULD issues

Feel free to ask questions if any fix is unclear! Happy to pair on the refactoring. 💪
```

---

## Key Takeaways

**What made this review find issues**:
1. **Dual-path verification** caught the SRP violation
2. **LOC counting** flagged the god function
3. **Test coverage analysis** revealed gaps
4. **Convention checking** found magic numbers

**Communication**:
- Clear severity (MUST blocks merge)
- Specific fixes with code examples
- Constructive tone (not blaming)
- Offers to help

**Result**: Author knows exactly what to fix and why, with code examples to guide them
