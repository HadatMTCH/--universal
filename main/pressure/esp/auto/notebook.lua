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
        SelectDelay = 0.5
    }

    local activeHighlights = {}
    local questionListener = nil -- To hold our persistent connection

    -- This function now solves a question and cleans up old highlights
    local function solveQuestion(answersFrame)
        -- Cleanup old highlights from the previous question
        for _, stroke in ipairs(activeHighlights) do
            if stroke and stroke.Parent then stroke:Destroy() end
        end
        activeHighlights = {}

        local correctAnswerButton = nil
        for _, answerFrame in ipairs(answersFrame:GetChildren()) do
            if answerFrame:IsA("Frame") and answerFrame:GetAttribute("Choice") ~= nil then
                correctAnswerButton = answerFrame:FindFirstChild("TextButton")
                break
            end
        end

        if correctAnswerButton then
            if SolverConfig.Highlight then
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(0, 255, 127); stroke.Thickness = 2
                stroke.Parent = correctAnswerButton
                table.insert(activeHighlights, stroke)
            end

            if SolverConfig.AutoSelect then
                task.wait(SolverConfig.SelectDelay)
                if answersFrame and answersFrame.Parent then -- Check if UI is still valid
                    firesignal(correctAnswerButton.Activated)
                end
            end
        end
    end

    -- Listen for when the Notebook UI is first added to the player's screen
    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "NotebookUI" then
            print("Notebook UI detected. Starting solver...")
            task.wait(0.2) -- Wait for UI to fully load

            local questionLabel = child:WaitForChild("Notebook"):WaitForChild("Notepad"):WaitForChild("Question")
            local answersFrame = child.Notebook.Notepad.Answers

            -- Solve the very first question immediately
            solveQuestion(answersFrame)

            -- Disconnect any old listener to be safe
            if questionListener then
                questionListener:Disconnect()
            end

            -- NEW: Create a persistent listener that watches for changes to the question text
            questionListener = questionLabel:GetPropertyChangedSignal("Text"):Connect(function()
                print("New question detected. Re-solving...")
                task.wait(0.1) -- A small delay for the new answers to load
                solveQuestion(answersFrame)
            end)

            -- When the Notebook is removed, disconnect our listener to prevent memory leaks
            child.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if questionListener then
                        print("Notebook UI closed. Stopping solver.")
                        questionListener:Disconnect()
                        questionListener = nil
                    end
                end
            end)
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
