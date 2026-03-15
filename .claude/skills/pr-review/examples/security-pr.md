# Example: Security-Focused Review

This example shows how security issues are identified and communicated.

## PR Context

**URL**: https://github.com/nubank/holocron/pull/321  
**Title**: Add customer search endpoint  
**Changes**: +95, -5 (3 files)

**Files Changed**:
- `src/holocron/diplomat/http_server.clj` (+40 lines)
- `src/holocron/controllers/customer.clj` (+45 lines)
- `src/holocron/wire/out.clj` (+10, -5)

---

## Review Output (Security Focus)

```markdown
## PR Summary

**Title**: Add customer search endpoint  
**Author**: developer@nubank.com.br  
**Status**: Open  
**Changes**: +95 -5 (3 files)  
**Branch**: feature/customer-search to main

**Description**:
Adds new HTTP endpoint for customer search by CPF or email.

---

## Security & Safety Review

### [PII_LOGGING MUST]: Logging sensitive customer data

- **Location**: controllers/customer.clj:23
- **Issue**: Customer CPF being logged in plain text
- **Impact**:
  - **Unrecoverable**: PII exposed in logs violates LGPD/GDPR
  - **Data breach**: Logs accessible by multiple teams, retention policies unclear
  - **Audit risk**: Cannot retroactively remove PII from archived logs
- **Guideline**: Security Standards § PII Handling - "Never log unmasked PII"
- **Fix**:
  ```clojure
  ;; Current (WRONG) - LGPD violation
  (log/info "Searching customer" {:cpf (:cpf params)})  ← PII in logs!
  
  ;; Fixed - Mask PII
  (log/info "Searching customer" {:cpf (mask-cpf (:cpf params))})
  ;; Or use customer-id
  (log/info "Searching customer" {:customer-id (:id customer)})
  
  ;; Mask function
  (defn mask-cpf [cpf]
    (str (subs cpf 0 3) ".***.***-" (subs cpf 9)))
  ;; "123.456.789-00" → "123.***.***-00"
  ```
- **Confidence**: HIGH

---

### [PII_IN_RESPONSE MUST]: Email in wire.out without explicit consent

- **Location**: wire/out.clj:45
- **Issue**: Customer email included in search response without verification
- **Impact**:
  - **Unrecoverable**: PII exposed to unauthorized systems via public API
  - **Compliance**: LGPD requires explicit consent for PII sharing
  - **Audit**: Cannot prove consent chain if questioned
- **Guideline**: Security Standards § PII in Responses
- **Fix**:
  ```clojure
  ;; Current (WRONG)
  (def CustomerSearchResult
    {:id s/Str
     :name s/Str
     :email s/Str  ← PII without consent check
     :cpf s/Str})  ← PII without masking
  
  ;; Fixed - Option 1: Remove PII
  (def CustomerSearchResult
    {:id s/Str
     :name s/Str})  ← Only non-sensitive data
  
  ;; Fixed - Option 2: Mask PII
  (def CustomerSearchResult
    {:id s/Str
     :name s/Str
     :email-domain s/Str  ← "**@nubank.com.br"
     :cpf-masked s/Str})  ← "***.***.789-**"
  
  ;; Fixed - Option 3: Conditional based on auth
  (defn customer-search-result [customer auth-context]
    (if (authorized-for-pii? auth-context)
      {:id (:id customer)
       :name (:name customer)
       :email (:email customer)}  ← Only if authorized
      {:id (:id customer)
       :name (:name customer)}))  ← Default: no PII
  ```
- **Confidence**: HIGH

---

### [SQL_INJECTION MUST]: Unsanitized input in query

- **Location**: controllers/customer.clj:35
- **Issue**: CPF parameter concatenated directly into SQL-like query
- **Impact**:
  - **Unrecoverable**: SQL injection enables data breach, data loss
  - **Escalation**: Attacker could access all customer data
  - **System compromise**: Could execute arbitrary database commands
- **Guideline**: Security Standards § Input Validation
- **Fix**:
  ```clojure
  ;; Current (WRONG) - SQL injection vulnerability
  (defn search-by-cpf [db cpf]
    (jdbc/query db 
      [(str "SELECT * FROM customers WHERE cpf = '" cpf "'")]))  ← DANGEROUS!
  ;; Attacker input: "123' OR '1'='1" → Returns ALL customers
  
  ;; Fixed - Use parameterized queries
  (defn search-by-cpf [db cpf]
    (jdbc/query db 
      ["SELECT * FROM customers WHERE cpf = ?" cpf]))  ← Safe
  
  ;; Even better - Use Datomic (safe by design)
  (defn search-by-cpf [db cpf]
    (d/q '[:find ?e
           :in $ ?cpf
           :where [?e :customer/cpf ?cpf]]
         db cpf))  ← Datomic parameterized by design
  ```
- **Confidence**: HIGH

---

### [MISSING_VALIDATION SHOULD]: No input validation before processing

- **Location**: controllers/customer.clj:28
- **Issue**: CPF not validated before database query
- **Impact**: Invalid inputs waste resources, could cause errors
- **Fix**:
  ```clojure
  ;; Current
  (defn search-customer! [components params]
    (let [cpf (:cpf params)]  ← No validation
      (db/search-by-cpf (:db components) cpf)))
  
  ;; Fixed
  (defn search-customer! [components params]
    (let [cpf (:cpf params)]
      (when-not (valid-cpf? cpf)
        (throw (ex-info "Invalid CPF format" {:cpf (mask-cpf cpf)})))
      (db/search-by-cpf (:db components) cpf)))
  
  ;; Validation function
  (defn valid-cpf? [cpf]
    (and (string? cpf)
         (re-matches #"\d{3}\.\d{3}\.\d{3}-\d{2}" cpf)
         (cpf-checksum-valid? cpf)))  ← Validates checksum
  ```
- **Confidence**: HIGH

---

### [NO_RATE_LIMITING SHOULD]: Endpoint has no rate limiting

- **Location**: diplomat/http_server.clj:12
- **Issue**: Search endpoint can be called unlimited times
- **Impact**: 
  - DoS vulnerability
  - Scraping risk (enumerate all customers)
  - Resource exhaustion
- **Fix**:
  ```clojure
  ;; Add rate limiting interceptor
  (def customer-search-route
    ["/api/customers/search"
     :post
     [rate-limit/per-user-limiter  ← Add interceptor
      auth/require-authenticated]
     customer-search-handler!])
  
  ;; Rate limit config
  (def per-user-limiter
    (rate-limit/make-limiter
      {:requests 10
       :per :minute
       :scope :user-id}))
  ```
- **Confidence**: MEDIUM

---

## Considered But Not Flagged

- **Authentication**: Endpoint properly requires authentication
- **Authorization**: Uses existing auth middleware
- **HTTPS**: Runs behind load balancer with TLS termination

---

## Security Assessment

### Critical Issues (Block Merge):
1. ❌ PII logging (LGPD violation)
2. ❌ PII in response (compliance risk)
3. ❌ SQL injection (critical vulnerability)

### Important Issues (Should Fix):
4. ⚠️ Missing input validation
5. ⚠️ No rate limiting

---

## Recommendations

### Immediate Actions (MUST fix before merge):
1. **Remove PII from logs** - Use masked CPF or customer ID only
2. **Remove or mask PII in response** - Check if email/CPF needed in response
3. **Fix SQL injection** - Use parameterized queries or Datomic

### Follow-up Actions (SHOULD fix before launch):
4. Add CPF validation before query
5. Implement rate limiting (10 requests/minute/user)

### Security Review Required:
6. **Request InfoSec review** before merging
7. **Add penetration test** for this endpoint
8. **Update threat model** to include search functionality

---

## Review Verdict

**Status**: 🚨 **CRITICAL_SECURITY_ISSUES**

**Summary**: Found 3 CRITICAL security issues that MUST be fixed before merge:
PII logging (LGPD violation), PII in response (compliance), SQL injection 
(critical vulnerability). These represent significant security and compliance risks.

**BLOCK MERGE** until InfoSec reviews and all CRITICAL issues are resolved.

---

## For the Author

⚠️ **Security issues found** - Please don't feel bad! Security is hard and these are common mistakes.

**Next steps**:
1. Fix the 3 CRITICAL issues (code examples provided above)
2. Request InfoSec review (required for PII-handling endpoints)
3. Consider security training on PII handling and input validation

**Help available**:
- #security channel for questions
- InfoSec team can pair on the fixes
- Security training available: [link]

**After fixes**: Will re-review and approve quickly. Thanks for being receptive to feedback! 🛡️
```

---

## Key Security Patterns Checked

**PII Protection**:
- ✅ Checked logs for unmasked PII
- ✅ Checked API responses for unnecessary PII
- ✅ Verified consent chain for PII sharing

**Input Validation**:
- ✅ SQL injection vectors
- ✅ Format validation
- ✅ Checksum validation

**Access Control**:
- ✅ Authentication required
- ✅ Authorization appropriate
- ✅ Rate limiting present

**Audit Trail**:
- ✅ Can prove compliance
- ✅ Logs don't leak PII
- ✅ InfoSec review documented

---

## Communication Approach

**Constructive, not blaming**:
- Acknowledge security is hard
- Provide specific fixes
- Offer help and resources
- Fast re-review promised

**Result**: Author fixes issues without feeling attacked, learns security best practices, InfoSec gets visibility
