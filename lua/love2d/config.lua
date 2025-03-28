local config = {}

config.defaults = {
  path_to_love_bin = "love",
  path_to_love_library = vim.fn.globpath(vim.o.runtimepath, "love2d/library"),
  restart_on_save = false,
}

---@class options
---@field path_to_love_bin? string: The path to the Love2D executable
---@field path_to_love_library? string: The path to the Love2D library. Set to "" to disable LSP
---@field restart_on_save? boolean: Restart Love2D when a file is saved
config.options = {}

---Setup the LSP for love2d using lspconfig
---@param library_path string: The path to the love2d library
local function setup_lsp(library_path)
  local lspconfig_installed, lspconfig = pcall(require, "lspconfig")
  if lspconfig_installed then
    -- Get current client if it exists
    local current_config = {}
    for _, client in pairs(vim.lsp.get_clients()) do
      if client.name == "lua_ls" then
        current_config = client.config.settings or {}
        break
      end
    end
    -- Prepare new settings by merging with current settings
    local settings = vim.deepcopy(current_config)
    -- Ensure the Lua table exists
    settings.Lua = settings.Lua or {}
    -- Ensure the workspace table exists
    settings.Lua.workspace = settings.Lua.workspace or {}
    -- Ensure the library table exists
    settings.Lua.workspace.library = settings.Lua.workspace.library or {}
    -- Add our library path
    table.insert(settings.Lua.workspace.library, library_path)
    -- Apply the merged settings
    lspconfig.lua_ls.setup({
      settings = settings,
    })
  else
    vim.notify("Install lspconfig to setup LSP for love2d", vim.log.levels.ERROR)
  end
end

---Create auto commands for love2d:
--- - Restart on save: Restart Love2D when a file is saved.
local function create_auto_commands()
  if config.options.restart_on_save then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("love2d_restart_on_save", { clear = true }),
      pattern = { "*.lua" },
      callback = function()
        local love2d = require("love2d")
        local path = love2d.find_src_path("")
        if path then
          love2d.stop()
          vim.defer_fn(function()
            love2d.run(path)
          end, 500)
        end
      end,
    })
  end
  -- add here other auto commands ...
end

---Setup the love2d configuration.
---It must be called before running a love2d project.
---@param opts? options: config table
config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})
  if config.options.path_to_love_library ~= "" then
    local library_path = vim.fn.split(vim.fn.expand(config.options.path_to_love_library), "\n")[1]
    if vim.fn.isdirectory(library_path) == 0 then
      vim.notify("The library path " .. library_path .. " does not exist.", vim.log.levels.ERROR)
      return
    end
    setup_lsp(library_path)
  end
  create_auto_commands()
end

return config
