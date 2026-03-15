# Q2-IMPORTANT: Insecure Open Scopes Examples

## Overview

**Risk Level**: 🟠 IMPORTANT (High Impact + High Effort)
**CWE**: CWE-863 (Incorrect Authorization)
**OWASP**: A01:2021 (Broken Access Control) - #1 Risk in OWASP Top 10
**Priority Score**: 788.04 (HIGH)

## The Problem

Endpoints using overly broad authentication scopes (`auth/admin`, `auth/trusted`) violate the **principle of least privilege**:

- Any user with admin token can access ANY endpoint
- Difficult to audit who should have access to what
- No context-specific permission control
- Broad attack surface if admin credential is compromised

## Real Examples from Production Code

### Example 1: Generic Admin Scope on Payment Endpoint

**❌ INSECURE** (common pattern in payment APIs):

```clojure
["/api/payment/execute"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin"})  ;; TOO BROAD
             (body/body-params)
             execute-payment-handler)
 :route-name :execute-payment]
```

**Problem**:
- ANY admin (from ANY service) can execute payments
- Admin from unrelated service (e.g., user management) can trigger financial transactions
- No differentiation between read/write operations
- Violates least privilege principle

**✅ SECURE FIX**:

```clojure
["/api/payment/execute"
 :post (conj common-interceptors
             (auth/allow? #{"payment/itau/write" 
                            "payment/itau/admin"})  ;; SPECIFIC
             (body/body-params)
             execute-payment-handler)
 :route-name :execute-payment]
```

**Benefits**:
- Only users with specific payment permissions can access
- Clear separation between services
- Granular control (read vs write)
- Easier to audit

---

### Example 2: Trusted Scope on Sensitive Data

**❌ INSECURE** (common pattern in account APIs):

```clojure
["/api/account/details"
 :get (conj common-interceptors
            (auth/allow? #{"auth/admin" "auth/trusted"})  ;; TOO PERMISSIVE
            get-account-handler)
 :route-name :get-account]
```

**Problem**:
- Both admin AND trusted can access sensitive account data
- "Trusted" is too vague - trusted by whom? for what?
- Difficult to track which services have access
- Violates need-to-know principle

**✅ SECURE FIX**:

```clojure
["/api/account/details"
 :get (conj common-interceptors
            (auth/allow? #{"account/service/read"})  ;; SPECIFIC READ PERMISSION
            get-account-handler)
 :route-name :get-account]
```

---

### Example 3: Multiple Endpoints with Same Broad Scope

**❌ INSECURE** (common pattern in REST services):

```clojure
;; Line 227
["/api/boleto/create"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin" "auth/trusted"})
             create-boleto-handler)]

;; Line 252
["/api/boleto/cancel"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin" "auth/trusted"})
             cancel-boleto-handler)]

;; Line 278
["/api/boleto/refund"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin" "auth/trusted"})
             refund-boleto-handler)]

;; Line 312
["/api/boleto/batch-update"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin" "auth/trusted"})
             batch-update-handler)]
```

**Problem**:
- All operations (create, cancel, refund, batch-update) use same broad scope
- No differentiation by sensitivity level
- Batch operations have same permissions as single operations
- Refunds (financial) same permission as read operations

**✅ SECURE FIX**:

```clojure
;; Differentiated by operation sensitivity
["/api/boleto/create"
 :post (conj common-interceptors
             (auth/allow? #{"boleto/create"})  ;; Create permission
             create-boleto-handler)]

["/api/boleto/cancel"
 :post (conj common-interceptors
             (auth/allow? #{"boleto/cancel"})  ;; Cancel permission
             cancel-boleto-handler)]

["/api/boleto/refund"
 :post (conj common-interceptors
             (auth/allow? #{"boleto/refund" 
                            "boleto/admin"})  ;; Refund requires higher privilege
             refund-boleto-handler)]

["/api/boleto/batch-update"
 :post (conj common-interceptors
             (auth/allow? #{"boleto/batch-write" 
                            "boleto/admin"})  ;; Batch requires special permission
             batch-update-handler)]
```

---

### Example 4: Admin Scope on Internal Endpoint

**❌ INSECURE** (common pattern in internal APIs):

```clojure
["/internal/reconciliation"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin" "auth/trusted"})
             reconciliation-handler)
 :route-name :reconciliation]
```

**Problem**:
- Internal endpoint accessible to all admins
- Reconciliation is critical financial operation
- No differentiation from regular operations

**✅ SECURE FIX**:

```clojure
["/internal/reconciliation"
 :post (conj common-interceptors
             (auth/allow? #{"epay/reconciliation" 
                            "epay/admin"})
             reconciliation-handler)
 :route-name :reconciliation]
```

---

### Example 5: Read and Write with Same Scope

**❌ INSECURE** (common anti-pattern):

```clojure
["/api/transactions"
 :get (conj common-interceptors
            (auth/allow? #{"auth/admin"})  ;; Read
            list-transactions-handler)]

["/api/transactions/:id"
 :delete (conj common-interceptors
              (auth/allow? #{"auth/admin"})  ;; Delete - same permission!
              delete-transaction-handler)]
```

**Problem**:
- Read operations have same permission as destructive operations
- Violates principle of least privilege
- Increases blast radius if credential compromised

**✅ SECURE FIX**:

```clojure
["/api/transactions"
 :get (conj common-interceptors
            (auth/allow? #{"transactions/read"})  ;; Read-only
            list-transactions-handler)]

["/api/transactions/:id"
 :delete (conj common-interceptors
              (auth/allow? #{"transactions/delete" 
                             "transactions/admin"})  ;; Requires write permission
              delete-transaction-handler)]
```

---

## Scope Naming Convention

### ✅ GOOD PATTERNS:

**Format**: `{service}/{resource}/{action}`

```clojure
;; Service-specific scopes
"payment/itau/read"
"payment/itau/write"
"payment/itau/admin"

;; Resource-specific scopes
"invoice/create"
"invoice/cancel"
"invoice/refund"

;; Action-specific scopes
"account/service/read"
"account/service/write"
"account/service/manage"

;; Context-specific scopes
"reconciliation/execute"
"batch/process"
"webhook/manage"
```

### ❌ BAD PATTERNS:

```clojure
;; Too broad
"auth/admin"
"auth/trusted"
"admin"
"superuser"

;; Too vague
"access"
"permission"
"allowed"

;; No context
"read"
"write"
"delete"
```

---

## Detection Patterns

The security checker looks for:

```clojure
;; Pattern 1: Direct auth/admin usage
(auth/allow? #{"auth/admin"})

;; Pattern 2: Direct auth/trusted usage
(auth/allow? #{"auth/trusted"})

;; Pattern 3: Combined broad scopes
(auth/allow? #{"auth/admin" "auth/trusted"})

;; Pattern 4: In route definitions
["/api/endpoint"
 :post (conj common-interceptors
             (auth/allow? #{"auth/admin"})  ;; FLAGGED
             handler)]
```

---

## Why This Is Important

### OWASP A01:2021 - Broken Access Control

**From OWASP Top 10 2021**:
> "Access control enforces policy such that users cannot act outside of their intended permissions. Failures typically lead to unauthorized information disclosure, modification, or destruction of all data or performing a business function outside the user's limits."

### Real-World Impact:

1. **Privilege Escalation**: Admin from Service A can access Service B's critical endpoints
2. **Audit Challenges**: Difficult to track who should have access
3. **Compliance Violations**: Violates SOC2, ISO 27001 principle of least privilege
4. **Increased Blast Radius**: Compromised admin credential affects ALL services

---

## Implementation Challenges

### Why This Is Q2 (Important but High Effort):

1. **Business Validation Required**:
   - Need to understand actual permission requirements per endpoint
   - Requires alignment with product/business teams

2. **IAM Integration**:
   - New scopes must be registered in IAM system
   - Requires coordination with InfoSec/Platform teams

3. **Consumer Coordination**:
   - API consumers must update their credentials
   - Requires communication and migration plan

4. **Testing Complexity**:
   - Must test all permission combinations
   - Risk of breaking existing integrations

5. **Rollback Difficulty**:
   - Scope changes are infrastructure changes
   - Not easily reversible

---

## Implementation Checklist

### Phase 1: Analysis (Week 1-2)
- [ ] Map all endpoints and their current scopes
- [ ] Identify business purpose of each endpoint
- [ ] Define required permissions per endpoint
- [ ] Document current consumers of each API
- [ ] Create scope naming convention

### Phase 2: Design (Week 2-3)
- [ ] Design new scope hierarchy
- [ ] Validate with business stakeholders
- [ ] Review with InfoSec team
- [ ] Create migration plan for consumers
- [ ] Document new scopes

### Phase 3: Implementation (Week 3-5)
- [ ] Register new scopes in IAM
- [ ] Update code to use new scopes
- [ ] Create scope migration guide for consumers
- [ ] Update API documentation
- [ ] Implement backward compatibility (if needed)

### Phase 4: Validation (Week 5-6)
- [ ] Test all endpoints with new scopes
- [ ] Validate with API consumers
- [ ] Deploy to staging
- [ ] Monitor authorization errors
- [ ] Gradual rollout to production

---

## Real Impact

**From industry analysis**:
- OWASP A01:2021 - #1 vulnerability in web applications
- Common in microservices with shared authentication
- **Average score**: 788.04 (HIGH priority)
- **Estimated fix time**: 5-6 weeks (requires IAM coordination)

---

## Mitigation Strategy

### Short Term (Quick Wins):
1. Document current scope usage
2. Add comments explaining why broad scopes are used
3. Create tracking tickets for proper fix

### Medium Term (This Quarter):
1. Define service-specific scope naming
2. Register new scopes in IAM
3. Migrate critical endpoints first (payments, refunds)

### Long Term (Next Quarter):
1. Migrate all endpoints to granular scopes
2. Deprecate auth/admin and auth/trusted
3. Implement scope monitoring and alerting

---

## References

- **CWE-863**: https://cwe.mitre.org/data/definitions/863.html
- **OWASP A01:2021**: https://owasp.org/Top10/A01_2021-Broken_Access_Control/
- **Nubank Playbook**: https://playbooks.nubank.com.br/tribe/infosec/sec-eng/scopes
- **Principle of Least Privilege**: https://en.wikipedia.org/wiki/Principle_of_least_privilege
