# Batching and Debouncing Reference

## Batch processing

```ruby
# Enqueue in bulk without loading every record
Card.active.in_batches do |batch|
  ActiveJob.perform_all_later(batch.map { |card| ProcessCardJob.new(card) })
end
```

Give every model that accumulates rows a `cleanup` class method, and drive it from
`config/recurring.yml`.

## Debouncing (avoid duplicate jobs)

```ruby
def reindex_later
  return if reindex_job_queued?
  ReindexBoardJob.perform_later(id)
end

def reindex_job_queued?
  SolidQueue::Job.exists?(
    job_class: "ReindexBoardJob",
    arguments: [id].to_json,
    finished_at: nil
  )
end
```
