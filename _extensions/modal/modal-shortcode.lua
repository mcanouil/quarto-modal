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

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

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

--- Pandoc utility function for stringifying elements.
--- @type fun(element: table): string
local stringify = pandoc.utils.stringify

--- Generate a Bootstrap modal button for Quarto shortcode.
--- @param args table List of arguments (first is button type).
--- @param kwargs table Key-value arguments (target, label, classes, inside).
--- @param meta table Pandoc document metadata.
--- @param raw_args table Raw arguments.
--- @param context table Pandoc context.
--- @return pandoc.RawBlock HTML button or pandoc.Null if invalid.
function modal(args, kwargs, meta, raw_args, context)
  if not quarto.doc.is_format("html:js") or not quarto.doc.has_bootstrap() then
    return pandoc.Null()
  end

  local button_type = stringify(args[1]) or "toggle"
  local target = stringify(kwargs.target)
  local label = stringify(kwargs.label)
  local classes = stringify(kwargs.classes)
  local inside = stringify(kwargs.inside) == "true"

  if (classes == "" or classes == nil) then
    if button_type == "toggle" or (label ~= "" and label ~= nil) then
      classes = "btn btn-primary"
    elseif button_type == "dismiss" then
      classes = "btn-close"
    end
  end

  local button = pandoc.Null()
  if button_type == "toggle" then
    button = string.format(
      '<button type="button" data-bs-toggle="modal" data-bs-target="#%s" class="%s">%s</button>',
      target, classes, label
    )
  elseif button_type == "dismiss" then
    if inside then
      button = string.format(
        '<button type="button" class="%s" data-bs-dismiss="modal" aria-label="Close">%s</button>',
        classes, label
      )
    else
      button = string.format(
        '<button type="button" class="%s" data-bs-dismiss="modal" data-bs-target="#%s" aria-label="Close">%s</button>',
        classes, target, label
      )
    end
  end

  if button ~= nil then
    return pandoc.RawBlock("html", button)
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
