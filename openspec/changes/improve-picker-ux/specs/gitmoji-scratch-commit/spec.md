# Spec Delta

## MODIFIED Requirements

### Requirement: Scratch buffer is pre-filled with the emoji title line
The system SHALL pre-fill the scratch buffer's first line with the selected
emoji followed by a trailing space, leaving the rest of the title on that
same line for the user to type, and SHALL leave at least one blank line
below it for the commit message body. When no emoji was selected (the "No
emoji" entry), the system SHALL leave the first line empty (no leading
emoji or space) instead, with the cursor at the start of that line.

#### Scenario: Buffer opens with emoji prefix on line 1
- **WHEN** the scratch flow opens for the "sparkles" entry (emoji `✨`)
- **THEN** the buffer's first line reads `✨ ` with the cursor positioned
  after it, and the buffer has a blank line below ready for the body

#### Scenario: Buffer opens with no emoji prefix when none was selected
- **WHEN** the scratch flow opens for the "No emoji" entry
- **THEN** the buffer's first line is empty with the cursor at the start of
  it, and the buffer has a blank line below ready for the body

### Requirement: Closing the scratch buffer commits title and body
The system SHALL treat the scratch buffer's first line as the commit title
and the remaining non-empty lines (if any) as the commit message body, and
SHALL run the commit when the user closes/hides the scratch buffer with
content present on the title line. When no emoji was selected, the title
line SHALL be committed as typed, with no emoji prefix to strip or require.

#### Scenario: Title and body are committed
- **GIVEN** the scratch buffer contains `✨ add dark mode toggle` on line 1,
  a blank line 2, and `Adds a settings entry and persists the choice.` on
  line 3
- **WHEN** the user closes the scratch buffer
- **THEN** the system runs a commit equivalent to
  `git commit -m "✨ add dark mode toggle" -m "Adds a settings entry and persists the choice."`

#### Scenario: Title and body are committed with no emoji prefix
- **GIVEN** the scratch flow was opened for the "No emoji" entry and the
  buffer contains `tidy up CI config` on line 1, a blank line 2, and
  `Pins the action versions.` on line 3
- **WHEN** the user closes the scratch buffer
- **THEN** the system runs a commit equivalent to
  `git commit -m "tidy up CI config" -m "Pins the action versions."`, with no
  emoji prefix

#### Scenario: Empty title aborts the commit
- **GIVEN** the scratch buffer's first line was cleared back to empty before
  closing
- **WHEN** the user closes the scratch buffer
- **THEN** no git commit is run
