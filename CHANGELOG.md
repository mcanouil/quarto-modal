# Changelog

## Unreleased

## 1.5.0 (2026-05-28)

### New Features

- feat: Add friendly `size` aliases (`small`, `medium`/`default`, `large`, `extra-large`/`xlarge`) and warn on unknown values.
- feat: Add `close-button` attribute to suppress the header close button and `close-button-label` to override its `aria-label`.
- feat: Validate `description` references and warn when the referenced identifier is absent from the document.
- feat: Detect nested modal containers and warn (Bootstrap does not support modal nesting).
- feat: Warn when a Div carries modal-specific attributes but its identifier is missing the required `modal-` prefix.
- feat: Warn on unknown `fullscreen` values instead of silently emitting no class.

### Bug Fixes

- fix: Preserve pre-existing `bs-toggle`/`bs-target` attributes on link expansion; the filter runs at `pre-quarto` where attributes have not yet been prefixed with `data-`, so writes now use the unprefixed names and detect existing values correctly.

### Refactoring

- refactor: Clarify the misleading filter-function comment to document that the callback is invoked on every Div and processes only those whose identifier starts with `modal-`.
- refactor: Synchronise shared modules (`content-extraction.lua`, `html.lua`, `logging.lua`, `metadata.lua`, `pandoc-helpers.lua`, `string.lua`) with the canonical version.

### Documentation

- docs: Document friendly size aliases, `close-button`/`close-button-label` attributes, `description` validation, and the nested-modal warning.

## 1.4.2 (2026-04-22)

### Bug Fixes

- fix: Preserve non-modal Divs in filter (return `nil` instead of `pandoc.Null()`), which previously deleted every Div without a `modal-` identifier from the output.

## 1.4.1 (2026-04-15)

### Refactoring

- refactor: Synchronise shared module (`logging.lua`) with canonical version.

## 1.4.0 (2026-03-23)

### Refactoring

- refactor: Replace monolithic `utils.lua` with focused modules (`string.lua`, `logging.lua`, `metadata.lua`, `pandoc-helpers.lua`, `html.lua`, `paths.lua`, `colour.lua`).

## 1.3.1 (2026-02-21)

### New Features

- feat: Rename element-attributes to attributes and add classes section (#17).

## 1.3.0 (2026-02-21)

### New Features

- feat: Add extension-provided code snippets (#15).
- feat: Add _schema.yml for configuration validation and IDE support (#12).

### Bug Fixes

- fix: Snippet should have ID using modal- prefix.

### Style

- style: Three colons by default.

## 1.2.1 (2026-02-11)

### Bug Fixes

- fix: Update copyright year.

## 1.2.0 (2025-12-03)

### Bug Fixes

- fix: Use british english spelling.

### Refactoring

- refactor: Update modal filter and README for content extraction (#9).

## 1.1.0 (2025-10-25)

### Refactoring

- refactor: Use module and enhance extension (#7).

## 1.0.2 (2025-08-08)

### New Features

- feat: Extend clipboard.js functionality to modals (#5).

## 1.0.1 (2025-07-27)

### New Features

- feat: Modal link expansion in markdown (#3).

### Documentation

- docs: `bs-target` and `bs-toggle` attributes.

## 1.0.0 (2025-07-27)

### Bug Fixes

- fix: Button before code.
- fix: Embedding resources not required.
- fix: Check for boostrap.

### Documentation

- docs: Add documentation and examples.
