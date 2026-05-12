local docsets = require("zeal.docsets")
local browser = require("zeal.browser")
local M = {}

---@param entries table
---@param title string
---@param cfg table
---@param query? string
local function entry_picker(entries, title, cfg, query)
  if #entries == 0 then
    vim.notify("zeal.nvim: no entries found for " .. title, vim.log.levels.WARN)
  end

  if cfg.picker.type == "default" then
    -- pre filter options since vim.ui.select doesn't support patterns
    local filtered = entries
    if query and query ~= "" then
      filtered = vim.tbl_filter(function(e)
        return e.display:lower():find(query:lower(), 1, true) ~= nil
      end, entries)
    end

    vim.ui.select(filtered, {
      prompt = "Zeal [" .. title .. "]:",
      format_item = function(e)
        return e.display
      end,
    }, function(choice)
      if choice then
        browser.open(choice, cfg)
      end
    end)
    return
  end

  local snacks = require("snacks")
  local picker_cfg = cfg.picker.snacks
  local items = {}

  for _, e in ipairs(entries) do
    table.insert(items, { text = e.display, path = e.path })
  end

  snacks.picker({
    items = items,
    format = function(e)
      return {
        { e.text, "SnacksPickerFile" },
      }
    end,
    layout = picker_cfg.layout,
    title = "  Zeal [" .. title .. "]",
    pattern = query or "",
    confirm = function(picker, choice)
      picker:close()
      browser.open(choice, cfg)
    end,
    preview = "none",
  })
end

---@param docset table
---@param cfg table
function M.pick_entry(docset, cfg)
  entry_picker(docsets.entries(docset), docset.name, cfg, query)
end

---@param docset_names table[]
---@param ft string
---@param cfg table
---@param query? string
function M.pick_entry_for_ft(docset_names, ft, cfg, query)
  local names = docsets.entries_for_ft(docset_names, cfg)
  entry_picker(names, ft, cfg, query)
end

---@param cfg table
function M.pick_docset(cfg)
  local all = docsets.list(cfg)

  if #all == 0 then
    return
  end

  if #all == 1 then
    M.pick_entry(all[1], cfg)
    return
  end

  if cfg.picker.type == "default" then
    vim.ui.select(all, {
      prompt = "Zeal Docsets:",
      format_item = function(d)
        return d.name
      end,
    }, function(choice)
      if choice then
        M.pick_entry(choice, cfg)
      end
    end)
    return
  end

  local picker_cfg = cfg.picker.snacks
  local snacks = require("snacks")
  local items = {}

  for _, d in ipairs(all) do
    table.insert(items, { text = d.name, name = d.name, path = d.path, file = d.path })
  end

  snacks.picker({
    items = items,
    format = function(d)
      return {
        { d.text, "SnacksPickerFile" },
      }
    end,
    layout = picker_cfg.layout,
    title = "  Zeal Docsets",
    confirm = function(picker, choice)
      picker:close()
      M.pick_entry(choice, cfg)
    end,
    preview = "none",
  })
end

---@param languages table[]
---@param cfg table
---@param callback function
function M.pick_download(languages, cfg, callback)
  if cfg.picker.type == "default" then
    vim.ui.select(languages, {
      prompt = "Zeal Docsets:",
      format_item = function(e)
        return e.name
      end,
    }, function(choice)
      if choice then
        callback(cfg, choice.name)
      end
    end)
    return
  end

  local picker_cfg = cfg.picker.snacks
  local snacks = require("snacks")
  local items = {}

  for _, e in ipairs(languages) do
    table.insert(items, { text = e.name, name = e.name })
  end

  snacks.picker({
    items = items,
    format = function(e)
      return {
        { e.text, "SnacksPickerFile" },
      }
    end,
    layout = picker_cfg.layout,
    title = "  Zeal Docsets",
    confirm = function(picker, choice)
      picker:close()
      if choice then
        callback(cfg, choice.name)
      end
    end,
    preview = "none",
  })
end

return M
