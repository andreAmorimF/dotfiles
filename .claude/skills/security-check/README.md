# Security Check Skill

Comprehensive security vulnerability detection based on real-world patterns from production microservices.

## Quick Start

```bash
# Check entire branch for security issues
/security-check

# Check only critical issues (sensitive logs)
/security-check --focus critical

# Check only working changes
/security-check --only-working
```

## What Gets Checked

### 🔴 Q1-CRITICAL: Sensitive Data in Logs
**Risk**: Exposure of PII, credentials, financial data  
**Impact**: LGPD violations, PCI-DSS violations  
**Examples**: Logging complete request/response objects, user data, payment details  
**Fix Time**: Varies by codebase (typically 2-3 weeks for systematic review)

### 🟠 Q2-IMPORTANT: Insecure Open Scopes  
**Risk**: Broken access control, privilege escalation  
**Impact**: OWASP A01:2021 #1 vulnerability  
**Examples**: Using `auth/admin` or `auth/trusted` instead of service-specific scopes  
**Fix Time**: 5-6 weeks (requires IAM coordination)

### 🟡 Q3-QUICK-WINS: Improper Externalization
**Risk**: Exposure of internal fields, lack of API contracts  
**Impact**: Potential data leakage, unclear contracts  
**Examples**: Missing `externalize!` interceptor, using `schema/Any`  
**Fix Time**: 2-4 hours per endpoint (quick wins!)

### 🟢 Q4-SECRETS: Hardcoded Secrets & Unencrypted Kafka
**Risk**: Credential exposure, data interception  
**Impact**: Depends on whether secrets are real or false positives  
**Examples**: API keys in code, Kafka without SSL/TLS  
**Fix Time**: 5 min (false positive) to 2-4 hours (real secret)

## Files

```
security-check/
├── SKILL.md                          # Main skill documentation
├── README.md                         # This file
└── examples/
    ├── critical-sensitive-logs.md    # Q1 examples (sensitive data in logs)
    ├── important-open-scopes.md      # Q2 examples (insecure scopes)
    ├── quick-wins-externalize.md     # Q3 examples (missing externalize)
    └── secrets-hardcoded.md          # Q4 examples (hardcoded secrets)
```

## Examples Directory

Detailed examples with real code patterns:

- **[critical-sensitive-logs.md](examples/critical-sensitive-logs.md)**: Learn what to log and what NOT to log
- **[important-open-scopes.md](examples/important-open-scopes.md)**: Understand scope design and least privilege
- **[quick-wins-externalize.md](examples/quick-wins-externalize.md)**: Quick security wins with schema validation
- **[secrets-hardcoded.md](examples/secrets-hardcoded.md)**: Secrets management best practices

## Command vs Skill

### Use the Command (`/security-check`) when:
- ✅ You want automated, fast validation
- ✅ You're about to commit/push/open PR
- ✅ You need a complete security report
- ✅ You want to integrate with git hooks

### Use the Skill (conversational) when:
- 💬 You have questions about security patterns
- 💬 You want to understand why something is vulnerable
- 💬 You need guidance on fixing a specific issue
- 💬 You want to learn security best practices

## Severity Levels

Following Nubank's severity standards:

### ⛔ MUST (Block Commit)
- Exposure of PII (CPF, email, credentials)
- Real hardcoded production secrets
- Financial data exposure (PCI-DSS violations)
- **Action**: Fix immediately before commit

### ⚠️ SHOULD (Fix Before PR)
- Logging complete objects (potential PII)
- Insecure open scopes (auth/admin, auth/trusted)
- Missing API schema validation
- Kafka without encryption (sensitive data)
- **Action**: Fix before opening pull request

### 💡 COULD (Improvements)
- Better logging practices
- More specific schemas
- False positive secrets with unclear naming
- **Action**: Consider for code quality

## Integration

### Pre-commit Hook
```bash
#!/bin/bash
claude /security-check --only-working
```

### Pre-push Hook
```bash
#!/bin/bash
claude /security-check --only-commits
```

### Git Alias
```ini
[alias]
    sec = !claude /security-check
    sec-critical = !claude /security-check --focus critical
```

## Vulnerability Categories

Based on comprehensive security analysis of production systems:

| Quadrant | Category | Priority | Typical Fix Time |
|----------|----------|----------|------------------|
| Q1-CRITICAL | Sensitive data in logs | HIGH (400) | 2-3 weeks |
| Q2-IMPORTANT | Insecure open scopes | HIGH (788) | 5-6 weeks |
| Q3-QUICK-WINS | Missing externalize | MEDIUM (600) | 3-5 days |
| Q4-SECRETS | Hardcoded secrets | VARIES | 5min - 4hrs |

### Common Patterns Found:
- Logging complete objects (requests, responses, user data)
- Generic admin/trusted scopes on sensitive endpoints
- Missing API schema validation
- Hardcoded credentials in configuration files
- Unencrypted Kafka topics handling sensitive data

## Compliance Standards

This skill helps ensure compliance with:

- ✅ **LGPD** (Lei Geral de Proteção de Dados) - Art. 46
- ✅ **PCI-DSS** (Payment Card Industry) - Requirements 3.4, 4.1
- ✅ **OWASP Top 10 2021** - A01, A02, A04, A07
- ✅ **CWE Top 25** - CWE-532, CWE-798, CWE-863, CWE-213, CWE-319
- ✅ **SOC2** - Principle of least privilege
- ✅ **ISO 27001** - Access control standards

## Performance

- **Speed**: 3-8 seconds for typical branch
- **Accuracy**: Based on real-world vulnerability patterns from production systems
- **Scope**: Only changed files (not entire codebase)
- **False Positives**: Minimal on Q1-Q3, verification needed on Q4

## Support

### For Questions:
1. Read the [SKILL.md](SKILL.md) documentation
2. Check relevant example file
3. Review internal vulnerability documentation
4. Consult InfoSec team

### For Issues:
1. Check if it's a false positive
2. Read the specific example guide
3. Ask for help in security channel
4. Open issue if tool has bugs

### For Contributions:
1. New patterns discovered? Add examples
2. Better detection logic? Submit PR
3. Documentation improvements welcome
4. Share learnings with the team

## Continuous Improvement

This skill evolves based on:
- 📊 New vulnerability patterns discovered
- 📈 Team feedback and usage patterns
- 🔒 Updated security standards
- 🎯 Reduced false positive rates

**Last major update**: Based on Q4 2024 vulnerability analysis  
**Next review**: Q1 2025

## Related Resources

### Commands:
- `/security-check` - This skill's automation
- `/code-check` - General code quality
- `/pr-review` - Comprehensive PR review
- `/style-check` - Code style validation

### Security Standards:
- OWASP Top 10 2021
- CWE Top 25 Most Dangerous Weaknesses
- LGPD (Brazilian Data Protection Law)
- PCI-DSS Payment Security Standards

### External References:
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [OWASP API Security](https://owasp.org/API-Security/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [LGPD](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [PCI-DSS](https://www.pcisecuritystandards.org/)

---

**Version**: 1.0  
**License**: Internal use only
