local usrcmd_name = require("cthru.defaults").usrcmd

if vim.fn.exists(":" .. usrcmd_name) ~= 2 then
    require("cthru").configure()
end
