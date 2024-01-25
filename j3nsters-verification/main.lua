local discordia = require("discordia")
local json = require("json")
local client = discordia.Client()
local botprefix = ""


client:on("ready", function()
    client:setGame("Verifying Accounts!")
end)

local file = io.open("./token.txt")
local token = file:read("*a")

client:run("bot" .. token)