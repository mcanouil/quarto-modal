--[[
# MIT License
#
# Copyright (c) 2025 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

---
--- Quarto shortcode for Bootstrap modal buttons.
--- Usage:
---   {{< modal toggle target="myModal" label="Launch modal" classes="btn btn-success" >}}
---   {{< modal dismiss target="myModal" inside=false >}}
---   # Args: toggle|dismiss
---   # Kwargs: target, label, classes, inside
---

--- Load utils module
local utils_path = quarto.utils.resolve_path("_modules/utils.lua")
local utils = require(utils_path)

--- Generate a Bootstrap modal button for Quarto shortcode.
--- @param args table List of arguments (first is button type).
--- @param kwargs table Key-value arguments (target, label, classes, inside).
--- @param _meta table Pandoc document metadata.
--- @param _raw_args table Raw arguments.
--- @param _context table Pandoc context.
--- @return pandoc.RawBlock HTML button or pandoc.Null if invalid.
local function modal(args, kwargs, _meta, _raw_args, _context)
  if not quarto.doc.is_format("html:js") or not quarto.doc.has_bootstrap() then
    return pandoc.Null()
  end

  local button_type = utils.stringify(args[1]) or "toggle"
  local target = utils.stringify(kwargs.target)
  local label = utils.stringify(kwargs.label)
  local classes = utils.stringify(kwargs.classes)
  local inside = utils.stringify(kwargs.inside) == "true"

  if classes == "" then
    if button_type == "toggle" or label ~= "" then
      classes = "btn btn-primary"
    elseif button_type == "dismiss" then
      classes = "btn-close"
    end
  end

  --- @type string|nil HTML button string or nil if invalid button type
  local button_html = nil
  if button_type == "toggle" then
    button_html = string.format(
      '<button type="button" data-bs-toggle="modal" data-bs-target="#%s" class="%s">%s</button>',
      target, classes, label
    )
  elseif button_type == "dismiss" then
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
    return pandoc.RawBlock("html", button_html)
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
