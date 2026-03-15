---
description: |
  Quick validation of Diplomat architecture boundaries and Single Responsibility 
  Principle (SRP) compliance in Clojure code. Checks for layer violations, 
  forbidden dependencies, and architectural drift.

tags:
  - architecture
  - diplomat
  - srp
  - boundaries
  - validation

category: code-quality

invocation-triggers:
  - "check architecture"
  - "validate SRP"
  - "architecture compliance"
  - "check boundaries"
  - "layer violations"
  - "diplomat check"
  - "SRP issues"

allowed-tools:
  - Read
  - Grep
  - Glob
---

# Architecture & SRP Compliance Check Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Ask to check architecture or SRP
- Mention layer boundaries or violations
- Want to validate Diplomat compliance
- Need quick architectural feedback

## What I Do

Quickly validate:
- ✅ **Component Boundaries**: Controllers, Logic, Adapters, etc.
- ✅ **SRP Violations**: Forbidden dependencies
- ✅ **Layer Separation**: Proper use of wire, models, components
- ✅ **Naming Patterns**: Functions ending with exclamation mark (!), etc.

## Complete Check Process

When invoked (naturally or via `/architecture-check`), I execute:

### Phase 1: Load Conventions
- **Load**: `@../../conventions/diplomat-guidelines.md` - Component boundaries
- **Load**: `@../../conventions/severity.md` - MUST/SHOULD/COULD rules

### Phase 2: Identify Files to Check
- If file/directory specified: Check those files
- If no args: Check all modified Clojure files in working directory

### Phase 3: Validate Each Component

**Component Type Detection** (by file path):
- `controllers/` → Controller
- `logic/` → Logic
- `adapters/` or `adapter/` → Adapter
- `wire/` → Wire schema
- `diplomat/http_client.clj` → HTTP Client
- `diplomat/producer.clj` → Producer
- `diplomat/consumer.clj` → Consumer

**Allowed Dependencies per Component:**

**Controllers** - Must ONLY know:
- ✅ ALLOWED: logic, models, diplomat/http_client, diplomat/producer, db/datomic, components, config
- ❌ FORBIDDEN: adapters, wire, diplomat/consumer

**Logic** - Must ONLY know:
- ✅ ALLOWED: models, other logic
- ❌ FORBIDDEN: components, side effects (functions with !), adapters, wire, diplomat

**Adapters** - Must ONLY know:
- ✅ ALLOWED: wire, models
- ❌ FORBIDDEN: logic, controllers, components, diplomat

**HTTP-Client** - Must ONLY know:
- ✅ ALLOWED: wire.in, wire.out, adapters, models, components, config
- ✅ REQUIREMENT: Functions must end with exclamation mark (!)

**Producers** - Must receive models (NOT wire):
- ✅ ALLOWED: models, adapters, wire.out, components, config
- ❌ FORBIDDEN: Never receive wire.in directly

**Consumers** - Must ONLY know:
- ✅ ALLOWED: wire.in, adapters, controllers, components, config

### Phase 4: Report Violations

For each violation found:
- **File and line** reference
- **Actual import/dependency** found
- **Why it violates SRP**
- **Suggested refactoring**
- **Severity**: MUST (SRP violation causes knowledge loss)

### Key Features

**As a Skill** (auto-invoked):
- I auto-detect files from context
- I understand "check this file" without explicit path
- I provide conversational, educational feedback

**As a Command** (explicit `/architecture-check`):
- Explicit file pattern specification
- Binary PASS/FAIL output
- Better for pre-commit hooks

## Usage Patterns

### Natural Language Invocation

```
"Is the architecture ok in these files?"
"Check if payment.clj follows SRP"
"Any architecture violations in controllers/?"
"Validate Diplomat boundaries"
```

### With File Context

```
User: "I'm working on src/holocron/controllers/payment.clj"
You: [Reads file]
User: "Does this follow SRP?"
You: [Automatically invokes this Skill]
```

## Success Criteria

A successful check provides:
- ✅ Clear PASS or VIOLATIONS_FOUND verdict
- ✅ Specific violations with file:line
- ✅ Explanation of why it violates SRP
- ✅ Concrete refactoring suggestion
- ✅ Fast execution (< 5 seconds)

---

**For developers**: This Skill provides quick architectural feedback. Use `/architecture-check` for scripting/automation.
