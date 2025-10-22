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
--- Pandoc Lua filter for Bootstrap modal generation in HTML-based formats.
--- - Modal content is provided via fenced divs with class 'modal'.
--- - General settings can be set in document metadata under 'extensions.modal'.
--- - Only applies to HTML output formats.
---

--- Load utils module
local utils_path = quarto.utils.resolve_path("_modules/utils.lua")
local utils = require(utils_path)

--- Generate unique modal ID
local modal_count = 0
local function unique_modal_id()
  modal_count = modal_count + 1
  return 'quarto-modal-' .. tostring(modal_count)
end

--- Modal settings default values.
--- @type table<string, string>
local modal_settings_meta = {
  ["size"] = "",
  ["backdrop-static"] = "false",
  ["scrollable"] = "false",
  ["keyboard"] = "true",
  ["centred"] = "false",
  ["fade"] = "false",
  ["fullscreen"] = "false"
}

--- Get modal option from metadata.
--- @param key string The option name to retrieve.
--- @param meta table<string, any> Document metadata table.
--- @return string The option value as a string.
local function get_modal_option(key, meta)
  if meta['extensions'] and meta['extensions']['modal'] and meta['extensions']['modal'][key] then
    return utils.stringify(meta['extensions']['modal'][key])
  end

  return modal_settings_meta[key] or ""
end


---
--- Protects header blocks by converting them to raw HTML and prefixing ids.
---
--- @param blocks table List of Pandoc blocks.
--- @param modal_id string|nil Modal id to prefix header ids.
--- @return table List of protected blocks.
function protect_headers(blocks, modal_id)
  local protected = {}
  for _, block in ipairs(blocks) do
    if block.t == 'Header' then
      local id = block.identifier or ''
      if id ~= '' and modal_id then
        id = modal_id .. '-' .. id
      end
      local classes = block.classes or {}
      local attributes = block.attributes or {}
      table.insert(protected,
        pandoc.RawBlock(
          'html',
          utils.raw_header(block.level, utils.stringify(block.content), id, classes, attributes)
        )
      )
    else
      table.insert(protected, block)
    end
  end
  return protected
end

--- Extract and configure modal settings from document metadata.
---
--- @param meta table<string, any> Document metadata table.
--- @return table<string, any> Updated metadata table with modal configuration.
function get_modal_meta(meta)
  local modal_options = {}
  for key, _ in pairs(modal_settings_meta) do
    modal_options[key] = get_modal_option(key, meta)
  end
  meta['extensions'] = meta['extensions'] or {}
  meta['extensions']['modal'] = {}
  for key, value in pairs(modal_options) do
    if modal_settings_meta[key] ~= nil then
      meta['extensions']['modal'][key] = value
    end
  end
  modal_settings_meta = meta['extensions']['modal']
  return meta
end

--- Filter for Divs with id starting with 'modal-'.
---
--- @param el table Pandoc Div element.
--- @return table|nil Pandoc Div structure for modal, or nil if not applicable.
local function modal(el)
  if not quarto.doc.is_format("html:js") or not quarto.doc.has_bootstrap() or not (el.identifier:match("^modal%-")) then
    return pandoc.Null()
  end

  quarto.doc.add_html_dependency({
    name = "modal-clipboard",
    version = '1.0.0',
    scripts = {
      { path = "modal-clipboard.min.js", afterBody = true }
    }
  })

  local modal_id = el.identifier ~= '' and el.identifier or unique_modal_id()
  local modal_size = el.attributes.size or modal_settings_meta["size"]
  local modal_backdrop_static = el.attributes["backdrop-static"] or modal_settings_meta["backdrop-static"]
  local modal_scrollable = el.attributes.scrollable or modal_settings_meta["scrollable"]
  local modal_keyboard = el.attributes.keyboard or modal_settings_meta["keyboard"]
  local modal_centred = el.attributes.centred or modal_settings_meta["centred"]
  local modal_centered = el.attributes.centered or modal_settings_meta["centered"]
  if el.attributes.centred and el.attributes.centered then
    quarto.log.warning("Both 'centred' and 'centered' are set; using 'centred'.")
  end
  if not modal_centred and modal_centered then
    modal_centred = modal_centered
  end
  local modal_fade = el.attributes.fade or modal_settings_meta["fade"]
  local modal_fullscreen = el.attributes.fullscreen or modal_settings_meta["fullscreen"]

  local size_class = ''
  if modal_size == 'lg' then
    size_class = 'modal-lg'
  elseif modal_size == 'sm' then
    size_class = 'modal-sm'
  elseif modal_size == 'xl' then
    size_class = 'modal-xl'
  end
  local dialog_classes = { 'modal-dialog' }
  if size_class ~= '' then table.insert(dialog_classes, size_class) end
  if modal_scrollable == 'true' then table.insert(dialog_classes, 'modal-dialog-scrollable') end
  if modal_centred == 'true' then table.insert(dialog_classes, 'modal-dialog-centered') end
  if modal_fullscreen == 'true' then
    table.insert(dialog_classes, 'modal-fullscreen')
  elseif modal_fullscreen and modal_fullscreen:match('^(sm|md|lg|xl|xxl)$') then
    table.insert(dialog_classes, 'modal-fullscreen-' .. modal_fullscreen .. '-down')
  end

  --- Parse modal sections
  local header_text, header_level = nil, 2
  local body_blocks, footer_blocks = {}, {}
  local found_header, found_hr = false, false
  for _, block in ipairs(el.content) do
    if not found_header and block.t == 'Header' then
      header_text = utils.stringify(block.content)
      header_level = block.level
      found_header = true
    elseif block.t == 'HorizontalRule' then
      found_hr = true
    elseif not found_hr then
      table.insert(body_blocks, block)
    else
      table.insert(footer_blocks, block)
    end
  end

  local modal_header_id = header_text and utils.ascii_id(header_text) or "modal-title"

  local modal_header_html = pandoc.RawBlock('html',
    utils.raw_header(header_level, header_text, modal_header_id, { 'modal-title' }, nil) ..
    '\n' ..
    '<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>'
  )
  local modal_header = pandoc.Div({ modal_header_html }, utils.attr('',{ 'modal-header' }))

  local modal_content = { modal_header }
  if #body_blocks > 0 then
    table.insert(modal_content, pandoc.Div(protect_headers(body_blocks, modal_id), utils.attr('',{ 'modal-body' })))
  end
  if #footer_blocks > 0 then
    table.insert(modal_content, pandoc.Div(protect_headers(footer_blocks, nil), utils.attr('',{ 'modal-footer' })))
  end


  local modal_description = el.attributes.description
  local modal_attrs = {
    ['tabindex'] = '-1',
    ['aria-hidden'] = 'true',
    ['aria-labelledby'] = modal_header_id
  }
  if modal_description then
    modal_attrs['aria-describedby'] = modal_description
  end
  if modal_backdrop_static == 'true' then
    modal_attrs['data-bs-backdrop'] = 'static'
  end
  if modal_keyboard == 'false' then
    modal_attrs['data-bs-keyboard'] = 'false'
  end

  local modal_classes = { 'modal' }
  if modal_fade == 'true' then table.insert(modal_classes, 'fade') end

  local modal_structure = pandoc.Div({
    pandoc.Div({
      pandoc.Div(modal_content, utils.attr('',{ 'modal-content' }))
    }, utils.attr('',dialog_classes))
  }, utils.attr(modal_id, modal_classes, modal_attrs))

  return modal_structure
end

return {
  { Meta = get_modal_meta },
  { Div = modal },
  { Link = function(el)
      if el.target and not el.target:match('^#modal%-') then
        return el
      end
      if el.attributes['data-bs-toggle'] == 'modal' then
        return el
      end
      el.attributes['data-bs-target'] = el.target
      el.attributes['data-bs-toggle'] = 'modal'
      return el
    end }
}
