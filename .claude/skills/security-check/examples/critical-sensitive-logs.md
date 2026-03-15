# Q1-CRITICAL: Sensitive Data in Logs Examples

## Overview

**Risk Level**: 🔴 CRITICAL
**CWE**: CWE-359, CWE-532
**OWASP**: A04:2021 (Insecure Design)
**Compliance**: LGPD Art. 46, PCI-DSS Requirement 3.4

## The Problem

Logging complete objects (requests, responses, users, payments) exposes sensitive data including:
- **PII**: CPF, email, phone, address, full name
- **Credentials**: Tokens, passwords, API keys, authorization headers
- **Financial**: Account numbers, bank details, card data

## Real Examples from Production Code

### Example 1: Logging Complete HTTP Response

**❌ VULNERABLE** (common pattern in HTTP clients):

```clojure
(defn call-external-api [endpoint payload]
  (let [response (http/post endpoint {:body payload})]
    (log/info "External API response" {:response response})  ;; EXPOSES EVERYTHING
    response))
```

**What gets exposed**:
- Customer CPF, email, phone in response body
- Authorization tokens in headers
- Account numbers and bank details
- Internal system information

**✅ SECURE FIX**:

```clojure
(defn call-external-api [endpoint payload]
  (let [response (http/post endpoint {:body payload})]
    (log/info "External API response" 
      {:status (:status response)
       :request-id (get-in response [:headers "x-request-id"])
       :duration-ms (- (System/currentTimeMillis) start-time)})
    response))
```

---

### Example 2: Logging Complete Request Object

**❌ VULNERABLE** (common pattern in `http_client.clj`):

```clojure
(defn process-payment [request]
  (log/info "Processing payment request" {:request request})  ;; DANGEROUS
  (let [payment (extract-payment request)]
    (save-payment! payment)))
```

**What gets exposed**:
- Authorization header (Bearer token)
- Customer data in request body
- Session information
- IP addresses and user agents

**✅ SECURE FIX**:

```clojure
(defn process-payment [request]
  (log/info "Processing payment request" 
    {:endpoint (:uri request)
     :method (:request-method request)
     :request-id (generate-request-id)})
  (let [payment (extract-payment request)]
    (save-payment! payment)))
```

---

### Example 3: Logging User Object

**❌ VULNERABLE** (common in controllers):

```clojure
(defn get-user-info [user-id]
  (let [user (db/fetch-user user-id)]
    (log/info "Retrieved user" {:user user})  ;; LGPD VIOLATION
    user))
```

**What gets exposed**:
- Full name, CPF, email (LGPD protected)
- Phone number, address
- Date of birth
- Internal user metadata

**✅ SECURE FIX**:

```clojure
(defn get-user-info [user-id]
  (let [user (db/fetch-user user-id)]
    (log/info "Retrieved user" 
      {:user-id (:id user)
       :status (:status user)
       :created-at (:created-at user)})
    user))
```

---

### Example 4: Logging Payment Details

**❌ VULNERABLE** (common pattern in payment processing):

```clojure
(defn execute-payment! [payment]
  (log/info "Executing payment" {:payment payment})  ;; PCI-DSS VIOLATION
  (external-api/process payment))
```

**What gets exposed**:
- Bank account numbers
- Transaction amounts and details
- Customer financial information
- Payment credentials

**✅ SECURE FIX**:

```clojure
(defn execute-payment! [payment]
  (log/info "Executing payment" 
    {:payment-id (:id payment)
     :type (:type payment)
     :status (:status payment)
     :timestamp (now)})
  (external-api/process payment))
```

---

### Example 5: Error Logging with Full Context

**❌ VULNERABLE** (common error handling pattern):

```clojure
(defn process-transaction [data]
  (try
    (execute! data)
    (catch Exception e
      (log/error "Transaction failed" 
        {:error (.getMessage e)
         :data data})  ;; EXPOSES SENSITIVE DATA IN ERROR LOGS
      (throw e))))
```

**What gets exposed**:
- Complete transaction data in error logs
- Sensitive fields in exception context
- Stack traces with sensitive values

**✅ SECURE FIX**:

```clojure
(defn process-transaction [data]
  (try
    (execute! data)
    (catch Exception e
      (log/error "Transaction failed" 
        {:error-type (class e)
         :error-message (.getMessage e)
         :transaction-id (:id data)
         :transaction-type (:type data)})
      (throw e))))
```

---

## Safe vs Unsafe Fields

### ✅ SAFE to Log (Technical IDs and Status):

- `:id`, `:uuid`, `:transaction-id`, `:request-id`
- `:status`, `:state`, `:type`, `:category`
- `:created-at`, `:updated-at`, `:timestamp`
- `:duration-ms`, `:retry-count`, `:attempt`
- HTTP status codes (200, 404, 500)
- Boolean flags (`:processed?`, `:valid?`)

### ❌ NEVER Log (Sensitive Data):

**PII (LGPD Protected)**:
- `:cpf`, `:cnpj`, `:tax-id`
- `:email`, `:phone`, `:mobile`
- `:name`, `:full-name`, `:first-name`, `:last-name`
- `:address`, `:street`, `:city`, `:zip-code`
- `:birth-date`, `:age`

**Credentials**:
- `:password`, `:token`, `:api-key`
- `:authorization`, `:bearer-token`
- `:secret`, `:private-key`
- `:session-id`, `:auth-token`

**Financial Data (PCI-DSS)**:
- `:account-number`, `:bank-account`
- `:card-number`, `:cvv`, `:card-data`
- `:bank-code`, `:agency`, `:routing-number`
- `:transaction-amount` (in some contexts)

**Complete Objects**:
- `:request`, `:response`
- `:user`, `:customer`, `:client`
- `:payment`, `:transaction`
- `:data`, `:payload`, `:body`

---

## Detection Patterns

The security checker looks for these patterns:

```clojure
;; Pattern 1: Logging complete maps
(log/info "message" {:request request})
(log/info "message" {:response response})
(log/info "message" {:user user})
(log/info "message" {:payment payment})

;; Pattern 2: Logging generic data variables
(log/info "message" data)
(log/debug "received" payload)
(log/warn "failed" {:data data})

;; Pattern 3: Logging in error handlers
(catch Exception e
  (log/error "error" {:data data}))  ;; Dangerous

;; Pattern 4: Logging with merge
(log/info "processing" (merge {:message "test"} user))  ;; Exposes user fields
```

---

## The Principle

> **"Log the MINIMUM necessary for debugging, never the MAXIMUM available"**

### Always Ask:

1. **Do I need this field for debugging?** 
   - If yes: Is it non-sensitive?
   - If no: Don't log it

2. **Can I use a technical ID instead?**
   - Use `:user-id` instead of `:user`
   - Use `:transaction-id` instead of `:transaction`

3. **What would happen if this log was exposed?**
   - Would it violate LGPD?
   - Would it expose credentials?
   - Would it reveal sensitive business data?

---

## Compliance Impact

### LGPD (Lei Geral de Proteção de Dados)

**Article 46**: Data controllers must implement security measures to protect personal data.

**Violation**: Logging PII without proper safeguards
**Penalty**: Up to 2% of company revenue (max R$ 50 million)

### PCI-DSS (Payment Card Industry)

**Requirement 3.4**: Display only last 4 digits of card number

**Violation**: Logging complete payment/card data
**Penalty**: Loss of payment processing capability, fines up to $500,000

---

## Quick Fix Checklist

For each log statement:

- [ ] Is it logging a complete object? (request, response, user, payment)
- [ ] If yes, replace with explicit field selection
- [ ] Are only non-sensitive fields selected? (IDs, status, timestamps)
- [ ] Could any field be considered PII or credential?
- [ ] Is the log message still useful for debugging?
- [ ] Test: Would I be comfortable if this log was public?

---

## Real Impact

**From industry analysis**:
- Most common security vulnerability in microservices
- Found in logging, error handling, and debugging code
- **Priority**: 400 (CRITICAL)
- **Estimated fix time**: 2-3 weeks for systematic review and refactoring

---

## References

- **CWE-532**: https://cwe.mitre.org/data/definitions/532.html
- **CWE-359**: https://cwe.mitre.org/data/definitions/359.html
- **OWASP**: https://owasp.org/API-Security/editions/2019/en/0xa3-excessive-data-exposure/
- **LGPD**: https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm
