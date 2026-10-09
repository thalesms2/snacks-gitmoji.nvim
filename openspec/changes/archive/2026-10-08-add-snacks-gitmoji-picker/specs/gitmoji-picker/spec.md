# Spec Delta

## Purpose

Lets a Neovim user browse and fuzzy-filter the full gitmoji set in a
Snacks.picker window and hand off the chosen emoji to a commit action.

## ADDED Requirements

### Requirement: List all gitmoji entries
The system SHALL open a `Snacks.picker` window listing every gitmoji entry
bundled with the plugin. Each entry SHALL display the emoji character, its
`:code:` form, and its one-line description.

#### Scenario: Open the picker with no arguments
- **WHEN** the user runs `:SnacksGitmoji` or calls
  `require("snacks-gitmoji").gitmoji()`
- **THEN** a picker window opens showing every bundled gitmoji entry with its
  emoji, code, and description visible

### Requirement: Fuzzy-filter gitmoji by description or code
The system SHALL allow the user to type a query in the picker's prompt to
fuzzy-filter the list by the entry's description and `:code:` text.

#### Scenario: Filtering narrows the list
- **WHEN** the user types `bug` into the picker prompt
- **THEN** the list narrows to entries whose description or code text matches
  `bug` (for example the "Fix a bug." entry), ranked by match quality

### Requirement: Recently and frequently used emoji are ranked higher
The system SHALL track how often and how recently each emoji was selected
and used across previous invocations, and SHALL use that history to rank
higher-scoring emoji above others when the prompt is empty or scores are
tied.

#### Scenario: A previously selected emoji ranks above an unused one
- **GIVEN** the user selected the "bug" emoji in a prior session and has
  never selected the "lipstick" emoji
- **WHEN** the user opens the picker again with an empty prompt
- **THEN** the "bug" entry is ordered above the "lipstick" entry

### Requirement: Selecting an entry invokes the configured action
The system SHALL invoke a configurable action function with the selected
gitmoji entry when the user confirms a selection, and SHALL close the picker
before invoking it. If the user cancels the picker without selecting an
entry, the system SHALL NOT invoke the action.

#### Scenario: Confirming a selection runs the action
- **WHEN** the user highlights the "sparkles" entry and confirms the
  selection (e.g. presses Enter)
- **THEN** the picker closes and the configured action function is called
  with the "sparkles" entry's emoji, code, and description

#### Scenario: Cancelling the picker runs no action
- **WHEN** the user opens the picker and cancels it (e.g. presses Escape)
  without confirming a selection
- **THEN** the picker closes and no action function is invoked
