--- @module modal-filter
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = "modal"

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_modules/pandoc-helpers.lua'):gsub('%.lua$', ''))
local html_mod = require(quarto.utils.resolve_path('_modules/html.lua'):gsub('%.lua$', ''))

--- Load content-extraction module
local content = require(quarto.utils.resolve_path('_modules/content-extraction.lua'):gsub('%.lua$', ''))

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

--- Friendly size presets that map to Bootstrap sizes.
--- Empty string keeps Bootstrap's default 500px width.
--- @type table<string, string>
local SIZE_PRESETS = {
  ["small"] = "sm",
  ["sm"] = "sm",
  ["medium"] = "",
  ["default"] = "",
  [""] = "",
  ["large"] = "lg",
  ["lg"] = "lg",
  ["extra-large"] = "xl",
  ["xlarge"] = "xl",
  ["xl"] = "xl"
}

--- Valid fullscreen breakpoint values, excluding boolean strings.
--- @type table<string, boolean>
local FULLSCREEN_BREAKPOINTS = {
  ["sm"] = true,
  ["md"] = true,
  ["lg"] = true,
  ["xl"] = true,
  ["xxl"] = true
}

--- Attribute names that mark a Div as intended to be a modal.
--- Used to detect Divs with modal-specific configuration but an
--- identifier missing the required ``modal-`` prefix.
--- @type table<integer, string>
local MODAL_ATTRIBUTE_HINTS = {
  "size",
  "backdrop-static",
  "scrollable",
  "keyboard",
  "centred",
  "centered",
  "fade",
  "fullscreen",
  "description",
  "close-button",
  "close-button-label"
}

--- Set of identifiers present anywhere in the document.
--- Populated during the Pandoc pass before Div processing.
--- @type table<string, boolean>
local document_ids = {}

--- Get modal option from metadata.
--- @param key string The option name to retrieve.
--- @param meta table<string, any> Document metadata table.
--- @return string The option value as a string.
local function get_modal_option(key, meta)
  local meta_value = meta_mod.get_metadata_value(meta, 'modal', key)
  if not str.is_empty(meta_value) then
    return meta_value
  end

  return modal_settings_meta[key] or ''
end

--- Resolve a user-supplied size value to a Bootstrap size token.
--- Accepts both raw Bootstrap tokens (``sm``/``lg``/``xl``) and friendly
--- aliases (``small``/``large``/``extra-large``).
--- Emits a warning and returns the empty default when the value is unknown.
--- @param value string|nil User-supplied size value.
--- @return string Resolved Bootstrap size token (one of "", "sm", "lg", "xl").
local function resolve_size(value)
  if value == nil or value == '' then
    return ''
  end
  local normalised = value:lower()
  local resolved = SIZE_PRESETS[normalised]
  if resolved == nil then
    log.log_warning(
      EXTENSION_NAME,
      "Unknown 'size' value '" .. value .. "'. " ..
      "Expected one of: small/sm, medium/default, large/lg, extra-large/xlarge/xl. " ..
      "Falling back to the default size."
    )
    return ''
  end
  return resolved
end

--- Collect every identifier appearing anywhere in the document.
--- Walks Pandoc blocks and inlines exactly once so later validations
--- (e.g. ``description`` references) can resolve targets cheaply.
--- @param doc table Pandoc Pandoc element.
local function collect_document_ids(doc)
  document_ids = {}
  local function record(el)
    if el.identifier and el.identifier ~= '' then
      document_ids[el.identifier] = true
    end
  end
  pandoc.walk_block(pandoc.Div(doc.blocks), {
    Div = record,
    Header = record,
    Span = record,
    Link = record,
    Image = record,
    CodeBlock = record,
    Table = record
  })
end

--- Extract and configure modal settings from document metadata.
---
--- @param doc table Pandoc Pandoc element.
--- @return table Updated Pandoc Pandoc element.
local function get_modal_meta(doc)
  local meta = doc.meta
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
  doc.meta = meta
  collect_document_ids(doc)
  return doc
end

--- Check whether a Div carries any attribute that suggests it was meant
--- to be a modal but is missing the ``modal-`` identifier prefix.
--- @param el table Pandoc Div element.
--- @return boolean True if any modal-specific attribute is set.
local function has_modal_attributes(el)
  if not el.attributes then return false end
  for _, attr_name in ipairs(MODAL_ATTRIBUTE_HINTS) do
    local value = el.attributes[attr_name]
    if value ~= nil and value ~= '' then
      return true
    end
  end
  return false
end

--- Detect modal Divs nested inside the supplied blocks and warn.
--- HTML and Bootstrap do not support nesting modals; nested modals are
--- almost always a markup mistake and lead to focus and backdrop issues.
--- @param blocks table<integer, table> Blocks to scan.
--- @param parent_id string Identifier of the enclosing modal.
local function warn_on_nested_modals(blocks, parent_id)
  if blocks == nil then return end
  pandoc.walk_block(pandoc.Div(blocks), {
    Div = function(child)
      if child.identifier and child.identifier:match('^modal%-') then
        log.log_warning(
          EXTENSION_NAME,
          "Modal '" .. parent_id .. "' contains nested modal '" .. child.identifier .. "'. " ..
          "Bootstrap does not support modal nesting; please move the nested modal out of its parent."
        )
      end
    end
  })
end

--- Process Divs whose identifier starts with ``modal-``.
--- Invoked by Pandoc on every Div; returns ``nil`` (leaving the Div
--- untouched) when the Div is not a modal container or when the active
--- format does not support Bootstrap modals.
---
--- @param el table Pandoc Div element.
--- @return table|nil Pandoc Div structure for a modal, or nil if not applicable.
local function modal(el)
  if not quarto.doc.is_format("html:js") or not quarto.doc.has_bootstrap() then
    return nil
  end

  local has_modal_prefix = el.identifier:match("^modal%-") ~= nil
  if not has_modal_prefix then
    if has_modal_attributes(el) then
      log.log_warning(
        EXTENSION_NAME,
        "Div '" .. (el.identifier ~= '' and el.identifier or '(no id)') ..
        "' carries modal-specific attributes but its identifier does not start with 'modal-'. " ..
        "Modal Divs must use an identifier like '#modal-my-id'."
      )
    end
    return nil
  end

  quarto.doc.add_html_dependency({
    name = "modal-clipboard",
    version = '1.0.0',
    scripts = {
      { path = "modal-clipboard.min.js", afterBody = true }
    }
  })

  local modal_id = el.identifier ~= '' and el.identifier or unique_modal_id()

  local raw_size = el.attributes.size or modal_settings_meta["size"]
  local modal_size = resolve_size(raw_size)
  local modal_backdrop_static = el.attributes["backdrop-static"] or modal_settings_meta["backdrop-static"]
  local modal_scrollable = el.attributes.scrollable or modal_settings_meta["scrollable"]
  local modal_keyboard = el.attributes.keyboard or modal_settings_meta["keyboard"]
  local modal_centred = el.attributes.centred or modal_settings_meta["centred"]
  local modal_centered = el.attributes.centered or modal_settings_meta["centered"]
  if el.attributes.centred and el.attributes.centered then
    log.log_warning(EXTENSION_NAME, "Both 'centred' and 'centered' are set; using 'centred'.")
  end
  if not modal_centred and modal_centered then
    modal_centred = modal_centered
  end
  local modal_fade = el.attributes.fade or modal_settings_meta["fade"]
  local modal_fullscreen = el.attributes.fullscreen or modal_settings_meta["fullscreen"]

  local dialog_classes = { 'modal-dialog' }
  if modal_size ~= '' then table.insert(dialog_classes, 'modal-' .. modal_size) end
  if modal_scrollable == 'true' then table.insert(dialog_classes, 'modal-dialog-scrollable') end
  if modal_centred == 'true' then table.insert(dialog_classes, 'modal-dialog-centered') end
  if modal_fullscreen == 'true' then
    table.insert(dialog_classes, 'modal-fullscreen')
  elseif modal_fullscreen and FULLSCREEN_BREAKPOINTS[modal_fullscreen] then
    table.insert(dialog_classes, 'modal-fullscreen-' .. modal_fullscreen .. '-down')
  elseif modal_fullscreen and modal_fullscreen ~= 'false' and modal_fullscreen ~= '' then
    log.log_warning(
      EXTENSION_NAME,
      "Unknown 'fullscreen' value '" .. modal_fullscreen .. "' on modal '" .. modal_id .. "'. " ..
      "Expected one of: false, true, sm, md, lg, xl, xxl. Falling back to no fullscreen."
    )
  end

  --- Parse modal sections
  local parsed = content.parse_sections(el.content)
  local header_text = parsed.header_text
  local header_level = parsed.header_level
  local body_blocks = parsed.body_blocks
  local footer_blocks = parsed.footer_blocks

  warn_on_nested_modals(body_blocks, modal_id)
  warn_on_nested_modals(footer_blocks, modal_id)

  local modal_header_id = header_text and str.ascii_id(header_text) or "modal-title"

  --- Optional close button in the header (Bootstrap-rendered "x").
  --- ``close-button=false`` suppresses it; ``close-button-label`` overrides
  --- the default aria-label (useful for localisation).
  local close_button_attr = el.attributes['close-button']
  local include_close_button = close_button_attr == nil or close_button_attr ~= 'false'
  local close_button_label = el.attributes['close-button-label'] or 'Close'

  local header_html = html_mod.raw_header(
    header_level,
    header_text,
    modal_header_id,
    { 'modal-title' },
    nil
  )
  if include_close_button then
    header_html = header_html ..
        '\n' ..
        '<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="' ..
        str.escape_attribute(close_button_label) .. '"></button>'
  end
  local modal_header = pandoc.Div({ pandoc.RawBlock('html', header_html) }, pdoc.attr('', { 'modal-header' }))

  local modal_content = { modal_header }
  if #body_blocks > 0 then
    table.insert(modal_content, pandoc.Div(content.protect_headers(body_blocks, modal_id .. '-', 'html'), pdoc.attr('', { 'modal-body' })))
  end
  if #footer_blocks > 0 then
    table.insert(modal_content, pandoc.Div(content.protect_headers(footer_blocks, '', 'html'), pdoc.attr('', { 'modal-footer' })))
  end

  local modal_description = el.attributes.description
  local modal_attrs = {
    ['tabindex'] = '-1',
    ['aria-hidden'] = 'true',
    ['aria-labelledby'] = modal_header_id
  }
  if modal_description then
    if not document_ids[modal_description] then
      log.log_warning(
        EXTENSION_NAME,
        "Modal '" .. modal_id .. "' has description='" .. modal_description ..
        "' but no element with that identifier exists in the document."
      )
    end
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
      pandoc.Div(modal_content, pdoc.attr('', { 'modal-content' }))
    }, pdoc.attr('', dialog_classes))
  }, pdoc.attr(modal_id, modal_classes, modal_attrs))

  return modal_structure
end

--- Expand bare Markdown links to a ``#modal-*`` anchor into Bootstrap
--- modal triggers.
---
--- Runs at the ``pre-quarto`` filter stage, where Pandoc-style attribute
--- names (``bs-target``, ``bs-toggle``) have not yet been prefixed with
--- ``data-`` by Quarto. The filter checks (and writes) the unprefixed
--- names so that author intent is preserved: if the link already declares
--- a Bootstrap toggle or target, the filter leaves it alone.
--- @param el table Pandoc Link element.
--- @return table Possibly-modified Link element.
local function expand_modal_link(el)
  if not el.target or not el.target:match('^#modal%-') then
    return el
  end
  if el.attributes['bs-toggle'] ~= nil and el.attributes['bs-toggle'] ~= '' then
    return el
  end
  if el.attributes['bs-target'] ~= nil and el.attributes['bs-target'] ~= '' then
    return el
  end
  el.attributes['bs-target'] = el.target
  el.attributes['bs-toggle'] = 'modal'
  return el
end

return {
  { Pandoc = get_modal_meta },
  { Div = modal },
  { Link = expand_modal_link }
}
