# Turbo Testing and Performance Reference

## Testing Turbo

```ruby
# Controller test
test "create returns turbo stream" do
  post card_comments_path(@card),
    params: { comment: { body: "Test" } },
    as: :turbo_stream

  assert_response :success
  assert_equal "text/vnd.turbo-stream.html", response.media_type
  assert_match /turbo-stream/, response.body
end

# System test
test "creating a comment" do
  visit card_path(@card)
  fill_in "Body", with: "Great card!"
  click_button "Add Comment"
  assert_text "Great card!"  # Turbo Stream inserts without reload
end
```

## Performance tips

1. **Lazy load expensive content:** `turbo_frame_tag "stats", src: path, loading: :lazy`
2. **Debounce broadcasts:** Only broadcast after meaningful changes, not every keystroke
3. **Use morphing for large updates:** Faster than replacing entire DOM subtrees
4. **Target specific elements:** Update just the count, not the entire sidebar
