# gitmoji-commit-input Specification

## Purpose
Defines the default post-selection behavior: prompting for a commit title
and running `git commit` with the chosen emoji prefix.

## Requirements

### Requirement: Prompt for a commit title after selecting an emoji
When the default action is invoked with a selected gitmoji entry, and
`use_scratch` is not enabled, the system SHALL open a `Snacks.input()`
single-line prompt whose prompt text displays the selected emoji, so the
user only has to type the commit title.

#### Scenario: Input prompt shows the selected emoji
- **WHEN** the default action runs for the "bug" entry (emoji `🐛`)
- **THEN** a `Snacks.input()` prompt opens with the emoji `🐛` visible in the
  prompt text and an empty editable value for the title

### Requirement: Run git commit with the emoji-prefixed title
The system SHALL run a git commit using the selected emoji and the title
entered by the user, in the form `<emoji> <title>` as the commit message.

#### Scenario: Confirming the title commits
- **WHEN** the user types `fix off-by-one in paginator` into the title
  prompt for the "bug" entry and confirms
- **THEN** the system runs a commit equivalent to
  `git commit -m "🐛 fix off-by-one in paginator"`

#### Scenario: Cancelling the title prompt aborts the commit
- **WHEN** the user opens the title prompt and cancels it (e.g. presses
  Escape or submits an empty/aborted input)
- **THEN** no git commit is run

### Requirement: Prefer vim-fugitive when loaded
The system SHALL run the commit through vim-fugitive's `:G commit` when
`vim.g.loaded_fugitive` is truthy, and SHALL otherwise fall back to running
`git commit` as a shell command.

#### Scenario: Fugitive is loaded
- **GIVEN** `vim.g.loaded_fugitive` is truthy
- **WHEN** a commit is executed after the title prompt
- **THEN** the system runs the commit via `:G commit -m "..."`

#### Scenario: Fugitive is not loaded
- **GIVEN** `vim.g.loaded_fugitive` is falsy or unset
- **WHEN** a commit is executed after the title prompt
- **THEN** the system runs the commit via a shell `git commit -m "..."`
  command

### Requirement: Custom action overrides the default input flow
The system SHALL allow the consumer to replace the default commit action
with a custom function via `setup({ action = ... })`, receiving the same
picker entry shape as the default action.

#### Scenario: Custom action is configured
- **GIVEN** the consumer called
  `setup({ action = function(entry) ... end })`
- **WHEN** the user selects a gitmoji entry in the picker
- **THEN** the configured custom function is called instead of the default
  input-and-commit flow
