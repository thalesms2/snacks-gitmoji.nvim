# Spec Delta

## MODIFIED Requirements

### Requirement: Prompt for a commit title after selecting an emoji
When the default action is invoked with a selected gitmoji entry, and
`use_scratch` is not enabled, the system SHALL open a `Snacks.input()`
single-line prompt whose prompt text displays the selected emoji (or no
emoji text, when no emoji was selected), so the user only has to type the
commit title. The prompt SHALL enter insert mode automatically when it
opens, so the user can start typing the title immediately without pressing
`i`.

#### Scenario: Input prompt shows the selected emoji
- **WHEN** the default action runs for the "bug" entry (emoji `🐛`)
- **THEN** a `Snacks.input()` prompt opens with the emoji `🐛` visible in the
  prompt text and an empty editable value for the title

#### Scenario: Input prompt opens in insert mode
- **WHEN** the default action runs for any entry, with or without an emoji
- **THEN** the `Snacks.input()` prompt opens with the cursor already in
  insert mode, ready to accept typed input

#### Scenario: Input prompt shows no emoji text when none was selected
- **WHEN** the default action runs for the "No emoji" entry
- **THEN** a `Snacks.input()` prompt opens with no emoji character in the
  prompt text and an empty editable value for the title

### Requirement: Run git commit with the emoji-prefixed title
The system SHALL run a git commit using the selected emoji and the title
entered by the user, in the form `<emoji> <title>` as the commit message.
When no emoji was selected (the "No emoji" entry), the system SHALL run the
commit using the title as typed, with no emoji prefix.

#### Scenario: Confirming the title commits
- **WHEN** the user types `fix off-by-one in paginator` into the title
  prompt for the "bug" entry and confirms
- **THEN** the system runs a commit equivalent to
  `git commit -m "🐛 fix off-by-one in paginator"`

#### Scenario: Confirming the title commits with no emoji prefix
- **WHEN** the user selected the "No emoji" entry, types
  `tidy up CI config` into the title prompt, and confirms
- **THEN** the system runs a commit equivalent to
  `git commit -m "tidy up CI config"`, with no emoji prefix

#### Scenario: Cancelling the title prompt aborts the commit
- **WHEN** the user opens the title prompt and cancels it (e.g. presses
  Escape or submits an empty/aborted input)
- **THEN** no git commit is run
