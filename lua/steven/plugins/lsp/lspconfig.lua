return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    mason_lspconfig.setup_handlers({
      -- default handler for installed servers
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
        })
      end,
      ["ruby_lsp"] = function()
        -- configure ruby server
        -- textDocument/diagnostic support until 0.10.0 is released
        _timers = {}
        local function setup_diagnostics(client, buffer)
          if require("vim.lsp.diagnostic")._enable then
            return
          end

          local diagnostic_handler = function()
            local params = vim.lsp.util.make_text_document_params(buffer)
            client.request("textDocument/diagnostic", { textDocument = params }, function(err, result)
              if err then
                local err_msg = string.format("diagnostics error - %s", vim.inspect(err))
                vim.lsp.log.error(err_msg)
              end
              local diagnostic_items = {}
              if result then
                diagnostic_items = result.items
              end
              vim.lsp.diagnostic.on_publish_diagnostics(
                nil,
                vim.tbl_extend("keep", params, { diagnostics = diagnostic_items }),
                { client_id = client.id }
              )
            end)
          end

          diagnostic_handler() -- to request diagnostics on buffer when first attaching

          vim.api.nvim_buf_attach(buffer, false, {
            on_lines = function()
              if _timers[buffer] then
                vim.fn.timer_stop(_timers[buffer])
              end
              _timers[buffer] = vim.fn.timer_start(200, diagnostic_handler)
            end,
            on_detach = function()
              if _timers[buffer] then
                vim.fn.timer_stop(_timers[buffer])
              end
            end,
          })
        end

        -- adds ShowRubyDeps command to show dependencies in the quickfix list.
        -- add the `all` argument to show indirect dependencies as well
        local function add_ruby_deps_command(client, bufnr)
          vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps",
            function(opts)

              local params = vim.lsp.util.make_text_document_params()

              local showAll = opts.args == "all"

              client.request("rubyLsp/workspace/dependencies", params,
                function(error, result)
                  if error then
                    print("Error showing deps: " .. error)
                    return
                  end

                  local qf_list = {}
                  for _, item in ipairs(result) do
                    if showAll or item.dependency then
                      table.insert(qf_list, {
                        text = string.format("%s (%s) - %s",
                          item.name,
                          item.version,
                          item.dependency),

                        filename = item.path
                      })
                    end
                  end

                  vim.fn.setqflist(qf_list)
                  vim.cmd('copen')
                end, bufnr)
            end, {nargs = "?", complete = function()
              return {"all"}
            end})
        end

        lspconfig["ruby_lsp"].setup({
          on_attach = function(client, buffer)
            setup_diagnostics(client, buffer)
            add_ruby_deps_command(client, buffer)
          end,
        })
      end,
      ["svelte"] = function()
        -- configure svelte server
        lspconfig["svelte"].setup({
          capabilities = capabilities,
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = { "*.js", "*.ts" },
              callback = function(ctx)
                -- Here use ctx.match instead of ctx.file
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              end,
            })
          end,
        })
      end,
      ["graphql"] = function()
        -- configure graphql language server
        lspconfig["graphql"].setup({
          capabilities = capabilities,
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,
      ["emmet_ls"] = function()
        -- configure emmet language server
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
        })
      end,
      ["lua_ls"] = function()
        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              -- make the language server recognize "vim" global
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        })
      end,
    })
  end,
}
