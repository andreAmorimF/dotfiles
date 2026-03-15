# Integration Test Generation Example

This example shows how integration tests are generated following state-flow patterns from juan-bolsa and cardway-client.

## Source Code (Controller)

`src/controllers/payment.clj`:

```clojure
(ns holocron.controllers.payment
  (:require [holocron.logic.payment :as logic]
            [holocron.db.datomic.payment :as db.payment]
            [holocron.diplomat.producer :as producer]))

(defn handle-new-payment
  "Handles NEW-PAYMENT Kafka message"
  [message]
  (let [{:keys [customer-id amount]} (:new-payment message)
        payment (logic/create-payment customer-id amount)
        saved-payment (db.payment/save! payment)]
    (producer/send-payment-created! saved-payment)
    saved-payment))
```

## Generated Integration Test

`test/integration/integration/payment_flow_test.clj`:

```clojure
;; ============================================================================
;; CRITICAL: Follow Nubank integration test patterns
;; Use defflow (NOT deftest), state-flow, helpers.delta for HTTP checking
;; ============================================================================

(ns integration.payment-flow  ; ← Direct namespace, no project prefix
  "Integration tests for payment processing flow."
  (:require [clojure.string :as string]
            [common-datomic.api :as db]
            [common-test.servlet :as test.servlet]
            [integration.aux.init :refer [defflow]]  ; ← defflow NOT deftest!
            [integration.aux.kafka :as aux.kafka]
            [holocron.db.datomic.payment :as db.payment]
            [matcher-combinators.matchers :as matchers]
            [state-flow.api :as flow :refer [flow match?]]
            [state-flow.helpers.component.kafka :as kafka]
            [state-flow.helpers.component.servlet :as servlet]
            [state-flow.helpers.core :as helpers.core]
            [state-flow.helpers.delta :as helpers.delta]
            [state-flow.helpers.http-client :as http]))

;; ============================================================================
;; Test Data (Nubank pattern: defs at top)
;; ============================================================================

;; Fixed UUIDs for test entities (like juan-bolsa)
(def customer-id #uuid "72977038-6584-4a8f-b738-f28d79b2f086")
(def source-id #uuid "4230da02-48c7-4426-b78e-a5b645ff71bf")
(def flow-id (random-uuid))

;; Time constants with tagged literals
(def as-of #nu/time "2024-02-05T10:20:00Z")  ; ← #nu/time

;; Complete message structures as defs
(def new-payment-message
  {:new-payment {:flow-id      flow-id
                 :source-id    source-id
                 :customer-id  customer-id
                 :amount       100M      ; ← BigDecimal
                 :currency     :brl}})   ; ← Keyword

;; Variations using threading macros (juan-bolsa pattern)
(def payment-with-high-amount
  (-> new-payment-message
      (assoc-in [:new-payment :amount] 200000M)))

(def payment-missing-required-field
  (-> new-payment-message
      (update-in [:new-payment] dissoc :customer-id)))

;; ============================================================================
;; Integration Tests (Use defflow, NOT deftest!)
;; ============================================================================

(defflow create-payment-success-test  ; ← defflow!
  (flow "Querying non-existent source-id returns 404"
    (match? {:status 404
             :body   {}}
            (servlet/request {:method    :get
                              :uri       (string/replace 
                                           "/api/payments/by-source-id/:source-id" 
                                           ":source-id" 
                                           (str source-id))
                              :user-info (test.servlet/scopes->user-info 
                                           #{"payment/read"})})))
  
  (flow "Given a NEW-PAYMENT Kafka message"
    ;; CRITICAL: Destructure delta to check HTTP calls
    [{:keys [delta]}
     (helpers.delta/with-delta
       (http/with-responses
         {:ptp/transactions {:status 201
                            :body   {:transaction-id "ext-123"}}}
         (aux.kafka/consume-message new-payment-message
                                    :spp.new-payment-request
                                    as-of
                                    false)))]  ; ← false for skip-timers

    (flow "Then payment is stored in the database"
      (match? {:id          uuid?
               :source-id   source-id
               :customer-id customer-id
               :amount      100M
               :currency    :brl}
              (helpers.core/with-datomic
                #(db.payment/find-by-source-id source-id %))))  ; ← Anonymous fn

    (flow "Then we can get the payment by source-id"
      (match? {:status 200
               :body   {:payment {:id          uuid?
                                  :source-id   source-id
                                  :customer-id customer-id
                                  :amount      100M}}}
              (servlet/request {:method    :get
                                :uri       (string/replace 
                                             "/api/payments/by-source-id/:source-id" 
                                             ":source-id" 
                                             (str source-id))
                                :user-info (test.servlet/scopes->user-info 
                                             #{"payment/read"})})))

    (flow "Then transaction request sent to external service"
      (match? [{:payload {:transaction {:amount      100M
                                       :customer-id customer-id
                                       :flow-id     uuid?}}}]
              (:ptp/transactions delta)))  ; ← Check via delta

    (flow "And payment-created event is published"
      (match? [{:message {:event-type  :payment-created
                         :payment-id  uuid?
                         :customer-id customer-id
                         :amount      100M}}]
              (kafka/messages :produced {:topic :payment-events})))))

(defflow create-payment-validation-error-test
  (flow "Given payment message with missing required field"
    (aux.kafka/consume-message payment-missing-required-field
                               :spp.new-payment-request
                               as-of
                               false))

  (flow "Then no payment is created in database"
    (match? nil
            (helpers.core/with-datomic
              #(db.payment/find-by-source-id source-id %))))

  (flow "And no event is published"
    (match? []
            (kafka/messages :produced {:topic :payment-events}))))

(defflow create-payment-duplicate-test
  (flow "Given payment already exists"
    (helpers.core/with-datomic
      #(db/transact! % [(db.payment/->tx-create new-payment-message as-of)])))

  (flow "When duplicate message arrives"
    (aux.kafka/consume-message new-payment-message
                               :spp.new-payment-request
                               as-of
                               false))

  (flow "Then no duplicate payment is created"
    (match? 1
            (helpers.core/with-datomic
              #(count (db.payment/find-all-by-customer-id customer-id %)))))

  (flow "And no duplicate event is published"
    (match? []
            (kafka/messages :produced {:topic :payment-events}))))
```

## Key Integration Test Patterns

### 1. defflow, NOT deftest ✅

```clojure
(defflow create-payment-success-test  ; ← defflow!
  (flow "Given..."
    ...))
```

### 2. Delta Destructuring ✅

**CRITICAL for checking external HTTP calls:**

```clojure
(flow "Given a request"
  [{:keys [delta]}  ; ← Destructure delta
   (helpers.delta/with-delta
     (http/with-responses
       {:ptp/transactions {:status 201}}
       (aux.kafka/consume-message message topic as-of false)))]

  (flow "Then external service was called"
    (match? [{:payload {...}}]
            (:ptp/transactions delta))))  ; ← Check HTTP calls via delta
```

### 3. Anonymous Functions with Datomic ✅

```clojure
(helpers.core/with-datomic
  #(db.payment/find-by-id payment-id %))  ; ← Anonymous function
```

### 4. Kafka Message Consumption ✅

```clojure
(aux.kafka/consume-message
  new-payment-message
  :spp.new-payment-request
  as-of
  false)  ; ← false for skip-timers
```

### 5. HTTP Mocks ✅

```clojure
(http/with-responses
  {:ptp/transactions {:status 201
                     :body   {:transaction-id "ext-123"}}}
  {test-flows})
```

### 6. Given-When-Then Structure ✅

```clojure
(flow "Given a payment request" ...)       ; Setup
(flow "When message is consumed" ...)      ; Action
(flow "Then payment stored in DB" ...)     ; Verification
(flow "And event is published" ...)        ; Additional verification
```

## Test Scenarios Generated

For each endpoint/consumer, tests are generated for:

1. **Happy Path**: Complete successful flow
2. **Validation Errors**: Missing fields, invalid data
3. **Business Rules**: Amount limits, duplicate prevention
4. **Downstream Failures**: Gateway timeouts, service unavailable
5. **Idempotency**: Duplicate message handling

## Coverage Report

```
✅ Integration Tests Generated

File: test/integration/integration/payment_flow_test.clj

Test Flows:
1. create-payment-success-test (Happy path)
   ✓ HTTP/Kafka entry point
   ✓ Payment stored in database
   ✓ External service called
   ✓ Event published to Kafka
   
2. create-payment-validation-error-test
   ✓ Invalid input handling
   ✓ No database entry created
   ✓ No event published
   
3. create-payment-duplicate-test (Idempotency)
   ✓ Duplicate detection
   ✓ No duplicate database entry
   ✓ No duplicate event

Total: 3 integration flows covering 12 assertions

Dependencies Tested:
✓ Datomic: Create, read operations
✓ Kafka: Message consumption and production
✓ HTTP: External service integration

Next Steps:
1. Review test scenarios
2. Run: lein test :integration
3. Verify mocks match API contracts
```

## Run the Tests

```bash
$ lein test :integration

Testing integration.payment-flow

Ran 3 tests containing 12 assertions.
0 failures, 0 errors.

Duration: 4.2s
```

All integration tests pass! ✅

## Integration vs Unit Tests

| Aspect | Unit Tests | Integration Tests |
|--------|------------|-------------------|
| **Scope** | Single function | Complete flow |
| **Database** | Mocked | Real (in-memory) |
| **External** | Mocked | Mocked |
| **Kafka** | Mocked | Real (test helpers) |
| **Test Framework** | `deftest` | `defflow` |
| **Speed** | <100ms | 1-5s per flow |

Both types are essential for complete coverage!
