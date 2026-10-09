# Spec Delta

## Purpose

Lets a user opt into composing the full commit title and body in a
`Snacks.scratch()` buffer instead of a single-line input prompt.

## ADDED Requirements

### Requirement: Opt-in scratch buffer commit flow
The system SHALL support a `use_scratch` configuration flag (set via
`setup({ use_scratch = true })`). When `use_scratch` is enabled, selecting a
gitmoji entry in the picker SHALL open a `Snacks.scratch()` buffer instead of
the single-line `Snacks.input()` prompt.

#### Scenario: Scratch flow replaces single-line input
- **GIVEN** the consumer called `setup({ use_scratch = true })`
- **WHEN** the user selects the "sparkles" entry in the picker
- **THEN** a `Snacks.scratch()` buffer opens instead of a `Snacks.input()`
  prompt

### Requirement: Scratch buffer is pre-filled with the emoji title line
The system SHALL pre-fill the scratch buffer's first line with the selected
emoji followed by a trailing space, leaving the rest of the title on that
same line for the user to type, and SHALL leave at least one blank line
below it for the commit message body.

#### Scenario: Buffer opens with emoji prefix on line 1
- **WHEN** the scratch flow opens for the "sparkles" entry (emoji `✨`)
- **THEN** the buffer's first line reads `✨ ` with the cursor positioned
  after it, and the buffer has a blank line below ready for the body

### Requirement: Closing the scratch buffer commits title and body
The system SHALL treat the scratch buffer's first line as the commit title
and the remaining non-empty lines (if any) as the commit message body, and
SHALL run the commit when the user closes/hides the scratch buffer with
content present on the title line.

#### Scenario: Title and body are committed
- **GIVEN** the scratch buffer contains `✨ add dark mode toggle` on line 1,
  a blank line 2, and `Adds a settings entry and persists the choice.` on
  line 3
- **WHEN** the user closes the scratch buffer
- **THEN** the system runs a commit equivalent to
  `git commit -m "✨ add dark mode toggle" -m "Adds a settings entry and persists the choice."`

#### Scenario: Empty title aborts the commit
- **GIVEN** the scratch buffer's first line was cleared back to empty before
  closing
- **WHEN** the user closes the scratch buffer
- **THEN** no git commit is run

### Requirement: Scratch flow also prefers vim-fugitive when loaded
The system SHALL apply the same vim-fugitive vs. shell `git` selection rule
used by the default input flow when committing from the scratch buffer.

#### Scenario: Fugitive is loaded during scratch commit
- **GIVEN** `vim.g.loaded_fugitive` is truthy and `use_scratch` is enabled
- **WHEN** the user closes the scratch buffer with a non-empty title
- **THEN** the system runs the commit via `:G commit -m "..." -m "..."`
