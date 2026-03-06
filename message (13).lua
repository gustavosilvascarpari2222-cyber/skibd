local groupId = 34352374
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ok, inGroup = pcall(function() return player:IsInGroup(groupId) end)
if not ok or not inGroup then
    warn("Você precisa estar no grupo para usar esse script!")
    return
end

if not game:IsLoaded() then game.Loaded:Wait() end

local env = getgenv()
if env.ESPLoaded then
    warn("ESP já está carregado! Não execute novamente.")
    return
end
env.ESPLoaded = true

local cloneref = cloneref or function(o) return o end
local isfile = isfile or function() return false end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end
local delfile = delfile or function() end
local queue_on_teleport = queue_on_teleport or function() end

local Services = setmetatable({}, {
    __index = function(self, name)
        local s = game:GetService(name)
        self[name] = s
        return s
    end
})

local RunService      = Services.RunService
local UserInputService= Services.UserInputService
local HttpService     = Services.HttpService
local TweenService    = Services.TweenService
local Players         = Services.Players
local CoreGui         = Services.CoreGui

local drawingNew    = Drawing.new
local instanceNew   = Instance.new
local Vector2New    = Vector2.new
local Vector3New    = Vector3.new
local Color3New     = Color3.new
local Color3fromRGB = Color3.fromRGB
local floor         = math.floor
local abs           = math.abs
local clamp         = math.clamp
local sqrt          = math.sqrt

local localPlayer = Players.LocalPlayer
if not localPlayer then
    Players.PlayerAdded:Wait()
    localPlayer = Players.LocalPlayer
end

env.Connections = env.Connections or {}
pcall(function()
    for _, conn in pairs(env.Connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    env.Connections = {}
end)

if env.ESPObjs then
    for _, playerData in pairs(env.ESPObjs) do
        pcall(function()
            for _, l in pairs(playerData.l or {}) do pcall(function() l:Remove() end) end
            for _, l in pairs(playerData.s or {}) do pcall(function() l:Remove() end) end
            if playerData.h then pcall(function() playerData.h:Remove() end) end
            if playerData.t then pcall(function() playerData.t:Remove() end) end
        end)
    end
end

pcall(function()
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g:IsA("ScreenGui") and (g.Name:find("ESP") or g.Name:find("Panel")) then g:Destroy() end
    end
end)

task.wait(0.3)

local function toScreen(cam, worldPos)
    local sp = cam:WorldToViewportPoint(worldPos)
    if sp.Z <= 0 then return sp, false end
    return sp, true
end

local Themes = {
    ["Dark"]      = { Background=Color3fromRGB(0,0,0),       Secondary=Color3fromRGB(60,60,60),    Accent=Color3fromRGB(100,100,100), Text=Color3fromRGB(255,255,255), TextDim=Color3fromRGB(180,180,180), Border=Color3fromRGB(80,80,80),    Success=Color3fromRGB(0,200,100),   Warning=Color3fromRGB(255,165,0),   Error=Color3fromRGB(220,50,50)    },
    ["Light"]     = { Background=Color3fromRGB(255,255,255), Secondary=Color3fromRGB(220,220,220), Accent=Color3fromRGB(180,180,180), Text=Color3fromRGB(30,30,30),   TextDim=Color3fromRGB(100,100,100), Border=Color3fromRGB(160,160,160), Success=Color3fromRGB(0,180,80),    Warning=Color3fromRGB(235,145,0),   Error=Color3fromRGB(200,30,30)    },
    ["Midnight"]  = { Background=Color3fromRGB(15,15,35),    Secondary=Color3fromRGB(25,25,50),    Accent=Color3fromRGB(100,100,200),Text=Color3fromRGB(220,220,255), TextDim=Color3fromRGB(150,150,200), Border=Color3fromRGB(50,50,100),   Success=Color3fromRGB(100,200,150), Warning=Color3fromRGB(255,180,50),  Error=Color3fromRGB(255,100,120)  },
    ["Ocean"]     = { Background=Color3fromRGB(15,25,35),    Secondary=Color3fromRGB(20,35,50),    Accent=Color3fromRGB(0,180,216),  Text=Color3fromRGB(220,240,255), TextDim=Color3fromRGB(130,160,180), Border=Color3fromRGB(30,50,70),    Success=Color3fromRGB(0,230,180),   Warning=Color3fromRGB(255,200,100), Error=Color3fromRGB(255,80,100)   },
    ["Forest"]    = { Background=Color3fromRGB(15,25,15),    Secondary=Color3fromRGB(25,40,25),    Accent=Color3fromRGB(60,140,60),  Text=Color3fromRGB(220,255,220), TextDim=Color3fromRGB(140,180,140), Border=Color3fromRGB(40,80,40),    Success=Color3fromRGB(100,220,100), Warning=Color3fromRGB(255,193,7),   Error=Color3fromRGB(244,67,54)    },
    ["Sunset"]    = { Background=Color3fromRGB(30,20,25),    Secondary=Color3fromRGB(40,28,35),    Accent=Color3fromRGB(255,87,34),  Text=Color3fromRGB(255,240,230), TextDim=Color3fromRGB(200,170,160), Border=Color3fromRGB(60,40,50),    Success=Color3fromRGB(255,193,7),   Warning=Color3fromRGB(255,152,0),   Error=Color3fromRGB(211,47,47)    },
    ["Neon"]      = { Background=Color3fromRGB(10,0,20),     Secondary=Color3fromRGB(20,0,40),     Accent=Color3fromRGB(255,0,255),  Text=Color3fromRGB(255,100,255), TextDim=Color3fromRGB(200,50,200),  Border=Color3fromRGB(150,0,150),   Success=Color3fromRGB(0,255,150),   Warning=Color3fromRGB(255,255,0),   Error=Color3fromRGB(255,50,150)   },
    ["Cyberpunk"] = { Background=Color3fromRGB(5,10,15),     Secondary=Color3fromRGB(15,20,30),    Accent=Color3fromRGB(0,255,255),  Text=Color3fromRGB(0,255,255),   TextDim=Color3fromRGB(0,180,180),   Border=Color3fromRGB(0,150,150),   Success=Color3fromRGB(255,0,255),   Warning=Color3fromRGB(255,200,0),   Error=Color3fromRGB(255,0,100)    },
}

local DEFAULT_CONFIG = {
    on=true, dist=700, box=true, name=true, hp=true, distance=true,
    skel=true, head=true, team=false, tcolor=true, thick=1,
    menuLocked=false, persist=true, updateRate=0, healthUpdateRate=0.05,
    currentTheme="Dark", transparency=0.05, headRadiusR6=20
}

local config = {}
for k,v in pairs(DEFAULT_CONFIG) do config[k]=v end

local configFile = "esp_config_modern.json"
local savedConfig = nil
pcall(function()
    if isfile(configFile) then
        savedConfig = HttpService:JSONDecode(readfile(configFile))
        for key, value in pairs(savedConfig) do
            if config[key] ~= nil then config[key] = value end
        end
    end
end)

local minimized   = savedConfig and savedConfig.minimized ~= nil and savedConfig.minimized or false
local currentPage = "Main"

local espObjects  = {}
local healthCache = {}
local partCache   = {}
getgenv().ESPObjs = espObjects

local function saveConfig(frame)
    if not frame then return end
    local data = {}
    for k,v in pairs(config) do data[k]=v end
    data.minimized       = minimized
    data.currentPage     = currentPage
    data.positionXScale  = frame.Position.X.Scale
    data.positionXOffset = frame.Position.X.Offset
    data.positionYScale  = frame.Position.Y.Scale
    data.positionYOffset = frame.Position.Y.Offset
    pcall(function() writefile(configFile, HttpService:JSONEncode(data)) end)
end

local function cleanup()
    for _, obj in pairs(espObjects) do
        for _, l in pairs(obj.l or {}) do pcall(function() l:Remove() end) end
        for _, l in pairs(obj.s or {}) do pcall(function() l:Remove() end) end
        if obj.h then pcall(function() obj.h:Remove() end) end
        if obj.t then pcall(function() obj.t:Remove() end) end
    end
    espObjects  = {}
    partCache   = {}
    healthCache = {}
    getgenv().ESPObjs   = nil
    getgenv().ESPLoaded = nil
    pcall(function()
        for _, g in ipairs(CoreGui:GetChildren()) do
            if g:IsA("ScreenGui") and (g.Name:find("ESP") or g.Name:find("Panel")) then g:Destroy() end
        end
    end)
    if env.Connections.ESPConnection       then env.Connections.ESPConnection:Disconnect()       end
    if env.Connections.ESPHealthConnection then env.Connections.ESPHealthConnection:Disconnect() end
end

local function createESP(p)
    if p == localPlayer then return end
    if espObjects[p] then return end
    pcall(function()
        local boxLines = {}
        for i=1,4 do
            local l = drawingNew("Line")
            l.Visible=false; l.Thickness=config.thick
            l.Color=Color3New(1,1,1); l.Transparency=1; l.ZIndex=2
            boxLines[i]=l
        end
        local skelLines = {}
        for i=1,15 do
            local l = drawingNew("Line")
            l.Visible=false; l.Thickness=config.thick
            l.Color=Color3New(1,1,1); l.Transparency=1; l.ZIndex=5
            skelLines[i]=l
        end
        local hc = drawingNew("Circle")
        hc.Visible=false; hc.Thickness=config.thick; hc.NumSides=12
        hc.Filled=false; hc.Color=Color3New(1,1,1); hc.Transparency=1; hc.ZIndex=3
        local nt = drawingNew("Text")
        nt.Visible=false; nt.Center=true; nt.Outline=true
        nt.Font=2; nt.Size=13; nt.Color=Color3New(1,1,1); nt.ZIndex=4
        espObjects[p] = { l=boxLines, s=skelLines, h=hc, t=nt }
        if p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                healthCache[p] = { health=hum.Health, maxHealth=hum.MaxHealth }
            end
        end
    end)
end

local function removeESP(p)
    local d = espObjects[p]
    if not d then return end
    pcall(function()
        for _,l in pairs(d.l or {}) do l:Remove() end
        for _,l in pairs(d.s or {}) do l:Remove() end
        if d.h then d.h:Remove() end
        if d.t then d.t:Remove() end
        espObjects[p]  = nil
        healthCache[p] = nil
        partCache[p]   = nil
    end)
end

local R15_BONES = {
    {"UpperTorso","Head"},{"LowerTorso","UpperTorso"},{"HumanoidRootPart","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6_BONES = {
    {"Torso","Head"},{"HumanoidRootPart","Torso"},
    {"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local _cacheTick = 0
local function refreshPartCache()
    local now = tick()
    local cacheSize = 0
    for _ in pairs(espObjects) do cacheSize = cacheSize + 1 end
    local cacheRate = cacheSize > 10 and 0.2 or 0.1
    if now - _cacheTick < cacheRate then return end
    _cacheTick = now
    for p in pairs(espObjects) do
        if p == localPlayer then partCache[p]=nil; continue end
        if not (p and p.Parent) then partCache[p]=nil; continue end
        local char = p.Character
        if not char then
            partCache[p] = nil
        else
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if not (hrp and head and hum) then
                partCache[p] = nil
            else
                local isR15 = char:FindFirstChild("LowerTorso") ~= nil
                local rawBones = isR15 and R15_BONES or R6_BONES
                local resolved = {}
                for _, b in ipairs(rawBones) do
                    local p0 = char:FindFirstChild(b[1])
                    local p1 = char:FindFirstChild(b[2])
                    if p0 and p1 and p0:IsA("BasePart") and p1:IsA("BasePart") then
                        resolved[#resolved+1] = {p0, p1}
                    end
                end
                partCache[p] = { hrp=hrp, head=head, hum=hum, isR15=isR15, bones=resolved }
            end
        end
    end
end

local _espTick   = 0
local _lastDt    = 0.022
local _frameOver = false

local function updateESP()
    local now = tick()
    local minInterval = _frameOver and 0.05 or 0.022
    if now - _espTick < minInterval then return end
    local frameStart = now
    _espTick = now

    refreshPartCache()

    if not config.on then
        for _, d in pairs(espObjects) do
            for _,l in pairs(d.l or {}) do l.Visible=false end
            for _,l in pairs(d.s or {}) do l.Visible=false end
            if d.h then d.h.Visible=false end
            if d.t then d.t.Visible=false end
        end
        return
    end

    if not localPlayer then return end
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    if not (hrp and cam) then return end

    local team      = localPlayer.Team
    local vpX       = cam.ViewportSize.X
    local vpY       = cam.ViewportSize.Y
    local localPos  = hrp.Position
    local camCF     = cam.CFrame
    local camPos    = camCF.Position
    local camLookX  = camCF.LookVector.X
    local camLookY  = camCF.LookVector.Y
    local camLookZ  = camCF.LookVector.Z
    local maxDistSq = config.dist * config.dist
    local fovFactor = vpY / (2 * math.tan(math.rad(cam.FieldOfView) * 0.5))
    local showBox   = config.box
    local showHead  = config.head
    local showSkel  = config.skel
    local showName  = config.name
    local showHp    = config.hp
    local showDist  = config.distance
    local checkTeam = config.team
    local useTeamC  = config.tcolor
    local thick     = config.thick
    local maxDist   = config.dist

    for p, d in pairs(espObjects) do
        pcall(function()
            local dl = d.l
            local ds = d.s
            dl[1].Visible=false; dl[2].Visible=false
            dl[3].Visible=false; dl[4].Visible=false
            local dh = d.h; local dt = d.t
            if dh then dh.Visible=false end
            if dt then dt.Visible=false end
            for i=1,#ds do ds[i].Visible=false end

            if not (p and p.Parent) then return end

            local cache = partCache[p]
            if not cache then return end
            local tHRP = cache.hrp
            local head = cache.head
            local hum  = cache.hum
            if not (tHRP and hum) then return end
            if hum.Health <= 0 then return end

            local rp   = tHRP.Position
            local dx2  = localPos.X - rp.X
            local dy2  = localPos.Y - rp.Y
            local dz2  = localPos.Z - rp.Z
            local distSq = dx2*dx2 + dy2*dy2 + dz2*dz2
            if distSq > maxDistSq then return end
            if checkTeam and p.Team == team then return end

            local toCamX = rp.X - camPos.X
            local toCamY = rp.Y - camPos.Y
            local toCamZ = rp.Z - camPos.Z
            local dot = toCamX*camLookX + toCamY*camLookY + toCamZ*camLookZ
            if dot < -5 then return end

            local dp = distSq / maxDistSq

            local rootSP, rootVis = toScreen(cam, rp)
            if not rootVis then return end
            if abs(rootSP.X) > 3500 or abs(rootSP.Y) > 3500 then return end

            local depth = rootSP.Z
            if depth < 0.1 then return end
            local estimatedHeight = clamp((170 / depth) * fovFactor * 0.018, 4, 400)
            local height = estimatedHeight
            local width  = height * 0.5

            local dist = sqrt(distSq)
            local scaledThick = clamp(thick * (1 - clamp(dp, 0, 1) * 0.6), 1, thick)

            local color
            if useTeamC and p.Team and p.Team.TeamColor then
                color = p.Team.TeamColor.Color
            else
                local hp = hum.Health / hum.MaxHealth
                if hp > 0.5 then
                    color = Color3New(1-(hp-0.5)*2, 1, 0)
                else
                    color = Color3New(1, hp*2, 0)
                end
            end

            if showBox then
                local cx = rootSP.X
                local cy = rootSP.Y
                local x1 = cx - width*0.5
                local y1 = cy - height*0.5
                local x2 = cx + width*0.5
                local y2 = cy + height*0.5
                if x1>-2000 and x2<vpX+2000 and y1>-2000 and y2<vpY+2000 then
                    dl[1].From=Vector2New(x1,y1); dl[1].To=Vector2New(x2,y1); dl[1].Color=color; dl[1].Thickness=scaledThick; dl[1].Visible=true
                    dl[2].From=Vector2New(x2,y1); dl[2].To=Vector2New(x2,y2); dl[2].Color=color; dl[2].Thickness=scaledThick; dl[2].Visible=true
                    dl[3].From=Vector2New(x2,y2); dl[3].To=Vector2New(x1,y2); dl[3].Color=color; dl[3].Thickness=scaledThick; dl[3].Visible=true
                    dl[4].From=Vector2New(x1,y2); dl[4].To=Vector2New(x1,y1); dl[4].Color=color; dl[4].Thickness=scaledThick; dl[4].Visible=true
                end
            end

            -- ✅ CORRIGIDO: toScreen direto na cabeça — sem deslocamento em animações
            if showHead and dh and dp < 0.7 then
                local headSP, headVis = toScreen(cam, head.Position)
                if headVis then
                    local hx = camPos.X - head.Position.X
                    local hy = camPos.Y - head.Position.Y
                    local hz = camPos.Z - head.Position.Z
                    local camDist = sqrt(hx*hx + hy*hy + hz*hz)
                    if camDist < 0.1 then camDist = 0.1 end
                    dh.Position  = Vector2New(headSP.X, headSP.Y)
                    dh.Radius    = clamp((head.Size.X * 0.5 / camDist) * fovFactor, 2, 40)
                    dh.Thickness = scaledThick
                    dh.Color     = color
                    dh.Visible   = true
                end
            end

            if showSkel and dp < 0.5 then
                local bones  = cache.bones
                local maxIdx
                if cache.isR15 then
                    if     dp < 0.3 then maxIdx = math.min(15, #bones)
                    else                  maxIdx = 6
                    end
                else
                    maxIdx = math.min(6, #bones)
                end
                maxIdx = math.min(maxIdx, #bones)
                for i = 1, maxIdx do
                    local b    = bones[i]
                    local bone = ds[i]
                    if b and bone then
                        local sp0, on0 = toScreen(cam, b[1].Position)
                        local sp1, on1 = toScreen(cam, b[2].Position)
                        if on0 and on1 then
                            if abs(sp0.X)<3000 and abs(sp0.Y)<3000 and abs(sp1.X)<3000 and abs(sp1.Y)<3000 then
                                bone.Visible=true
                                bone.From=Vector2New(sp0.X, sp0.Y)
                                bone.To=Vector2New(sp1.X, sp1.Y)
                                bone.Color=color
                                bone.Thickness=scaledThick
                                bone.Transparency=1
                            end
                        end
                    end
                end
            end

            if (showName or showHp or showDist) and dp < 0.9 then
                local text = ""
                if showName then text = p.Name end
                if showHp then
                    text = text .. (showName and "\n" or "") .. floor(hum.Health) .. "/" .. floor(hum.MaxHealth) .. " HP"
                end
                if showDist then
                    text = text .. ((showName or showHp) and "\n" or "") .. floor(dist * 0.28) .. "m"
                end
                dt.Text     = text
                dt.Position = Vector2New(rootSP.X, rootSP.Y - height*0.5 - 14)
                dt.Color    = color
                dt.Visible  = true
            end
        end)
    end

    _lastDt   = tick() - frameStart
    _frameOver = _lastDt > 0.012
end

local _healthTick = 0
local function updateHealth()
    local now = tick()
    if now - _healthTick < config.healthUpdateRate then return end
    _healthTick = now
    if not config.on or not config.hp then return end
    for p, d in pairs(espObjects) do
        if not (p and p.Parent) then continue end
        if d.t and d.t.Visible then
            local tc = p.Character
            if tc then
                local hum = tc:FindFirstChildOfClass("Humanoid")
                if hum then
                    local cur = hum.Health; local mx = hum.MaxHealth
                    local cache = healthCache[p]
                    if not cache or cache.health~=cur or cache.maxHealth~=mx then
                        healthCache[p] = { health=cur, maxHealth=mx }
                        d.healthChanged = true
                    end
                end
            end
        end
    end
end

local function createModernGUI()
    local theme = Themes[config.currentTheme]
    local themeElements = {}

    local function updateThemeColors(newThemeName)
        local newTheme = Themes[newThemeName]
        if not newTheme then return end
        config.currentTheme = newThemeName
        local ti = TweenInfo.new(0.3, Enum.EasingStyle.Sine)
        for _, el in ipairs(themeElements) do
            pcall(function()
                local o = el.obj
                if     el.type=="frame"            then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Background}):Play()
                elseif el.type=="header"           then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Secondary}):Play()
                    if el.gradient then el.gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,newTheme.Accent),ColorSequenceKeypoint.new(1,newTheme.Secondary)}) end
                elseif el.type=="border"           then TweenService:Create(o,ti,{Color=newTheme.Accent}):Play()
                elseif el.type=="text"             then TweenService:Create(o,ti,{TextColor3=newTheme.Text}):Play()
                elseif el.type=="toggle_container" then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Secondary}):Play()
                elseif el.type=="toggle_button"    then TweenService:Create(o,ti,{BackgroundColor3=el.getValue() and newTheme.Success or newTheme.Border}):Play()
                elseif el.type=="toggle_indicator" then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Text}):Play()
                elseif el.type=="slider_bg"        then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Border}):Play()
                elseif el.type=="slider_fill"      then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Accent}):Play()
                elseif el.type=="page_button"      then TweenService:Create(o,ti,{BackgroundColor3=el.pageName==currentPage and newTheme.Accent or newTheme.Secondary,TextColor3=newTheme.Text}):Play()
                elseif el.type=="theme_card"       then
                    local isSel = el.themeName==newThemeName
                    TweenService:Create(el.border,ti,{Color=isSel and newTheme.Accent or el.themeColors.Border,Thickness=isSel and 3 or 1}):Play()
                elseif el.type=="save_button"      then
                    TweenService:Create(o,ti,{BackgroundColor3=newTheme.Accent}):Play()
                    if el.gradient then el.gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,newTheme.Accent),ColorSequenceKeypoint.new(1,Color3fromRGB(clamp(newTheme.Accent.R*255+30,0,255),clamp(newTheme.Accent.G*255+30,0,255),clamp(newTheme.Accent.B*255+30,0,255)))}) end
                    if el.glow then el.glow.ImageColor3=newTheme.Accent end
                elseif el.type=="reset_button"     then
                    TweenService:Create(o,ti,{BackgroundColor3=newTheme.Error}):Play()
                    if el.gradient then el.gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,newTheme.Error),ColorSequenceKeypoint.new(1,Color3fromRGB(clamp(newTheme.Error.R*255+30,0,255),clamp(newTheme.Error.G*255+30,0,255),clamp(newTheme.Error.B*255+30,0,255)))}) end
                    if el.glow then el.glow.ImageColor3=newTheme.Error end
                elseif el.type=="save_container"   then
                    TweenService:Create(o,ti,{BackgroundColor3=newTheme.Secondary}):Play()
                    if el.stroke then TweenService:Create(el.stroke,ti,{Color=newTheme.Accent}):Play() end
                elseif el.type=="minimize_button"  then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Accent}):Play()
                elseif el.type=="close_button"     then TweenService:Create(o,ti,{BackgroundColor3=newTheme.Error}):Play()
                end
            end)
        end
        saveConfig(frame)
    end

    local screenGui = instanceNew("ScreenGui")
    screenGui.Name = "ESP_Modern_"..math.random(10000,999999)
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = instanceNew("Frame")
    frame.Size = minimized and UDim2.new(0,300,0,35) or UDim2.new(0,300,0,450)
    frame.BackgroundColor3 = theme.Background
    frame.BackgroundTransparency = config.transparency
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = false
    if savedConfig and savedConfig.positionXScale then
        frame.Position = UDim2.new(savedConfig.positionXScale, savedConfig.positionXOffset or 0, savedConfig.positionYScale, savedConfig.positionYOffset or 0)
    else
        frame.Position = UDim2.new(0.02,0,0.25,0)
    end
    frame.Parent = screenGui
    table.insert(themeElements,{type="frame",obj=frame})

    instanceNew("UICorner",frame).CornerRadius=UDim.new(0,12)
    local border = instanceNew("UIStroke",frame); border.Color=theme.Accent; border.Thickness=2; border.Transparency=0.3
    table.insert(themeElements,{type="border",obj=border})

    local header = instanceNew("Frame")
    header.Size=UDim2.new(1,0,0,35); header.BackgroundColor3=theme.Secondary
    header.BackgroundTransparency=config.transparency; header.BorderSizePixel=0; header.Parent=frame
    instanceNew("UICorner",header).CornerRadius=UDim.new(0,12)
    local headerGradient=instanceNew("UIGradient",header)
    headerGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,theme.Accent),ColorSequenceKeypoint.new(1,theme.Secondary)})
    headerGradient.Rotation=45
    table.insert(themeElements,{type="header",obj=header,gradient=headerGradient})

    local draggingFrame=false; local dragStartPos, dragFrameStart
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 and not config.menuLocked then
            draggingFrame=true; dragStartPos=input.Position; dragFrameStart=frame.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 and draggingFrame then
            draggingFrame=false; saveConfig(frame)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingFrame and input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta=input.Position-dragStartPos
            frame.Position=UDim2.new(dragFrameStart.X.Scale,dragFrameStart.X.Offset+delta.X,dragFrameStart.Y.Scale,dragFrameStart.Y.Offset+delta.Y)
        end
    end)

    local title=instanceNew("TextLabel"); title.Size=UDim2.new(1,-110,1,0); title.Position=UDim2.new(0,12,0,0)
    title.BackgroundTransparency=1; title.Text="ESP BY GX7ツ"; title.TextColor3=theme.Text
    title.TextSize=16; title.Font=Enum.Font.GothamBold; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=header
    table.insert(themeElements,{type="text",obj=title})

    local lockButton=instanceNew("TextButton"); lockButton.Size=UDim2.new(0,28,0,28); lockButton.Position=UDim2.new(1,-100,0.5,-14)
    lockButton.BackgroundColor3=config.menuLocked and Color3fromRGB(0,200,100) or Color3fromRGB(0,150,255)
    lockButton.BackgroundTransparency=0.2; lockButton.BorderSizePixel=0
    lockButton.Text=config.menuLocked and "🔒" or "🔓"; lockButton.TextColor3=theme.Text; lockButton.TextSize=14; lockButton.Font=Enum.Font.GothamBold; lockButton.Parent=header
    instanceNew("UICorner",lockButton).CornerRadius=UDim.new(0,8)

    local minimizeButton=instanceNew("TextButton"); minimizeButton.Size=UDim2.new(0,28,0,28); minimizeButton.Position=UDim2.new(1,-65,0.5,-14)
    minimizeButton.BackgroundColor3=theme.Accent; minimizeButton.BackgroundTransparency=0.2; minimizeButton.BorderSizePixel=0
    minimizeButton.Text=minimized and "+" or "_"; minimizeButton.TextColor3=theme.Text; minimizeButton.TextSize=18; minimizeButton.Font=Enum.Font.GothamBold; minimizeButton.Parent=header
    table.insert(themeElements,{type="minimize_button",obj=minimizeButton})
    instanceNew("UICorner",minimizeButton).CornerRadius=UDim.new(0,8)

    local closeButton=instanceNew("TextButton"); closeButton.Size=UDim2.new(0,28,0,28); closeButton.Position=UDim2.new(1,-30,0.5,-14)
    closeButton.BackgroundColor3=theme.Error; closeButton.BackgroundTransparency=0.2; closeButton.BorderSizePixel=0
    closeButton.Text="X"; closeButton.TextColor3=theme.Text; closeButton.TextSize=16; closeButton.Font=Enum.Font.GothamBold; closeButton.Parent=header
    table.insert(themeElements,{type="close_button",obj=closeButton})
    instanceNew("UICorner",closeButton).CornerRadius=UDim.new(0,8)

    local navContainer=instanceNew("Frame"); navContainer.Size=UDim2.new(1,0,0,40); navContainer.Position=UDim2.new(0,0,0,45)
    navContainer.BackgroundTransparency=1; navContainer.Visible=not minimized; navContainer.Parent=frame
    local navLayout=instanceNew("UIListLayout",navContainer); navLayout.FillDirection=Enum.FillDirection.Horizontal
    navLayout.Padding=UDim.new(0,8); navLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment=Enum.VerticalAlignment.Center

    local pageButtons={}
    for _, pageName in ipairs({"Main","Settings","Themes"}) do
        local btn=instanceNew("TextButton"); btn.Size=UDim2.new(0,82,1,0)
        btn.BackgroundColor3=currentPage==pageName and theme.Accent or theme.Secondary
        btn.BackgroundTransparency=0.3; btn.BorderSizePixel=0; btn.Text=pageName
        btn.TextColor3=theme.Text; btn.TextSize=12; btn.Font=Enum.Font.GothamBold; btn.Parent=navContainer
        instanceNew("UICorner",btn).CornerRadius=UDim.new(0,8)
        table.insert(themeElements,{type="page_button",obj=btn,pageName=pageName})
        pageButtons[pageName]=btn
    end

    local contentFrame=instanceNew("Frame"); contentFrame.Size=UDim2.new(1,-20,1,-95); contentFrame.Position=UDim2.new(0,10,0,90)
    contentFrame.AnchorPoint=Vector2.new(0,0); contentFrame.BackgroundTransparency=1; contentFrame.Visible=not minimized; contentFrame.Parent=frame

    local function makeScrollPage(visible)
        local sf=instanceNew("ScrollingFrame"); sf.Size=UDim2.new(1,0,1,0); sf.BackgroundTransparency=1
        sf.BorderSizePixel=0; sf.ScrollBarThickness=4; sf.CanvasSize=UDim2.new(0,0,0,0)
        sf.AutomaticCanvasSize=Enum.AutomaticSize.Y; sf.Visible=visible; sf.Parent=contentFrame
        instanceNew("UIListLayout",sf).Padding=UDim.new(0,8)
        return sf
    end

    local mainPage     = makeScrollPage(currentPage=="Main")
    local settingsPage = makeScrollPage(currentPage=="Settings")
    local themesPage   = instanceNew("Frame"); themesPage.Size=UDim2.new(1,0,1,0)
    themesPage.BackgroundTransparency=1; themesPage.BorderSizePixel=0; themesPage.Visible=currentPage=="Themes"; themesPage.Parent=contentFrame

    local function createToggle(parent, text, defaultValue, callback)
        local container=instanceNew("Frame"); container.Size=UDim2.new(1,0,0,32)
        container.BackgroundColor3=theme.Secondary; container.BackgroundTransparency=0.5
        container.BorderSizePixel=0; container.Parent=parent
        table.insert(themeElements,{type="toggle_container",obj=container})
        instanceNew("UICorner",container).CornerRadius=UDim.new(0,8)
        local label=instanceNew("TextLabel"); label.Size=UDim2.new(1,-55,1,0); label.Position=UDim2.new(0,10,0,0)
        label.BackgroundTransparency=1; label.Text=text; label.TextColor3=theme.Text; label.TextSize=12
        label.Font=Enum.Font.Gotham; label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=container
        table.insert(themeElements,{type="text",obj=label})
        local value=defaultValue
        local toggle=instanceNew("TextButton"); toggle.Size=UDim2.new(0,45,0,22); toggle.Position=UDim2.new(1,-50,0.5,-11)
        toggle.BackgroundColor3=value and theme.Success or theme.Border; toggle.BackgroundTransparency=0.2
        toggle.BorderSizePixel=0; toggle.Text=""; toggle.Parent=container
        table.insert(themeElements,{type="toggle_button",obj=toggle,getValue=function() return value end})
        instanceNew("UICorner",toggle).CornerRadius=UDim.new(1,0)
        local indicator=instanceNew("Frame"); indicator.Size=UDim2.new(0,18,0,18)
        indicator.Position=value and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        indicator.BackgroundColor3=theme.Text; indicator.BorderSizePixel=0; indicator.Parent=toggle
        table.insert(themeElements,{type="toggle_indicator",obj=indicator})
        instanceNew("UICorner",indicator).CornerRadius=UDim.new(1,0)
        toggle.MouseButton1Click:Connect(function()
            value=not value
            local t=Themes[config.currentTheme]
            TweenService:Create(toggle,TweenInfo.new(0.2),{BackgroundColor3=value and t.Success or t.Border}):Play()
            TweenService:Create(indicator,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{Position=value and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play()
            callback(value)
        end)
    end

    local function createSlider(parent, text, min, max, defaultValue, callback)
        local container=instanceNew("Frame"); container.Size=UDim2.new(1,0,0,60)
        container.BackgroundColor3=theme.Secondary; container.BackgroundTransparency=0.5
        container.BorderSizePixel=0; container.Parent=parent
        table.insert(themeElements,{type="toggle_container",obj=container})
        instanceNew("UICorner",container).CornerRadius=UDim.new(0,8)
        local label=instanceNew("TextLabel"); label.Size=UDim2.new(1,-20,0,25); label.Position=UDim2.new(0,10,0,5)
        label.BackgroundTransparency=1; label.Text=text..": "..defaultValue; label.TextColor3=theme.Text
        label.TextSize=13; label.Font=Enum.Font.GothamBold; label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=container
        table.insert(themeElements,{type="text",obj=label})
        local sliderBg=instanceNew("Frame"); sliderBg.Size=UDim2.new(1,-20,0,8); sliderBg.Position=UDim2.new(0,10,1,-18)
        sliderBg.BackgroundColor3=theme.Border; sliderBg.BackgroundTransparency=0.3; sliderBg.BorderSizePixel=0; sliderBg.Parent=container
        table.insert(themeElements,{type="slider_bg",obj=sliderBg})
        instanceNew("UICorner",sliderBg).CornerRadius=UDim.new(1,0)
        local sliderFill=instanceNew("Frame"); sliderFill.Size=UDim2.new((defaultValue-min)/(max-min),0,1,0)
        sliderFill.BackgroundColor3=theme.Accent; sliderFill.BorderSizePixel=0; sliderFill.Parent=sliderBg
        table.insert(themeElements,{type="slider_fill",obj=sliderFill})
        instanceNew("UICorner",sliderFill).CornerRadius=UDim.new(1,0)
        local dragging=false
        sliderBg.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; draggingFrame=false end end)
        sliderBg.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local pct=clamp((input.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X,0,1)
                TweenService:Create(sliderFill,TweenInfo.new(0.1),{Size=UDim2.new(pct,0,1,0)}):Play()
                local val=floor(min+(max-min)*pct)
                label.Text=text..": "..val
                callback(val)
            end
        end)
    end

    local themeOrder={"Dark","Light","Midnight","Ocean","Forest","Sunset","Neon","Cyberpunk"}
    local cardW,cardH,cardPad,startX=128,82,8,8
    for idx, tName in ipairs(themeOrder) do
        local tc=Themes[tName]
        local col=(idx-1)%2; local row=math.floor((idx-1)/2)
        local card=instanceNew("TextButton"); card.Size=UDim2.new(0,cardW,0,cardH)
        card.Position=UDim2.new(0,startX+col*(cardW+cardPad),0,row*(cardH+cardPad))
        card.BackgroundColor3=tc.Background; card.BorderSizePixel=0; card.Text=""; card.AutoButtonColor=false; card.Parent=themesPage
        instanceNew("UICorner",card).CornerRadius=UDim.new(0,10)
        local cardBorder=instanceNew("UIStroke",card)
        cardBorder.Color=config.currentTheme==tName and theme.Accent or tc.Border
        cardBorder.Thickness=config.currentTheme==tName and 3 or 1
        table.insert(themeElements,{type="theme_card",border=cardBorder,themeName=tName,themeColors=tc})
        local nl=instanceNew("TextLabel",card); nl.Size=UDim2.new(1,0,0,26); nl.Position=UDim2.new(0,0,0,0)
        nl.BackgroundTransparency=1; nl.Text=tName; nl.TextColor3=tc.Text; nl.TextSize=12; nl.Font=Enum.Font.GothamBold
        local cp=instanceNew("Frame",card); cp.Size=UDim2.new(1,-12,0,36); cp.Position=UDim2.new(0,6,0,30)
        cp.BackgroundColor3=tc.Background; cp.BorderSizePixel=0
        instanceNew("UICorner",cp).CornerRadius=UDim.new(0,6)
        local pg=instanceNew("UIGradient",cp)
        pg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,tc.Background),ColorSequenceKeypoint.new(0.5,tc.Secondary),ColorSequenceKeypoint.new(1,tc.Accent)})
        pg.Rotation=90
        local cn=tName
        card.MouseButton1Click:Connect(function() updateThemeColors(cn) end)
    end

    createToggle(mainPage,"Enabled",     config.on,       function(v) config.on=v;       saveConfig(frame) end)
    createToggle(mainPage,"Box",         config.box,      function(v) config.box=v;      saveConfig(frame) end)
    createToggle(mainPage,"Skeleton",    config.skel,     function(v) config.skel=v;     saveConfig(frame) end)
    createToggle(mainPage,"Head Circle", config.head,     function(v) config.head=v;     saveConfig(frame) end)
    createToggle(mainPage,"Name",        config.name,     function(v) config.name=v;     saveConfig(frame) end)
    createToggle(mainPage,"Health",      config.hp,       function(v) config.hp=v;       saveConfig(frame) end)
    createToggle(mainPage,"Distance",    config.distance, function(v) config.distance=v; saveConfig(frame) end)
    createToggle(mainPage,"Team Check",  config.team,     function(v) config.team=v;     saveConfig(frame) end)
    createToggle(mainPage,"Team Colors", config.tcolor,   function(v) config.tcolor=v;   saveConfig(frame) end)

    createSlider(settingsPage,"Max Distance (m)",100,5000,floor(config.dist*0.28),function(v) config.dist=floor(v/0.28); saveConfig(frame) end)
    createSlider(settingsPage,"Thickness",1,5,config.thick,function(v)
        config.thick=v
        for _,pd in pairs(espObjects) do
            for _,l in pairs(pd.l or {}) do l.Thickness=v end
            for _,l in pairs(pd.s or {}) do l.Thickness=v end
            if pd.h then pd.h.Thickness=v end
        end
        saveConfig(frame)
    end)
    createSlider(settingsPage,"Transparency",0,100,config.transparency*100,function(v)
        config.transparency=v/100
        frame.BackgroundTransparency=config.transparency
        header.BackgroundTransparency=config.transparency
        saveConfig(frame)
    end)
    createToggle(settingsPage,"Auto Execute",config.persist,function(v)
        config.persist=v
        if v then
            pcall(function()
                queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/gx7-team/gx7777/main/gx7777.lua",true))()')
            end)
        end
        saveConfig(frame)
    end)

    local saveContainer=instanceNew("Frame"); saveContainer.Size=UDim2.new(1,0,0,135)
    saveContainer.BackgroundColor3=theme.Secondary; saveContainer.BackgroundTransparency=0.5
    saveContainer.BorderSizePixel=0; saveContainer.Parent=settingsPage
    instanceNew("UICorner",saveContainer).CornerRadius=UDim.new(0,8)
    local saveStroke=instanceNew("UIStroke",saveContainer); saveStroke.Color=theme.Accent; saveStroke.Thickness=1; saveStroke.Transparency=0.6
    table.insert(themeElements,{type="save_container",obj=saveContainer,stroke=saveStroke})

    local saveButton=instanceNew("TextButton"); saveButton.Size=UDim2.new(1,-20,0,50); saveButton.Position=UDim2.new(0,10,0,8)
    saveButton.BackgroundColor3=theme.Accent; saveButton.BackgroundTransparency=0.1; saveButton.BorderSizePixel=0
    saveButton.AutoButtonColor=false; saveButton.Text=""; saveButton.Parent=saveContainer
    instanceNew("UICorner",saveButton).CornerRadius=UDim.new(0,10)
    local saveGradient=instanceNew("UIGradient",saveButton)
    saveGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,theme.Accent),ColorSequenceKeypoint.new(1,Color3fromRGB(clamp(theme.Accent.R*255+30,0,255),clamp(theme.Accent.G*255+30,0,255),clamp(theme.Accent.B*255+30,0,255)))}); saveGradient.Rotation=45
    local saveGlow=instanceNew("ImageLabel",saveButton); saveGlow.Size=UDim2.new(1,30,1,30); saveGlow.Position=UDim2.new(0.5,-15,0.5,-15)
    saveGlow.AnchorPoint=Vector2.new(0.5,0.5); saveGlow.BackgroundTransparency=1; saveGlow.Image="rbxassetid://4996891970"
    saveGlow.ImageColor3=theme.Accent; saveGlow.ImageTransparency=0.8; saveGlow.ZIndex=0
    local saveTL=instanceNew("TextLabel",saveButton); saveTL.Size=UDim2.new(1,0,1,0); saveTL.BackgroundTransparency=1
    saveTL.Text="💾 SAVE CONFIG"; saveTL.TextColor3=Color3New(1,1,1); saveTL.TextStrokeColor3=Color3New(0,0,0)
    saveTL.TextStrokeTransparency=0; saveTL.TextSize=18; saveTL.Font=Enum.Font.GothamBold; saveTL.ZIndex=10
    table.insert(themeElements,{type="save_button",obj=saveButton,gradient=saveGradient,glow=saveGlow})
    saveButton.MouseButton1Click:Connect(function()
        saveConfig(frame); saveTL.Text="✅ SAVED!"
        TweenService:Create(saveButton,TweenInfo.new(0.3),{BackgroundColor3=Themes[config.currentTheme].Success}):Play()
        task.delay(1.5,function() saveTL.Text="💾 SAVE CONFIG"; TweenService:Create(saveButton,TweenInfo.new(0.3),{BackgroundColor3=Themes[config.currentTheme].Accent}):Play() end)
    end)
    saveButton.MouseEnter:Connect(function() TweenService:Create(saveButton,TweenInfo.new(0.2),{Size=UDim2.new(1,-17,0,53)}):Play() end)
    saveButton.MouseLeave:Connect(function() TweenService:Create(saveButton,TweenInfo.new(0.2),{Size=UDim2.new(1,-20,0,50)}):Play() end)

    local resetButton=instanceNew("TextButton"); resetButton.Size=UDim2.new(1,-20,0,50); resetButton.Position=UDim2.new(0,10,0,77)
    resetButton.BackgroundColor3=theme.Error; resetButton.BackgroundTransparency=0.1; resetButton.BorderSizePixel=0
    resetButton.AutoButtonColor=false; resetButton.Text=""; resetButton.Parent=saveContainer
    instanceNew("UICorner",resetButton).CornerRadius=UDim.new(0,10)
    local resetGradient=instanceNew("UIGradient",resetButton)
    resetGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,theme.Error),ColorSequenceKeypoint.new(1,Color3fromRGB(clamp(theme.Error.R*255+30,0,255),clamp(theme.Error.G*255+30,0,255),clamp(theme.Error.B*255+30,0,255)))}); resetGradient.Rotation=45
    local resetGlow=instanceNew("ImageLabel",resetButton); resetGlow.Size=UDim2.new(1,30,1,30); resetGlow.Position=UDim2.new(0.5,-15,0.5,-15)
    resetGlow.AnchorPoint=Vector2.new(0.5,0.5); resetGlow.BackgroundTransparency=1; resetGlow.Image="rbxassetid://4996891970"
    resetGlow.ImageColor3=theme.Error; resetGlow.ImageTransparency=0.8; resetGlow.ZIndex=0
    local resetTL=instanceNew("TextLabel",resetButton); resetTL.Size=UDim2.new(1,0,1,0); resetTL.BackgroundTransparency=1
    resetTL.Text="🔄 RESET FACTORY"; resetTL.TextColor3=Color3New(1,1,1); resetTL.TextStrokeColor3=Color3New(0,0,0)
    resetTL.TextStrokeTransparency=0; resetTL.TextSize=18; resetTL.Font=Enum.Font.GothamBold; resetTL.ZIndex=10
    table.insert(themeElements,{type="reset_button",obj=resetButton,gradient=resetGradient,glow=resetGlow})

    resetButton.MouseButton1Click:Connect(function()
        resetTL.Text="⏳ RESETANDO..."
        TweenService:Create(resetButton,TweenInfo.new(0.3),{BackgroundColor3=Themes["Dark"].Warning}):Play()
        pcall(function() if isfile(configFile) then delfile(configFile) end end)
        for k,v in pairs(DEFAULT_CONFIG) do config[k]=v end
        minimized=false; currentPage="Main"
        for _, obj in pairs(espObjects) do
            for _,l in pairs(obj.l or {}) do pcall(function() l:Remove() end) end
            for _,l in pairs(obj.s or {}) do pcall(function() l:Remove() end) end
            if obj.h then pcall(function() obj.h:Remove() end) end
            if obj.t then pcall(function() obj.t:Remove() end) end
        end
        espObjects={}; healthCache={}; getgenv().ESPObjs=nil
        if env.Connections.ESPConnection then env.Connections.ESPConnection:Disconnect() end
        if env.Connections.ESPHealthConnection then env.Connections.ESPHealthConnection:Disconnect() end
        task.delay(0.5, function()
            resetTL.Text="✅ RESETADO!"
            TweenService:Create(resetButton,TweenInfo.new(0.3),{BackgroundColor3=Themes["Dark"].Success}):Play()
            task.delay(1, function()
                pcall(function()
                    for _,g in ipairs(CoreGui:GetChildren()) do
                        if g:IsA("ScreenGui") and (g.Name:find("ESP") or g.Name:find("Panel")) then g:Destroy() end
                    end
                end)
                getgenv().ESPLoaded=nil; getgenv().ESPObjs=nil
                pcall(function() if isfile(configFile) then delfile(configFile) end end)
                task.wait(0.3)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/gx7-team/gx7777/main/gx7777.lua",true))()
            end)
        end)
    end)
    resetButton.MouseEnter:Connect(function() TweenService:Create(resetButton,TweenInfo.new(0.2),{Size=UDim2.new(1,-17,0,53)}):Play() end)
    resetButton.MouseLeave:Connect(function() TweenService:Create(resetButton,TweenInfo.new(0.2),{Size=UDim2.new(1,-20,0,50)}):Play() end)

    lockButton.MouseButton1Click:Connect(function()
        config.menuLocked=not config.menuLocked
        TweenService:Create(lockButton,TweenInfo.new(0.2),{BackgroundColor3=config.menuLocked and Color3fromRGB(0,200,100) or Color3fromRGB(0,150,255)}):Play()
        lockButton.Text=config.menuLocked and "🔒" or "🔓"
        saveConfig(frame)
    end)
    minimizeButton.MouseButton1Click:Connect(function()
        minimized=not minimized
        navContainer.Visible=not minimized; contentFrame.Visible=not minimized
        TweenService:Create(frame,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{Size=minimized and UDim2.new(0,300,0,35) or UDim2.new(0,300,0,450)}):Play()
        minimizeButton.Text=minimized and "+" or "_"
        saveConfig(frame)
    end)
    closeButton.MouseButton1Click:Connect(function() saveConfig(frame); cleanup() end)

    for pageName, btn in pairs(pageButtons) do
        btn.MouseButton1Click:Connect(function()
            currentPage=pageName
            mainPage.Visible=pageName=="Main"; settingsPage.Visible=pageName=="Settings"; themesPage.Visible=pageName=="Themes"
            local t=Themes[config.currentTheme]
            for n,b in pairs(pageButtons) do
                TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=n==pageName and t.Accent or t.Secondary}):Play()
            end
        end)
    end

    screenGui.Parent = CoreGui
    return frame
end

for _, p in pairs(Players:GetPlayers()) do
    task.spawn(function() if p and p.Parent then createESP(p) end end)
end
Players.PlayerAdded:Connect(function(p)
    task.delay(0.05, function() if p and p.Parent then createESP(p) end end)
end)
Players.PlayerRemoving:Connect(removeESP)

env.Connections.ESPConnection       = RunService.RenderStepped:Connect(updateESP)
env.Connections.ESPHealthConnection = RunService.Heartbeat:Connect(updateHealth)

localPlayer.CharacterAdded:Connect(function()
    task.delay(0.5, function()
        for p in pairs(espObjects) do
            removeESP(p)
            task.delay(0.1, function() createESP(p) end)
        end
    end)
end)

if config.persist then
    pcall(function()
        queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/gx7-team/gx7777/main/gx7777.lua", true))()')
    end)
end

createModernGUI()
print("✅ ESP GX7 carregado com GUI completa!")