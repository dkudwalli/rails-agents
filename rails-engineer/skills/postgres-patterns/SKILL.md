---
name: postgres-patterns
description: >-
  PostgreSQL query optimization, schema design, indexing, Row Level Security, connection management, and the review checklist for database code. Use when writing SQL or migrations, designing a schema, diagnosing a slow query, or reviewing database changes. WHEN NOT: ActiveRecord-level N+1 and eager loading (see performance-optimization), migration mechanics and zero-downtime sequencing (see layered-migration-patterns), or query-object structure (see query-patterns).
license: MIT
compatibility: PostgreSQL 14+
---

# PostgreSQL Patterns

Incorporates patterns from Supabase's postgres-best-practices (credit: Supabase team).

## Diagnostics

```bash
psql $DATABASE_URL
psql -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
psql -c "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC;"
psql -c "SELECT indexrelname, idx_scan, idx_tup_read FROM pg_stat_user_indexes ORDER BY idx_scan DESC;"
```

## Principles

- **Index foreign keys** — always, no exceptions
- **Partial indexes** — `WHERE deleted_at IS NULL` for soft deletes
- **Covering indexes** — `INCLUDE (col)` to avoid table lookups
- **`SKIP LOCKED` for queues** — roughly 10x throughput for worker patterns
- **Cursor pagination** — `WHERE id > $last` instead of `OFFSET`
- **Batch inserts** — multi-row `INSERT` or `COPY`, never individual inserts in a loop
- **Short transactions** — never hold a lock across an external API call
- **Consistent lock ordering** — `ORDER BY id FOR UPDATE` to prevent deadlocks

## Quick Reference

### Index Cheat Sheet

| Query Pattern | Index Type | Example |
|--------------|------------|---------|
| `WHERE col = value` | B-tree (default) | `CREATE INDEX idx ON t (col)` |
| `WHERE col > value` | B-tree | `CREATE INDEX idx ON t (col)` |
| `WHERE a = x AND b > y` | Composite | `CREATE INDEX idx ON t (a, b)` |
| `WHERE jsonb @> '{}'` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| `WHERE tsv @@ query` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| Time-series ranges | BRIN | `CREATE INDEX idx ON t USING brin (col)` |

### Data Type Quick Reference

| Use Case | Correct Type | Avoid |
|----------|-------------|-------|
| IDs | `bigint` | `int`, random UUID |
| Strings | `text` | `varchar(255)` |
| Timestamps | `timestamptz` | `timestamp` |
| Money | `numeric(10,2)` | `float` |
| Flags | `boolean` | `varchar`, `int` |

### Common Patterns

**Composite Index Order:**
```sql
-- Equality columns first, then range columns
CREATE INDEX idx ON orders (status, created_at);
-- Works for: WHERE status = 'pending' AND created_at > '2024-01-01'
```

**Covering Index:**
```sql
CREATE INDEX idx ON users (email) INCLUDE (name, created_at);
-- Avoids table lookup for SELECT email, name, created_at
```

**Partial Index:**
```sql
CREATE INDEX idx ON users (email) WHERE deleted_at IS NULL;
-- Smaller index, only includes active users
```

**RLS Policy (Optimized):**
```sql
CREATE POLICY policy ON orders
  USING ((SELECT auth.uid()) = user_id);  -- Wrap in SELECT!
```

**UPSERT:**
```sql
INSERT INTO settings (user_id, key, value)
VALUES (123, 'theme', 'dark')
ON CONFLICT (user_id, key)
DO UPDATE SET value = EXCLUDED.value;
```

**Cursor Pagination:**
```sql
SELECT * FROM products WHERE id > $last_id ORDER BY id LIMIT 20;
-- O(1) vs OFFSET which is O(n)
```

**Queue Processing:**
```sql
UPDATE jobs SET status = 'processing'
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending'
  ORDER BY created_at LIMIT 1
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

### Anti-Pattern Detection

```sql
-- Find unindexed foreign keys
SELECT conrelid::regclass, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );

-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;

-- Check table bloat
SELECT relname, n_dead_tup, last_vacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Configuration Template

```sql
-- Connection limits (adjust for RAM)
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET work_mem = '8MB';

-- Timeouts
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET statement_timeout = '30s';

-- Monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Security defaults
REVOKE ALL ON SCHEMA public FROM public;

SELECT pg_reload_conf();
```

## Review

Work these in order of severity when reviewing database code.

**Query performance (critical).** Are WHERE and JOIN columns indexed? Run `EXPLAIN ANALYZE` on
complex queries and look for sequential scans on large tables. Watch for N+1 patterns. Verify
composite index column order — equality columns first, then range.

**Security (critical).** RLS enabled on multi-tenant tables, using the `(SELECT auth.uid())` form so
the function is evaluated once rather than per row. RLS policy columns indexed. Least privilege — no
`GRANT ALL` to application users. Public schema permissions revoked.

**Schema design (high).** Correct types: `bigint` for IDs, `text` for strings, `timestamptz` for
timestamps, `numeric` for money, `boolean` for flags. Constraints defined — primary key, foreign key
with `ON DELETE`, `NOT NULL`, `CHECK`. `lowercase_snake_case` identifiers, never quoted mixed case.

### Flag these

- `SELECT *` in production code
- `int` for IDs (use `bigint`); `varchar(255)` without a stated reason (use `text`)
- `timestamp` without time zone (use `timestamptz`)
- Random UUIDs as primary keys (use UUIDv7 or `IDENTITY`)
- `OFFSET` pagination on large tables
- Unparameterized queries — SQL injection risk
- `GRANT ALL` to application users
- RLS policies calling a function per row rather than wrapping it in `SELECT`

### Checklist

- [ ] All WHERE/JOIN columns indexed, foreign keys included
- [ ] Composite indexes in the correct column order
- [ ] Proper data types (`bigint`, `text`, `timestamptz`, `numeric`)
- [ ] RLS enabled on multi-tenant tables, using `(SELECT auth.uid())`
- [ ] No N+1 query patterns
- [ ] `EXPLAIN ANALYZE` run on complex queries
- [ ] Transactions kept short

## Related

- `layered-migration-patterns` — writing the migration that adds these indexes and constraints safely
- `performance-optimization` — the ActiveRecord side: eager loading and N+1 detection
- `query-patterns` — structuring the Ruby that issues these queries
