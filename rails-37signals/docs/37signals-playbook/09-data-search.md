# 09 — Data & search

SQLite in production, no Elasticsearch, no Redis (in the newest app), and search implemented in the
database with SQL you can read.

---

## SQLite is a production database here

Writebook and campfire ship SQLite only (`gem "sqlite3"` and nothing else). Fizzy supports both, with
two database configs — `config/database.sqlite.yml` and `config/database.mysql.yml`, selected by
`DATABASE_ADAPTER`, plus two committed schema files: `db/schema.rb` (MySQL) and `db/schema_sqlite.rb`.

The whole "self-hostable by one person" constraint in [`01-philosophy.md`](01-philosophy.md) flows from
this choice: no database server to install, back up, or upgrade.

Fizzy's `db/` shows the Solid trifecta as separate schemas:

```
fizzy/db/
  schema.rb           primary
  schema_sqlite.rb    primary, SQLite variant
  queue_schema.rb     Solid Queue
  cache_schema.rb     Solid Cache
  cable_schema.rb     Solid Cable
  migrate/
  seeds.rb
  seeds/
```

Four databases, one process, one file each — configured in `config/database.yml` as multiple
connections. See `config/cache.yml` and `config/queue.yml` in [`08-jobs-async.md`](08-jobs-async.md).

> Divergence: campfire and writebook run Redis for cache and jobs (`gem "redis"`, `gem "kredis"` in
> campfire) with a `redis: redis-server config/redis.conf` line in their `Procfile`. Fizzy has no Redis.
> Direction of travel: Solid Cache/Queue/Cable.

## Schema conventions

`fizzy/db/schema.rb:13-26`:

```ruby
ActiveRecord::Schema[8.2].define(version: 2026_07_09_120000) do
  create_table "accesses", id: :uuid, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "accessed_at"
    t.uuid "account_id", null: false
    t.uuid "board_id", null: false
    t.datetime "created_at", null: false
    t.string "involvement", default: "access_only", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["account_id", "accessed_at"], name: "index_accesses_on_account_id_and_accessed_at"
    t.index ["board_id", "user_id"], name: "index_accesses_on_board_id_and_user_id", unique: true
    t.index ["board_id"], name: "index_accesses_on_board_id"
    t.index ["user_id"], name: "index_accesses_on_user_id"
  end
```

- **`null: false` on everything that isn't genuinely optional**, including `created_at` /`updated_at`.
- **String enums with a database default** — `t.string "involvement", default: "access_only", null: false`,
  matching the `%w[…].index_by(&:itself)` enum style in [`03-models.md`](03-models.md).
- **Unique composite indexes enforce the real constraint** — `["board_id", "user_id"], unique: true`
  makes duplicate access rows impossible regardless of application code.
- **`utf8mb4` with the `_0900_ai_ci` collation** on MySQL, so emoji and accents work.
- No foreign key constraints; integrity is expressed through `dependent:` on associations and unique
  indexes.

`writebook/db/schema.rb:14-23` is the same shape with integer keys:

```ruby
  create_table "accesses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "book_id", null: false
    t.string "level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_accesses_on_book_id"
    t.index ["user_id", "book_id"], name: "index_accesses_on_user_id_and_book_id", unique: true
```

## Migrations are single-purpose and tiny

`fizzy/db/migrate/20260709120000_add_account_board_status_index_to_cards.rb`, the whole file:

```ruby
class AddAccountBoardStatusIndexToCards < ActiveRecord::Migration[8.2]
  def change
    add_index :cards, [ :account_id, :board_id, :status ]
  end
end
```

`once-campfire/db/migrate/20251212154340_add_singleton_constraint_to_accounts.rb`, the whole file —
and a nice trick worth stealing:

```ruby
class AddSingletonConstraintToAccounts < ActiveRecord::Migration[8.2]
  def change
    add_column :accounts, :singleton_guard, :integer, default: 0, null: false
    add_index :accounts, :singleton_guard, unique: true
  end
end
```

A unique index on a constant-valued column makes "there can be exactly one account" a **database**
guarantee rather than a validation. That's the ONCE single-tenant assumption (`Current#account` returns
`Account.first`) enforced where it can't be violated.

**Rules:**
- One concern per migration, descriptive class name, `change` only.
- Timestamps are readable dates — fizzy uses round numbers for hand-written ones
  (`20260709120000`).
- Migrations are excluded from RuboCop (`fizzy/.rubocop.yml`), so generated style is left alone.
- Prefer a database constraint over a validation when the invariant is absolute.

## UUIDv7 primary keys (fizzy only)

`create_table "accesses", id: :uuid` — fizzy uses UUIDs everywhere, stored as `binary(16)` on MySQL and
`blob(16)` on SQLite, exposed to Ruby as 25-character base36 strings.

Neither adapter supports a native UUID type, so `fizzy/config/initializers/uuid_primary_keys.rb:1-124`
teaches Active Record about one. The whole initializer is worth reading as an example of extending
Rails cleanly; the mechanism is five small prepended modules and `on_load` hooks
(`uuid_primary_keys.rb:111-124`):

```ruby
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.singleton_class.prepend(UuidPrimaryKeyDefault)
  ActiveRecord::ConnectionAdapters::TableDefinition.prepend(TableDefinitionUuidSupport)
end

ActiveSupport.on_load(:active_record_trilogyadapter) do
  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend(MysqlUuidAdapter)
  ActiveRecord::ConnectionAdapters::MySQL::SchemaDumper.prepend(SchemaDumperUuidType)
end

ActiveSupport.on_load(:active_record_sqlite3adapter) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(SqliteUuidAdapter)
  ActiveRecord::ConnectionAdapters::SQLite3::SchemaDumper.prepend(SchemaDumperUuidType)
end
```

**Rules for extending the framework, visible here:**
- `ActiveSupport.on_load(:...)` rather than requiring Rails internals at boot.
- `prepend` a named module per responsibility (`MysqlUuidAdapter`, `SqliteUuidAdapter`,
  `SchemaDumperUuidType`, `TableDefinitionUuidSupport`), each with a comment saying what it overrides
  and why:
  ```ruby
    # Override lookup_cast_type to recognize binary(16) as UUID type
  ```
- Always call `super` in the non-matching branch.
- Handle the not-yet-migrated case explicitly (`uuid_primary_keys.rb:14-16`):
  ```ruby
      rescue ActiveRecord::StatementInvalid
        # Table doesn't exist yet
  ```

Because UUIDv7 embeds a timestamp, `id` ordering is still chronological — which is why every ordering
scope can tie-break on `id` (see [`03-models.md`](03-models.md)) and why fixtures need deterministic
UUIDs (see [`11-testing.md`](11-testing.md)).

> Divergence: campfire and writebook use plain integer primary keys. UUIDs buy you shardable,
> non-enumerable, client-generatable ids; they cost you an initializer this long. Fizzy needed them for
> multi-tenancy — don't adopt them by default.

## Counter columns incremented under a lock

`fizzy/app/models/card.rb:92-94`:

```ruby
    def assign_number
      self.number ||= account.with_lock { account.increment!(:cards_count).cards_count }
    end
```

Per-account sequential card numbers (so URLs are `/cards/42`, via `to_param` returning `number`) even
though the primary key is a UUID. `with_lock` around `increment!` makes it race-free.

## Full-text search runs in the database

No Elasticsearch, no OpenSearch, no pg_search, no gem. All three implement search with the database's
own FTS features and a handful of model classes.

### The portable half: a `Searchable` concern writing to an index table

`fizzy/app/models/concerns/searchable.rb` (quoted in [`08-jobs-async.md`](08-jobs-async.md)) keeps an
index row per searchable record, maintained by `after_*_commit` callbacks, with the record class chosen
at runtime:

```ruby
    def search_record_class
      Search::Record.for(account_id)
    end
```

### The adapter split

`fizzy/app/models/search/record.rb:1-7`:

```ruby
class Search::Record < ApplicationRecord
  include const_get(connection.adapter_name)

  belongs_to :searchable, polymorphic: true
  belongs_to :card

  validates :account_id, :searchable_type, :searchable_id, :card_id, :board_id, :created_at, presence: true
```

`include const_get(connection.adapter_name)` resolves to `Search::Record::Trilogy` or
`Search::Record::SQLite` at class-definition time. Both concerns implement the same three-method
contract — `matching(query, account_id)` as a scope, `search_fields(query)`, and `for(account_id)` —
so `Search::Record.for(...).for_query(...)` reads identically either way
(`search/record.rb:25-42`):

```ruby
  scope :for_query, ->(query, user:) do
    query = Search::Query.wrap(query)

    if query.valid? && user.board_ids.any?
      matching(query.to_s, user.account_id).where(account_id: user.account_id, board_id: user.board_ids)
    else
      none
    end
  end
```

Note `else none` — an invalid query returns an empty relation, not `nil` and not an error.

### MySQL: 16 shards by CRC32, generated at boot

`fizzy/app/models/search/record/trilogy.rb:1-38`:

```ruby
module Search::Record::Trilogy
  extend ActiveSupport::Concern

  SHARD_COUNT = 16

  included do
    self.abstract_class = true
    before_save :set_account_key, :stem_content

    scope :matching, ->(query, account_id) do
      full_query = "+account#{account_id} +(#{Search::Stemmer.stem(query)})"
      where("MATCH(#{table_name}.account_key, #{table_name}.content, #{table_name}.title) AGAINST(? IN BOOLEAN MODE)", full_query)
    end

    SHARD_CLASSES = SHARD_COUNT.times.map do |shard_id|
      Class.new(self) do
        self.table_name = "search_records_#{shard_id}"

        def self.name
          "Search::Record"
        end
      end
    end.freeze
  end

  class_methods do
    def shard_id_for_account(account_id)
      Zlib.crc32(account_id.to_s) % SHARD_COUNT
    end

    def search_fields(query)
      "#{connection.quote(query.terms)} AS query"
    end

    def for(account_id)
      SHARD_CLASSES[shard_id_for_account(account_id)]
    end
  end
```

Sixteen anonymous subclasses, one per physical table, all reporting `name` as `"Search::Record"` so
polymorphic types and GlobalIDs stay stable. An account's rows always land in
`search_records_<crc32(account_id) % 16>`, which keeps each FTS index small without any sharding
infrastructure.

Also note the tenancy trick on line 11: the account id is baked into the **full-text query itself**
(`+account#{account_id}`) alongside a matching `account_key` column, so the FTS engine filters by
tenant, not just the `WHERE` clause.

### SQLite: one FTS5 virtual table

`fizzy/app/models/search/record/sqlite.rb:1-33`:

```ruby
module Search::Record::SQLite
  extend ActiveSupport::Concern

  included do
    attribute :result_title, :string
    attribute :result_content, :string

    has_one :search_records_fts, -> { with_rowid },
      class_name: "Search::Record::SQLite::Fts", foreign_key: :rowid, primary_key: :id, dependent: :destroy

    after_save :upsert_to_fts5_table

    scope :matching, ->(query, account_id) {
      joins("INNER JOIN search_records_fts ON search_records_fts.rowid = #{table_name}.id")
        .where("search_records_fts MATCH ?", query)
    }
  end

  class_methods do
    def search_fields(query)
      opening_mark = connection.quote(Search::Highlighter::OPENING_MARK)
      closing_mark = connection.quote(Search::Highlighter::CLOSING_MARK)
      ellipsis = connection.quote(Search::Highlighter::ELIPSIS)

      [ "highlight(search_records_fts, 0, #{opening_mark}, #{closing_mark}) AS result_title",
        "snippet(search_records_fts, 1, #{opening_mark}, #{closing_mark}, #{ellipsis}, 20) AS result_content",
        "#{connection.quote(query.terms)} AS query" ]
    end

    def for(account_id)
      self
    end
  end
```

The FTS5 virtual table is modelled as a real association with `rowid` as the foreign key. Highlighting
and snippeting are done by **SQLite functions selected as extra attributes** (`highlight(...)`,
`snippet(...)`), declared on the model with `attribute :result_title, :string` so Active Record casts
them. No Ruby-side excerpting.

`fizzy/app/models/search/` also holds `query.rb` (parsing/validating user input), `stemmer.rb`,
`highlighter.rb` and `result.rb` — a small set of POROs in `app/models`, exactly as
[`01-philosophy.md`](01-philosophy.md) describes.

### Writebook: FTS5 with hand-written SQL, sanitised in Ruby

`writebook/app/models/leaf/searchable.rb:12-40`:

```ruby
  class_methods do
    def reindex_all
      all.map &:reindex
    end

    def sanitize_query_syntax(terms)
      terms = terms.to_s
      terms = remove_invalid_search_characters(terms)
      terms = remove_unbalanced_quotes(terms)
      terms.presence
    end

    def search(terms)
      if terms = sanitize_query_syntax(terms)
        with_search_results_for(terms)
          .select(
            "leaves.*",
            "highlight(leaf_search_index, 0, '<mark>', '</mark>') as title_match",
            "snippet(leaf_search_index, 1, '<mark>', '</mark>', '...', 20) as content_match")
      else
        none
      end
    end

    def with_search_results_for(terms)
      joins("join leaf_search_index on leaves.id = leaf_search_index.rowid")
        .where("leaf_search_index match ?", terms)
    end
  end
```

with BM25 relevance as an ordinary scope (`writebook/app/models/leaf/searchable.rb:9`):

```ruby
    scope :favoring_title, -> { order(Arel.sql("bm25(leaf_search_index, 2.0)")) }
```

**Handling raw SQL safely** — the three things this file gets right:

1. **User input is sanitised into the query syntax**, not escaped ad hoc. `remove_invalid_search_characters`
   (`terms.gsub(/[^\w"]/, " ")`) and `remove_unbalanced_quotes` are private class methods, and an
   unusable query returns `none` (`searchable.rb:105-115`).
2. **Binds everywhere**, including in hand-written statements
   (`writebook/app/models/leaf/searchable.rb:92-96`):
   ```ruby
       def execute_sql_with_binds(*statement)
         self.class.connection.execute self.class.sanitize_sql(statement)

         self.class.connection.raw_connection.changes.nonzero?
       end
   ```
   `sanitize_sql` with a `["… ?", value]` array, never interpolation. The return value —
   `changes.nonzero?` — is then used to make the update idempotent (`searchable.rb:79-86`):
   ```ruby
       def update_in_search_index
         transaction do
           updated = execute_sql_with_binds "update leaf_search_index set title = ?, content = ? where rowid = ?",
             sanitize_for_index(title), sanitize_for_index(searchable_content), id

           create_in_search_index unless updated
         end
       end
   ```
3. **`Arel.sql` only around a literal**, never around anything derived from params.

And the comment explaining a security boundary precisely
(`writebook/app/models/leaf/searchable.rb:61-65`):

```ruby
    # Strip tags from content before indexing to keep the FTS table clean.
    # This is a hygiene measure, not a security boundary — display-time
    # sanitization in sanitize_search_result is the primary defense.
    # ActionText content (Pages) is already HTML-safe plain text via
    # ERB::Util.html_escape, so skip it to avoid double-encoding.
```

**Rule: when a comment concerns security, say which layer is the actual defence.**

### Campfire: a `Search` record is a saved query, not an index

`once-campfire/app/models/search.rb:1-18`, in full:

```ruby
class Search < ApplicationRecord
  belongs_to :user

  after_create :trim_recent_searches

  scope :ordered, -> { order(updated_at: :desc) }

  class << self
    def record(query)
      find_or_create_by(query: query).touch
    end
  end

  private
    def trim_recent_searches
      user.searches.excluding(user.searches.ordered.limit(10)).destroy_all
    end
end
```

Recent-searches history capped at 10 by a callback. `Search.record(query)` upserts and touches in one
call. Eighteen lines for a feature that often becomes a service object and a Redis list.

## Rich text and attachments are Rails' own

- `has_rich_text :description` / `:body` / `:public_description` (`fizzy/app/models/card.rb:13`,
  `once-campfire/app/models/message.rb:9`, `fizzy/app/models/board.rb:7`) — Action Text.
- `has_one_attached :image, dependent: :purge_later` (`fizzy/app/models/card.rb:11`),
  `has_one_attached :cover, dependent: :purge_later` (`writebook/app/models/book.rb:5`) — Active
  Storage, with `image_processing` + libvips for variants.
- Editors: writebook uses `redcarpet` for Markdown, campfire uses Trix, fizzy uses `lexxy`.
  Syntax highlighting is `rouge` server-side (fizzy, writebook) or `highlight.js` pinned in the
  importmap (campfire).

Storage config is per-instance rather than compiled in: fizzy has both `config/storage.yml` and
`config/storage.oss.yml`, with `aws-sdk-s3` required lazily (`gem "aws-sdk-s3", require: false`) so a
local-disk install never loads it.

## Seeds are real code, in `db/seeds/`

fizzy has `db/seeds.rb` plus a `db/seeds/` directory and an `Account::Seeder`
(`fizzy/app/models/account/seeder.rb`); writebook has `db/seeds.rb` and a `DemoContent` model
(`writebook/app/models/demo_content.rb`). `bin/setup` runs seeds only when the database is empty — see
[`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md).

## Related

- [`03-models.md`](03-models.md) — the model side of these tables.
- [`08-jobs-async.md`](08-jobs-async.md) — the `Searchable` concern's callbacks and Solid Queue.
- [`11-testing.md`](11-testing.md) — deterministic fixture UUIDs, which exist because of this schema.
- [`18-content-storage-portability.md`](18-content-storage-portability.md) — attachment authorization, storage lifecycle, and data portability.
