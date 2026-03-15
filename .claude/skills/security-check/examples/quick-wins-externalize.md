# Q3-QUICK-WINS: Improper Externalization Examples

## Overview

**Risk Level**: 🟡 QUICK WINS (Medium Impact + Low Effort)
**CWE**: CWE-213 (Exposure of Sensitive Information)
**OWASP**: A04:2021 (Insecure Design), A03:2021 (Excessive Data Exposure)
**Priority Score**: 600.0 (MEDIUM)
**Fix Time**: 2-4 hours per endpoint

## The Problem

API endpoints returning data without schema validation can:
- Expose internal fields not intended for external use
- Leak sensitive information accidentally
- Create unclear API contracts
- Make breaking changes harder to detect

## Real Examples from Production Code

### Example 1: Missing externalize! Interceptor

**❌ VULNERABLE** (common pattern in API services):

```clojure
["/api/boleto/status/:id"
 :get (conj common-interceptors
            (auth/allow? #{"boleto/read"})
            get-boleto-status-handler)  ;; NO SCHEMA VALIDATION
 :route-name :get-boleto-status]
```

**Problem**:
- Handler returns whatever it produces - no filtering
- May include internal fields (`:internal-state`, `:debug-info`)
- May include database metadata
- No contract enforcement

**What could leak**:
```clojure
;; Handler might return:
{:id "123"
 :status :paid
 :amount 100.50
 ;; Dangerous internal fields:
 :internal-state :reconciliation-pending  ;; Internal state machine
 :created-by-user-id "user-456"          ;; Internal user reference
 :last-modified-by "admin@internal"       ;; Internal email
 :db-version 5                            ;; Database metadata
 :retry-count 3                           ;; Internal retry logic
 :error-details {:stack-trace "..."}     ;; Debug information
}
```

**✅ SECURE FIX**:

```clojure
["/api/boleto/status/:id"
 :get (conj common-interceptors
            (auth/allow? #{"boleto/read"})
            (common-io.interceptors.adapt/externalize!
              {200 wire.out.model/BoletoStatusResponse
               404 wire.out.model/NotFoundError
               500 wire.out.model/ServerError})
            get-boleto-status-handler)
 :route-name :get-boleto-status]
```

**Define schema**:

```clojure
(ns payment_service.wire.out.model
  (:require [schema.core :as s]))

(def BoletoStatusResponse
  "Public API response - only external fields"
  {:id s/Uuid
   :status s/Keyword
   :amount s/Num
   :created-at s/Inst
   :expires-at s/Inst})

;; Note: Internal fields are NOT in schema
;; They will be filtered out automatically
```

---

### Example 2: Using schema/Any (Too Permissive)

**❌ VULNERABLE** (common pattern with schema validation):

```clojure
["/api/payment/execute"
 :post (conj common-interceptors
             (auth/allow? #{"payment/write"})
             (common-io.interceptors.adapt/externalize!
               {200 schema/Any})  ;; ACCEPTS ANYTHING!
             execute-payment-handler)
 :route-name :execute-payment]
```

**Problem**:
- `schema/Any` validates nothing
- Essentially same as having no schema
- Handler can return any structure
- No protection against internal field leakage

**✅ SECURE FIX**:

```clojure
["/api/payment/execute"
 :post (conj common-interceptors
             (auth/allow? #{"payment/write"})
             (common-io.interceptors.adapt/externalize!
               {200 wire.out.model/PaymentExecutionSuccess
                400 wire.out.model/ValidationError
                409 wire.out.model/ConflictError
                500 wire.out.model/ServerError})
             execute-payment-handler)
 :route-name :execute-payment]
```

**Define specific schema**:

```clojure
(def PaymentExecutionSuccess
  {:transaction-id s/Uuid
   :status (s/enum :pending :processing :completed)
   :estimated-completion s/Inst
   :confirmation-code s/Str})

;; NOT included: internal processing details
;; NOT included: full payment object
;; NOT included: database IDs
```

---

### Example 3: Multiple Status Codes Without Schemas

**❌ VULNERABLE** (common pattern in REST APIs):

```clojure
["/api/transaction/details/:id"
 :get (conj common-interceptors
            (auth/allow? #{"transaction/read"})
            get-transaction-handler)  ;; Missing externalize
 :route-name :get-transaction]
```

**Problem**:
- No schema for success response (200)
- No schema for error responses (404, 500)
- Inconsistent error format across endpoints
- May expose different fields per error type

**✅ SECURE FIX**:

```clojure
["/api/transaction/details/:id"
 :get (conj common-interceptors
            (auth/allow? #{"transaction/read"})
            (common-io.interceptors.adapt/externalize!
              {200 wire.out.model/TransactionDetails
               404 wire.out.model/NotFoundError
               403 wire.out.model/ForbiddenError
               500 wire.out.model/ServerError})
            get-transaction-handler)
 :route-name :get-transaction]
```

**Define all schemas**:

```clojure
;; Success response
(def TransactionDetails
  {:id s/Uuid
   :type s/Keyword
   :amount s/Num
   :status s/Keyword
   :created-at s/Inst
   :updated-at s/Inst})

;; Error responses
(def NotFoundError
  {:error (s/eq "not-found")
   :message s/Str
   :resource-type s/Str
   :resource-id s/Str})

(def ForbiddenError
  {:error (s/eq "forbidden")
   :message s/Str
   :required-permissions [s/Str]})

(def ServerError
  {:error (s/eq "internal-error")
   :message s/Str
   :request-id s/Uuid})
```

---

### Example 4: Nested Objects Without Schema Control

**❌ VULNERABLE**:

```clojure
(defn get-user-with-transactions [user-id]
  (let [user (db/get-user user-id)
        transactions (db/get-transactions user-id)]
    {:user user                    ;; Complete user object!
     :transactions transactions})) ;; Complete transaction objects!

["/api/user/:id/full"
 :get (conj common-interceptors
            get-user-with-transactions)  ;; No schema!
 :route-name :user-full]
```

**What gets exposed**:
```clojure
{:user {:id "123"
        :cpf "12345678900"              ;; PII - LGPD violation
        :email "user@email.com"         ;; PII
        :internal-notes "VIP customer"  ;; Internal notes
        :credit-score 750               ;; Sensitive
        :db-created-at ...
        :db-updated-at ...}
 :transactions [{:id "t1"
                 :amount 1000
                 :account-number "12345"  ;; Financial data
                 :internal-fee 2.50       ;; Internal pricing
                 :processor-response {...}}]} ;; Complete processor data
```

**✅ SECURE FIX**:

```clojure
["/api/user/:id/full"
 :get (conj common-interceptors
            (common-io.interceptors.adapt/externalize!
              {200 wire.out.model/UserWithTransactions})
            get-user-with-transactions)
 :route-name :user-full]
```

```clojure
(def PublicUserInfo
  "Only public user fields"
  {:id s/Uuid
   :name s/Str
   :status s/Keyword
   :created-at s/Inst})

(def PublicTransactionInfo
  "Only public transaction fields"
  {:id s/Uuid
   :type s/Keyword
   :amount s/Num
   :status s/Keyword
   :created-at s/Inst})

(def UserWithTransactions
  {:user PublicUserInfo
   :transactions [PublicTransactionInfo]
   :summary {:total-count s/Int
             :total-amount s/Num}})
```

---

### Example 5: Admin Endpoint Exposing Everything

**❌ VULNERABLE** (common in internal tools):

```clojure
["/admin/debug/user/:id"
 :get (conj common-interceptors
            (auth/allow? #{"admin"})
            (fn [request]
              (let [user-id (get-in request [:path-params :id])]
                {:status 200
                 :body (db/get-user-full-details user-id)})))  ;; Everything!
 :route-name :admin-debug]
```

**Problem**:
- "It's admin only" is not an excuse
- Admins might have tools that log responses
- Admin credentials might be compromised
- Still violates principle of least exposure

**✅ BETTER (but still admin)**:

```clojure
["/admin/debug/user/:id"
 :get (conj common-interceptors
            (auth/allow? #{"admin/debug"})
            (common-io.interceptors.adapt/externalize!
              {200 wire.out.model/AdminUserDebug})
            admin-debug-handler)
 :route-name :admin-debug]
```

```clojure
(def AdminUserDebug
  "Admin view - more fields than public, but still controlled"
  {:id s/Uuid
   :email s/Str
   :status s/Keyword
   :created-at s/Inst
   :last-login s/Inst
   :permission-groups [s/Str]
   :flag-states {s/Keyword s/Bool}
   ;; Still exclude: passwords, internal notes, sensitive PII
   })
```

---

## Schema Design Best Practices

### ✅ GOOD SCHEMA DESIGN:

```clojure
(ns myservice.wire.out.model
  (:require [schema.core :as s]))

;; Specific, well-defined schemas
(def PaymentResponse
  "Response for successful payment creation"
  {:payment-id s/Uuid
   :status (s/enum :pending :processing)
   :created-at s/Inst
   :estimated-completion s/Inst
   (s/optional-key :message) s/Str})

;; Reusable error schemas
(def ValidationError
  {:error (s/eq "validation-failed")
   :message s/Str
   :fields [{:field s/Str
             :error s/Str}]})

;; Nested schemas with control
(def TransactionWithDetails
  {:transaction {:id s/Uuid
                 :type s/Keyword
                 :amount s/Num}
   :details {:created-at s/Inst
             :status s/Keyword
             :confirmations s/Int}})
```

### ❌ BAD SCHEMA DESIGN:

```clojure
;; Too permissive
(def Response schema/Any)  ;; Useless

;; Too generic
(def GenericResponse
  {s/Keyword s/Any})  ;; Any keys, any values

;; Mixing concerns
(def ResponseWithInternals
  {:id s/Uuid
   :data s/Any  ;; What's in here?
   :_internal s/Any  ;; Why expose internal fields?
   :metadata s/Any})  ;; Too vague
```

---

## Detection Patterns

The security checker looks for:

```clojure
;; Pattern 1: Missing externalize!
["/api/endpoint"
 :get (conj interceptors handler)]  ;; No schema validation

;; Pattern 2: schema/Any usage
(externalize! {200 schema/Any})

;; Pattern 3: Generic map schemas
(externalize! {200 {s/Keyword s/Any}})

;; Pattern 4: No error schemas
(externalize! {200 SuccessSchema})  ;; What about 400, 404, 500?
```

---

## Why This Is a Quick Win

### Low Effort:
- **2-4 hours per endpoint** to fix
- Clear pattern to follow
- Can be done incrementally
- No coordination required (unlike Q2)

### High Value:
- ✅ Prevents accidental data exposure
- ✅ Creates clear API contracts
- ✅ Makes breaking changes visible
- ✅ Improves API documentation
- ✅ Helps with versioning

### Immediate Benefits:
- Better security posture
- Clearer API contracts
- Easier to maintain
- Helps prevent Q1 (logging) issues

---

## Implementation Checklist

### For Each Endpoint (2-4 hours):

#### 1. Analysis (30 min):
- [ ] Identify endpoint and handler
- [ ] Check what data handler currently returns
- [ ] Identify which fields should be public
- [ ] Check existing documentation (if any)

#### 2. Schema Definition (1-2 hours):
- [ ] Create/update `wire.out.model` namespace
- [ ] Define success response schema (200)
- [ ] Define error schemas (400, 404, 500)
- [ ] Use specific types (not `Any`)
- [ ] Document schema purpose

#### 3. Implementation (30 min):
- [ ] Add `externalize!` interceptor
- [ ] Pass schemas for all status codes
- [ ] Remove `schema/Any` if present
- [ ] Update handler if needed

#### 4. Testing (1 hour):
- [ ] Test endpoint locally
- [ ] Verify response matches schema
- [ ] Test error scenarios (404, 500)
- [ ] Check that internal fields are filtered
- [ ] Update API documentation

---

## Real Impact

**From industry analysis**:
- Common in microservices architectures
- Often overlooked during rapid development
- **Priority**: 600 (MEDIUM)
- **Estimated fix time**: 2-4 hours per endpoint
- **ROI**: HIGH (quick wins, significant security improvement)

---

## References

- **CWE-213**: https://cwe.mitre.org/data/definitions/213.html
- **OWASP A04:2021**: https://owasp.org/Top10/A04_2021-Insecure_Design/
- **OWASP API3**: https://owasp.org/API-Security/editions/2019/en/0xa3-excessive-data-exposure/
- **Postel's Law**: https://en.wikipedia.org/wiki/Robustness_principle
