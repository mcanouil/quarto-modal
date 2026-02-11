--- @module modal-shortcode
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Load utils module
local utils = require(quarto.utils.resolve_path('_modules/utils.lua'):gsub('%.lua$', ''))

--- Generate a Bootstrap modal button for Quarto shortcode.
--- @param args table List of arguments (first is button type).
--- @param kwargs table Key-value arguments (target, label, classes, inside).
--- @param _meta table Pandoc document metadata.
--- @param _raw_args table Raw arguments.
--- @param _context table Pandoc context.
--- @return pandoc.RawBlock HTML button or pandoc.Null if invalid.
local function modal(args, kwargs, _meta, _raw_args, _context)
  if not quarto.doc.is_format('html:js') or not quarto.doc.has_bootstrap() then
    return pandoc.Null()
  end

  local button_type = utils.stringify(args[1]) or 'toggle'
  local target = utils.stringify(kwargs.target)
  local label = utils.stringify(kwargs.label)
  local classes = utils.stringify(kwargs.classes)
  local inside = utils.stringify(kwargs.inside) == 'true'

  if classes == '' then
    if button_type == 'toggle' or label ~= '' then
      classes = 'btn btn-primary'
    elseif button_type == 'dismiss' then
      classes = 'btn-close'
    end
  end

  --- @type string|nil HTML button string or nil if invalid button type
  local button_html = nil
  if button_type == 'toggle' then
    button_html = string.format(
      '<button type="button" data-bs-toggle="modal" data-bs-target="#%s" class="%s">%s</button>',
      target, classes, label
    )
  elseif button_type == 'dismiss' then
    if inside then
      button_html = string.format(
        '<button type="button" class="%s" data-bs-dismiss="modal" aria-label="Close">%s</button>',
        classes, label
      )
    else
      button_html = string.format(
        '<button type="button" class="%s" data-bs-dismiss="modal" data-bs-target="#%s" aria-label="Close">%s</button>',
        classes, target, label
      )
    end
  end

  if button_html then
    return pandoc.RawBlock('html', button_html)
  else
    return pandoc.Null()
  end
end

---
--- Export modal shortcode function for Quarto.
--- @return table Table with modal function.
---
return {
  ['modal'] = modal
}
