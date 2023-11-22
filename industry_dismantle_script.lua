-- Industry dismantle script
-- put this script on a programming board and link the core unit

require "math"
require "cpml/vec3"

local maxIndustryToDisplay = 5     --export: limit the industry list
local maxContainersToDisplay = 5   --export: limit the container list
local showAllContainers = false    --export: for finding hidden containers
local showAllElements = false      --export: for finding the last few elements


local core_unit = {}
for slot_name, slot in pairs(unit) do
    if type(slot) == "table" and type(slot.export) == "table" and slot.getClass then
        slot.slotname = slot_name
        
        local class = slot.getClass():lower()
        if class == 'coreunitstatic' or class == 'coreunitspace' then
            table.insert(core_unit, slot)
        end
    end
end

if #core_unit == 0 then
    system.print("No core detected. Link this script to the core unit.") 
    unit.exit()
    error("Error: Exit Failed...")
end
local core = core_unit[1]

local elementIdList = core.getElementIdList()

--[[
If the Element is an Industry Unit, a table with fields {
    [int] state, 
    [bool] stopRequested, 
    [int] schematicId (deprecated = 0), 
    [int] schematicsRemaining (deprecated = 0), 
    [table] requiredSchematicIds {[int] id}, 
    [int] requiredSchematicAmount, 
    [int] unitsProduced, 
    [int] remainingTime, 
    [int] batchesRequested, 
    [int] batchesRemaining, 
    [float] maintainProductAmount, 
    [int] currentProductAmount, 
    [table] currentProducts:{ {[int] id, [double] quantity}, ...}}

(Stopped = 1, 
Running = 2, 
Jammed missing ingredient = 3, 
Jammed output full = 4, 
Jammed no output container = 5, 
Pending = 6, 
Jammed missing schematics = 7)
]]

local industry = 0
local notStopped = 0
local worldPosition = vec3(construct.getWorldPosition())
local worldRight = vec3(construct.getWorldOrientationRight())
local worldForward = vec3(construct.getWorldOrientationForward())
local worldUp = vec3(construct.getWorldOrientationUp())

function local2world(loc)
    local loc = vec3(loc)   

    local w = worldPosition + loc.x*worldRight + loc.y*worldForward + loc.z*worldUp
    return w
end

function stickerAndWaypoint(loc, showSticker)
    local loc = vec3(loc) 
    local showSticker = showSticker or true
    
    if showSticker == true then
        local stickerIndex = core.spawnArrowSticker(loc.x+1, loc.y+1, loc.z+1, "down")
        core.rotateSticker(stickerIndex, -45, 45, 25)
    end
    
    local world = local2world(loc)
    local pos = string.format("::pos{0,0,%0.4f,%0.4f,%0.4f}", world.x, world.y, world.z)
    system.setWaypoint(pos, false)
    system.print(pos)
end

function allContainers() 
    for _,id in ipairs(elementIdList) do
        -- Container Class Id == 703994582
        local classId = core.getElementClassIdById(id)
        if classId == 703994582 then
            local itemId = core.getElementItemIdById(id)
            local item = system.getItem(itemId)
            local displayName = item["displayNameWithSize"]
            local elementName = core.getElementNameById(id)
            system.print(displayName .. " - " .. elementName)

            local localPosition = core.getElementPositionById(id)
            stickerAndWaypoint(localPosition, false)
        end
    end
end

function allElements()
    for _,id in ipairs(elementIdList) do
        local elementName = core.getElementNameById(id)
        system.print(elementName)

        local localPosition = core.getElementPositionById(id)
        stickerAndWaypoint(localPosition, false)
    end
end


function dismantle()
    for _,id in ipairs(elementIdList) do
        -- Industry Class Id == 3943695040
        local classId = core.getElementClassIdById(id)
        if classId == 3943695040 then
            industry = industry + 1
            local info = core.getElementIndustryInfoById(id)
            local state = info["state"] or -1
            local stopping = info["stopRequested"] or false
            local schematics = info["schematicsRemaining"] or -1

            if state ~= 1 then 
                notStopped = notStopped + 1 
            end
            if notStopped <= maxIndustryToDisplay and (state ~= 1 or schematics > 0) then
                local msg = core.getElementDisplayNameById(id)
                if stopping then msg = msg .. " - Stopping" end
                if schematics > 0 then msg = msg .. " - " .. schematics .. " schematics" end
                system.print(msg)

                local localPosition = core.getElementPositionById(id)
                stickerAndWaypoint(localPosition)
            end
        end
    end
    system.print(">>> " .. tostring(industry) .. " industry. " .. tostring(notStopped) .. " not stopped.")


    --[[
    system.getItem(itemId)
    {[int] id,
    [string] name,
    [string] displayName,
    [string] locDisplayName,
    [string] displayNameWithSize,
    [string] locDisplayNameWithSize,
    [string] description,
    [string] locDescription,
    [string] type,
    [number] unitMass,
    [number] unitVolume,
    [integer] tier,
    [string] size,
    [string] iconPath,
    [table] schematics,
    [table] products}
    ]]
    local containers = 0
    local notEmpty = 0
    for _,id in ipairs(elementIdList) do
        -- Container Class Id == 703994582
        local classId = core.getElementClassIdById(id)
        if classId == 703994582 then
            containers = containers + 1
            local mass = core.getElementMassById(id)
            local itemId = core.getElementItemIdById(id)
            local item = system.getItem(itemId)
            local unitMass = tonumber(item["unitMass"])

            if mass > unitMass then
                notEmpty = notEmpty + 1
                if notEmpty <= maxContainersToDisplay then
                    local displayName = item["displayNameWithSize"]
                    local elementName = core.getElementNameById(id)
                    system.print(displayName .. " - " .. elementName)

                    local localPosition = core.getElementPositionById(id)
                    stickerAndWaypoint(localPosition)
                end
            end
        end
    end
    system.print(">>> " .. tostring(containers) .. " containers. " .. tostring(notEmpty) .. " not empty.")
end

system.print("")
system.print("")
system.print("=======================================")
if showAllContainers == true then
    allContainers()
elseif showAllElements == true then
    allElements()
else
    dismantle()
end 

-- Exiting will remove all stickers
--unit.exit()

