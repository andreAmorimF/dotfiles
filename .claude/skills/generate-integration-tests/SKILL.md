---
description: |
  Generates comprehensive integration tests for Clojure services following state-flow 
  patterns from juan-bolsa and cardway-client. Tests complete internal flows with 
  real Datomic (in-memory) and business logic, mocking only external services. Uses 
  defflow, delta destructuring, Given-When-Then structure, and comprehensive scenario 
  coverage (happy path, errors, idempotency).

tags:
  - testing
  - integration-tests
  - state-flow
  - clojure
  - kafka
  - datomic
  - service-testing

category: testing

invocation-triggers:
  - "generate integration tests"
  - "create flow tests"
  - "test this endpoint"
  - "integration test"
  - "test this controller"
  - "test kafka consumer"
  - "test service flow"

allowed-tools:
  - Shell
  - Read
  - Grep
  - Glob
  - Write

required_permissions:
  - network

model: claude-sonnet-4-5-20250929
---

# Integration Test Generator Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Implement new controllers or endpoints
- Create Kafka consumers or event handlers
- Modify existing service flows
- Ask for integration or flow tests
- Need to test complete service interactions

## What I Do

Generate comprehensive integration tests:
- ✅ **Complete Flows**: From entry point to data persistence and events
- ✅ **Nubank Patterns**: Follows juan-bolsa/cardway-client exactly
- ✅ **Real Internal**: In-memory Datomic, business logic, internal components
- ✅ **Mocked External**: PTP, THub, external APIs via `http/with-responses`
- ✅ **Smart Analysis**: Avoids duplicating existing test flows
- ✅ **defflow**: Uses state-flow patterns, NOT deftest

## Integration vs E2E Tests

**Integration Tests (what this generates):**
- ✅ Real: Datomic (in-memory), business logic, internal flow
- ❌ Mocked: External services, Kafka (via helpers), external APIs
- Fast feedback in development and CI

**E2E Tests (NOT generated here):**
- ✅ Real: All external services running
- Separate, run in staging environments

## Critical Nubank Patterns

### 1. Use defflow, NOT deftest (MANDATORY)

```clojure
(ns integration.payment-flow  ; ← Direct namespace
  (:require [integration.aux.init :refer [defflow]]  ; ← defflow!
            [state-flow.api :refer [flow match?]]))

(defflow create-payment-success-test  ; ← defflow, not deftest!
  (flow "Given a NEW-PAYMENT message"
    ...))
```

### 2. Delta Destructuring (CRITICAL)

**For checking external HTTP calls:**

```clojure
(flow "Given a payment request"
  [{:keys [delta]}  ; ← Destructure delta!
   (helpers.delta/with-delta
     (http/with-responses
       {:ptp/transactions {:status 201}}
       (aux.kafka/consume-message new-payment-message
                                  :spp.new-payment-request
                                  as-of
                                  false)))]  ; ← false for skip-timers

  (flow "Then external service was called"
    (match? [{:payload {:transaction {...}}}]
            (:ptp/transactions delta))))  ; ← Check via delta
```

### 3. Test Data as Defs

**Complete message structures at top:**

```clojure
;; Fixed UUIDs for test entities
(def customer-id #uuid "72977038-6584-4a8f-b738-f28d79b2f086")
(def source-id #uuid "4230da02-48c7-4426-b78e-a5b645ff71bf")

;; Time with tagged literals
(def as-of #nu/time "2024-02-05T10:20:00Z")

;; Complete messages
(def new-payment-message
  {:new-payment {:flow-id      (random-uuid)
                 :source-id    source-id
                 :customer-id  customer-id
                 :amount       100M      ; ← BigDecimal
                 :currency     :brl}})   ; ← Keyword

;; Variations with threading macros
(def payment-high-amount
  (-> new-payment-message
      (assoc-in [:new-payment :amount] 200000M)))
```

### 4. Given-When-Then Structure

```clojure
(defflow create-payment-success-test
  (flow "Given a NEW-PAYMENT message"        ; Setup
    ...)
    
  (flow "When message is consumed"           ; Action
    ...)
    
  (flow "Then payment is stored in database" ; Verification
    (match? {...}
            (helpers.core/with-datomic
              #(db.payment/find-by-id id %))))
              
  (flow "And event is published"             ; Additional verification
    (match? [{:message {...}}]
            (kafka/messages :produced {:topic :events}))))
```

### 5. Anonymous Functions with Datomic

```clojure
(helpers.core/with-datomic
  #(db.payment/find-by-source-id source-id %))  ; ← Anonymous function #(...)
```

### 6. Kafka Assertions

```clojure
(match? [{:message {:event-type  :payment-created
                   :payment-id  uuid?
                   :customer-id customer-id}}]
        (kafka/messages :produced {:topic :payment-events}))
```

## Generation Process

### Phase 1: Repository Context

1. Establish repository context (git root, branch)
2. Detect service dependencies (Datomic, Kafka, HTTP clients)
3. Find existing integration test patterns

### Phase 2: Analyze Target

For each controller/endpoint/consumer:

1. **Identify entry points**: HTTP endpoints, Kafka consumers
2. **Database operations**: Datomic transact/query, Docstore
3. **External service calls**: HTTP client calls
4. **Event emissions**: Kafka producer calls
5. **Side effects**: Slack, metrics, logs

### Phase 3: Analyze Existing Coverage

**If test file exists:**

1. Parse existing `defflow` definitions
2. Identify covered scenarios (happy path, errors, etc.)
3. Analyze flow completeness (missing assertions)
4. Generate gap report

```
📊 Integration Test Coverage Analysis

Entry Points Covered:
  ✅ POST /api/payments (partial)
    ✓ Happy path
    ✓ Validation errors
    ✗ Business rule errors (MISSING)
    ✗ Downstream failures (MISSING)

Entry Points Not Covered:
  ❌ GET /api/payments/:id
  ❌ Kafka consumer: payment-confirmed

Recommendations:
  1. Complete existing flows
  2. Add missing scenarios
  3. Test uncovered endpoints
```

### Phase 4: Determine Test Scenarios

For each entry point, generate tests for:

#### Happy Path
```
Given: Valid input and system preconditions
When: Request/event is processed
Then: 
  - Correct response returned
  - Database updated correctly
  - Events emitted
  - External services called
```

#### Validation Errors
```
Given: Missing required fields
When: Request is processed
Then: Returns 400, no DB entry, no events
```

#### Business Logic Errors
```
Given: Amount exceeds limit
When: Payment is processed
Then: Returns 422 with business rule error
```

#### Downstream Failures
```
Given: Payment gateway is down
When: Payment is attempted
Then: Returns 503, payment marked as failed
```

#### Idempotency
```
Given: Payment already processed
When: Same request arrives again
Then: Returns 200 with existing payment
      No duplicate DB entry
      No duplicate event
```

### Phase 5: Generate Test Code

**Test File Structure:**

```clojure
(ns integration.{feature-name}
  "Integration tests for {feature} complete flow."
  (:require [integration.aux.init :refer [defflow]]
            [state-flow.api :refer [flow match?]]
            [state-flow.helpers.component.kafka :as kafka]
            [state-flow.helpers.component.servlet :as servlet]
            [state-flow.helpers.core :as helpers.core]
            [state-flow.helpers.delta :as helpers.delta]
            [state-flow.helpers.http-client :as http]))

;; Test Data as defs
(def customer-id #uuid "...")
(def as-of #nu/time "...")
(def new-payment-message {...})

;; Integration Tests
(defflow happy-path-test ...)
(defflow validation-error-test ...)
(defflow duplicate-test ...)
```

### Phase 6: Output Report

**Complete Generation:**
```
✅ Integration Tests Generated (Complete Suite)

File: test/integration/integration/payment_flow_test.clj (NEW)

Test Flows:
1. create-payment-success-test (Happy path)
   ✓ HTTP/Kafka entry, DB persistence, events, external calls
   
2. create-payment-validation-error-test
   ✓ Invalid input, no DB entry, no events
   
3. create-payment-duplicate-test (Idempotency)
   ✓ Duplicate detection, no duplicate DB/events

Total: 3 flows covering 12 assertions

Dependencies: Datomic ✓, Kafka ✓, HTTP ✓

Next Steps:
1. Review test scenarios
2. Run: lein test :integration
3. Verify mocks match API contracts
```

**Incremental Generation:**
```
✅ Integration Tests Generated (Incremental)

File: test/integration/integration/payment_test.clj (UPDATED)

Existing Flows Preserved:
  ✓ create-payment-success-test (kept)

New Flows Added:
  + create-payment-business-rule-error-test
  + get-payment-by-id-success-test
  + process-payment-confirmed-event-test

Enhancement Suggestions:
  ! create-payment-success-test
    → Add Kafka event assertion (missing)

Coverage Improvement:
  Before: 1 flow, 1 endpoint
  After: 4 flows, 2 endpoints, 1 consumer
```

## Assertion Patterns

### HTTP Response
```clojure
(match? {:status 201
         :body   {:id uuid? :amount 100M}}
        (servlet/post {...}))
```

### Database Query
```clojure
(match? {:customer-id customer-id
         :amount      100M}
        (helpers.core/with-datomic
          #(db.payment/find-by-id payment-id %)))
```

### Kafka Messages
```clojure
(match? [{:message {:payment-id uuid?}}]
        (kafka/messages :produced {:topic :events}))
```

### HTTP Calls via Delta
```clojure
(match? [{:payload {:transaction {...}}}]
        (:ptp/transactions delta))
```

## Examples

### Natural Language Invocation

```
"Generate integration tests for payment endpoint"
"Create flow tests for this controller"
"Test the payment-confirmed consumer"
"I need integration tests for this service"
```

### With File Context

```
User: "I just added POST /api/refunds endpoint"
You: [Notes the implementation]
User: "Create integration tests"
You: [Automatically invokes this Skill]
```

## Success Criteria

Generated tests include:
- ✅ Complete flow coverage (entry → DB → events)
- ✅ Given-When-Then structure
- ✅ Database assertions with `helpers.core/with-datomic`
- ✅ Kafka assertions with `kafka/messages`
- ✅ HTTP mock verification via delta
- ✅ Multiple scenarios (happy, errors, idempotency)
- ✅ No duplication of existing flows

## See Examples

- **Integration Test Generation**: `examples/integration-test-example.md`

---

**For developers**: This Skill generates integration tests following state-flow patterns exactly. Complete flow coverage with smart duplication avoidance.
