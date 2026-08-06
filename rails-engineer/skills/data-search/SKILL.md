---
name: data-search
description: >-
  Implements full-text search inside the database on SQLite FTS5 or MySQL
  full-text, with no search service and no search gem. Use when adding search,
  building an index, writing search queries, or ranking and highlighting results
  in an app running SQLite or MySQL.
  WHEN NOT: The app runs PostgreSQL or another adapter — the concern here resolves
  `SQLite`/`Mysql2` by constant lookup and has no branch for it, so port the shape
  rather than the code. Also not for simple `WHERE ... LIKE` filters (use a model
  scope), schema design (use migration-patterns), or query caching (use
  caching-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, SQLite or MySQL
---

# Data & Search

**Full-text search runs in the database.** No Elasticsearch, no OpenSearch, no Algolia, no `pg_search`,
no search gem of any kind.

This holds across all three source applications, at every size. Add a search service only when
database-backed search demonstrably cannot satisfy the query or the scale requirement — and say what
that requirement is.

**On PostgreSQL, take the shape and not the code.** All three source applications run SQLite or
MySQL, so every adapter module below is one of those two. The principle — an index the model
maintains, resolved once inside a `Searchable` concern — ports directly onto `tsvector` plus a GIN
index. The SQL does not. Do not switch an app's database to use this skill.

## The shape

A `Searchable` concern on the model writes index rows as the record changes. The adapter difference
is resolved once, by constant lookup on the connection:

```ruby
module Searchable
  extend ActiveSupport::Concern

  included do
    include const_get(connection.adapter_name)   # SQLite or Mysql2/Trilogy
    after_save_commit :reindex_later
    after_destroy_commit :deindex
  end
end
```

Everything adapter-specific lives in the nested module. Nothing else in the app branches on the
database.

## SQLite FTS5 modelled as a real association

The virtual table is an ordinary association with `rowid` as the foreign key. `highlight()` and
`snippet()` are selected as cast attributes, so a search result is just a record with extra
attributes:

```ruby
has_one :fts, class_name: "Search::Record::SQLite::Fts",
  foreign_key: :rowid, primary_key: :id, dependent: :destroy

scope :matching, ->(query) {
  joins(:fts)
    .where("search_index MATCH ?", Search::Query.new(query).to_fts)
    .select("records.*", "snippet(search_index, 0, '<mark>', '</mark>', '…', 20) AS excerpt")
    .order("rank")
}
```

## MySQL sharding

Where volume demands it, shard the index by `CRC32` across a fixed number of tables, and bake the
tenant identifier **into the FTS query itself** rather than filtering afterwards — the index does the
isolation, not a `WHERE` clause applied to a large match.

> Fizzy profile only: the 16-shard MySQL arrangement and the account id in the query. Start with
> SQLite FTS5; a shard scheme is a response to a measured problem.

## Hand-written SQL, safely

Where you drop to SQL, three things must all be true:

1. **Sanitise user input into query syntax** before it reaches the matcher — a search query is a
   language, and the user does not get to write it directly
2. **Bind everywhere**, including inside `sanitize_sql`
3. **`Arel.sql` only around literals** you wrote — never around anything derived from params

## Keep the feature small

A "recent searches" feature is a saved query model with a trim callback — eighteen lines. It does not
need a service object and a Redis list.

Query objects, parsers, and stemmers live in `app/models/` (`Search::Query`, `Search::Stemmer`) like
any other domain object. There is no `app/queries/` directory.

## Related schema rules

- Give the index table a unique composite index that expresses the real constraint
- Order results deterministically — rank, then `id`
- Counter columns are incremented under `with_lock`
- Search indexing is `after_*_commit` work, and its job is shallow like any other

## Boundaries

- **Always:** Search in the database, resolve the adapter once in a concern, sanitise user input into
  query syntax, bind every value, order deterministically, reindex from `after_save_commit`
- **Ask first:** Before sharding an index, before adding a stemmer or synonym layer, before
  introducing a search service — name the requirement the database cannot meet
- **Profile override:** if the app's `AGENTS.md` records Elasticsearch, OpenSearch, or a search
  gem under **Deliberate divergences**, that row wins over the Never rule below — write in the
  idiom the app already runs. Removing it is `rich-models-legacy-migration`'s call, not a precondition for the
  task at hand.
- **Never:** Add Elasticsearch, OpenSearch, or a search gem by default; interpolate params into SQL;
  wrap user input in `Arel.sql`; create an `app/queries/` directory for search objects

See [`09-data-search.md`](../../docs/37signals-playbook/09-data-search.md).
