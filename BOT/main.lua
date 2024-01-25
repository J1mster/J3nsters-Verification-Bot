

local discordia = require("discordia")
local json = require("json")
local http = require("coro-http")
local xml2lua = require("xml2lua")


local client = discordia.Client()
local gameLink = "https://www.roblox.com/games/15689192855/App"
local jsonFilePath = "./data.json"
local activeCodes = {}
local defaultConfig = {
    ["defaultRole"] = "",
    ["VerifiedRole"] = "",
    ["UsernameMethod"] = "%discorddisplay% (%robloxuser%)",
    ["UseUsernameMethod"] = true,
    ["ClothingSourceRequiresAdmin"] = true,
    ["VerifiedUsers"] = {}
}

local function GET_GUILD(id)
    return client:getGuild(id)
end




local function generateCode()
    local number = math.random(100000, 999999)
    
    for _, item in pairs(activeCodes) do
        if item[2] == number then
            return generateCode()
        end
    end
    
    return number
end


local function addRoleToUser(member, roleName)
    local role = member.guild:getRole(roleName)
    
    -- Check if the role exists
    if not role then return end
    
    member:addRole(role)
end



local function deleteOldDataMessage(channel)
    local messages = channel:getMessages()
    for message in messages:iter() do
        if message.author == client.user then
            message:delete()
            break
        end
    end
end

local function loadNewestJSONData(channel)
    
    local messages = channel:getMessages()
    local latestMessage = nil
    
    for index, msg in pairs(messages) do
        if msg.author == client.user and msg.attachments then
            latestMessage = msg
            break
        end
    end
    
    if latestMessage and latestMessage.attachment then
        local _, file = http.request("GET", latestMessage.attachment.url)
        local decodedData = json.decode(file)
        
        
        return decodedData
    else
        return nil
    end
end

local function createAndSendDataMessage(channel, jsonData)
    local maxRetries = 10
    local retryDelay = 1
    
    for attempt = 1, maxRetries do
        deleteOldDataMessage(channel)
        
        local data = json.encode(jsonData)
        local success, error_message = pcall(function()
            channel:send{
                file = {"localdata.json", data}
            }
        end)
        
        if success then
            return true
        else
            discordia.sleep(retryDelay * 1000)-- Convert seconds to milliseconds
        end
    end
    
    print("Exceeded maximum retry attempts. Message not sent.")
end




--{ user.id, code, message.guild, message.channel}
local function verifyMember(member, rblxinfo, tablex)
    local function AlreadyVerified()
        local guild = GET_GUILD("1186891224376938516")
        local channel = guild:getChannel("1187095120055648298")
        local loadedData = loadNewestJSONData(channel)
        if not loadedData then
            createAndSendDataMessage(channel, {})
        end
        local loadedData = loadNewestJSONData(channel)
        if loadedData then
            if not loadedData[tablex[3].id] then
                loadedData[tablex[3].id] = defaultConfig
            end
            --{member.id, rblxinfo}
            for index, item in pairs(loadedData[tablex[3].id].VerifiedUsers) do
                if item[2].rblxID == rblxinfo.rblxID then
                    return true
                end
            end
            
            return false
        end
    end
    if AlreadyVerified() then
        channel:send("<@" .. tostring(member.id) .. "> Sorry! This user is already verified. Please remove your old user first.")
        return
    end
    
    
    
    
    local guild = GET_GUILD("1186891224376938516")
    local channel = guild:getChannel("1187095120055648298")
    local loadedData = loadNewestJSONData(channel)
    if not loadedData then
        createAndSendDataMessage(channel, {[tablex[3].id] = defaultConfig})
    end
    local loadedData = loadNewestJSONData(channel)
    if loadedData then
        if not loadedData[tablex[3].id] then
            loadedData[tablex[3].id] = defaultConfig
        end
        
        local dmResult, dmError = member:send{embed = {
            title = "Confirm Account",
            description = "Code matched! Was this you?",
            fields = {
                {
                    name = rblxinfo.rblxDN,
                    value = rblxinfo.rblxUN .. " (" .. rblxinfo.rblxID .. ")",
                    inline = true
                }
            },
            footer = {
                text = "If this wasn't you, Just continue to put in your code normally."
            },
            color = 0xe64b40
        }}
        dmResult:addReaction("✔️")
        local OnQueue = true
        client:on("reactionAdd", function(reaction, userId)
            if OnQueue then
                if userId == member.id and reaction.message == dmResult then
                    if reaction.emojiName == "✔️" then
                        
                        loadedData[tablex[3].id]["VerifiedUsers"][#loadedData[tablex[3].id]["VerifiedUsers"] + 1] = {member.id, rblxinfo}
                        
                        createAndSendDataMessage(channel, loadedData)
                        reaction.message:removeReaction("✔️", client.user.id)
                        member:send("<@" .. tostring(tablex[1]) .. "> You have been verified!")
                        
                        
                        
                        for index, item in pairs(activeCodes) do
                            if item[1] == member.id then
                                table.remove(activeCodes, index)
                            end
                        end
                        
                        local member = tablex[3]:getMember(userId)
                        local guild = GET_GUILD("1186891224376938516")
                        local channel = guild:getChannel("1187095120055648298")
                        local loadedData = loadNewestJSONData(channel)
                        if not loadedData then
                            createAndSendDataMessage(channel, {})
                        end
                        local loadedData = loadNewestJSONData(channel)
                        if loadedData then
                            if not loadedData[tablex[3].id] then
                                loadedData[tablex[3].id] = defaultConfig
                            end
                            if GET_GUILD(tostring(tablex[3].id)):getRole(loadedData[tablex[3].id].verifiedRole) then
                                member:addRole(loadedData[tablex[3].id].verifiedRole)
                            end
                            
                            if loadedData[tablex[3].id].UseUsernameMethod == true then
                                member:setNickname(
                                    string.gsub(loadedData[tablex[3].id].UsernameMethod,
                                        "%discordusername%", guild:getMember(userId).user.name
                                    ):gsub(
                                        "%discorddisplayname%", member.nickname or member.username
                                    ):gsub(
                                        "%discordid%", tostring(userId)
                                    ):gsub(
                                        "%robloxusername%", tostring(rblxinfo.rblxUN)
                                    ):gsub(
                                        "%robloxdisplayname%", tostring(rblxinfo.rblxDN)
                                    ):gsub(
                                        "%robloxid%", tostring(rblxinfo.rblxID
                            )
                            )
                            )
                            end
                        end
                        
                        local OnQueue = false
                    end
                end
            end
        end)
    else
        verifyMember(member, rblxinfo, tablex)
    end
end


local function OnNewVerif(rblxinfo, code, message)
    for index, item in ipairs(activeCodes) do
        if tonumber(code) == tonumber(item[2]) then
            verifyMember(client:getUser(item[1]), rblxinfo, item)
            
            return true
        end
    end
    
    return false
end

local functions = {
    retrieveToken = function()
        local success, file = pcall(function()
            return io.open("./token.txt", "r")
        end)
        
        if not success then
            print("TOKEN FAILED: " .. file)
            return ""
        end
        
        local token = file:read("*a")
        file:close()
        
        return token
    end,
    
    retrieveSavedData = function()
        local success, file = pcall(function()
            return io.open("./datainfo.json", "r")
        end)
        
        if not success then
            print("Data Failed: " .. file)
            return ""
        end
        
        local data = file:read("*a")
        file:close()
        
        return json.decode(data)
    end,
    SetSaveData = function(WrittenInfo)
        local success, file = pcall(function()
            return io.open("./datainfo.json", "r")
        end)
        
        if not success then
            print("Data Failed: " .. file)
            return ""
        end
        
        local data = file:write(WrittenInfo)
        file:close()
        
        return success
    end,
    
    generateCode = generateCode,
    
    sendVerificationDM = (function(user, channelMAIN, message)
        local function AlreadyHasCode()
            for index, item in ipairs(activeCodes) do
                if item[1] == user.id then
                    return item[2]
                end
            end
            
            return false
        end
        
        local function AlreadyVerified()
            local guild = GET_GUILD("1186891224376938516")
            local channel = guild:getChannel("1187095120055648298")
            local loadedData = loadNewestJSONData(channel)
            if not loadedData then
                createAndSendDataMessage(channel, {})
            end
            local loadedData = loadNewestJSONData(channel)
            if loadedData then
                if not loadedData[message.guild.id] then
                    loadedData[message.guild.id] = defaultConfig
                end
                --{member.id, rblxinfo}
                for index, item in pairs(loadedData[message.guild.id].VerifiedUsers) do
                    if item[1] == user.id then
                        return true
                    end
                end
                
                return false
            end
        end
        if AlreadyVerified() then
            local msg = channelMAIN:send("<@" .. tostring(user.id) .. "> You are already verified. Would you like to re-verify?")
            
            msg:addReaction("✔️")
            msg:addReaction("❌")
            local OnQueue = true
            client:on("reactionAdd", function(reaction, userId)
                if OnQueue then
                    if userId == user.id and reaction.message == msg and reaction.message.channel == channelMAIN then
                        if reaction.emojiName == "✔️" then
                            
                            
                            --REMOVE THEIR VERIFIED ROLE
                            local guild = GET_GUILD("1186891224376938516")
                            local channel = guild:getChannel("1187095120055648298")
                            local loadedData = loadNewestJSONData(channel)
                            if not loadedData then
                                createAndSendDataMessage(channel, {})
                            end
                            local loadedData = loadNewestJSONData(channel)
                            if loadedData then
                                if not loadedData[channelMAIN.guild.id] then
                                    loadedData[channelMAIN.guild.id] = defaultConfig
                                end
                                
                                channelMAIN.guild:getMember(user.id):removeRole(loadedData[channelMAIN.guild.id].verifiedRole)
                            end
                            
                            
                            
                            reaction.message:removeReaction("✔️", userId)
                            reaction.message:removeReaction("✔️", client.user.id)
                            reaction.message:removeReaction("❌", client.user.id)
                            local t = loadedData[message.guild.id].VerifiedUsers
                            for index, item in pairs(t) do
                                if item[1] == user.id then
                                    table.remove(t, index)
                                end
                            end
                            createAndSendDataMessage(channel, loadedData)
                            
                            
                            channelMAIN:send("<@" .. tostring(user.id) .. "> Done! Please reverify now!")
                            local OnQueue = false
                        elseif reaction.emojiName == "❌" then
                            channel:send("<@" .. tostring(user.id) .. "> Got it! I won't make you reverify!")
                            reaction.message:removeReaction("❌", userId)
                            reaction.message:removeReaction("✔️", client.user.id)
                            reaction.message:removeReaction("❌", client.user.id)
                            local OnQueue = false
                        end
                    end
                end
            end)
            
            return
        end
        
        if not AlreadyHasCode() then
            local code = generateCode()
            activeCodes[#activeCodes + 1] = {user.id, code, message.guild, message.channel}
            
            local dmResult, dmError = user:send{embed = {
                title = "RBLX Account Verification Code",
                description = "Please join [This Game](" .. gameLink .. ") and enter the following code to verify your account!",
                fields = {
                    {
                        name = "Verification Code",
                        value = "```" .. tostring(code) .. "``` This code expires in 5 minutes.",
                        inline = true
                    }
                },
                footer = {
                    text = "Do not share this code with anyone."
                },
                color = 0xe64b40
            }}
            
            if not dmResult then
                channelMAIN:send("<@" .. tostring(user.id) .. "> Failed to resend verification code. Please make sure your DMs are open. \n\n(error: ``" .. dmError .. "``)")
                return
            else
                channelMAIN:send("<@" .. tostring(user.id) .. "> Check your DMs for the verification code!")
                return
            end
            
            discordia.sleep(300 * 1000)
            
            user:send{embed = {
                title = "Code expired.",
                description = "Your code has expired",
                fields = {
                    {
                        name = "Verification Code",
                        value = "```" .. tostring(code) .. "``` This code expires in 5 minutes.",
                        inline = true
                    }
                },
                footer = {
                    text = "Do not share this code with anyone."
                },
                color = 0xe64b40
            }}
        
        
        elseif AlreadyHasCode() then
            local msg = channelMAIN:send("<@" .. tostring(user.id) .. "> You already have an active code. It has been sent to you again, Or you can cancel it.\n\nWould you like to cancel your existing one?")
            local code = AlreadyHasCode()
            local dmResult, dmError = user:send{embed = {
                title = "RBLX Account Verification Code",
                description = "Please join [This Game](" .. gameLink .. ") and enter the following code to verify your account!",
                fields = {
                    {
                        name = "Verification Code",
                        value = "```" .. tostring(code) .. "``` This code expires in 5 minutes.",
                        inline = true
                    }
                },
                footer = {
                    text = "Do not share this code with anyone."
                },
                color = 0xe64b40
            }}
            msg:addReaction("✔️")
            msg:addReaction("❌")
            local OnQueue = true
            client:on("reactionAdd", function(reaction, userId)
                if OnQueue then
                    if userId == user.id and reaction.message == msg and reaction.message.channel == channel then
                        if reaction.emojiName == "✔️" then
                            channelMAIN:send("<@" .. tostring(user.id) .. "> Successfully cancelled code. You may now create a new one.")
                            reaction.message:removeReaction("✔️", userId)
                            reaction.message:removeReaction("✔️", client.user.id)
                            reaction.message:removeReaction("❌", client.user.id)
                            
                            for index, item in pairs(activeCodes) do
                                if item[1] == user.id then
                                    table.remove(activeCodes, index)
                                end
                            end
                            
                            local OnQueue = false
                        elseif reaction.emojiName == "❌" then
                            channelMAIN:send("<@" .. tostring(user.id) .. "> Got it! I won't remove your old code!")
                            reaction.message:removeReaction("❌", userId)
                            reaction.message:removeReaction("✔️", client.user.id)
                            reaction.message:removeReaction("❌", client.user.id)
                            local OnQueue = false
                        end
                    end
                end
            end)
            
            if not dmResult then
                channelMAIN:send("<@" .. tostring(user.id) .. "> Failed to send verification code. Please make sure your DMs are open. \n\n(error: ``" .. dmError .. "``)")
                return
            end
        end
    
    end),
    wait = (function(seconds)
        local endx = os.time() + 5
        repeat
            
            until (os.time() == endx)
    end)


}

print(
[[

       _______            __                
      / /__  /____  _____/ /____  __________
 __  / / /_ </ __ \/ ___/ __/ _ \/ ___/ ___/
/ /_/ /___/ / / / (__  ) /_/  __/ /  (__  ) 
\____//____/_/ /_/____/\__/\___/_/  /____/  

    ___            
   /   | __________
  / /| |/ ___/ ___/
 / ___ / /__/ /__  
/_/  |_\___/\___/  


 _    __          _ _____          
| |  / /__  _____(_) __(_)__  _____
| | / / _ \/ ___/ / /_/ / _ \/ ___/
| |/ /  __/ /  / / __/ /  __/ /    
|___/\___/_/  /_/_/ /_/\___/_/     
                                   
]])
client:on("ready", function()

    client:setActivity({
        name = "Making account verification easy!",
        type = 1
    })
	
end)

client:on("messageCreate", function(message)
	if message.author == client.user or message.author.id=="1191836718098296923" or message.author.id=="1191922358143942677" then comp = true return end
    if message.author.id == "821567060022132787" then
        if message.content == "/s3" then 
            message:delete()
            io.write("What would you like to say?\n")
            message.channel:send(io.read())
            comp = true
        end 
    end
    if not message.guild then
        if string.lower(message.content) == "/clear" then
            local messages = message.channel:getMessages(limit)
            local deletedMessages = 0
            for _, msg in pairs(messages) do
                if (msg.author == client.user) then
                    if msg:delete() then
                        deletedMessages = deletedMessages + 1
                    else
                        local del = msg:delete()
                        repeat del = msg:delete() until del
                    end
                end
            
            end
            
            local replymsg = message:reply("Successfully deleted " .. tostring(deletedMessages) .. " messages.")
            functions.wait(5)
            replymsg:delete()
            return
        else
            message:reply("Sorry, Verifying Roblox Accounts cannot be done from DMs! Please message from a verification channel in a guild.")
            return
        end
    end
    
    if message.guild.id == "1186891224376938516" and message.channel.id == "1186891275102851092" then
        local function GetUserProfile(input)
            -- {code}, {RobloxID}, {RobloxUsername}, {RobloxDisplayname}
            local code = input:match("{(.-)}  {.-}  {.-}  {.-}")
            local RobloxID = input:match("{.-}  {(.-)}  {.-}  {.-}")
            local RobloxUsername = input:match("{.-}  {.-}  {(.-)}  {.-}")
            local RobloxDisplayname = input:match("{.-}  {.-}  {.-}  {(.-)}")
            
            return {
                ["code"] = code,
                ["rblxInfo"] = {
                    ["rblxID"] = RobloxID,
                    ["rblxUN"] = RobloxUsername,
                    ["rblxDN"] = RobloxDisplayname,
                }
            }
        end
        
        local information = GetUserProfile(message.content)
        
        OnNewVerif(information.rblxInfo, information.code)
        
        
        return
    end
    
    
    
    if string.lower(message.content) == "/verify" then
        if true then
            functions.sendVerificationDM(message.author, message.channel, message)
        end
    
    elseif string.lower(message.content) == "/ping" then
        local success, ping = pcall(function()
            local pingResult = io.popen("ping -n 4 www.discord.com"):read("*a")
            return pingResult
        end)
        
        if success then
            local dmResult, dmError = message.channel:send{
                embed = {
                    title = "Ping",
                    description = "Pong!",
                    fields = {
                        {
                            name = "Result",
                            value = "```" .. ping .. "```",
                            inline = true
                        }
                    },
                    footer = {
                        text = "Reply from www.discord.com"
                    },
                    color = 0xe64b40
                }
            }
        end
    elseif string.lower(message.content):match("/setdefaultrole%s*.*") then
        local author = message.guild:getMember(message.author)
        if member and not (member:hasPermission(discordia.enums.permission.administrator)) then
            message.channel:send("<@" .. author.id .. "> You do not have permission to do this. Permission needed: Administrator")
            return
        end
        local guild = GET_GUILD("1186891224376938516")
        local channel = guild:getChannel("1187095120055648298")
        local loadedData = loadNewestJSONData(channel)
        if not loadedData then
            createAndSendDataMessage(channel, {})
        end
        local loadedData = loadNewestJSONData(channel)
        if loadedData then
            if not loadedData[message.guild.id] then
                loadedData[message.guild.id] = defaultConfig
            end
            
            loadedData[message.guild.id]["defaultRole"] = message.content:match("/setdefaultrole%s*(.+)")
            
            if createAndSendDataMessage(channel, loadedData) then
                message.channel:send("<@" .. author.id .. "> Done!")
            else
                message.channel:send("<@" .. author.id .. "> Error setting data. Please try again later.")
            end
        end
    elseif string.lower(message.content):match("/setverifiedrole%s*.+") then
        
        local author = message.guild:getMember(message.author)
        if member and not (member:hasPermission(discordia.enums.permission.administrator)) then
            message.channel:send("<@" .. author.id .. "> You do not have permission to do this. Permission needed: Administrator")
            return
        end
        local guild = GET_GUILD("1186891224376938516")
        local channel = guild:getChannel("1187095120055648298")
        local loadedData = loadNewestJSONData(channel)
        if not loadedData then
            createAndSendDataMessage(channel, {})
        end
        local loadedData = loadNewestJSONData(channel)
        if loadedData then
            if not loadedData[message.guild.id] then
                loadedData[message.guild.id] = defaultConfig
            end
            
            loadedData[message.guild.id]["VerifiedRole"] = message.content:match("/setverifiedrole%s*(.+)")
            
            if createAndSendDataMessage(channel, loadedData) then
                message.channel:send("<@" .. author.id .. "> Done!")
            else
                message.channel:send("<@" .. author.id .. "> Error setting data. Please try again later.")
            end
        end
    elseif string.lower(message.content):match("/usernamemethod%s*.+") then
        local author = message.guild:getMember(message.author)
        if member and not (member:hasPermission(discordia.enums.permission.administrator)) then
            message.channel:send("<@" .. author.id .. "> You do not have permission to do this. Permission needed: Administrator")
            return
        end
        local guild = GET_GUILD("1186891224376938516")
        local channel = guild:getChannel("1187095120055648298")
        local loadedData = loadNewestJSONData(channel)
        if not loadedData then
            createAndSendDataMessage(channel, {})
        end
        local loadedData = loadNewestJSONData(channel)
        if loadedData then
            if not loadedData[message.guild.id] then
                loadedData[message.guild.id] = defaultConfig
            end
            
            loadedData[message.guild.id]["UsernameMethod"] = message.content:match("/usernamemethod%s*(.+)")
            
            if createAndSendDataMessage(channel, loadedData) then
                message.channel:send("<@" .. author.id .. "> Done!")
            else
                message.channel:send("<@" .. author.id .. "> Error setting data. Please try again later.")
            end
        end
    elseif string.lower(message.content):match("/clothingsourcerequiresadmin%s*.+") then
        local author = message.guild:getMember(message.author)
        if member and not (member:hasPermission(discordia.enums.permission.administrator)) then
            message.channel:send("<@" .. author.id .. "> You do not have permission to do this. Permission needed: Administrator")
            return
        end
        local guild = GET_GUILD("1186891224376938516")
        local channel = guild:getChannel("1187095120055648298")
        local loadedData = loadNewestJSONData(channel)
        if not loadedData then
            createAndSendDataMessage(channel, {})
        end
        local loadedData = loadNewestJSONData(channel)
        if loadedData then
            if not loadedData[message.guild.id] then
                loadedData[message.guild.id] = defaultConfig
            end
            
            if string.lower(message.content):match("/clothingsourcerequiresadmin%s*(.+)") == "false" then
                loadedData[message.guild.id]["ClothingSourceRequiresAdmin"] = false
            elseif string.lower(message.content):match("/clothingsourcerequiresadmin%s*(.+)") == "true" then
                loadedData[message.guild.id]["ClothingSourceRequiresAdmin"] = true
            else
                message.channel:send("<@" .. author.id .. "> command should be /ClothingSourceRequiresAdmin [true/false]. \n Example: ``/ClothingSourceRequiresAdmin true``")
                return
            end
            
            
            if createAndSendDataMessage(channel, loadedData) then
                message.channel:send("<@" .. author.id .. "> Done!")
            else
                message.channel:send("<@" .. author.id .. "> Error setting data. Please try again later.")
            end
        end
    elseif string.lower(message.content):match("/getclothingsource%s*.+") then
        local author = message.guild:getMember(message.author)
        local guild = GET_GUILD("1186891224376938516")
        local channel = guild:getChannel("1187095120055648298")
        local loadedData = loadNewestJSONData(channel)
        if not loadedData then
            createAndSendDataMessage(channel, {})
        end
        local loadedData = loadNewestJSONData(channel)


        if loadedData then
            if not loadedData[message.guild.id] then
                loadedData[message.guild.id] = defaultConfig
            end

            if member and (loadedData[message.guild.id]["ClothingSourceRequiresAdmin"] and loadedData[message.guild.id]["ClothingSourceRequiresAdmin"]==true) and not (member:hasPermission(discordia.enums.permission.administrator)) then
                message.channel:send("<@" .. author.id .. "> You do not have permission to do this. Permission needed: Administrator")
                return
            end
            
            if not string.lower(message.content):match("/getclothingsource%s*(.+)"):match(".*roblox.com/.+/%d+/.*") then 
                message.channel:send("<@" .. author.id .. "> Not a valid link!")
            end

            local URLBasic = string.lower(message.content):match("/getclothingsource%s*(.+)")
            local catalogNumber = string.match(URLBasic, "/(%d+)/")

            local function findXML(url)
                local response = {}
                local _, status = http.request{
                    url = url,
                    sink = ltn12.sink.table(response),
                }

                local _, file = http.request("GET", latestMessage.attachment.url)
        
                if status == 200 then
                    local data = table.concat(response)
                    extractXML(data)
                else
                    print("Failed to fetch data:", status)
                end
            end

            local function extractXML(data)
                local parser = require("XmlParser") -- Assuming you have an XML parsing library for Lua
        
                -- Parse XML data
                local xmlDoc = parser:ParseXmlText(data)
        
                -- Extract URL ID
                local imgURLNode = xmlDoc:SelectSingleNode("/roblox/Item/Properties/Content/url")
                if imgURLNode then
                    local imgURL = imgURLNode:get_Text()
                    local id = string.match(imgURL, "(%d+)")
                    openURL(id)
                else
                    print("URL not found in XML")
                end
            end









            local dmResult, dmError = message.author:send{embed = {
                title = "Link to image",
                description = "Here is your image",
                fields = {
                    {
                        name = "Link",
                        value = "Here is your link! " .. EditedURL ,
                        inline = true
                    }
                },
                footer = {
                    text = "Please do not use this for stealing or any other actions that go against TOS"
                },
                color = 0xe64b40
                
            }}
            
            if not dmResult then
                channelMAIN:send("<@" .. tostring(user.id) .. "> Failed to DM you. Make sure your DMs are open and try again. \n\n(error: ``" .. dmError .. "``)")
                return
            else
                message.channel:send("<@" .. author.id .. "> Sent you the file!") 
                return
            end
            
        end
    elseif string.lower(message.content):match("/profile%s*.+") then
        local function GetUserProfile()
            local loadedData = loadNewestJSONData(channel)
            if not loadedData then
                createAndSendDataMessage(channel, {})
            end
            local loadedData = loadNewestJSONData(channel)
            if loadedData then
                if not loadedData[message.guild.id] then
                    loadedData[message.guild.id] = defaultConfig
                end
                
                
                local mentionedUser = message.mentionedUsers.first
                
                if mentionedUser then
                    local userID = mentionedUser.id
                    for index, item in ipairs(loadedData[message.guild.id]) do
                        if item[1] == userID then
                            message.channel:send("<@" .. author.id .. "> [Here you go!](https://www.roblox.com/users/" .. tostring(item[2]["rblxID"]) .." /profile)")
                        end
                    end
                else
                    
                    end
            
            end
            
            return nil
        
        
        end
        
        
        local up = GetUserProfile()
        if up then
            message.channel:send("<@" .. author.id .. "> https://www.roblox.com/users/" .. tostring(up) .. "/profile")
        else
            message.channel:send("<@" .. author.id .. "> You must be in the same server as this member.")
        end
    elseif string.lower(message.content)=="fuck off" or string.lower(message.content)=="die"  then 
        message:reply("no.")
    elseif string.lower(message.content)=="deez" then 
        message:reply("nuts.")
    elseif string.find(string.lower(message.content),"kys") then 
        message:reply("(keep yourself safe)")
    end  
end)


client:on("memberJoin", function(member)
    local guild = GET_GUILD("1186891224376938516")
    local channel = guild:getChannel("1187095120055648298")
    local loadedData = loadNewestJSONData(channel)
    if not loadedData then
        createAndSendDataMessage(channel, {})
    end
    local loadedData = loadNewestJSONData(channel)
    if loadedData then
        if not loadedData[member.guild.id] then
            loadedData[member.guild.id] = defaultConfig
        end
        
        local function AlreadyVerified()
            local guild = GET_GUILD("1186891224376938516")
            local channel = guild:getChannel("1187095120055648298")
            local loadedData = loadNewestJSONData(channel)
            if not loadedData then
                createAndSendDataMessage(channel, {})
            end
            local loadedData = loadNewestJSONData(channel)
            if loadedData then
                if not loadedData[member.guild.id] then
                    loadedData[member.guild.id] = defaultConfig
                end
                --{member.id, rblxinfo}
                for index, item in pairs(loadedData[tablex[3].id].VerifiedUsers) do
                    if item[1] == member.id then
                        return true
                    end
                end
                
                return false
            end
        end
        
        
        if not AlreadyVerified() then
            if member.guild:getRole(loadedData[member.guild.id].defaultRole) then
                member:addRole(loadedData[member.guild.id].defaultRole)
            end
        else
            if member.guild:getRole(loadedData[member.guild.id].defaultRole) then
                member:addRole(loadedData[member.guild.id].defaultRole)
            end
            if member.guild:getRole(loadedData[member.guild.id].verifiedRole) then
                member:addRole(loadedData[member.guild.id].verifiedRole)
            end
        end
    end


end)

client:run("Bot " .. functions.retrieveToken())
