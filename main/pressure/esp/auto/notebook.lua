local Module = {}

function Module.CreateTab(Window)
    -- Services
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Configuration for our solver
    local SolverConfig = {
        Highlight = true,
        AutoSelect = false,
        SelectDelay = 0.5 -- Delay in seconds before auto-selecting
    }

    local activeHighlights = {}

    -- This is the main function that runs when the notebook UI appears
    local function solveNotebook(notebookUI)
        -- Find the frame containing the answer buttons
        local answersFrame = notebookUI:WaitForChild("Notebook"):WaitForChild("Notepad"):WaitForChild("Answers")
        if not answersFrame then
            return
        end

        ---[[ NEW: Cleanup old highlights before starting ]]---
        for _, stroke in ipairs(activeHighlights) do
            if stroke and stroke.Parent then
                stroke:Destroy()
            end
        end
        activeHighlights = {} -- Reset the table
        ----------------------------------------------------

        local correctAnswerButton = nil

        -- Loop through all the answer frames (Answer1, Answer2, etc.)
        for _, answerFrame in ipairs(answersFrame:GetChildren()) do
            if answerFrame:IsA("Frame") then
                -- The game's script sets a "Choice" attribute on the correct answer.
                -- Incorrect answers have this attribute as nil.
                if answerFrame:GetAttribute("Choice") ~= nil then
                    correctAnswerButton = answerFrame:FindFirstChild("TextButton")
                    break -- We found the correct one, no need to loop further
                end
            end
        end

        if correctAnswerButton then
             -- Action 1: Highlight the correct answer
            if SolverConfig.Highlight then
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(0, 255, 127) -- Bright green
                stroke.Thickness = 2
                stroke.Parent = correctAnswerButton
                table.insert(activeHighlights, stroke) -- NEW: Store the new highlight
            end

            -- Action 2: Auto-select the correct answer
            if SolverConfig.AutoSelect then
                task.wait(SolverConfig.SelectDelay)

                -- Check if the UI is still visible before clicking
                if notebookUI and notebookUI.Parent then
                    correctAnswerButton.Activated:Fire()
                end
            end
        end
    end

    -- Listen for when the Notebook UI is added to the player's screen
    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "NotebookUI" then
            print("Notebook UI detected. Attempting to solve...")
            -- A small wait to ensure all elements inside the UI are loaded
            task.wait(0.1)
            solveNotebook(child)
        end
    end)

    -- Add the controls to your existing UI
    local MinigameTab = Window:CreateTab("Minigames", "box")
    MinigameTab:CreateSection("Notebook Solver")

    MinigameTab:CreateToggle({
        Name = "Highlight Correct Answer",
        CurrentValue = SolverConfig.Highlight,
        Flag = "NotebookSolver_Highlight",
        Callback = function(value)
            SolverConfig.Highlight = value
        end
    })

    MinigameTab:CreateToggle({
        Name = "Auto-Select Correct Answer",
        CurrentValue = SolverConfig.AutoSelect,
        Flag = "NotebookSolver_AutoSelect",
        Callback = function(value)
            SolverConfig.AutoSelect = value
        end
    })

    MinigameTab:CreateSlider({
        Name = "Auto-Select Delay",
        Range = {0, 2},
        Increment = 0.1,
        Suffix = "s",
        CurrentValue = SolverConfig.SelectDelay,
        Flag = "NotebookSolver_Delay",
        Callback = function(value)
            SolverConfig.SelectDelay = value
        end
    })

end
return Module
