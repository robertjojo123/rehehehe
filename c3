local cipher = peripheral.wrap("advanced_cipher_0")
if not cipher then error("No advanced_cipher_0") end

local function try(label, fn)
    print("")
    print("TRY: " .. label)

    local ok, a, b, c, d = pcall(fn)

    print("OK:", ok)

    if ok then
        print("RET1:", tostring(a), type(a))
        print("RET2:", tostring(b), type(b))
        print("RET3:", tostring(c), type(c))
        print("RET4:", tostring(d), type(d))
        return a, b, c, d
    else
        print("ERR:", tostring(a))
        return nil
    end
end

local function safeValue(v)
    if type(v) == "string" then
        if #v > 80 then
            return v:sub(1, 80) .. "... len=" .. #v
        end
        return v
    end

    return tostring(v)
end

local keyset = try("createRandomKeySet()", function()
    return cipher.createRandomKeySet()
end)

if type(keyset) ~= "table" then
    error("Expected keyset table, got " .. type(keyset))
end

print("")
print("=== KEYSET TABLE FIELDS ===")

local candidates = {}

for k, v in pairs(keyset) do
    print("KEY:", tostring(k), "TYPE:", type(v), "VALUE:", safeValue(v))

    if type(v) == "string" then
        candidates[#candidates + 1] = {
            label = "keyset[" .. tostring(k) .. "]",
            value = v
        }
    elseif type(v) == "function" then
        local out = try("keyset[" .. tostring(k) .. "]()", function()
            return v()
        end)

        if type(out) == "string" then
            candidates[#candidates + 1] = {
                label = "keyset[" .. tostring(k) .. "]()",
                value = out
            }
        end
    end
end

print("")
print("=== COMMON FIELD CHECKS ===")

local common = {
    "public", "private",
    "pub", "priv",
    "publicKey", "privateKey",
    "encrypt", "decrypt",
    "e", "d", "n",
    1, 2, 3, 4
}

for _, k in ipairs(common) do
    local v = keyset[k]
    print("FIELD", tostring(k), "TYPE:", type(v), "VALUE:", safeValue(v))

    if type(v) == "string" then
        candidates[#candidates + 1] = {
            label = "keyset[" .. tostring(k) .. "]",
            value = v
        }
    elseif type(v) == "function" then
        local out = try("keyset[" .. tostring(k) .. "]()", function()
            return v()
        end)

        if type(out) == "string" then
            candidates[#candidates + 1] = {
                label = "keyset[" .. tostring(k) .. "]()",
                value = out
            }
        end
    end
end

print("")
print("CANDIDATE STRING KEYS:", #candidates)

for i, cand in ipairs(candidates) do
    print(i .. ") " .. cand.label .. " = " .. safeValue(cand.value))
end

print("")
print("=== ENCRYPT / DECRYPT TESTS ===")

local msg = "hello casino"

for i, encKey in ipairs(candidates) do
    local encrypted = try("encrypt(msg, " .. encKey.label .. ")", function()
        return cipher.encrypt(msg, encKey.value)
    end)

    if type(encrypted) == "string" then
        print("Encrypted with candidate " .. i)

        for j, decKey in ipairs(candidates) do
            local plain = try("decrypt(encrypted, " .. decKey.label .. ")", function()
                return cipher.decrypt(encrypted, decKey.value)
            end)

            if plain == msg then
                print("")
                print("======================================")
                print("WORKING RSA PAIR FOUND")
                print("ENCRYPT KEY: " .. encKey.label)
                print("DECRYPT KEY: " .. decKey.label)
                print("======================================")
                return
            end
        end
    end
end

print("")
print("No working pair found from visible table fields.")
print("Send me the KEYSET TABLE FIELDS output.")
