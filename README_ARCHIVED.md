# KGCash - MySQL Version (Archived)

This repository represents the MySQL-backed version of KGCash with a single
transaction table architecture. This codebase was active until October 18, 2025.

**Migrated to:** [kgcash-sqlite repository](link-to-new-repo)

## Architecture
- Database: MySQL (separate container)
- Schema: Single `transactions` table with `debit`/`credit` columns
- Split transactions: Parent/child relationship via `parent_id`
- Docker: 2 containers (mysql + web)
