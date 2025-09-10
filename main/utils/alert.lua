-- ===================================================================
-- CUSTOM ALERTS MODULE (V2 - with 9 Positions)
-- ===================================================================

local Alerts = {}

-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Variables
local LocalPlayer = Players.LocalPlayer

--[[=================================================================
-- [!] Private Configuration
-- Styles are kept inside the module.
--==================================================================]]
local AlertStyles = {
    info = {
        BackgroundColor = Color3.fromRGB(35, 35, 35),
        StrokeColor = Color3.fromRGB(80, 80, 80),
        TitleColor = Color3.fromRGB(255, 255, 255),
    },
    warn = {
        BackgroundColor = Color3.fromRGB(60, 50, 20),
        StrokeColor = Color3.fromRGB(255, 190, 0),
        TitleColor = Color3.fromRGB(255, 190, 0),
    },
    danger = {
        BackgroundColor = Color3.fromRGB(60, 25, 25),
        StrokeColor = Color3.fromRGB(255, 60, 60),
        TitleColor = Color3.fromRGB(255, 80, 80),
    }
}

--[[=================================================================
-- [!] GUI Setup (Runs once when the module is loaded)
-- This creates the main container for all notifications.
--==================================================================]]
local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "CustomNotificationGui"
NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotificationGui.ResetOnSpawn = false
NotificationGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.fromOffset(300, 300)
Container.Position = UDim2.new(0.5, 0, 0, 10)
Container.AnchorPoint = Vector2.new(0.5, 0)
Container.BackgroundTransparency = 1
Container.Parent = NotificationGui

local ListLayout = Instance.new("UIListLayout")
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 8)
ListLayout.Parent = Container


--[[=================================================================
-- [!] Public Module Functions
--==================================================================]]

--- Changes the position for all future notifications.
-- @param options (table) - A table with a 'position' key.
function Alerts:ConfigureAlerts(options)
    options = options or {}
    local position = options.position or "TopCenter"
    
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    if position == "TopCenter" then
        Container.Position = UDim2.new(0.5, 0, 0, 10)
        Container.AnchorPoint = Vector2.new(0.5, 0)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    elseif position == "TopLeft" then
        Container.Position = UDim2.new(0, 10, 0, 10)
        Container.AnchorPoint = Vector2.new(0, 0)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    elseif position == "TopRight" then
        Container.Position = UDim2.new(1, -10, 0, 10)
        Container.AnchorPoint = Vector2.new(1, 0)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    elseif position == "Center" then
        Container.Position = UDim2.new(0.5, 0, 0.5, 0)
        Container.AnchorPoint = Vector2.new(0.5, 0.5)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    elseif position == "Left" then
        Container.Position = UDim2.new(0, 10, 0.5, 0)
        Container.AnchorPoint = Vector2.new(0, 0.5)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    elseif position == "Right" then
        Container.Position = UDim2.new(1, -10, 0.5, 0)
        Container.AnchorPoint = Vector2.new(1, 0.5)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    elseif position == "BottomCenter" then
        Container.Position = UDim2.new(0.5, 0, 1, -10)
        Container.AnchorPoint = Vector2.new(0.5, 1)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    elseif position == "BottomLeft" then
        Container.Position = UDim2.new(0, 10, 1, -10)
        Container.AnchorPoint = Vector2.new(0, 1)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    elseif position == "BottomRight" then
        Container.Position = UDim2.new(1, -10, 1, -10)
        Container.AnchorPoint = Vector2.new(1, 1)
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end
end

--- Creates, animates, and destroys a single notification.
-- @param options (table) - A table of options for the alert.
function Alerts:SendAlert(options)
    options = options or {}
    local title = options.title or "Notification"
    local content = options.content or ""
    local duration = options.duration or 5
    local alertType = options.type or "info"
    local textSize = options.textSize or 14

    local style = AlertStyles[alertType] or AlertStyles.info

    local AlertFrame = Instance.new("Frame")
    AlertFrame.Name = "AlertFrame"
    AlertFrame.BackgroundColor3 = style.BackgroundColor
    AlertFrame.BorderSizePixel = 0
    AlertFrame.Size = UDim2.new(0, 280, 0, 60)
    AlertFrame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = AlertFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = style.StrokeColor
    stroke.Thickness = 1.5
    stroke.Parent = AlertFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, -10, 0, 20)
    TitleLabel.Position = UDim2.new(0, 5, 0, 5)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = title
    TitleLabel.TextColor3 = style.TitleColor
    TitleLabel.TextSize = textSize + 2
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = AlertFrame

    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Name = "Content"
    ContentLabel.Size = UDim2.new(1, -10, 0, 25)
    ContentLabel.Position = UDim2.new(0, 5, 0, 25)
    ContentLabel.Font = Enum.Font.Gotham
    ContentLabel.Text = content
    ContentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ContentLabel.TextSize = textSize
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.TextWrapped = true
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Parent = AlertFrame

    task.spawn(function()
        -- Set initial position above the screen for animation
        AlertFrame.Parent = Container
        AlertFrame.Visible = false
        task.wait()
        AlertFrame.Visible = true

        local startY = AlertFrame.Position.Y.Offset
        local startPos = UDim2.new(AlertFrame.Position.X.Scale, AlertFrame.Position.X.Offset, AlertFrame.Position.Y.Scale, startY - 20)
        AlertFrame.Position = startPos
        AlertFrame.BackgroundTransparency = 1

        -- Animate In (Slide down)
        local tweenInfoIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tweenIn = TweenService:Create(AlertFrame, tweenInfoIn, { Position = UDim2.fromOffset(AlertFrame.Position.X.Offset, startY), BackgroundTransparency = 0 })
        tweenIn:Play()
        
        -- Wait for the duration without blocking the main script
        task.wait(duration)

        -- Animate Out (Slide up)
        local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local tweenOut = TweenService:Create(AlertFrame, tweenInfoOut, { Position = startPos, BackgroundTransparency = 1 })
        tweenOut:Play()

        -- Clean up the frame after it animates out
        tweenOut.Completed:Wait()
        AlertFrame:Destroy()
    end)
end

return Alerts