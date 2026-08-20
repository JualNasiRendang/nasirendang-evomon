-- [[ Upgraded Unified Integrity & Constant Stack Patcher ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local getgc = (getgc or get_gc_objects)
local getconstants = (debug.getconstants or getconstants)
local getstack = (debug.getstack or getstack)
local setstack = (debug.setstack or setstack)
local hookfunction = (hookfunction or hookfunc)

if not getgc then
    warn("[!] Executor does not support getgc")
    return
end

-- print("[*] Starting Unified Integrity & Stack Patcher...")

-- 1. Targeted Internal Tokens & Error Identifiers
local TARGET_TOKENS = {
    ["X-16"] = true,
    ["Character integrity sampling was intercepted"] = true,
    ["Character integrity evaluator returned an invalid completion receipt"] = true,
    ["Character integrity movement evaluation failed"] = true,
    ["Character integrity execution was interrupted"] = true,
    ["Invalid character state mutation scope"] = true,
    ["Invalid ground-contact mutation scope"] = true
}

-- 2. Scan and Patch Target Closures in GC
local patchedClosures = 0

for _, value in pairs(getgc(true)) do
    if type(value) == "function" and islclosure(value) and not isexecutorclosure(value) then
        local success, constants = pcall(getconstants, value)
        if success and type(constants) == "table" then
            local shouldPatch = false
            for _, constant in pairs(constants) do
                if type(constant) == "string" and TARGET_TOKENS[constant] then
                    shouldPatch = true
                    break
                end
            end

            if shouldPatch then
                local oldHook
                oldHook = hookfunction(value, newcclosure(function(...)
                    -- Inspect active frame level 1
                    local stackSuccess, stack = pcall(getstack, 1)
                    if stackSuccess and type(stack) == "table" then
                        for index, stackVal in pairs(stack) do
                            if type(stackVal) == "string" and TARGET_TOKENS[stackVal] then
                                pcall(setstack, 1, index, nil)
                            end
                        end
                    end
                    return oldHook(...)
                end))
                patchedClosures = patchedClosures + 1
            end
        end
    end
end

-- print(string.format("[+] Patched %d integrity-monitoring closure(s).", patchedClosures))

-- 3. Layered Network Filter (Drop Outgoing Violation Reports Only)
local VIOLATIONS = {
    ["ClientCharacter: IntegrityViolation"] = true,
    ["ClientCharacter: CorrectionStarted"] = true,
    ["ClientCharacter: RequestCharacterReset"] = true
}

pcall(function()
    local Network = require(ReplicatedStorage.Library.Client.Network)
    local rawFire = Network.Fire

    if rawFire then
        Network.Fire = function(endpoint, ...)
            if type(endpoint) == "string" and VIOLATIONS[endpoint] then
                return -- Silently drop violation report
            end
            return rawFire(endpoint, ...)
        end
    end
end)

-- print("[✓] Unified Integrity Patcher active & operational.")
