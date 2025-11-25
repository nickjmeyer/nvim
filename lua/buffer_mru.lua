local M = {}
M.mru_list = {}

-- Inserts the current buffer as the most recently used.
local function update_mru(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    -- Remove buffer from current position in the list if it exists.
    for i, v in ipairs(M.mru_list) do
        if v == bufnr then
            table.remove(M.mru_list, i)
            break
        end
    end
    -- Add buffer to the front of the list
    table.insert(M.mru_list, 1, bufnr)
end

-- Autocommand to update the list on buffer change
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        update_mru(args.buf)
    end,
    group = vim.api.nvim_create_augroup("MRUBufferGroup", { clear = true }),
})

-- Function to get the sorted MRU list
function M.mru_buffers()
    -- Filter out invalid/deleted buffers
    local valid_buffers = {}
    for _, bufnr in ipairs(M.mru_list) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 then
            table.insert(valid_buffers, bufnr)
        end
    end
    M.mru_list = valid_buffers -- Update the internal list as well
    return M.mru_list
end

return M

