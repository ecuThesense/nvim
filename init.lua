-- ==========================================================================
-- 1. LEADER KEY
-- ==========================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ==========================================================================
-- 2. APPEARANCE & UI (The "Beautiful" Part)
-- ==========================================================================
local opt = vim.opt

-- Colorscheme (Neovim 0.9+ has great built-in themes: habamax, retrobox, lunaperche)
vim.cmd.colorscheme("habamax")

opt.termguicolors = true      -- Enable 24-bit RGB colors
opt.number = true             -- Show line numbers
opt.relativenumber = true     -- Show relative line numbers
opt.cursorline = true         -- Highlight the current line
opt.signcolumn = "yes"        -- Always show the signcolumn to prevent UI shifting
opt.cmdheight = 1             -- Keep command line height clean
opt.showmode = false          -- Hide "-- INSERT --" since we will build a custom statusline
opt.wrap = false              -- Disable line wrap
opt.scrolloff = 8             -- Keep 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8         -- Keep 8 columns to the left/right when scrolling
-- opt.colorcolumn = "80"        -- Subtle line at 80 characters
opt.fillchars = { eob = " " } -- Hide the '~' characters at the end of buffers! (Very clean)

-- Make invisible characters look pretty
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- ==========================================================================
-- 3. CUSTOM STATUSLINE (No lualine needed)
-- ==========================================================================
-- We set up nice colors for our statusline that feel like a modern theme
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        vim.api.nvim_set_hl(0, "StlNormal", { bg = "#7aa2f7", fg = "#15161e", bold = true })
        vim.api.nvim_set_hl(0, "StlInsert", { bg = "#9ece6a", fg = "#15161e", bold = true })
        vim.api.nvim_set_hl(0, "StlVisual", { bg = "#bb9af7", fg = "#15161e", bold = true })
        vim.api.nvim_set_hl(0, "StlCommand", { bg = "#e0af68", fg = "#15161e", bold = true })
        vim.api.nvim_set_hl(0, "StlFile",   { bg = "#3b4261", fg = "#c0caf5", bold = true })
        vim.api.nvim_set_hl(0, "StlLoc",    { bg = "#1f2335", fg = "#7aa2f7", bold = true })
    end,
})
vim.cmd("doautocmd ColorScheme") -- Trigger immediately

-- Logic for the statusline
_G.CustomStatusline = function()
    local mode = vim.api.nvim_get_mode().mode
    local mode_hl = "%#StlNormal#"
    local mode_name = " NORMAL "

    if mode == "i" then
        mode_hl = "%#StlInsert#"
        mode_name = " INSERT "
    elseif mode == "v" or mode == "V" or mode == "\22" then
        mode_hl = "%#StlVisual#"
        mode_name = " VISUAL "
    elseif mode == "c" then
        mode_hl = "%#StlCommand#"
        mode_name = " COMMAND "
    elseif mode == "R" then
        mode_hl = "%#StlCommand#"
        mode_name = " REPLACE "
    end

    -- Construct the string: Mode -> Filepath -> Modified flag -> Right Align -> Line:Col
    return string.format(
        "%s%s%%#StlFile# %%f %%m %%r%%=%%#StlLoc# %%l:%%c %%P ",
        mode_hl,
        mode_name
    )
end

-- Attach the custom statusline
opt.statusline = "%!v:lua.CustomStatusline()"

-- ==========================================================================
-- 4. BUILT-IN FILE EXPLORER (Netrw -> Looks like nvim-tree)
-- ==========================================================================
vim.g.netrw_banner = 0         -- Hide the ugly top banner
vim.g.netrw_liststyle = 3      -- Use tree view
vim.g.netrw_browse_split = 4   -- Open files in previous window
vim.g.netrw_altv = 1           -- Open splits to the right
vim.g.netrw_winsize = 25       -- Width of the explorer window

-- ==========================================================================
-- 5. FUNCTIONALITY & BEHAVIOR
-- ==========================================================================
-- Indentation
opt.expandtab = true           -- Use spaces instead of tabs
opt.shiftwidth = 4             -- Size of an indent
opt.tabstop = 4                -- Number of spaces a tab counts for
opt.smartindent = true         -- Auto-indent new lines

-- Search
opt.ignorecase = true          -- Ignore case when searching
opt.smartcase = true           -- Don't ignore case with capitals
opt.incsearch = true           -- Show search matches as you type
opt.hlsearch = true            -- Highlight all matches

-- System
opt.updatetime = 250           -- Faster completion and responsiveness
opt.timeoutlen = 300           -- Faster mapping delays
opt.clipboard = "unnamedplus"  -- Sync with system clipboard
opt.splitbelow = true          -- Horizontal splits open below
opt.splitright = true          -- Vertical splits open to the right

-- ==========================================================================
-- 6. KEYMAPS
-- ==========================================================================
local keymap = vim.keymap.set
local km_opts = { noremap = true, silent = true }

-- Toggle File Explorer (Netrw)
keymap("n", "<leader>e", vim.cmd.Lexplore, km_opts)

-- Clear search highlights with ESC
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", km_opts)

-- Better window navigation (Ctrl + h/j/k/l to move between splits)
keymap("n", "<C-h>", "<C-w>h", km_opts)
keymap("n", "<C-j>", "<C-w>j", km_opts)
keymap("n", "<C-k>", "<C-w>k", km_opts)
keymap("n", "<C-l>", "<C-w>l", km_opts)

-- Move selected text up/down in visual mode automatically re-indenting
keymap("v", "J", ":m '>+1<CR>gv=gv", km_opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", km_opts)

-- Keep cursor in the middle when page jumping
keymap("n", "<C-d>", "<C-d>zz", km_opts)
keymap("n", "<C-u>", "<C-u>zz", km_opts)

-- ==========================================================================
-- 7. AUTO COMMANDS
-- ==========================================================================
-- Flash text briefly when you copy/yank it
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})

-- Python LSP (pylsp)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function(args)
        local root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" }
        local root_dir = vim.fs.root(args.buf, root_markers) or vim.fn.getcwd()

        vim.lsp.start({
            name = "pylsp",
            cmd = { "pylsp" },
            root_dir = root_dir,
            settings = {
                pylsp = {
                    plugins = {
                        jedi = {
                            extra_paths = { root_dir },
                        },
                    },
                },
            },
            on_attach = function(client, bufnr)
                vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
            end,
        })
    end,
})
