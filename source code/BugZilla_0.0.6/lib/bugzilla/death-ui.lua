
DeathUI = {}



function DeathUI.Init(self)
  if not global.BZ_gui then
    self:InitGlobalData()
  end
end



function DeathUI.OnConfigurationChanged(self)
  local guiData = global.BZ_gui

  if not guiData then
    self:InitGlobalData()
    return
  end

  if not guiData.Version then
    -- We need to check if it was the first test version without version number
    if not guiData.guiState then
      -- No guiState means no UI exist
      self:InitGlobalData()
    else
      -- We need to update to version 1
      guiData.Name = "BZ_gui"
      guiData.Version = "1"

      local oldDeaths = guiData.deaths
      deathRank = {}
      deathRankLength = 0

      for playerIndex, _ in pairs(game.players) do
        deathRankLength = deathRankLength + 1
        deathRank[deathRankLength] = playerIndex

        -- Now we added the player as last rank, check if we need to move it up
        if deathRankLength > 1 then
          local playerRank = deathRankLength
          local playerDeaths = guiData.deaths[playerIndex]

          while playerRank > 1 and playerDeaths > guiData.deaths[deathRank[playerRank - 1]] do
            -- switch places
            deathRank[playerRank] = deathRank[playerRank-1]
            playerRank = playerRank - 1
            deathRank[playerRank] = playerIndex
          end
        end

        -- On this version we need also recreate the UI for each player
        local scrollPane = game.players[playerIndex].gui.top.BZ_gui_frame.BZ_gui_flow.BZ_gui_scrollPane
        scrollPane.BZ_gui_lblDeaths.destroy() -- Destroy the old label

        -- Now create the new labels
        local deathsTable = scrollPane.add{
          type = "table",
          name = "BZ_gui_deathsTable",
          colspan = 3
        }
        deathsTable.add{
          type = "label",
          name = "BZ_gui_lblDeathsRank",
          caption = "Deahts: ",
          single_line = false
        }
        deathsTable.add{
          type = "label",
          name = "BZ_gui_lblDeathsName",
          caption = "0",
          single_line = false
        }
        deathsTable.add{
          type = "label",
          name = "BZ_gui_lblDeathsCount",
          caption = "",
          single_line = false
        }
      end

      -- All players are added, now sync the data
      guiData.deathRank = deathRank
      guiData.deathRankLength = deathRankLength
    end
  end

  -- Up to date data here, now lets re-draw the GUI
  self:UpdateAllLabels()
end



function DeathUI.OnNewPlayerCreated(self, playerIndex)
  self:InitPlayer(playerIndex)
  self:UpdateAllLabels()
end



function DeathUI.OnClick(self, event)
  if event.element.name == "BZ_gui_btnMore" then
    local playerIndex = event.player_index
    global.BZ_gui.guiState[playerIndex].detailsVisible = not global.BZ_gui.guiState[playerIndex].detailsVisible
    self:UpdateButtons(playerIndex)
    self:UpdateLabels(playerIndex)
  end
end



function DeathUI.InitGlobalData(self)
  global.BZ_gui = {}
  global.BZ_gui.Name = "BZ_gui"
  global.BZ_gui.Version = "1"

  global.BZ_gui.deaths = {}
  global.BZ_gui.deathRank = {}
  global.BZ_gui.deathRankLength = 0
  global.BZ_gui.guiState = {}

  for playerIndex, _ in pairs(game.players) do
    self:InitPlayer(playerIndex)
  end
end



function DeathUI.InitPlayer(self, playerIndex)
  -- init deaths
  if not global.BZ_gui.deaths[playerIndex] then
    global.BZ_gui.deaths[playerIndex] = 0
    global.BZ_gui.deathRankLength = global.BZ_gui.deathRankLength + 1
    global.BZ_gui.deathRank[global.BZ_gui.deathRankLength] = playerIndex
  end

  -- init gui for the player
  if not global.BZ_gui.guiState[playerIndex] then
    local frame = game.players[playerIndex].gui.top.add{
      type = "frame",
      name = "BZ_gui_frame"
    }
    local flow = frame.add{
      type = "flow",
      name = "BZ_gui_flow",
      direction = "vertical"
    }
    local scrollPane = flow.add{
      type = "scroll-pane",
      name = "BZ_gui_scrollPane",
      vertical_scroll_policy = "auto"
    }
    scrollPane.style.maximal_height = 500

    -- Death count
    local deathsTable = scrollPane.add{
      type = "table",
      name = "BZ_gui_deathsTable",
      colspan = 3
    }
    deathsTable.add{
      type = "label",
      name = "BZ_gui_lblDeathsRank",
      caption = "Deahts: ",
      single_line = false
    }
    deathsTable.add{
      type = "label",
      name = "BZ_gui_lblDeathsName",
      caption = "0",
      single_line = false
    }
    deathsTable.add{
      type = "label",
      name = "BZ_gui_lblDeathsCount",
      caption = "",
      single_line = false
    }

    flow.add{
      type = "button",
      name = "BZ_gui_btnMore",
      caption = "More..."
    }

    -- init gui state visible for the player
    local state = {}
    state.detailsVisible = false
    global.BZ_gui.guiState[playerIndex] = state
  end
end



function DeathUI.AddDeath(self, playerIndex)
  local guiData = global.BZ_gui

  -- Add death
  local playerDeaths = guiData.deaths[playerIndex]
  playerDeaths = playerDeaths + 1
  guiData.deaths[playerIndex] = playerDeaths

  -- Check if we need to move the player a rank up, first find its current rank
  local playerRank = 0
  local deathRank = guiData.deathRank
  for i = 1, global.BZ_gui.deathRankLength, 1 do
    if deathRank[i] == playerIndex then
      playerRank = i
    end
  end

  -- We can assume we are sure we found a rank, now orden the player
  while playerRank > 1 and playerDeaths > guiData.deaths[deathRank[playerRank - 1]] do
    -- switch places
    deathRank[playerRank] = deathRank[playerRank-1]
    playerRank = playerRank - 1
    deathRank[playerRank] = playerIndex
  end
  guiData.deathRank = deathRank

  -- save changes
  global.BZ_gui = guiData

  self:UpdateAllLabels()
end



function DeathUI.UpdateButtons(self, playerIndex)
  local frame = game.players[playerIndex].gui.top.BZ_gui_frame
  if frame then
    local btnMore = frame.BZ_gui_flow.BZ_gui_btnMore
    local state = global.BZ_gui.guiState[playerIndex]
    if state.detailsVisible then
      btnMore.caption = "Less..."
    else
      btnMore.caption = "More..."
    end
  end
end



function DeathUI.UpdateAllLabels(self)
  for playerIndex, _ in pairs(game.players) do
    self:UpdateLabels(playerIndex)
  end
end



function DeathUI.UpdateLabels(self, playerIndex)
-- Update label UI elements to match death count / GUI state
  local frame = game.players[playerIndex].gui.top.BZ_gui_frame
  if frame then
    local deathsRank, deathsName, deathsCount = self:GetDeathsLabelText(playerIndex)
    local deathsTable = frame.BZ_gui_flow.BZ_gui_scrollPane.BZ_gui_deathsTable

    deathsTable.BZ_gui_lblDeathsRank.caption = deathsRank
    deathsTable.BZ_gui_lblDeathsName.caption = deathsName
    deathsTable.BZ_gui_lblDeathsCount.caption = deathsCount
  end
end



function DeathUI.GetDeathsLabelText(self, playerIndex)
  -- Either single line or multi line string depending on GUI state
  if global.BZ_gui.guiState[playerIndex].detailsVisible then
    local deathsRank = "†"
    local deathsName = "Deaths:"
    local deathsCount = ""

    for i = 1, global.BZ_gui.deathRankLength, 1 do
      local playerIndex = global.BZ_gui.deathRank[i]

      -- "00 | playerName | playerDeaths"
      if i < 10 then
        deathsRank = deathsRank .. "\n0" .. i
      else
        deathsRank = deathsRank .. "\n" .. i
      end

      deathsName = deathsName .. " \n " .. game.players[playerIndex].name
      deathsCount = deathsCount .. " \n " .. global.BZ_gui.deaths[playerIndex]
    end

    return deathsRank, deathsName, deathsCount

  else
    return "† Deaths: ", global.BZ_gui.deaths[playerIndex], ""
  end
end
