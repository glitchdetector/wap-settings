-- God this turned into such a bowl of spaghet but eh here we are
local PAGE_NAME = "settings"
local PAGE_TITLE = "Settings"
local PAGE_ICON = "wrench"

-- Sidebar badge
local PAGE_BADGE = false
local PAGE_BADGE_TYPE = "primary"

local CV_REPLICATE = 0xFF
local CV_BOOL, CV_INT, CV_STRING, CV_SLIDER, CV_MULTI, CV_COMBI, CV_PASSWORD = 1, 2, 3, 4, 5, 6, 7
-- List of convars
local CONVARS = {
    -- CAT: name, [desc]
    -- BOOL: name, convar, type, default, [label]
    -- INT: name, convar, type, default, [min], [max]
    -- STRING: name, convar, type, default
    -- SLIDER: name, convar, type, default, min, max
    -- COMBI: name, convar, type, default, min, max
    -- MULTI: name, convar, type, items[{name, value}] (first is default)

    {"Server Settings", ""},
    {"Server Name",         "sv_hostname",          CV_STRING,  "My new FXServer!"},
    {"Player Limit",        "sv_maxclients",        CV_COMBI,   32, 1, 128},
    {"Enable OneSync",      "onesync_enabled",      CV_BOOL,    false},

    {"Server Listing"},
    {"Show on server list", "sv_master1",           CV_MULTI,   {
        {"Yes",             "live-internal.fivem.net:30110"},
        {"No",              ""},
    }},
    {"Map Name",            "mapname",              CV_STRING,  "San Andreas"},
    {"Game Mode",           "gametype",             CV_STRING,  "Freeroam"},
    {"Locale",              "locale",               CV_STRING,  "en-US"},
    {"Tags",                "tags",                 CV_STRING,  "default"},

    {"Scripthook"},
    {"Enable Scripthook",   "sv_scriptHookAllowed", CV_BOOL,    false,  "Allows players to run custom game modifications"},

    {"Authentication", "Control requirements for joining the server"},
    {"Maximum Variance",    "sv_authMaxVariance",   CV_SLIDER,  1, 1, 5},
    {"Minimum Trust",       "sv_authMinTrust",      CV_SLIDER,  5, 1, 5},
}

local RESOURCE_CONVARS = {}
local CONVAR_LIST = {}
local function RefreshConvarlist()
    local _cvlist = {}
    for _, entry in next, CONVARS do
        table.insert(_cvlist, entry)
    end
    for resourceName, resourceFiles in next, RESOURCE_CONVARS do
        for resourceFileName, resourceConvars in next, resourceFiles do
            for _, entry in next, resourceConvars do
                table.insert(_cvlist, entry)
            end
        end
    end
    CONVAR_LIST = _cvlist
end
RefreshConvarlist()

-- Verify if a convar can be changed (input sanitization)
local function IsConvarSafe(convar)
    for _, data in next, CONVAR_LIST do
        if data[3] and data[2] == convar then
            return true, data
        end
    end
    return false, {}
end

local function ParseStructure(struct)
    local output = {}
    for _, entry in next, struct do
        local name, convar_desc, type, default_items, label_min, max = entry[1], entry[2], entry[3], entry[4], entry[5], entry[6]
        if not type then
            -- Header
            table.insert(output, {name, convar_desc})
        elseif type == "CV_BOOL" then
            table.insert(output, {name, convar_desc, CV_BOOL, default_items, label_min})
        elseif type == "CV_INT" then
            table.insert(output, {name, convar_desc, CV_INT, default_items, label_min, max})
        elseif type == "CV_STRING" then
            table.insert(output, {name, convar_desc, CV_STRING, default_items})
        elseif type == "CV_SLIDER" then
            table.insert(output, {name, convar_desc, CV_SLIDER, default_items, label_min, max})
        elseif type == "CV_MULTI" then
            table.insert(output, {name, convar_desc, CV_MULTI, default_items})
        elseif type == "CV_COMBI" then
            table.insert(output, {name, convar_desc, CV_COMBI, default_items, label_min, max})
        elseif type == "CV_PASSWORD" then
            table.insert(output, {name, convar_desc, CV_PASSWORD, default_items})

        -- Replicated
        elseif type == "CV_BOOL_R" then
            table.insert(output, {name, convar_desc, CV_BOOL + CV_REPLICATE, default_items, label_min})
        elseif type == "CV_INT_R" then
            table.insert(output, {name, convar_desc, CV_INT + CV_REPLICATE, default_items, label_min, max})
        elseif type == "CV_STRING_R" then
            table.insert(output, {name, convar_desc, CV_STRING + CV_REPLICATE, default_items})
        elseif type == "CV_SLIDER_R" then
            table.insert(output, {name, convar_desc, CV_SLIDER + CV_REPLICATE, default_items, label_min, max})
        elseif type == "CV_MULTI_R" then
            table.insert(output, {name, convar_desc, CV_MULTI + CV_REPLICATE, default_items})
        elseif type == "CV_COMBI_R" then
            table.insert(output, {name, convar_desc, CV_COMBI + CV_REPLICATE, default_items, label_min, max})
        elseif type == "CV_PASSWORD_R" then
            table.insert(output, {name, convar_desc, CV_PASSWORD + CV_REPLICATE, default_items})
        end
    end
    return output
end

local function AddResourceConvars(resourceName, fileName, fileData)
    if not RESOURCE_CONVARS[resourceName] then RESOURCE_CONVARS[resourceName] = {} end
    local data = ParseStructure(fileData)
    RESOURCE_CONVARS[resourceName][fileName] = data
    return true
end

local function RemoveResourceConvars(resourceName, fileName)
    if not RESOURCE_CONVARS[resourceName] then return false end
    if not fileName then
        RESOURCE_CONVARS[resourceName] = nil
        return true
    else
        if RESOURCE_CONVARS[resourceName] then
            RESOURCE_CONVARS[resourceName][fileName] = {}
            return true
        end
    end
    return false
end

local function HandleResourceStart(resourceName)
    -- Load convar files
    local n = GetNumResourceMetadata(resourceName, "convar_json")
    if n > 0 then
        for i = 0, n - 1 do
            local fileName = GetResourceMetadata(resourceName, "convar_json", i)
            local fileData = LoadResourceFile(resourceName, fileName)
            if AddResourceConvars(resourceName, fileName, json.decode(fileData)) then
                RefreshConvarlist()
            end
        end
    end
    -- Load rich convar entries
    local n = GetNumResourceMetadata(resourceName, "convar_category")
    if n > 0 then
        for i = 0, n - 1 do
            local categoryName = GetResourceMetadata(resourceName, "convar_category", i)
            local categoryStruct = GetResourceMetadata(resourceName, "convar_category_extra", i)
            local categoryData = json.decode(categoryStruct)
            local category = categoryData[2]
            table.insert(category, 1, {categoryName, categoryData[1]})
            if AddResourceConvars(resourceName, categoryName, category) then
                RefreshConvarlist()
            end
        end
    end
end
AddEventHandler("onResourceStart", HandleResourceStart)
AddEventHandler("onResourceStop", function(resourceName)
    if RemoveResourceConvars(resourceName) then
        RefreshConvarlist()
    end
end)

Citizen.CreateThread(function()
    local resources = GetNumResources()
    for i = 0, resources -1 do
        local resourceName = GetResourceByFindIndex(i)
        if GetResourceState(resourceName) == "started" then
            HandleResourceStart(resourceName)
        end
    end
end)

-- Input group builder
local function GenerateInputGroup(FAQ, input, left, right)
    return FAQ.Node("div", {class = "input-group mb-3"}, {
        left and FAQ.Node("div", {class = "input-group-prepend"}, left) or "",
        input,
        right and FAQ.Node("div", {class = "input-group-append"}, right) or "",
    })
end

-- Input group select field builder
local function GenerateCustomSelect(FAQ, name, list)
    local options = {}
    for _, entry in next, list do
        table.insert(options, FAQ.Node("option", {value = entry[2]}, entry[1]))
    end
    return FAQ.Node("select", {class = "custom-select", name = name}, options)
end

-- Input group checkbox field builder
local function FormInputCheckbox(FAQ, name, checked, label, inline)
    return FAQ.Node("div", {class = "form-check" .. (inline and " form-check-inline" or "")}, {
        FAQ.Node("input", {class = "form-check-input", name = name, type = "checkbox", value = (checked and "true" or "false"), checked = (checked and "true" or nil)}, ""),
        label and FAQ.Node("label", {class = "form-check-label"}, label) or "",
    })
end

-- Main page creator
function CreatePage(FAQ, data, add)
    if data.convar then
        local safe, convar = IsConvarSafe(data.convar)
        if not safe then
            return false, FAQ.Nodes({"The value of ", FAQ.Node("strong", {}, data.convar), " cannot be changed."})
        else
            if not exports['webadmin']:isInRole("command." .. data.convar) then
                return false, FAQ.Nodes({"You are not authorized to change the value of ", FAQ.Node("strong", {}, data.convar), "."})
            end
            local default = convar[4]
            if convar[3] and (convar[3] % 0xFF) == CV_MULTI then
                default = convar[4][1][2]
            end
            local oldvar = GetConvar(data.convar, tostring(default))
            oldvar = (oldvar == "" and "[nothing]" or oldvar)
            if convar[3] and (convar[3] % 0xFF) == CV_BOOL then
                if data[data.convar] then data[data.convar] = "true" end
                if not data[data.convar] then data[data.convar] = "false" end
            end
            local newvar = (data[data.convar] == "" and "[nothing]" or data[data.convar])
            if tostring(oldvar) == tostring(data[data.convar]) then
                add(FAQ.Alert("warning", FAQ.Nodes({"The value of ", FAQ.Node("strong", {}, convar[2]), " is already set to ", FAQ.Node("code", {}, oldvar)})))
            else
                if convar[3] and convar[3] > 0xFF then
                    print("set convar", data.convar, data[data.convar], "(replicated)")
                    SetConvarReplicated(data.convar, data[data.convar])
                else
                    print("set convar", data.convar, data[data.convar])
                    SetConvar(data.convar, data[data.convar])
                end
                add(FAQ.Alert("info", FAQ.Nodes({"Updated ", FAQ.Node("strong", {}, convar[2]), " from ", FAQ.Node("code", {}, oldvar), " to ", FAQ.Node("code", {}, newvar)})))
            end
        end
    end
    local list = CONVAR_LIST
    if data.resource then
        if RESOURCE_CONVARS[data.resource] then
            if data.file then
                if RESOURCE_CONVARS[data.resource][data.file] then
                    list = RESOURCE_CONVARS[data.resource][data.file]
                else
                    return false, FAQ.Nodes({"No configurations for ", FAQ.Node("strong", {}, data.resource), "'s ", FAQ.Node("strong", {}, data.file), " are available"})
                end
            else
                list = {}
                for resourceFileName, resourceConvars in next, RESOURCE_CONVARS[data.resource] do
                    for _, entry in next, resourceConvars do
                        table.insert(list, entry)
                    end
                end
            end
        else
            return false, FAQ.Nodes({"No configurations for ", FAQ.Node("strong", {}, data.resource), " are available"})
        end
    end
    for _, convar in next, list do
        local cvtype, cvname = convar[3], convar[2]
        if not cvtype then
            -- Header
            local title, subtitle = convar[1], convar[2]
            local header = FAQ.Node("h2", {}, title)
            if subtitle then
                header = FAQ.Nodes({
                    header,
                    FAQ.Node("h5", {class = "text-muted"}, subtitle)
                })
            end
            add(header)
            add(FAQ.Node("hr", {}, ""))
        elseif (cvtype % 0xFF) == CV_BOOL then
            -- Toggle switch
            local title, name, default, label = convar[1], convar[2], tostring(convar[4]), convar[5]
            local cvval = tostring(GetConvar(name, default))
            local checked = (cvval == "true" or cvval == "1")
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, GenerateInputGroup(FAQ, {
                FAQ.Node("span", {class = "input-group-text form-control"}, {
                    FormInputCheckbox(FAQ, name, checked, label or "Yes / No", true)
                }),
            }, {
                FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title),
            }, FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)})))
            add(form)
        elseif (cvtype % 0xFF) == CV_INT then
            -- Number input
            local title, name, default, min, max = convar[1], convar[2], convar[4], convar[5], convar[6]
            local cvval = tostring(GetConvar(name, default))
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, GenerateInputGroup(FAQ, FAQ.Node("input", {
                type = "number",
                class = "form-control",
                name = name,
                value = cvval,
                min = min,
                max = max,
                placeholder = default or "",
                disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil),
            }, ""), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)})))
            add(form)
        elseif (cvtype % 0xFF) == CV_COMBI then
            -- Combined number slider input
            local title, name, default, min, max = convar[1], convar[2], convar[4], convar[5], convar[6]
            local cvval = tostring(GetConvar(name, default))
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, {
                FAQ.Node("input", {
                    type = "hidden",
                    name = name,
                    id = name,
                    value = cvval,
                }, ""),
                GenerateInputGroup(FAQ, {
                    FAQ.Node("span", {class = "input-group-text"}, {
                        FAQ.Node("span", {}, min),
                    }),
                    FAQ.Node("span", {class = "input-group-text form-control"}, FAQ.Node("input", {
                        type = "range",
                        id = name .. "_range",
                        class = "custom-range",
                        value = cvval,
                        min = min,
                        max = max,
                        step = "1",
                        placeholder = default or "",
                        disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil),
                        oninput = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_number').value = this.value]],
                        onchange = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_number').value = this.value]],
                    }, "")),
                }, FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), {
                    FAQ.Node("span", {class = "input-group-text"}, {
                        FAQ.Node("span", {}, max),
                    }),
                    FAQ.Node("input", {
                        type = "number",
                        id = name .. "_number",
                        class = "form-control",
                        value = cvval,
                        min = min,
                        max = max,
                        placeholder = default or "",
                        disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil),
                        oninput = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_range').value = this.value]],
                        onchange = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_range').value = this.value]],
                    }, ""),
                    FAQ.Button("primary", {
                        "Update ", FAQ.Icon("sync-alt")
                    }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)}),
                })
            })
            add(form)
        elseif (cvtype % 0xFF) == CV_STRING then
            -- Text input
            local title, name, default = convar[1], convar[2], convar[4]
            local cvval = tostring(GetConvar(name, default))
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, GenerateInputGroup(FAQ, FAQ.Node("input", {
                type = "text",
                class = "form-control",
                name = name,
                value = cvval,
                placeholder = default or "",
                disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil),
            }, ""), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)})))
            add(form)
        elseif (cvtype % 0xFF) == CV_PASSWORD then
            -- Text input
            local title, name, default = convar[1], convar[2], convar[4]
            local cvval = tostring(GetConvar(name, default))
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, GenerateInputGroup(FAQ, FAQ.Node("input", {
                type = "password",
                class = "form-control",
                name = name,
                value = cvval,
                placeholder = default or "",
                disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil),
            }, ""), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)})))
            add(form)
        elseif (cvtype % 0xFF) == CV_SLIDER then
            -- Slider
            local title, name, default, min, max = convar[1], convar[2], convar[4], convar[5], convar[6]
            local cvval = GetConvarInt(name, default)
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, GenerateInputGroup(FAQ, {
                FAQ.Node("span", {class = "input-group-text form-control"}, FAQ.Node("input", {
                    type = "range",
                    class = "custom-range",
                    name = name,
                    value = cvval,
                    min = min,
                    max = max,
                    step = "1",
                    placeholder = default or "",
                    disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil),
                    oninput = [[document.getElementById(']]..name..[[').innerHTML = this.value]],
                    onchange = [[document.getElementById(']]..name..[[').innerHTML = this.value]],
                }, "")),
            }, {
                FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title),
            }, {
                FAQ.Node("span", {class = "input-group-text"}, {
                    FAQ.Node("span", {id = name}, cvval),
                    FAQ.Node("span", {style = "margin-left: 5px; margin-right: 5px;"}, "/"),
                    FAQ.Node("span", {}, max),
                }),
                FAQ.Button("primary", {
                    "Update ", FAQ.Icon("sync-alt")
                }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)}),
            }))
            add(form)
        elseif (cvtype % 0xFF) == CV_MULTI then
            -- Dropdown
            local title, name, list = convar[1], convar[2], convar[4]
            local dropdown = {}
            local cvval = tostring(GetConvar(name, list[1][2]))
            local current = nil
            for _, entry in next, list do
                if tostring(cvval) == tostring(entry[2]) then
                    current = {entry[1], entry[2]}
                else
                    table.insert(dropdown, {entry[1], entry[2]})
                end
            end
            if current then
                table.insert(dropdown, 1, current)
            end
            local form = FAQ.Form(PAGE_NAME, {convar = name, resource = data.resource, file = data.file}, GenerateInputGroup(FAQ, GenerateCustomSelect(FAQ, name, dropdown), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit", disabled = (not exports['webadmin']:isInRole("command." .. name) and "disabled" or nil)})))
            add(form)
        end
    end
    return true, "OK"
end

-- Automatically sets up a page and sidebar option based on the above configurations
Citizen.CreateThread(function()
    local PAGE_ACTIVE = false
    local FAQ = exports['webadmin-lua']:getFactory()
    exports['webadmin']:registerPluginOutlet("nav/sideList", function(data) --[[R]]--
        if not exports['webadmin']:isInRole("webadmin."..PAGE_NAME..".view") then return "" end
        local _PAGE_ACTIVE = PAGE_ACTIVE PAGE_ACTIVE = false
        return FAQ.SidebarOption(PAGE_NAME, PAGE_ICON, PAGE_TITLE, PAGE_BADGE, PAGE_BADGE_TYPE, _PAGE_ACTIVE) --[[R]]--
    end)
    exports['webadmin']:registerPluginPage(PAGE_NAME, function(data) --[[E]]--
        if not exports['webadmin']:isInRole("webadmin."..PAGE_NAME..".view") then return "" end
        PAGE_ACTIVE = true
        return FAQ.Nodes({ --[[R]]--
            FAQ.PageTitle(PAGE_TITLE),
            FAQ.BuildPage(CreatePage, data), --[[R]]--
        })
    end)
end)
