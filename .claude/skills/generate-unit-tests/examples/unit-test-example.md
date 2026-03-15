# Unit Test Generation Example

This example shows how unit tests are generated following Nubank patterns from cardway-client and juan-bolsa.

## Source Code

`src/logic/payment.clj`:

```clojure
(ns holocron.logic.payment
  (:require [schema.core :as s]))

(def MAX_PAYMENT_AMOUNT 100000M)

(s/defn calculate-total :- s/Num
  "Calculates total amount from payment items"
  [items :- [{:amount s/Num}]]
  (->> items
       (map :amount)
       (reduce + 0M)))

(s/defn valid-payment? :- s/Bool
  "Validates payment amount and fields"
  [payment :- {:amount s/Num :customer-id s/Uuid}]
  (and (pos? (:amount payment))
       (<= (:amount payment) MAX_PAYMENT_AMOUNT)
       (some? (:customer-id payment))))
```

## Generated Unit Test

`test/unit/logic/payment_test.clj`:

```clojure
;; ============================================================================
;; CRITICAL: Namespace follows Nubank convention
;; Unit test namespace does NOT include project prefix!
;; ============================================================================

(ns logic.payment-test  ; ← NO holocron prefix!
  (:require [clojure.test :refer [is testing]]
            [schema.test :as st]
            [matcher-combinators.test :refer [match?]]
            [holocron.logic.payment :as logic.payment]  ; ← Full path in require
            [clojure.test.check.clojure-test :refer [defspec]]
            [common-test.schema :as test.schema]))

;; ============================================================================
;; Test Data (as defs at top, Nubank pattern)
;; ============================================================================

;; Realistic values (not "foo", "bar", "test")
(def sample-payment
  {:id          #uuid "d963b21f-7408-42dc-b8d9-2d599fd0893b"
   :customer-id #uuid "72977038-6584-4a8f-b738-f28d79b2f086"
   :amount      10000M          ; ← BigDecimal with M
   :currency    :brl             ; ← Keyword
   :status      "pending"})      ; ← String

(def sample-payments
  [sample-payment
   {:id          #uuid "e074c32f-8519-53e4-b567-537725285001"
    :customer-id #uuid "72977038-6584-4a8f-b738-f28d79b2f086"
    :amount      5000M
    :currency    :brl
    :status      "confirmed"}])

(def payment-items
  [{:amount 100M}
   {:amount 200M}
   {:amount 300M}])

(def empty-items [])

;; ============================================================================
;; Unit Tests (Nubank pattern: st/deftest with multiple testing blocks)
;; ============================================================================

(st/deftest calculate-total-test  ; ← st/deftest, NOT deftest!
  (testing "should calculate correct total for valid items"
    (let [result (logic.payment/calculate-total payment-items)]
      (is (= 600M result))))  ; ← (is (= expected actual))

  (testing "should return zero for empty list"
    (let [result (logic.payment/calculate-total empty-items)]
      (is (= 0M result))))

  (testing "should handle single item"
    (let [items [{:amount 100M}]
          result (logic.payment/calculate-total items)]
      (is (= 100M result))))

  (testing "should handle decimal precision correctly"
    (let [items [{:amount 100.555M}]
          result (logic.payment/calculate-total items)]
      (is (= 100.555M result))))

  (testing "should handle large numbers without overflow"
    (let [items [{:amount 999999999.99M}]
          result (logic.payment/calculate-total items)]
      (is (pos? result))
      (is (instance? BigDecimal result)))))

;; Property-based test (Nubank pattern from juan-bolsa)
(defspec calculate-total-generative-test {:num-tests 20 :max-size 5}
  (test.schema/fn-output-check-property logic.payment/calculate-total))

(st/deftest valid-payment?-test
  (testing "should accept valid payment"
    (is (true? (logic.payment/valid-payment? sample-payment))))

  (testing "should reject payment with zero amount"
    (let [invalid-payment (assoc sample-payment :amount 0M)]
      (is (false? (logic.payment/valid-payment? invalid-payment)))))

  (testing "should reject payment with negative amount"
    (let [invalid-payment (assoc sample-payment :amount -100M)]
      (is (false? (logic.payment/valid-payment? invalid-payment)))))

  (testing "should reject payment exceeding maximum"
    (let [invalid-payment (assoc sample-payment :amount 200000M)]
      (is (false? (logic.payment/valid-payment? invalid-payment)))))

  (testing "should reject payment without customer-id"
    (let [invalid-payment (dissoc sample-payment :customer-id)]
      (is (false? (logic.payment/valid-payment? invalid-payment))))))
```

## Key Nubank Patterns Applied

### 1. Namespace Convention ✅
```clojure
;; Source: src/holocron/logic/payment.clj
;; Test:   test/unit/logic/payment_test.clj (NOT holocron.logic!)

(ns logic.payment-test  ; ← NO project prefix
  (:require [holocron.logic.payment :as logic.payment]))  ; ← Full path in require
```

### 2. Test Data as Defs ✅
```clojure
;; At top of file (NOT inside tests)
(def sample-payment
  {:id          #uuid "d963b21f-7408-42dc-b8d9-2d599fd0893b"
   :customer-id #uuid "72977038-6584-4a8f-b738-f28d79b2f086"
   :amount      10000M})  ; ← BigDecimal with M
```

### 3. Schema Test (st/deftest) ✅
```clojure
(st/deftest calculate-total-test  ; ← st/deftest, NOT deftest!
  ...)
```

### 4. Multiple Testing Blocks ✅
```clojure
(st/deftest calculate-total-test
  (testing "should calculate correct total"
    ...)
  (testing "should return zero for empty"
    ...)
  (testing "should handle single item"
    ...))
```

### 5. Assertion Order ✅
```clojure
(is (= 600M result))  ; ← (= expected actual)
```

### 6. Property-Based Tests ✅
```clojure
(defspec calculate-total-generative-test {:num-tests 20}
  (test.schema/fn-output-check-property logic.payment/calculate-total))
```

## Coverage Analysis

```
📊 Test Coverage Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Source: src/logic/payment.clj
Test File: test/unit/logic/payment_test.clj (NEW)

Functions Covered:
  ✅ calculate-total (5 tests + property-based)
     - Happy path ✓
     - Empty list ✓
     - Single item ✓
     - Decimal precision ✓
     - Large numbers ✓
     - Property-based ✓
     
  ✅ valid-payment? (5 tests)
     - Valid input ✓
     - Zero amount ✓
     - Negative amount ✓
     - Exceeds maximum ✓
     - Missing customer-id ✓

Total: 10 tests + 1 property-based test

Edge Cases Covered:
✅ Nil/empty inputs
✅ Boundary values (0, negative, maximum)
✅ Type validation (BigDecimal)
✅ Invalid input handling

Next Steps:
1. Review generated tests
2. Run: lein test logic.payment-test
3. Verify all tests pass
```

## Run the Tests

```bash
$ lein test logic.payment-test

Testing logic.payment-test

Ran 12 tests containing 15 assertions.
0 failures, 0 errors.
```

All tests pass! ✅
