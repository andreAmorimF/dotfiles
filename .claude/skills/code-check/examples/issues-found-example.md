# Code Validation Example: Issues Found ⚠️

This example shows code with various issues that need fixing.

## Code with Issues

```clojure
(ns holocron.controllers.payment
  (:require [holocron.logic.payment :as logic]
            [holocron.adapters.payment :as adapter]  ; ❌ Controller importing adapter!
            [holocron.wire.payment :as wire]))        ; ❌ Controller importing wire!

(def maxAmount 100000)  ; ❌ camelCase, should be MAX_AMOUNT

(defn processPayment [request]  ; ❌ camelCase, missing !
  (let [amount (get-in request [:payment :amount])]
    (if (> amount maxAmount)  ; ❌ Magic number
      (do  ; ❌ Use 'when' instead of 'if' with 'do'
        (log/error "Amount too high")
        {:error "invalid"})
      (if (valid-payment? request)  ; ❌ Nested if (use cond)
        (do
          (db/save! request)  ; ❌ Side effect in controller without proper error handling
          {:status "ok"})
        {:error "invalid"}))))

(defn calculate  ; ❌ Vague name
  [x]  ; ❌ Non-descriptive parameter
  (delay  ; ❌ Using delay in logic (should be in component)
    (* x 0.05)))  ; ❌ Magic number
```

## Validation Output

```
# Code Validation Report

**Branch**: feature/payment-refactor (2 commits since main)
**Scope**: All branch commits + working changes
**Files Analyzed**: 1
**Focus**: All (architecture + style)

---

## Summary

**Verdict**: ❌ MUST_ISSUES

**Counts**:
- MUST issues: 2
- SHOULD issues: 4
- COULD improvements: 3

---

## Changed Files

- ❌ `src/holocron/controllers/payment.clj` - 2 MUST, 4 SHOULD, 3 COULD issues

---

## Findings

### [ARCHITECTURE MUST]: Controller importing adapter/wire violates SRP

**File**: `src/holocron/controllers/payment.clj:3-4`

**Issue**: Controller is directly importing adapters and wire schemas

**Impact**: Violates Diplomat Architecture SRP. Controllers should only orchestrate, not do data transformation. This creates tight coupling and makes testing difficult.

**Guideline**: Diplomat Guidelines § Component Boundaries

**Fix**:
```clojure
;; ❌ WRONG - Controller importing adapter/wire
(ns holocron.controllers.payment
  (:require [holocron.logic.payment :as logic]
            [holocron.adapters.payment :as adapter]  ; ← Remove this
            [holocron.wire.payment :as wire]))       ; ← Remove this

;; ✅ CORRECT - Controller only knows logic and models
(ns holocron.controllers.payment
  (:require [holocron.logic.payment :as logic]
            [holocron.models.payment :as model]
            [holocron.diplomat.http-client :as http-client]))
```

**Confidence**: HIGH

---

### [ERROR_HANDLING MUST]: Database operation without error handling

**File**: `src/holocron/controllers/payment.clj:16`

**Issue**: `db/save!` can fail but error is not handled

**Impact**: If database write fails, user gets "ok" response but data isn't saved. Silent data loss. No way to recover or detect this from logs.

**Guideline**: Diplomat Guidelines § Error Handling

**Fix**:
```clojure
;; ❌ WRONG - No error handling
(db/save! request)
{:status "ok"}

;; ✅ CORRECT - Explicit error handling
(try
  (db/save! request)
  {:status "ok"}
  (catch Exception e
    (log/error e "Failed to save payment")
    {:error "database-error" :retry true}))
```

**Confidence**: HIGH

---

### [NAMING SHOULD]: Function name not idiomatic

**File**: `src/holocron/controllers/payment.clj:7`

**Issue**: Function `processPayment` uses camelCase and missing exclamation mark (!) for side effect

**Guideline**: Clojure Style § Naming Conventions

**Fix**:
```clojure
;; ❌ WRONG
(defn processPayment [request]
  ...)

;; ✅ CORRECT
(defn process-payment! [request]
  ...)
```

**Confidence**: HIGH

---

### [NAMING SHOULD]: Constant not in SCREAMING_SNAKE_CASE

**File**: `src/holocron/controllers/payment.clj:6`

**Issue**: Constant `maxAmount` should be `MAX_AMOUNT`

**Guideline**: Clojure Style § Naming Conventions

**Fix**:
```clojure
;; ❌ WRONG
(def maxAmount 100000)

;; ✅ CORRECT
(def MAX_AMOUNT 100000)
```

**Confidence**: HIGH

---

### [IDIOM SHOULD]: Using 'if' with 'do' block

**File**: `src/holocron/controllers/payment.clj:9-12`

**Issue**: Using `(if ... (do ...))` when `when` is more idiomatic

**Guideline**: Clojure Style § Idiomatic Patterns

**Fix**:
```clojure
;; ❌ WRONG
(if (> amount maxAmount)
  (do
    (log/error "Amount too high")
    {:error "invalid"})
  ...)

;; ✅ CORRECT
(when (> amount MAX_AMOUNT)
  (log/error "Amount too high")
  {:error "invalid"})
```

**Confidence**: HIGH

---

### [IDIOM SHOULD]: Nested if statements

**File**: `src/holocron/controllers/payment.clj:13-18`

**Issue**: Nested `if` statements should use `cond` for clarity

**Guideline**: Clojure Style § Idiomatic Patterns

**Fix**:
```clojure
;; ❌ WRONG
(if condition1
  (do ...)
  (if condition2
    (do ...)
    {...}))

;; ✅ CORRECT
(cond
  condition1 (do ...)
  condition2 (do ...)
  :else {...})
```

**Confidence**: HIGH

---

### [ANTI-PATTERN COULD]: Magic number

**File**: `src/holocron/controllers/payment.clj:8`

**Issue**: Magic number `100000` should be named constant

**Guideline**: Clojure Style § Anti-Patterns

**Fix**:
```clojure
;; ❌ WRONG
(if (> amount 100000)
  ...)

;; ✅ CORRECT
(def MAX_PAYMENT_AMOUNT 100000)

(if (> amount MAX_PAYMENT_AMOUNT)
  ...)
```

**Confidence**: MEDIUM

---

### [NAMING COULD]: Vague function name

**File**: `src/holocron/controllers/payment.clj:20`

**Issue**: Function name `calculate` is too vague

**Guideline**: Clojure Style § Naming Conventions

**Fix**:
```clojure
;; ❌ WRONG
(defn calculate [x]
  (* x 0.05))

;; ✅ CORRECT
(defn calculate-fee [amount]
  (* amount FEE_PERCENTAGE))
```

**Confidence**: MEDIUM

---

### [ANTI-PATTERN COULD]: Using delay in logic layer

**File**: `src/holocron/controllers/payment.clj:22`

**Issue**: `delay` should be in component layer, not in logic

**Guideline**: Diplomat Guidelines § Component Layers

**Fix**: Move `delay` usage to component initialization

**Confidence**: MEDIUM

---

## Considered But Not Flagged

- Long function in processPayment: Actual business complexity justifies length
- Multiple return types: All are maps with consistent error structure
- Parameter name `request`: Standard convention for HTTP handlers

---

## Recommendations

### Fix Before Commit (MUST issues):
1. Remove adapter/wire imports from controller
2. Add error handling to db/save! operation

### Fix Before Push (SHOULD issues):
1. Rename processPayment to process-payment!
2. Rename maxAmount to MAX_AMOUNT
3. Replace if+do with when
4. Replace nested if with cond

### Optional Improvements (COULD):
1. Extract magic numbers to named constants
2. Rename calculate to calculate-fee
3. Move delay to component layer

---

✅ **After fixes, re-run**: `/code-check --only-working`
```

## Summary of Issues

| Severity | Count | Must Fix? |
|----------|-------|-----------|
| MUST | 2 | ✅ Before commit |
| SHOULD | 4 | ✅ Before push |
| COULD | 3 | Optional |

## Main Problems

1. **Architecture Violation**: Controller importing adapters/wire (MUST fix)
2. **Silent Failures**: No error handling on database operations (MUST fix)
3. **Naming Issues**: camelCase, missing exclamation mark (!) for side effects (SHOULD fix)
4. **Clojure Idioms**: Not using `when`, nested `if` (SHOULD fix)
5. **Magic Numbers**: Hardcoded values (COULD fix)
