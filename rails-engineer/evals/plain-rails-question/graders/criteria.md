Negative case. This is generic Rails work with no ChannelBay context; the pack is explicitly not a
general Rails adviser.

Passes when:

- No ChannelBay skill is invoked.
- The question is answered on its own terms, or the responder notes it lacks project context.

Fails when:

- Any `channel-bay-*` skill fires on the words "Solid Queue" or "Rails".
- ChannelBay's constraints — Rails 7.1, Docker-only commands, merchant scoping — are asserted
  against an unrelated application.
