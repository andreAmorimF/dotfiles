# Q4-SECRETS: Hardcoded Secrets & Unencrypted Kafka Examples

## Overview

**Risk Level**: 🟢 REQUIRES ANALYSIS (Potentially Critical if Real)
**CWE**: CWE-798 (Hard-coded Credentials), CWE-319 (Cleartext Transmission)
**OWASP**: A07:2021 (Authentication Failures), A02:2021 (Cryptographic Failures)
**Unique Challenge**: Requires verification - many are false positives

## The Problem

### Hardcoded Secrets:
- Credentials embedded in source code
- API keys, passwords, tokens in plain text
- Exposed in git history forever
- Can be discovered by attackers

### Unencrypted Kafka:
- Sensitive data transmitted in clear text
- Messages can be intercepted
- No authentication on topics
- Compliance violations (PCI-DSS, LGPD)

## CRITICAL: Verification Required

**⚠️ BEFORE ACTING**:

1. **Check if it's a real secret**:
   - Is it a production credential?
   - Is it a staging/dev credential?
   - Or is it just a string that looks like a secret?

2. **If real secret**:
   - 🔥 **IMMEDIATE**: Rotate credential
   - 🔥 Check access logs
   - 🔥 Notify InfoSec team
   - 🔥 Remove from code

3. **If false positive**:
   - Add explanatory comment
   - Document why it looks like a secret
   - Consider renaming

---

## Real Examples from Codebase

### Example 1: Potential API Key in Config

**❌ SUSPICIOUS** (requires verification):

```clojure
(ns myservice.config)

(def api-key "EXAMPLE-sk_live_HARDCODED-KEY")  ;; ❌ Looks like Stripe API key - Example only

(defn connect-to-service []
  (http/get "https://api.service.com"
    {:headers {"Authorization" (str "Bearer " api-key)}}))
```

**Verification needed**:
- [ ] Is this a real API key?
- [ ] Is it production or test key?
- [ ] Can it be found in git history?
- [ ] Has it been rotated recently?

**If real - URGENT FIX**:

```clojure
(ns myservice.config)

;; Read from environment variable
(def api-key (System/getenv "SERVICE_API_KEY"))

(when (nil? api-key)
  (throw (ex-info "SERVICE_API_KEY environment variable not set" 
                  {:required-env-vars ["SERVICE_API_KEY"]})))

(defn connect-to-service []
  (http/get "https://api.service.com"
    {:headers {"Authorization" (str "Bearer " api-key)}}))
```

**Set environment variable**:
```bash
# In deployment configuration
export SERVICE_API_KEY="your-actual-api-key-from-secure-source"

# Or use secrets manager (recommended)
export SERVICE_API_KEY=$(vault read -field=value secret/myservice/api-key)
```

---

### Example 2: Hardcoded Database Password

**❌ CRITICAL** (if real):

```clojure
(def db-config
  {:host "prod-db.internal"
   :port 5432
   :database "payments"
   :user "app_user"
   :password "EXAMPLE-P@ssw0rd-HARDCODED!"})  ;; ❌ HARDCODED PASSWORD - Example only
```

**If real - IMMEDIATE ACTION**:

```clojure
(def db-config
  {:host (System/getenv "DB_HOST")
   :port (Integer/parseInt (System/getenv "DB_PORT" "5432"))
   :database (System/getenv "DB_NAME")
   :user (System/getenv "DB_USER")
   :password (System/getenv "DB_PASSWORD")})

;; Validation
(doseq [key [:host :database :user :password]]
  (when (nil? (key db-config))
    (throw (ex-info (str key " not configured")
                    {:missing-config key}))))
```

---

### Example 3: Token in HTTP Client

**❌ SUSPICIOUS**:

```clojure
(defn call-external-api [endpoint]
  (http/post endpoint
    {:headers {"Authorization" "Bearer EXAMPLE-JWT-TOKEN-HARDCODED-HERE"}}))  ;; ❌ Example only
```

**Verification**:
- Is this a real JWT token?
- Does it have an expiration?
- Is it for production?

**Secure alternative**:

```clojure
(defn call-external-api [endpoint token]
  (http/post endpoint
    {:headers {"Authorization" (str "Bearer " token)}}))

;; Token comes from secure source
(def service-token
  (or (System/getenv "EXTERNAL_SERVICE_TOKEN")
      (vault-read "secret/external-service/token")))

;; Usage
(call-external-api "https://api.external.com/data" service-token)
```

---

### Example 4: Base64 Encoded "Secret"

**❌ FALSE SECURITY** (encoding ≠ encryption):

```clojure
(def secret-key "c2VjcmV0LWtleS0xMjM0NTY=")  ;; Base64 encoded

(defn decrypt-data [data]
  (let [key (String. (b64/decode secret-key))]  ;; "secret-key-123456"
    (aes/decrypt data key)))
```

**Problem**:
- Base64 is NOT encryption
- Anyone can decode it
- Still a hardcoded secret

**Secure alternative**:

```clojure
(defn get-encryption-key []
  (or (System/getenv "ENCRYPTION_KEY")
      (vault-read "secret/myservice/encryption-key")))

(defn decrypt-data [data]
  (let [key (get-encryption-key)]
    (aes/decrypt data key)))
```

---

### Example 5: Kafka Without Encryption

**❌ INSECURE** (common pattern in Kafka configurations):

```clojure
(def kafka-config
  {:bootstrap.servers "kafka-prod.internal:9092"  ;; Plain text port
   :group.id "payment-processor"
   :key.deserializer "org.apache.kafka.common.serialization.StringDeserializer"
   :value.deserializer "org.apache.kafka.common.serialization.StringDeserializer"})
```

**Problem**:
- Port 9092 is plain text (no SSL)
- No authentication
- Messages transmitted in clear text
- Sensitive payment data exposed

**✅ SECURE FIX**:

```clojure
(def kafka-config
  {:bootstrap.servers "kafka-prod.internal:9093"  ;; SSL port
   :group.id "payment-processor"
   
   ;; SSL/TLS Configuration
   :security.protocol "SSL"
   :ssl.truststore.location (System/getenv "KAFKA_TRUSTSTORE_PATH")
   :ssl.truststore.password (System/getenv "KAFKA_TRUSTSTORE_PASSWORD")
   :ssl.keystore.location (System/getenv "KAFKA_KEYSTORE_PATH")
   :ssl.keystore.password (System/getenv "KAFKA_KEYSTORE_PASSWORD")
   :ssl.key.password (System/getenv "KAFKA_KEY_PASSWORD")
   
   ;; SASL Authentication (optional but recommended)
   :sasl.mechanism "PLAIN"
   :sasl.jaas.config (format 
     "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"%s\" password=\"%s\";"
     (System/getenv "KAFKA_USERNAME")
     (System/getenv "KAFKA_PASSWORD"))
   
   :key.deserializer "org.apache.kafka.common.serialization.StringDeserializer"
   :value.deserializer "org.apache.kafka.common.serialization.StringDeserializer"})
```

---

### Example 6: Secrets in Comments (Yes, really)

**❌ FOUND IN THE WILD**:

```clojure
(defn authenticate []
  ;; TODO: Remove this before production!
  ;; Test credentials: admin / EXAMPLE-TestPass-123
  ;; Production API key: EXAMPLE-sk_live_abc123xyz
  (let [username (System/getenv "USERNAME")
        password (System/getenv "PASSWORD")]
    (auth/login username password)))
```

**Problem**:
- Secrets in comments are still in git history
- Easy to forget to remove
- Visible to anyone with repo access

**Fix**:
1. Remove comments with secrets
2. Rotate credentials mentioned
3. Use separate test credentials (invalid for production)

---

## Detection Patterns

### Pattern 1: API Key Patterns

```clojure
;; Stripe (patterns to watch for)
"sk_live_" 
"pk_live_"

;; AWS (patterns to watch for)
"AKIA[A-Z0-9]{16}"

;; Generic
"api_key"
"api-key"
"apiKey"

;; In code (examples of what NOT to do)
(def api-key "EXAMPLE-sk_live-HARDCODED")  ;; ❌
(def token "Bearer EXAMPLE-TOKEN")  ;; ❌
```

### Pattern 2: Password Patterns

```clojure
;; Explicit password
(def password "...")
:password "..."

;; Suspicious strings (examples)
"Example-P@ssw0rd"
"Example-password123"
"Example-admin123"

;; In config
{:password "HARDCODED-VALUE"}  ;; ❌ Never do this
```

### Pattern 3: Token Patterns

```clojure
;; JWT tokens (these start with "eyJ...")
"EXAMPLE-eyJhbGc-JWT-TOKEN-HERE"

;; Generic tokens
"token" "..."
"auth-token" "..."
"bearer-token" "..."
```

### Pattern 4: Kafka Without SSL

```clojure
;; Plain text port
":9092"
:bootstrap.servers "...:9092"

;; Missing security config
;; No :security.protocol
;; No :ssl.* keys
```

---

## False Positive Examples

### ✅ These are OK (not secrets):

```clojure
;; Example/dummy data
(def example-api-key "your-api-key-here")
(def test-token "test-token-123")

;; UUID/ID (not secret)
(def transaction-id "550e8400-e29b-41d4-a716-446655440000")

;; Hash/Checksum (not secret)
(def content-hash "a3f4b2c1d5e6f7g8h9i0j1k2l3m4n5o6")

;; Public key (intentionally public)
(def public-key "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkq...")
```

**How to mark as safe**:
```clojure
;; Add explanatory comment
(def example-api-key "your-api-key-here")
;; ^ This is placeholder text for documentation, not a real key

(def test-token "test-token-123")
;; ^ Invalid test token for unit tests only
```

---

## Secrets Management Solutions

### Option 1: Environment Variables (Quick)

**Pros**:
- ✅ Quick to implement
- ✅ No additional infrastructure
- ✅ Secrets out of code

**Cons**:
- ⚠️ Plain text in environment
- ⚠️ Hard to rotate (requires redeploy)
- ⚠️ No audit trail

```clojure
(def api-key (System/getenv "API_KEY"))

(when (nil? api-key)
  (throw (ex-info "API_KEY not set" {})))
```

---

### Option 2: HashiCorp Vault (Recommended)

**Pros**:
- ✅ Encrypted at rest
- ✅ Easy rotation (no redeploy)
- ✅ Audit trail
- ✅ Fine-grained access control

**Cons**:
- ⚠️ Requires Vault infrastructure
- ⚠️ More complex setup

```clojure
(ns myservice.secrets
  (:require [vault.client :as vault]))

(defn get-secret [path]
  (-> (vault/read path)
      :data
      :value))

(def api-key (get-secret "secret/myservice/api-key"))
```

---

### Option 3: AWS Secrets Manager

**Pros**:
- ✅ Managed service (no ops)
- ✅ Automatic rotation
- ✅ IAM integration
- ✅ Audit trail

```clojure
(ns myservice.secrets
  (:require [cognitect.aws.client.api :as aws]))

(def secrets-client (aws/client {:api :secretsmanager}))

(defn get-secret [secret-name]
  (-> (aws/invoke secrets-client 
        {:op :GetSecretValue
         :request {:SecretId secret-name}})
      :SecretString))

(def api-key (get-secret "myservice/api-key"))
```

---

## Prevention: Pre-commit Hooks

### Install gitleaks

```bash
# macOS
brew install gitleaks

# Linux
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

### Configure pre-commit hook

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "🔍 Scanning for secrets..."
gitleaks protect --staged --verbose

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Potential secrets detected!"
    echo "   Review the findings above"
    echo "   If false positive, add to .gitleaksignore"
    exit 1
fi

echo "✅ No secrets detected"
EOF

chmod +x .git/hooks/pre-commit
```

---

## Incident Response: What to Do If Real Secret Found

### 🔥 IMMEDIATE (Within 1 hour):

1. **Rotate the credential**:
   - Production: IMMEDIATELY
   - Staging: Within 1 hour
   - Development: Within 24 hours

2. **Check access logs**:
   - Were there unauthorized uses?
   - When was last legitimate use?
   - Any suspicious patterns?

3. **Notify InfoSec**:
   - Severity: CRITICAL
   - Provide: What was exposed, when, where
   - Impact: What systems are affected

4. **Remove from code**:
   - Update code to read from env/vault
   - Remove hardcoded value
   - Commit and deploy ASAP

### 🕐 WITHIN 24 HOURS:

5. **Check git history**:
   - How long has it been exposed?
   - How many commits contain it?
   - Is it in any tags/releases?

6. **Notify affected teams**:
   - Which services used this credential?
   - Do they need to update?
   - Are there backup credentials?

7. **Document incident**:
   - What was exposed
   - How it was discovered
   - Actions taken
   - Lessons learned

### 📅 WITHIN 1 WEEK:

8. **Implement prevention**:
   - Add pre-commit hooks
   - Update documentation
   - Team training on secrets management

9. **Review similar patterns**:
   - Are there other hardcoded secrets?
   - Check related repositories
   - Scan all config files

---

## Real Impact

**From industry analysis**:
- Common in legacy code and rapid prototypes
- Often discovered during security audits
- **Requires**: Manual verification of each finding
- **Estimated fix time**: 
  - If false positive: 5 minutes (add comment)
  - If real secret: 2-4 hours (rotate + fix + deploy)

---

## Checklist: Secret Found Response

- [ ] **VERIFY**: Is it a real secret or false positive?
- [ ] **IF REAL - URGENT**:
  - [ ] Rotate credential immediately
  - [ ] Check access logs for unauthorized use
  - [ ] Notify InfoSec team
  - [ ] Remove from code
  - [ ] Deploy new code with env var / vault
  - [ ] Verify old credential no longer works
- [ ] **IF FALSE POSITIVE**:
  - [ ] Add explanatory comment
  - [ ] Consider renaming variable
  - [ ] Add to `.gitleaksignore`
- [ ] **PREVENTION**:
  - [ ] Install pre-commit hooks
  - [ ] Document secrets management policy
  - [ ] Train team on best practices

---

## References

- **CWE-798**: https://cwe.mitre.org/data/definitions/798.html
- **CWE-319**: https://cwe.mitre.org/data/definitions/319.html
- **OWASP A07:2021**: https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/
- **OWASP Secrets Management**: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- **Gitleaks**: https://github.com/gitleaks/gitleaks
- **TruffleHog**: https://github.com/trufflesecurity/trufflehog
- **Vault**: https://www.vaultproject.io/
- **AWS Secrets Manager**: https://aws.amazon.com/secrets-manager/
