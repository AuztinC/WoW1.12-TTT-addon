local addon = {}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function CreateMainFrame()
    local f = CreateFrame("Frame", "Travel-Tac-Toe", UIParent)
    f:SetWidth(240)
    f:SetHeight(300)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    f:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText("Tic-Tac-Toe")

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOP", title, "BOTTOM", 0, -6)
    status:SetText("Choose a mode and start!")

    return f, title, status
end

local function CreateButton(parent, label, width, height)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width)
    b:SetHeight(height)
    b:SetText(label)
    return b
end

local function CreateCell(parent, index, size)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(size)
    b:SetHeight(size)
    b:SetText("")
    b.index = index
    return b
end

local function CloneBoard(board)
    local t = {}
    for i = 1, 9 do
        t[i] = board[i]
    end
    return t
end

local WIN_LINES = {
    {1, 2, 3}, {4, 5, 6}, {7, 8, 9},
    {1, 4, 7}, {2, 5, 8}, {3, 6, 9},
    {1, 5, 9}, {3, 5, 7},
}

local function GetWinner(board)
    for _, line in ipairs(WIN_LINES) do
        local a, b, c = line[1], line[2], line[3]
        if board[a] and board[a] == board[b] and board[a] == board[c] then
            return board[a]
        end
    end
    return nil
end

local function IsBoardFull(board)
    for i = 1, 9 do
        if not board[i] then
            return false
        end
    end
    return true
end

local function GetEmptyCells(board)
    local cells = {}
    for i = 1, 9 do
        if not board[i] then
            table.insert(cells, i)
        end
    end
    return cells
end

local function FindWinningMove(board, mark)
    for _, line in ipairs(WIN_LINES) do
        local a, b, c = line[1], line[2], line[3]
        local count = 0
        local empty = nil
        if board[a] == mark then count = count + 1 elseif not board[a] then empty = a end
        if board[b] == mark then count = count + 1 elseif not board[b] then empty = b end
        if board[c] == mark then count = count + 1 elseif not board[c] then empty = c end
        if count == 2 and empty then
            return empty
        end
    end
    return nil
end

local function Minimax(board, isMax, aiMark, playerMark)
    local winner = GetWinner(board)
    if winner == aiMark then
        return 1
    elseif winner == playerMark then
        return -1
    elseif IsBoardFull(board) then
        return 0
    end

    if isMax then
        local best = -2
        for _, cell in ipairs(GetEmptyCells(board)) do
            local nextBoard = CloneBoard(board)
            nextBoard[cell] = aiMark
            local score = Minimax(nextBoard, false, aiMark, playerMark)
            if score > best then
                best = score
            end
        end
        return best
    else
        local best = 2
        for _, cell in ipairs(GetEmptyCells(board)) do
            local nextBoard = CloneBoard(board)
            nextBoard[cell] = playerMark
            local score = Minimax(nextBoard, true, aiMark, playerMark)
            if score < best then
                best = score
            end
        end
        return best
    end
end

local function ChooseAIMove(board, mode, aiMark, playerMark)
    local empty = GetEmptyCells(board)
    if table.getn(empty) == 0 then
        return nil
    end

    if mode == "prankster" then
        return empty[math.random(1, table.getn(empty))]
    end

    local winMove = FindWinningMove(board, aiMark)
    if winMove then
        return winMove
    end

    if mode == "warchief" then
        local blockMove = FindWinningMove(board, playerMark)
        if blockMove then
            return blockMove
        end

        if not board[5] then
            return 5
        end

        local corners = {1, 3, 7, 9}
        local openCorners = {}
        for _, c in ipairs(corners) do
            if not board[c] then
                table.insert(openCorners, c)
            end
        end
        if table.getn(openCorners) > 0 then
            return openCorners[math.random(1, table.getn(openCorners))]
        end

        return empty[math.random(1, table.getn(empty))]
    end

    local bestScore = -2
    local bestMove = empty[1]
    for _, cell in ipairs(empty) do
        local nextBoard = CloneBoard(board)
        nextBoard[cell] = aiMark
        local score = Minimax(nextBoard, false, aiMark, playerMark)
        if score > bestScore then
            bestScore = score
            bestMove = cell
        end
    end
    return bestMove
end

local function UpdateBoardUI(state)
    for i = 1, 9 do
        local value = state.board[i]
        local cell = state.cells[i]
        if value then
            cell:SetText(value)
            cell:Disable()
        else
            cell:SetText("")
            cell:Enable()
        end
    end
end

local function FinishGame(state, winner)
    state.gameOver = true
    if winner == state.playerMark then
        state.status:SetText("You win! Glory to you.")
    elseif winner == state.aiMark then
        state.status:SetText("You lose. The AI prevails.")
    else
        state.status:SetText("Draw. The board rests.")
    end
end

local function CheckGameState(state)
    local winner = GetWinner(state.board)
    if winner then
        FinishGame(state, winner)
        return true
    end

    if IsBoardFull(state.board) then
        FinishGame(state, nil)
        return true
    end

    return false
end

local function AITakeTurn(state)
    if state.gameOver then
        return
    end

    local move = ChooseAIMove(state.board, state.mode, state.aiMark, state.playerMark)
    if not move then
        return
    end

    state.board[move] = state.aiMark
    UpdateBoardUI(state)
    if not CheckGameState(state) then
        state.status:SetText("Your turn.")
    end
end

local function ResetBoard(state)
    for i = 1, 9 do
        state.board[i] = nil
    end
    state.gameOver = false
    UpdateBoardUI(state)
    state.status:SetText("Your turn.")
end

local function CreateGame()
    local frame, title, status = CreateMainFrame()

    local state = {
        frame = frame,
        title = title,
        status = status,
        board = {},
        cells = {},
        gameOver = false,
        playerMark = "X",
        aiMark = "O",
        mode = "prankster",
    }

    local grid = CreateFrame("Frame", nil, frame)
    grid:SetWidth(180)
    grid:SetHeight(180)
    grid:SetPoint("TOP", status, "BOTTOM", 0, -10)

    local cellSize = 52
    for row = 1, 3 do
        for col = 1, 3 do
            local idx = (row - 1) * 3 + col
            local cell = CreateCell(grid, idx, cellSize)
            cell:SetPoint("TOPLEFT", grid, "TOPLEFT", (col - 1) * (cellSize + 4), -((row - 1) * (cellSize + 4)))
            cell:SetScript("OnClick", function()
                if state.gameOver then
                    return
                end
                if state.board[idx] then
                    return
                end
                state.board[idx] = state.playerMark
                UpdateBoardUI(state)
                if not CheckGameState(state) then
                    state.status:SetText("AI is thinking...")
                    AITakeTurn(state)
                end
            end)
            state.cells[idx] = cell
        end
    end

    local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeLabel:SetPoint("TOPLEFT", grid, "BOTTOMLEFT", 0, -8)
    modeLabel:SetText("Mode:")

    local modeButton = CreateButton(frame, "Prankster (Easy)", 160, 20)
    modeButton:SetPoint("LEFT", modeLabel, "RIGHT", 6, 0)

    local function SetMode(mode)
        state.mode = mode
        if mode == "prankster" then
            modeButton:SetText("Prankster (Easy)")
        elseif mode == "warchief" then
            modeButton:SetText("Warchief (Normal)")
        else
            modeButton:SetText("Titan (Hard)")
        end
        ResetBoard(state)
    end

    modeButton:SetScript("OnClick", function()
        if state.mode == "prankster" then
            SetMode("warchief")
        elseif state.mode == "warchief" then
            SetMode("titan")
        else
            SetMode("prankster")
        end
    end)

    local resetButton = CreateButton(frame, "Reset", 80, 22)
    resetButton:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -8)
    resetButton:SetScript("OnClick", function()
        ResetBoard(state)
    end)

    local closeButton = CreateButton(frame, "Close", 80, 22)
    closeButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    state.modeButton = modeButton

    SetMode("prankster")

    return state
end

local game = CreateGame()

SLASH_Travel-Tac-Toe1 = "/ttt"
SlashCmdList["Travel-Tac-Toe"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "show" or msg == "" then
        game.frame:Show()
    elseif msg == "hide" then
        game.frame:Hide()
    elseif msg == "mode" then
        if game.mode == "prankster" then
            game.modeButton:Click()
        elseif game.mode == "warchief" then
            game.modeButton:Click()
        else
            game.modeButton:Click()
        end
    else
        Print("|cff00ff00Travel-Tac-Toe|r commands: /ttt, /ttt show, /ttt hide")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    Print("|cff00ff00Travel-Tac-Toe loaded!|r Type /ttt")
end)
