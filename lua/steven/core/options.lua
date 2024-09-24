vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt -- For conciseness

-- Line Numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- show absolute line number on cursor line (when relative number is on)

-- Tabs and Indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces of indent width
opt.expandtab = true -- expand tab to speces
opt.autoindent = true -- copt indent from current line when starting new one

-- Line Wrapping
opt.wrap = false -- disable line wrapping

-- Search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assume you want case-sensative

-- Cursor Line
opt.cursorline = true -- highlight the current cursor line

-- Appearance

-- Turn on termguicolors for tokyonight colorscheme to work
-- (have to use iTerm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so text doesn't shift

-- Backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line, or insert mode start position

-- Clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- Split Windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom
