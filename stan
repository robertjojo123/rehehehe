local BASE = "https://cc-yt-bridge.onrender.com"

local function urlEncode(s)
    return tostring(s):gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function get(url)
    local res, err = http.get(url)
    if not res then
        return nil, err
    end

    local body = res.readAll()
    res.close()
    return body, nil
end

local function getJson(url)
    local body, err = get(url)
    if not body then
        return nil, err
    end

    local data = textutils.unserializeJSON(body)
    if not data then
        return nil, "Bad JSON: " .. tostring(body)
    end

    return data, nil
end

print("YouTube Search")
print("--------------")
write("Search: ")
local q = read()

local data, err = getJson(BASE .. "/search?q=" .. urlEncode(q) .. "&max_results=5")
if not data then
    print("Search failed:")
    print(tostring(err))
    return
end

local results = data.results or {}
if #results == 0 then
    print("No results.")
    return
end

print("")
for i, v in ipairs(results) do
    print(i .. ". " .. tostring(v.title))
    print("   " .. tostring(v.channel))
    print("   " .. tostring(v.id))
    print("")
end

write("Pick 1-" .. #results .. ": ")
local choice = tonumber(read())

if not choice or not results[choice] then
    print("Bad choice.")
    return
end

local picked = results[choice]

print("")
print("Picked:")
print(tostring(picked.title))
print(tostring(picked.id))
print("")
print("Preparing job...")

local prep, err = getJson(BASE .. "/prepare?id=" .. urlEncode(picked.id))
if not prep then
    print("Prepare failed:")
    print(tostring(err))
    return
end

print("Prepare response:")
print(textutils.serialize(prep))

if prep.job then
    print("")
    print("Job ID: " .. tostring(prep.job))
end
