# Spec Delta

## ADDED Requirements

### Requirement: A "No emoji" entry is pinned above the gitmoji list
The system SHALL always render a "No emoji" entry at the top of the picker
list, above every frecency-sorted gitmoji entry, regardless of search query
or frecency scores. The system SHALL NOT include this entry in frecency
scoring or recording.

#### Scenario: No emoji entry is the default highlight
- **WHEN** the user opens the picker with an empty prompt
- **THEN** the "No emoji" entry is the first item shown, above any
  previously-used gitmoji entries

#### Scenario: Confirming the no-emoji entry skips emoji selection
- **WHEN** the user opens the picker and confirms immediately (e.g. presses
  `<CR>` without typing or moving the selection)
- **THEN** the picker closes and the configured action is invoked with an
  entry that carries no emoji, and frecency is not updated

#### Scenario: No emoji entry is unaffected by filtering
- **WHEN** the user types a query into the picker prompt
- **THEN** the "No emoji" entry's presence or position in the fuzzy-matched
  results is not scored using frecency (it may still match or be filtered
  out like any other entry's text, per the existing fuzzy-filter
  requirement)

### Requirement: The picker opens without a preview panel
The system SHALL open the picker with no preview pane; only the list of
emoji, code, and description is shown.

#### Scenario: Picker has no preview pane
- **WHEN** the user opens the picker
- **THEN** no preview panel is displayed alongside the list, regardless of
  which entry is highlighted
