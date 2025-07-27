# Modal Extension For Quarto

This Quarto extension provides a simple way to create Bootstrap modals in your HTML documents.
It allows you to define modal buttons and containers using shortcodes, making it easy to integrate modals into your content.

## Installation

```bash
quarto add mcanouil/quarto-modal
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Usage

To use modals in your HTML Quarto document, you need to include the `modal` extension in your YAML header.

```yaml
filters:
  - modal
```

### Options

You can customise the modals generally by setting options in the `extensions.modal` section of your YAML header.

```yaml
extensions:
  modal:
    size: null|sm|lg|xl
    backdrop-static: false|true
    scrollable: false|true
    keyboard: true|false
    centred: false|true
    fade: false|true
    fullscreen: false|true|sm|md|lg|xl|xxl
```

### Modal Structure

Modals are structured using a toggle button and a modal container.

#### Modal Button

- Use `{{< modal toggle ... >}}` to create a button that opens a modal.
- Use `{{< modal dismiss ... >}}` to create a button that closes a modal.
- Named arguments:
  - `target`: the modal's unique identifier required unless `inside=true`.
  - `label`: the button text.
  - `classes`: custom CSS classes for the button, e.g., `btn btn-primary`.
  - `inside`: set to `true` if the dismiss button is inside the modal to be dismissed.

```{.markdown shortcodes=false}
{{< modal <toggle|dismiss> target=<modal-id> label=<label> classes=<classes> inside=<boolean> >}}
```

#### Modal Container

```{.markdown shortcodes=false}
:::: {#modal-<id> description="<accessibility-description>" <options>}
## Modal Title

Body content goes here.

---

Footer content goes here.
:::
```

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Outputs of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-modal/)
