-- NOVA CHAT v6 - RABEE OWNER EDITION
-- LocalScript واحد - حطه في StarterPlayer > StarterPlayerScripts
-- لازم تحط NOVA_Server.lua في ServerScriptService

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("NOVAChat")
if old then old:Destroy() end

local GOLD = Color3.fromRGB(212, 175, 55)
local BLACK = Color3.fromRGB(13, 13, 16)
local PANEL = Color3.fromRGB(20, 20, 24)
local TEXT = Color3.fromRGB(245, 242, 255)
local MUTED = Color3.fromRGB(165, 158, 185)
local DARK_BUTTON = Color3.fromRGB(38, 35, 45)

local accent = GOLD
local rgbEnabled = false
local rgbNameEnabled = false
local currentTab = "عام"
local displayName = player.DisplayName
local opened = true
local busy = false
local hue = 0
local noticeId = 0
local activeBubble

-- جديد
local remote
local myRole = "member"
local onlineUsers = {}
local convs = {}
local convOrder = 0
local activeConv
local selected = {}
local stopping = false
local globalConns = {}
local fadeA, fadeB

local function make(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 9)
    }, obj)
end

local function outline(obj, color, thickness)
    return make("UIStroke", {
        Color = color or accent,
        Thickness = thickness or 1
    }, obj)
end

local function tween(obj, duration, props)
    local animation = TweenService:Create(
        obj,
        TweenInfo.new(duration, Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out),
        props
    )
    animation:Play()
    return animation
end

local gui = make("ScreenGui", {
    Name = "NOVAChat",
    ResetOnSpawn = false,
    DisplayOrder = 50
}, playerGui)

-- Main window
local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 18, 0.5, 0),
    Size = UDim2.fromOffset(365, 430),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    Active = true
}, gui)

round(main, 15)
local mainStroke = outline(main, GOLD, 2)

-- Header
local header = make("TextLabel", {
    Name = "Header",
    Position = UDim2.fromOffset(12, 19),
    Size = UDim2.new(1, -105, 0, 27),
    BackgroundTransparency = 1,
    Text = "NOVA CHAT",
    TextColor3 = GOLD,
    Font = Enum.Font.GothamBold,
    TextSize = 21,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = true,
    ZIndex = 5
}, main)

-- Owner name above NOVA CHAT
local ownerLabel = make("TextLabel", {
    Name = "OwnerLabel",
    Position = UDim2.fromOffset(13, 3),
    Size = UDim2.new(1, -110, 0, 16),
    BackgroundTransparency = 1,
    Text = "Rabee1258 | THE OWNER",
    TextColor3 = GOLD,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
}, main)

local closeButton = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 8),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Color3.fromRGB(68, 40, 35),
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = TEXT,
    Font = Enum.Font.GothamBold,
    TextSize = 23,
    ZIndex = 5
}, main)
round(closeButton, 9)

local settingsButton = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -47, 0, 8),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = DARK_BUTTON,
    BorderSizePixel = 0,
    Text = "⚙",
    TextColor3 = GOLD,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    ZIndex = 5
}, main)
round(settingsButton, 9)

-- Drag main window from the top header
local draggingMain = false
local mainDragStart
local mainStartPosition
local dragInput

local function updateMainDrag(inputObject)
    if not draggingMain or not mainDragStart then return end

    local delta = inputObject.Position - mainDragStart
    main.Position = UDim2.new(
        mainStartPosition.X.Scale,
        mainStartPosition.X.Offset + delta.X,
        mainStartPosition.Y.Scale,
        mainStartPosition.Y.Offset + delta.Y
    )
end

header.InputBegan:Connect(function(obj)
    if obj.UserInputType == Enum.UserInputType.MouseButton1
        or obj.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        mainDragStart = obj.Position
        mainStartPosition = main.Position

        obj.Changed:Connect(function()
            if obj.UserInputState == Enum.UserInputState.End then
                draggingMain = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(obj)
    if obj.UserInputType == Enum.UserInputType.MouseMovement
        or obj.UserInputType == Enum.UserInputType.Touch then
        dragInput = obj
    end
end)

table.insert(globalConns, UserInputService.InputChanged:Connect(function(obj)
    if draggingMain and (
        obj.UserInputType == Enum.UserInputType.MouseMovement
        or obj == dragInput
    ) then
        updateMainDrag(obj)
    end
end))

-- Tabs
local publicTab = make("TextButton", {
    Position = UDim2.fromOffset(10, 50),
    Size = UDim2.new(0.5, -14, 0, 36),
    BackgroundColor3 = GOLD,
    BorderSizePixel = 0,
    Text = "العام",
    TextColor3 = TEXT,
    Font = Enum.Font.GothamBold,
    TextSize = 15
}, main)
round(publicTab, 9)

local privateTab = make("TextButton", {
    Position = UDim2.new(0.5, 4, 0, 50),
    Size = UDim2.new(0.5, -14, 0, 36),
    BackgroundColor3 = DARK_BUTTON,
    BorderSizePixel = 0,
    Text = "الخاص",
    TextColor3 = TEXT,
    Font = Enum.Font.GothamBold,
    TextSize = 15
}, main)
round(privateTab, 9)

-- Message lists
local function createMessageList(name, isPrivate)
    local list = make("ScrollingFrame", {
        Name = name,
        Position = UDim2.fromOffset(10, isPrivate and 130 or 96),
        Size = UDim2.new(1, -20, 1, isPrivate and -199 or -165),
        BackgroundColor3 = BLACK,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = GOLD,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, main)
    round(list, 10)

    make("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    }, list)

    make("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    return list
end

local publicMessages = createMessageList("PublicMessages", false)
publicMessages.Visible = true

-- Private: شريط المحادثات + زر +
local convBar = make("ScrollingFrame", {
    Name = "ConvBar",
    Position = UDim2.fromOffset(10, 96),
    Size = UDim2.new(1, -20, 0, 30),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    Visible = false
}, main)
round(convBar, 8)

make("UIPadding", {
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4)
}, convBar)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center
}, convBar)

local plusButton = make("TextButton", {
    Size = UDim2.fromOffset(32, 26),
    BackgroundColor3 = DARK_BUTTON,
    BorderSizePixel = 0,
    Text = "+",
    TextColor3 = GOLD,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    LayoutOrder = 0
}, convBar)
round(plusButton, 8)

local privateHint = make("TextLabel", {
    Position = UDim2.fromOffset(10, 130),
    Size = UDim2.new(1, -20, 1, -199),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
    Text = "اضغط + لبدء محادثة خاصة مع لاعب أو مجموعة",
    TextColor3 = MUTED,
    TextWrapped = true,
    Font = Enum.Font.Gotham,
    TextSize = 14,
    Visible = false
}, main)
round(privateHint, 10)

-- اختيار لاعبين للمحادثة الخاصة
local picker = make("Frame", {
    Position = UDim2.fromOffset(10, 130),
    Size = UDim2.new(1, -20, 1, -199),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 20
}, main)
round(picker, 10)
outline(picker, GOLD, 1)

local pickerTitle = make("TextLabel", {
    Position = UDim2.fromOffset(8, 3),
    Size = UDim2.new(1, -16, 0, 24),
    BackgroundTransparency = 1,
    Text = "اختر لاعب أو أكثر لعمل مجموعة",
    TextColor3 = TEXT,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 21
}, picker)

local pickerList = make("ScrollingFrame", {
    Position = UDim2.fromOffset(6, 30),
    Size = UDim2.new(1, -12, 1, -74),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 21
}, picker)
round(pickerList, 8)

make("UIPadding", {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4)
}, pickerList)

make("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, pickerList)

local pickerEmpty = make("TextLabel", {
    Position = UDim2.fromOffset(10, 34),
    Size = UDim2.new(1, -20, 0, 40),
    BackgroundTransparency = 1,
    Text = "ما في لاعبين ثانيين مشغلين السكربت",
    TextColor3 = MUTED,
    TextWrapped = true,
    Font = Enum.Font.Gotham,
    TextSize = 13,
    Visible = false,
    ZIndex = 22
}, picker)

local pickerStart = make("TextButton", {
    Position = UDim2.new(0, 6, 1, -38),
    Size = UDim2.new(1, -12, 0, 32),
    BackgroundColor3 = GOLD,
    BorderSizePixel = 0,
    Text = "ابدأ المحادثة",
    TextColor3 = BLACK,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    ZIndex = 21
}, picker)
round(pickerStart, 7)

local function makeKey(ids)
    local copy = table.clone(ids)
    table.sort(copy)
    return table.concat(copy, ",")
end

local function short(s, n)
    local len = utf8.len(s)
    if len and len > n then
        return s:sub(1, utf8.offset(s, n + 1) - 1) .. "…"
    end
    return s
end

local function convTitle(ids)
    local names = {}
    for _, id in ipairs(ids) do
        if id ~= player.UserId then
            local n = onlineUsers[id]
            if not n then
                local p = Players:GetPlayerByUserId(id)
                n = p and p.DisplayName or tostring(id)
            end
            table.insert(names, n)
        end
    end
    local title = table.concat(names, "، ")
    if #ids > 2 then title = "👥 " .. title end
    return title
end

local function refreshConvUI()
    local onPrivate = currentTab == "خاص"
    convBar.Visible = onPrivate
    privateHint.Visible = onPrivate and activeConv == nil
    for key, conv in pairs(convs) do
        local isActive = activeConv == key
        conv.list.Visible = onPrivate and isActive
        conv.chip.BackgroundColor3 = isActive and accent or DARK_BUTTON
        conv.chip.TextColor3 = isActive and BLACK or TEXT
    end
    plusButton.TextColor3 = accent
    pickerStart.BackgroundColor3 = accent
end

local function showConversation(key)
    activeConv = key
    picker.Visible = false
    refreshConvUI()
end

local function getConv(key, ids)
    if convs[key] then return convs[key] end
    convOrder += 1

    local list = createMessageList("Conv" .. convOrder, true)
    local chip = make("TextButton", {
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = DARK_BUTTON,
        BorderSizePixel = 0,
        Text = short(convTitle(ids), 16),
        TextColor3 = TEXT,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        LayoutOrder = convOrder
    }, convBar)
    round(chip, 8)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, chip)
    chip.Activated:Connect(function()
        showConversation(key)
    end)

    convs[key] = { ids = ids, list = list, chip = chip }
    return convs[key]
end

local function rebuildPicker()
    for _, item in ipairs(pickerList:GetChildren()) do
        if item:IsA("TextButton") then item:Destroy() end
    end

    for id in pairs(selected) do
        if not onlineUsers[id] then selected[id] = nil end
    end

    local entries = {}
    for id, name in pairs(onlineUsers) do
        if id ~= player.UserId then
            table.insert(entries, { id = id, name = name })
        end
    end
    table.sort(entries, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    pickerEmpty.Visible = #entries == 0

    for i, e in ipairs(entries) do
        local on = selected[e.id] == true
        local button = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = on and accent or DARK_BUTTON,
            BorderSizePixel = 0,
            Text = (on and "✓ " or "") .. e.name,
            TextColor3 = on and BLACK or TEXT,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            LayoutOrder = i,
            ZIndex = 22
        }, pickerList)
        round(button, 7)
        button.Activated:Connect(function()
            selected[e.id] = not selected[e.id] or nil
            rebuildPicker()
        end)
    end
end

local function setUsers(list)
    onlineUsers = {}
    for _, e in ipairs(list or {}) do
        onlineUsers[e.id] = e.name
    end
    if picker.Visible then rebuildPicker() end
end

-- Notifications (للرسايل فقط، وتختفي بسلاسة)
local notification = make("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, -55),
    Size = UDim2.fromOffset(245, 45),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = TEXT,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextWrapped = true,
    Visible = true,
    ZIndex = 30
}, gui)
round(notification, 10)
local notificationStroke = outline(notification, GOLD, 1)

local function notify(message)
    noticeId += 1
    local id = noticeId

    if fadeA then fadeA:Cancel() end
    if fadeB then fadeB:Cancel() end

    notification.Text = message
    notification.BackgroundTransparency = 0
    notification.TextTransparency = 0
    notificationStroke.Transparency = 0
    notification.Position = UDim2.new(1, -12, 0, -55)

    tween(notification, 0.3, {
        Position = UDim2.new(1, -12, 0, 12)
    })

    task.delay(2.8, function()
        if id == noticeId and notification.Parent then
            fadeA = tween(notification, 0.5, {
                BackgroundTransparency = 1,
                TextTransparency = 1
            })
            fadeB = tween(notificationStroke, 0.5, { Transparency = 1 })
        end
    end)

    task.delay(3.4, function()
        if id == noticeId and notification.Parent then
            notification.Position = UDim2.new(1, -12, 0, -55)
        end
    end)
end

-- Message rows
local function addMessage(list, name, message, useRGB)
    local row = make("Frame", {
        BackgroundColor3 = Color3.fromRGB(35, 31, 42),
        BackgroundTransparency = 0.05,
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, list)
    round(row, 8)

    make("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8)
    }, row)

    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, row)

    local nameLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 20),
        Text = name .. ":",
        TextColor3 = GOLD,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
        LayoutOrder = 1
    }, row)

    make("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 20),
        Text = message,
        TextColor3 = TEXT,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2
    }, row)

    if useRGB then
        task.spawn(function()
            local localHue = math.random()
            while row.Parent do
                if rgbEnabled and rgbNameEnabled then
                    localHue = (localHue + 0.012) % 1
                    nameLabel.TextColor3 =
                        Color3.fromHSV(localHue, 0.75, 1)
                else
                    nameLabel.TextColor3 = GOLD
                end
                task.wait(0.04)
            end
        end)
    end

    task.defer(function()
        if list.Parent then
            list.CanvasPosition = Vector2.new(
                0, math.max(0, list.AbsoluteCanvasSize.Y)
            )
        end
    end)

    return row
end

local function clearList(list)
    for _, item in ipairs(list:GetChildren()) do
        if item:IsA("Frame") or item:IsA("TextLabel") then
            item:Destroy()
        end
    end
end

-- رسايل النظام (بدل الإشعارات القديمة)
local function sysMsg(text)
    if currentTab == "عام" then
        addMessage(publicMessages, "النظام", text, false)
    elseif activeConv and convs[activeConv] then
        addMessage(convs[activeConv].list, "النظام", text, false)
    else
        notify(text)
    end
end

-- Local speech bubble
local function showLocalBubble(message)
    if activeBubble then
        activeBubble:Destroy()
        activeBubble = nil
    end

    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return end

    local bubble = make("BillboardGui", {
        Name = "NOVA_LocalBubble",
        Adornee = head,
        Size = UDim2.fromOffset(210, 62),
        StudsOffset = Vector3.new(0, 3, 0),
        AlwaysOnTop = true,
        MaxDistance = 45
    }, gui)
    activeBubble = bubble

    local label = make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = PANEL,
        BackgroundTransparency = 0.05,
        Text = message,
        TextColor3 = TEXT,
        TextWrapped = true,
        TextSize = 14,
        Font = Enum.Font.GothamBold
    }, bubble)
    round(label, 12)
    outline(label, accent, 1)

    task.delay(4, function()
        if bubble.Parent then bubble:Destroy() end
    end)
end

-- Input
local input = make("TextBox", {
    Name = "MessageInput",
    Position = UDim2.new(0, 10, 1, -54),
    Size = UDim2.new(1, -145, 0, 42),
    BackgroundColor3 = DARK_BUTTON,
    BorderSizePixel = 0,
    PlaceholderText = "اكتب رسالة أو /help",
    PlaceholderColor3 = MUTED,
    Text = "",
    TextColor3 = TEXT,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    TextSize = 15
}, main)
round(input, 9)

local stickerButton = make("TextButton", {
    Position = UDim2.new(1, -128, 1, -54),
    Size = UDim2.fromOffset(68, 42),
    BackgroundColor3 = DARK_BUTTON,
    BorderSizePixel = 0,
    Text = "ملصقات",
    TextColor3 = TEXT,
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, main)
round(stickerButton, 9)

local sendButton = make("TextButton", {
    Position = UDim2.new(1, -48, 1, -54),
    Size = UDim2.fromOffset(38, 42),
    BackgroundColor3 = GOLD,
    BorderSizePixel = 0,
    Text = "➤",
    TextColor3 = BLACK,
    TextSize = 20,
    Font = Enum.Font.GothamBold
}, main)
round(sendButton, 9)

-- Stickers
local stickerPanel = make("Frame", {
    Position = UDim2.new(1, -10, 1, -105),
    AnchorPoint = Vector2.new(1, 1),
    Size = UDim2.fromOffset(230, 148),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10
}, main)
round(stickerPanel, 10)
outline(stickerPanel, GOLD, 1)

make("TextLabel", {
    Position = UDim2.fromOffset(8, 4),
    Size = UDim2.new(1, -16, 0, 24),
    BackgroundTransparency = 1,
    Text = "ملصقات الصور",
    TextColor3 = TEXT,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    ZIndex = 11
}, stickerPanel)

local stickerGrid = make("Frame", {
    Position = UDim2.fromOffset(7, 31),
    Size = UDim2.new(1, -14, 1, -38),
    BackgroundTransparency = 1,
    ZIndex = 11
}, stickerPanel)

make("UIGridLayout", {
    CellSize = UDim2.fromOffset(62, 49),
    CellPadding = UDim2.fromOffset(6, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, stickerGrid)

for i = 1, 6 do
    local sticker = make("TextButton", {
        Name = "Sticker" .. i,
        BackgroundColor3 = DARK_BUTTON,
        BorderSizePixel = 0,
        Text = "ملصق " .. i,
        TextColor3 = GOLD,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        LayoutOrder = i,
        ZIndex = 12
    }, stickerGrid)
    round(sticker, 7)
    sticker.Activated:Connect(function()
        sysMsg("أضف صورة ملصق معتمدة لهذا الزر")
    end)
end

-- Settings panel
local settingsPanel = make("Frame", {
    Position = UDim2.new(0, 12, 0, 54),
    Size = UDim2.fromOffset(250, 197),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 40
}, gui)
round(settingsPanel, 12)
outline(settingsPanel, GOLD, 2)

make("TextLabel", {
    Position = UDim2.fromOffset(10, 5),
    Size = UDim2.new(1, -20, 0, 25),
    BackgroundTransparency = 1,
    Text = "إعدادات NOVA",
    TextColor3 = GOLD,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    ZIndex = 41
}, settingsPanel)

local nameInput = make("TextBox", {
    Position = UDim2.fromOffset(10, 36),
    Size = UDim2.new(1, -20, 0, 34),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
    PlaceholderText = "اسم العرض",
    Text = displayName,
    TextColor3 = TEXT,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    TextSize = 14,
    ZIndex = 41
}, settingsPanel)
round(nameInput, 7)

local function settingButton(text, y)
    local button = make("TextButton", {
        Position = UDim2.fromOffset(10, y),
        Size = UDim2.new(1, -20, 0, 32),
        BackgroundColor3 = GOLD,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = BLACK,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 41
    }, settingsPanel)
    round(button, 7)
    return button
end

local saveName = settingButton("حفظ اسم العرض", 77)
local rgbButton = settingButton("RGB: OFF", 115)
local serverButton = settingButton("إيقاف السكربت", 153)

-- Floating toggle
local toggle = make("TextButton", {
    Name = "ToggleChat",
    Position = UDim2.new(0, 18, 0.76, 0),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = GOLD,
    BorderSizePixel = 0,
    Text = "N",
    TextColor3 = BLACK,
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    Visible = false
}, gui)
round(toggle, 18)
outline(toggle, GOLD, 2)

-- Theme
local function applyTheme()
    accent = rgbEnabled and Color3.fromHSV(hue, 0.8, 1) or GOLD

    mainStroke.Color = accent
    header.TextColor3 = accent
    ownerLabel.TextColor3 = accent
    toggle.BackgroundColor3 = accent
    notificationStroke.Color = accent

    rgbButton.Text = rgbEnabled and "RGB: ON" or "RGB: OFF"

    rgbButton.BackgroundColor3 = accent
    saveName.BackgroundColor3 = accent
    serverButton.BackgroundColor3 = accent
    sendButton.BackgroundColor3 = accent
    stickerButton.TextColor3 = accent
    settingsButton.TextColor3 = accent
    publicTab.BackgroundColor3 =
        currentTab == "عام" and accent or DARK_BUTTON
    privateTab.BackgroundColor3 =
        currentTab == "خاص" and accent or DARK_BUTTON
    refreshConvUI()
end

saveName.Activated:Connect(function()
    local value = nameInput.Text:match("^%s*(.-)%s*$")
    if not value or value == "" then
        sysMsg("اكتب اسمًا أولًا")
        return
    end
    displayName = value:sub(1, 24)
    sysMsg("تغير الاسم داخل واجهة NOVA فقط")
end)

rgbButton.Activated:Connect(function()
    rgbEnabled = not rgbEnabled
    applyTheme()
    sysMsg(rgbEnabled and "تم تشغيل RGB للواجهة 🌈"
        or "رجع الوضع الأسود والذهبي 🖤")
end)

-- إيقاف السكربت نهائيًا
serverButton.Activated:Connect(function()
    if stopping then return end
    stopping = true
    settingsPanel.Visible = false
    main.Visible = false
    toggle.Visible = false

    if remote then
        pcall(function() remote:FireServer("Leave") end)
    end

    notify("وداعا نراك مجددا 👋")

    task.delay(3.5, function()
        for _, c in ipairs(globalConns) do
            c:Disconnect()
        end
        gui:Destroy()
    end)
end)

settingsButton.Activated:Connect(function()
    settingsPanel.Visible = not settingsPanel.Visible
    if settingsPanel.Visible then
        stickerPanel.Visible = false
    end
end)

stickerButton.Activated:Connect(function()
    stickerPanel.Visible = not stickerPanel.Visible
    if stickerPanel.Visible then
        settingsPanel.Visible = false
    end
end)

-- Private: فتح اختيار اللاعبين
local function openPicker()
    selected = {}
    pickerTitle.Text = "اختر لاعب أو أكثر لعمل مجموعة"
    rebuildPicker()
    picker.Visible = true
    settingsPanel.Visible = false
    stickerPanel.Visible = false
end

plusButton.Activated:Connect(function()
    if picker.Visible then
        picker.Visible = false
    else
        openPicker()
    end
end)

pickerStart.Activated:Connect(function()
    local ids = { player.UserId }
    for id in pairs(selected) do
        table.insert(ids, id)
    end
    if #ids < 2 then
        pickerTitle.Text = "اختر لاعب واحد على الأقل"
        return
    end
    table.sort(ids)
    local key = makeKey(ids)
    getConv(key, ids)
    showConversation(key)
end)

-- Tab switching
local function selectTab(tab)
    currentTab = tab
    publicMessages.Visible = (tab == "عام")
    settingsPanel.Visible = false
    stickerPanel.Visible = false
    picker.Visible = false
    applyTheme()
end

publicTab.Activated:Connect(function()
    selectTab("عام")
end)

privateTab.Activated:Connect(function()
    selectTab("خاص")
end)

-- Network (عن طريق سكربت السيرفر - الرسايل توصل بس لمشغلين السكربت)
local function onServerEvent(kind, a, b, c, d)
    if kind == "Hello" then
        myRole = a
        setUsers(b)

    elseif kind == "Users" then
        setUsers(a)

    elseif kind == "Role" then
        myRole = a

    elseif kind == "Joined" then
        addMessage(publicMessages, "NOVA", a .. " شغّل السكربت ✅", false)

    elseif kind == "Left" then
        addMessage(publicMessages, "NOVA", a .. " طفّى السكربت 👋", false)

    elseif kind == "Public" then
        addMessage(publicMessages, a, b, false)
        if currentTab ~= "عام" or not opened then
            notify(a .. ": " .. b)
        end

    elseif kind == "Private" then
        local key, ids, name, text = a, b, c, d
        getConv(key, ids)
        if not activeConv then
            activeConv = key
            refreshConvUI()
        end
        addMessage(convs[key].list, name, text, false)
        if not (opened and currentTab == "خاص" and activeConv == key) then
            notify("🔒 " .. name .. ": " .. text)
        end

    elseif kind == "Info" then
        sysMsg(a)
    end
end

task.spawn(function()
    remote = ReplicatedStorage:WaitForChild("NOVAEvent", 10)
    if not remote then
        sysMsg("ما لقيت سكربت السيرفر (NOVAEvent) - حط NOVA_Server في ServerScriptService")
        return
    end
    table.insert(globalConns, remote.OnClientEvent:Connect(onServerEvent))
    remote:FireServer("Join")
end)

-- Commands
local function sendMessage()
    local message = input.Text
    if message:gsub("%s", "") == "" then return end

    local command, rest = message:match("^(%S+)%s*(.*)$")
    command = command and string.lower(command) or ""

    if command == "/help" then
        local text = "/rgbname | /name اسم | /clear"
        if myRole ~= "member" then
            text = text .. " | /kickplayer اسم [سبب]"
        end
        if myRole == "owner" then
            text = text .. " | /giveadmin اسم"
        end
        sysMsg(text)
        input.Text = ""
        return
    elseif command == "/rgbname" then
        rgbNameEnabled = not rgbNameEnabled
        sysMsg(rgbNameEnabled and "RGB للاسم: ON" or "RGB للاسم: OFF")
        input.Text = ""
        return
    elseif command == "/name" then
        local value = (rest or ""):match("^%s*(.-)%s*$")
        if value and value ~= "" then
            displayName = value:sub(1, 24)
            nameInput.Text = displayName
            sysMsg("تم تغيير الاسم داخل الواجهة")
        else
            sysMsg("اكتب الاسم بعد /name")
        end
        input.Text = ""
        return
    elseif command == "/clear" then
        if currentTab == "عام" then
            clearList(publicMessages)
        elseif activeConv and convs[activeConv] then
            clearList(convs[activeConv].list)
        end
        input.Text = ""
        return
    elseif command == "/kickplayer" then
        if myRole == "member" then
            sysMsg("هالأمر للأدمن وصاحب السكربت فقط")
        elseif not remote then
            sysMsg("مو متصل بالسيرفر")
        else
            local target, reason = (rest or ""):match("^(%S+)%s*(.*)$")
            if target then
                remote:FireServer("Command", "kick", target, reason)
            else
                sysMsg("الاستخدام: /kickplayer اسم [سبب]")
            end
        end
        input.Text = ""
        return
    elseif command == "/giveadmin" then
        if myRole ~= "owner" then
            sysMsg("هالأمر لصاحب السكربت فقط")
        elseif not remote then
            sysMsg("مو متصل بالسيرفر")
        else
            local target = (rest or ""):match("^(%S+)")
            if target then
                remote:FireServer("Command", "giveadmin", target)
            else
                sysMsg("الاستخدام: /giveadmin اسم")
            end
        end
        input.Text = ""
        return
    end

    local list
    if currentTab == "عام" then
        list = publicMessages
    else
        local conv = activeConv and convs[activeConv]
        if not conv then
            openPicker()
            return
        end
        list = conv.list
    end

    if not remote then
        sysMsg("مو متصل بالسيرفر")
        return
    end

    addMessage(list, displayName, message, rgbNameEnabled)
    showLocalBubble(message)

    local text = message:sub(1, 200)
    if currentTab == "عام" then
        remote:FireServer("Public", text)
    else
        remote:FireServer("Private", convs[activeConv].ids, text)
    end

    input.Text = ""
    stickerPanel.Visible = false
end

sendButton.Activated:Connect(sendMessage)
input.FocusLost:Connect(function(enterPressed)
    if enterPressed then sendMessage() end
end)

-- Open/close
local originalPosition = main.Position

local function openChat()
    if busy or opened then return end
    busy = true
    opened = true
    main.Visible = true
    main.Position = UDim2.new(0, -main.AbsoluteSize.X - 20, 0.5, 0)
    toggle.Visible = false

    tween(main, 0.35, {Position = originalPosition}).Completed:Connect(function()
        busy = false
    end)
end

local function closeChat()
    if busy or not opened then return end
    busy = true
    opened = false
    settingsPanel.Visible = false
    stickerPanel.Visible = false

    tween(main, 0.3, {
        Position = UDim2.new(0, -main.AbsoluteSize.X - 20, 0.5, 0)
    }).Completed:Connect(function()
        main.Visible = false
        toggle.Visible = true
        busy = false
    end)
end

closeButton.Activated:Connect(closeChat)
toggle.Activated:Connect(openChat)

-- Drag floating icon
local dragging = false
local dragStart
local buttonStart

toggle.InputBegan:Connect(function(obj)
    if obj.UserInputType == Enum.UserInputType.MouseButton1
        or obj.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = obj.Position
        buttonStart = toggle.Position
    end
end)

table.insert(globalConns, UserInputService.InputChanged:Connect(function(obj)
    if not dragging then return end

    if obj.UserInputType == Enum.UserInputType.MouseMovement
        or obj.UserInputType == Enum.UserInputType.Touch then
        local delta = obj.Position - dragStart
        toggle.Position = UDim2.new(
            buttonStart.X.Scale, buttonStart.X.Offset + delta.X,
            buttonStart.Y.Scale, buttonStart.Y.Offset + delta.Y
        )
    end
end))

table.insert(globalConns, UserInputService.InputEnded:Connect(function(obj)
    if obj.UserInputType == Enum.UserInputType.MouseButton1
        or obj.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- Responsive layout (أصغر للجوالات)
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local isMobile = UserInputService.TouchEnabled or viewport.X < 600

    if isMobile then
        local width = math.clamp(viewport.X - 24, 250, 300)
        local height = math.clamp(viewport.Y - 60, 220, 300)
        main.Size = UDim2.fromOffset(width, height)
        toggle.Size = UDim2.fromOffset(46, 46)
    else
        main.Size = UDim2.fromOffset(365, 430)
        toggle.Size = UDim2.fromOffset(58, 58)
    end
end

resize()

local function connectCamera()
    local camera = workspace.CurrentCamera
    if camera then
        table.insert(globalConns,
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize))
    end
end

connectCamera()
table.insert(globalConns,
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(connectCamera)
        task.defer(resize)
    end))

-- RGB animation
task.spawn(function()
    while gui.Parent do
        if rgbEnabled then
            hue = (hue + 0.003) % 1
            applyTheme()
        end
        task.wait(0.04)
    end
end)

applyTheme()

addMessage(publicMessages, "NOVA", "تم تشغيل الواجهة.", false)
addMessage(publicMessages, "NOVA", "صنع من قبل ربيع | Rabee1258", false)
-- NOVA CHAT SERVER
-- Script عادي - حطه في ServerScriptService
-- بيعمل RemoteEvent اسمه NOVAEvent وبيوصل الرسايل بين اللي مشغلين السكربت بس

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

-- صاحب السكربت (الأفضل تحط الـ UserId بدل الاسم)
local OWNER_NAMES = { ["Rabee1258"] = true }
local OWNER_USER_IDS = { [5732145417] = true }
    -- [1

local remote = ReplicatedStorage:FindFirstChild("NOVAEvent")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "NOVAEvent"
    remote.Parent = ReplicatedStorage
end

local users = {}     -- اللاعبين اللي مشغلين السكربت
local admins = {}    -- [UserId] = true
local lastAction = {}

local function isOwner(p)
    return OWNER_NAMES[p.Name] == true or OWNER_USER_IDS[p.UserId] == true
end

local function roleOf(p)
    if isOwner(p) then return "owner" end
    if admins[p.UserId] then return "admin" end
    return "member"
end

local function userList()
    local list = {}
    for p in pairs(users) do
        table.insert(list, { id = p.UserId, name = p.DisplayName })
    end
    return list
end

local function snapshotUsers()
    local list = {}
    for p in pairs(users) do
        table.insert(list, p)
    end
    return list
end

local function broadcast(...)
    for _, p in ipairs(snapshotUsers()) do
        remote:FireClient(p, ...)
    end
end

local function filterMessage(text, sender, context)
    local ok, result = pcall(function()
        return TextService:FilterStringAsync(text, sender.UserId, context)
    end)
    return ok and result or nil
end

local function chatFor(filterObject, recipient)
    local ok, text = pcall(function()
        return filterObject:GetChatForUserAsync(recipient.UserId)
    end)
    return ok and text or nil
end

local function makeKey(ids)
    local copy = table.clone(ids)
    table.sort(copy)
    return table.concat(copy, ",")
end

local function removeUser(player)
    if not users[player] then return end
    users[player] = nil
    lastAction[player] = nil
    broadcast("Left", player.DisplayName)
    broadcast("Users", userList())
end

local function findTarget(query)
    if typeof(query) ~= "string" or query == "" then return nil end
    query = query:lower()
    local prefixMatch
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == query or p.DisplayName:lower() == query then
            return p
        end
        if not prefixMatch and (p.Name:lower():sub(1, #query) == query
            or p.DisplayName:lower():sub(1, #query) == query) then
            prefixMatch = p
        end
    end
    return prefixMatch
end

remote.OnServerEvent:Connect(function(player, kind, a, b, c)
    if typeof(kind) ~= "string" then return end

    if kind == "Join" then
        local already = users[player]
        users[player] = true
        remote:FireClient(player, "Hello", roleOf(player), userList())
        if not already then
            broadcast("Joined", player.DisplayName)
            broadcast("Users", userList())
        end
        return
    end

    if kind == "Leave" then
        removeUser(player)
        return
    end

    if not users[player] then return end

    -- حماية من السبام
    local now = os.clock()
    if now - (lastAction[player] or 0) < 0.4 then return end
    lastAction[player] = now

    if kind == "Public" then
        if typeof(a) ~= "string" then return end
        local text = a:sub(1, 200)
        if text:gsub("%s", "") == "" then return end

        local filtered = filterMessage(text, player, Enum.TextFilterContext.PublicChat)
        if not filtered then return end

        for _, p in ipairs(snapshotUsers()) do
            if p ~= player then
                local clean = chatFor(filtered, p)
                if clean then
                    remote:FireClient(p, "Public", player.DisplayName, clean)
                end
            end
        end

    elseif kind == "Private" then
        -- a = قائمة UserIds (تشمل المرسل) ، b = النص
        if typeof(a) ~= "table" or typeof(b) ~= "string" then return end
        if #a < 2 or #a > 8 then return end

        local ids, seen, members = {}, {}, {}
        local includesSender = false
        for _, id in ipairs(a) do
            if typeof(id) ~= "number" or seen[id] then return end
            seen[id] = true
            local p = Players:GetPlayerByUserId(id)
            if not p or not users[p] then return end
            if p == player then includesSender = true end
            table.insert(ids, id)
            table.insert(members, p)
        end
        if not includesSender then return end

        local text = b:sub(1, 200)
        if text:gsub("%s", "") == "" then return end

        local filtered = filterMessage(text, player, Enum.TextFilterContext.PrivateChat)
        if not filtered then return end

        table.sort(ids)
        local key = makeKey(ids)
        for _, p in ipairs(members) do
            if p ~= player then
                local clean = chatFor(filtered, p)
                if clean then
                    remote:FireClient(p, "Private", key, ids, player.DisplayName, clean)
                end
            end
        end

    elseif kind == "Command" then
        local role = roleOf(player)

        if a == "kick" then
            if role == "member" then
                remote:FireClient(player, "Info", "هالأمر للأدمن وصاحب السكربت فقط")
                return
            end
            local target = findTarget(b)
            if not target then
                remote:FireClient(player, "Info", "ما لقيت اللاعب")
                return
            end
            if target == player then
                remote:FireClient(player, "Info", "ما بتقدر تطرد نفسك")
                return
            end
            if isOwner(target) then
                remote:FireClient(player, "Info", "ما بتقدر تطرد صاحب السكربت")
                return
            end
            if admins[target.UserId] and role ~= "owner" then
                remote:FireClient(player, "Info", "ما بتقدر تطرد أدمن")
                return
            end
            local reason = (typeof(c) == "string" and c ~= "") and c:sub(1, 100)
                or "تم طردك من السيرفر"
            remote:FireClient(player, "Info", "تم طرد " .. target.DisplayName)
            target:Kick(reason)

        elseif a == "giveadmin" then
            if role ~= "owner" then
                remote:FireClient(player, "Info", "هالأمر لصاحب السكربت فقط")
                return
            end
            local target = findTarget(b)
            if not target then
                remote:FireClient(player, "Info", "ما لقيت اللاعب")
                return
            end
            admins[target.UserId] = true
            remote:FireClient(player, "Info", "تم إعطاء " .. target.DisplayName .. " أدمن")
            if users[target] then
                remote:FireClient(target, "Role", "admin")
                remote:FireClient(target, "Info", "صرت أدمن بالسكربت 👑")
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeUser(player)
    admins[player.UserId] = nil
end)
