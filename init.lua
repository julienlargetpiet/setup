vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Make <Space> usable as leader
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.opt.timeout = true
vim.opt.timeoutlen = 500

-- Basic options
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"

-- Lazy.nvim bootstrap
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

require("lazy").setup({

  {
    "catppuccin/nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "cpp" },
      highlight = { enable = true },
    },
  },

  {
    "echasnovski/mini.starter",
    version = false,
    config = function()
      require("mini.starter").setup()
    end,
  },

  {
    "karb94/neoscroll.nvim",
    config = function()
      require("neoscroll").setup({
        easing_function = "cubic",
        hide_cursor = true,
        stop_eof = true,
      })
    end,
  },

})

-- --------------------------------------------------
-- Helpers
-- --------------------------------------------------

local function current_file_dir()
  -- Ignore non-file buffers (terminal, help, starter, etc.)
  if vim.bo.buftype ~= "" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end

  return vim.fn.fnamemodify(path, ":h")
end


local function lcd_if_valid(path)
  if path then
    vim.cmd("lcd " .. vim.fn.fnameescape(path))
  end
end

-- --------------------------------------------------
-- Terminal helpers
-- --------------------------------------------------

local function open_right_terminal()
  local path = current_file_dir()

  vim.cmd("vsplit")
  vim.cmd("wincmd l")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.3))
  lcd_if_valid(path)

  vim.cmd("terminal")
  vim.cmd("startinsert")
end

local function open_bottom_terminal()
  local path = current_file_dir()

  vim.cmd("belowright new")
  lcd_if_valid(path)

  vim.cmd("terminal")
  vim.cmd("startinsert")
end

local function open_terminal_tab()
  local path = current_file_dir()

  vim.cmd("tabnew")
  lcd_if_valid(path)

  vim.cmd("terminal")
  vim.cmd("startinsert")
end

-- --------------------------------------------------
-- Leader mappings (splits)
-- --------------------------------------------------

--vim.keymap.set("n", "<leader>t", open_right_terminal,
--  { desc = "Terminal in right 30% split" })
--
--vim.keymap.set("n", "<leader>b", open_bottom_terminal,
--  { desc = "Terminal in bottom split" })
--
--vim.keymap.set("t", "<leader>t", function()
--  vim.cmd("stopinsert")
--  vim.schedule(open_right_terminal)
--end)
--
--vim.keymap.set("t", "<leader>b", function()
--  vim.cmd("stopinsert")
--  vim.schedule(open_bottom_terminal)
--end)

-- :T → terminal in right split
vim.api.nvim_create_user_command("T", function()
  open_right_terminal()
end, { desc = "Terminal in right 30% split" })

-- :B → terminal in bottom split
vim.api.nvim_create_user_command("B", function()
  open_bottom_terminal()
end, { desc = "Terminal in bottom split" })

-- --------------------------------------------------
-- Split navigation (Alt + Arrows)
-- --------------------------------------------------

vim.keymap.set("n", "<M-Left>",  "<C-w>h")
vim.keymap.set("n", "<M-Down>",  "<C-w>j")
vim.keymap.set("n", "<M-Up>",    "<C-w>k")
vim.keymap.set("n", "<M-Right>", "<C-w>l")

vim.keymap.set("t", "<M-Left>",  "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<M-Down>",  "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<M-Up>",    "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<M-Right>", "<C-\\><C-n><C-w>l")

-- --------------------------------------------------
-- Maximize / restore split (Alt + m)
-- --------------------------------------------------

local function save_win_sizes()
  local sizes = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    sizes[win] = {
      width = vim.api.nvim_win_get_width(win),
      height = vim.api.nvim_win_get_height(win),
    }
  end
  return sizes
end

local function restore_win_sizes(sizes)
  if not sizes then return end
  for win, size in pairs(sizes) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_width(win, size.width)
      vim.api.nvim_win_set_height(win, size.height)
    end
  end
end

vim.keymap.set("n", "<M-m>", function()
  if vim.t._maximized then
    restore_win_sizes(vim.t._win_sizes)
    vim.t._maximized = false
  else
    vim.t._win_sizes = save_win_sizes()
    vim.cmd("wincmd |")
    vim.cmd("wincmd _")
    vim.t._maximized = true
  end
end, { desc = "Toggle maximize split" })

vim.keymap.set("t", "<M-m>", function()
  vim.cmd("stopinsert")
  vim.schedule(function()
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<M-m>", true, false, true),
      "n",
      false
    )
  end)
end)

-- --------------------------------------------------
-- Tabs
-- --------------------------------------------------

vim.keymap.set("n", "<M-k>", "gt", { desc = "Next tab" })
vim.keymap.set("n", "<M-j>", "gT", { desc = "Previous tab" })

vim.keymap.set("t", "<M-k>", function()
  vim.cmd("stopinsert")
  vim.schedule(function() vim.cmd("tabnext") end)
end)

vim.keymap.set("t", "<M-j>", function()
  vim.cmd("stopinsert")
  vim.schedule(function() vim.cmd("tabprevious") end)
end)

vim.keymap.set("n", "<M-w>", ":tabclose<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<M-t>", open_terminal_tab,
  { desc = "Terminal in new tab" })

vim.keymap.set("t", "<M-t>", function()
  vim.cmd("stopinsert")
  vim.schedule(open_terminal_tab)
end)

-- --------------------------------------------------
-- Misc
-- --------------------------------------------------

vim.keymap.set("n", "H", "<cmd>noh<CR>", {
  noremap = true,
  silent = true,
  desc = "Clear search highlight",
})

vim.keymap.set("i", "(", "()<Left>")
vim.keymap.set("i", "[", "[]<Left>")
vim.keymap.set("i", "{", "{}<Left>")
vim.keymap.set("i", "\"", "\"\"<Left>")
vim.keymap.set("i", "'", "''<Left>")

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.buftype ~= "" then return end
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then return end
    vim.cmd("lcd " .. vim.fn.fnamemodify(path, ":h"))
  end,
})





