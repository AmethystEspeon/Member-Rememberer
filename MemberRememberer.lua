--[[Copyright (c) 2022, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...);
end

local MAX_LIST_SIZE = 4
MemberRememberer = CreateFrame("Frame", nil, UIParent);

--Size of frames
MemberRememberer.WIDTH = 400
MemberRememberer.HEIGHT = 330

local BUTTON_FRAME_WIDTH = 280

--Starting position of rating frame
MemberRememberer.START_X = 0
MemberRememberer.START_Y = 500

--Colors
MemberRememberer.BACKGROUND_COLORS = {0.0588, 0.0549, 0.102, 0.85}

--Slash Commands

--DB
MemberRemembererPlayerDB = MemberRemembererPlayerDB or {}
local hooked = {}
function MemberRememberer:OnLoad()
    --debugPrint("Loaded")
    self:setupRatingFrame(self);
    
    --self:setupDungeonTrigger(self); --DONE IN MemberDungeons.lua No need for this trigger
    hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(gametooltip, resultID, autoAcceptOption)
        --debugPrint("LFGListUtil_SetSearchEntryTooltip")
        local entry = C_LFGList.GetSearchResultInfo(resultID)
        if not entry or not entry.leaderName then
            return
        end
        local skill, attitude, note, playerNumber = self:getPlayer(self:addServerName(entry.leaderName))
        --debugPrint("hooked correctly!")
        if skill ~= 0 or attitude ~= 0 or note ~= "" then
            GameTooltip:AddLine("\n")
        end
        if skill ~= 0 then
            GameTooltip:AddDoubleLine("Skill:", tostring(skill), 1,0.82,0.0,1,1,1)
        end
        if attitude ~= 0 then
            GameTooltip:AddDoubleLine("Attitude:", tostring(attitude), 1,0.82,0.0,1,1,1)
        end
        if note ~= "" then
            GameTooltip:AddLine(note,1,1,1,true)
        end
    end)

    --Add Tooltip to Applicant's first member on mouseover
    local function ApplicantOnEnterHook(applicationFrame)
        if not GameTooltip:IsShown() then
            --debugPrint("Not tooltip")
            return
        end
        --debugPrint("Hooked Successfully")
        local id = applicationFrame:GetParent().applicantID
        --debugPrint(applicationFrame:GetParent().applicantID)
        local name, _ = C_LFGList.GetApplicantMemberInfo(id,1)
        --GameTooltip:AddLine("\n" .. name)
        local skill, attitude, note = self:getPlayer(self:addServerName(name))
        if skill ~= 0 or attitude ~= 0 or note ~= "" then
            GameTooltip:AddLine("\n")
        end
        if skill ~= 0 then
            GameTooltip:AddDoubleLine("Skill:", tostring(skill), 1,0.82,0.0,1,1,1)
        end
        if attitude ~= 0 then
            GameTooltip:AddDoubleLine("Attitude:", tostring(attitude), 1,0.82,0.0,1,1,1)
        end
        if note ~= "" then
            GameTooltip:AddLine(note,1,1,1,true)
        end

        GameTooltip:Show()
    end

    --This hooks into the creation of the frames to add an OnEnter function into it.
    hooksecurefunc("LFGListApplicationViewer_UpdateResults", function(applicationFrame)
        --debugPrint(applicationFrame.ScrollFrame.offset)
        local buttons = applicationFrame.ScrollFrame.buttons
        for i = 1, #buttons do
            local button = buttons[i]
            if not hooked[button] then
                button.Member1:HookScript("OnEnter", ApplicantOnEnterHook)
                hooked[button] = true
                --debugPrint("Hook attached")
            end
        end

    end)

    --Add tooltip when mousing over non-first member
    hooksecurefunc("LFGListApplicantMember_OnEnter", function(secondaryMemberFrame)
        local id = secondaryMemberFrame:GetParent().applicantID
        local name, _ = C_LFGList.GetApplicantMemberInfo(id,secondaryMemberFrame.memberIdx)
        --debugPrint("Refresh prevented")
        local skill, attitude, note = self:getPlayer(self:addServerName(name))
        --GameTooltip:AddLine("\n" .. name)
        if skill ~= 0 or attitude ~= 0 or note ~= "" then
            GameTooltip:AddLine("\n")
        end
        if skill ~= 0 then
            GameTooltip:AddDoubleLine("Skill:", tostring(skill), 1,0.82,0.0,1,1,1)
        end
        if attitude ~= 0 then
            GameTooltip:AddDoubleLine("Attitude:", tostring(attitude), 1,0.82,0.0,1,1,1)
        end
        if note ~= "" then
            GameTooltip:AddLine(note,1,1,1,true)
        end
        GameTooltip:Show()
    end)

    self:Hide()
end

---@param frame frame @The frame to edit into the rating frame
function MemberRememberer:setupRatingFrame(frame)
    --debugPrint(frame.WIDTH, frame.HEIGHT)
    frame:SetSize(frame.WIDTH, frame.HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame.Background = frame:CreateTexture(nil,"BACKGROUND");
    frame.Background:SetAllPoints(frame);
    frame.Background:SetColorTexture(frame.BACKGROUND_COLORS[1],frame.BACKGROUND_COLORS[2],frame.BACKGROUND_COLORS[3],frame.BACKGROUND_COLORS[4])
    self:createTitleFrame(self,"Member Rememberer")
    self:createPlayerFrames(self,4)
    self:createAcceptButtons(self)
end

---@param frame frame @The frame to add a title frame onto
---@param titleText string @The text for the title
function MemberRememberer:createTitleFrame(frame,titleText)
    frame.titleFrame = frame.titleFrame or CreateFrame("Frame",nil,frame)
    frame.titleFrame:SetPoint("TOP",frame,"TOP")
    frame.titleFrame:SetSize(frame.WIDTH-43,20)
    frame.titleFrame.title = frame.titleFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.titleFrame.title:SetPoint("TOP",frame.titleFrame,"CENTER",0,5)
    frame.titleFrame.title:SetText(titleText)
    self:setupDragging(frame.titleFrame,frame)
end

---@param frame frame @The parent frame that should move when the clickable frame is dragged
---@param draggableFrame frame @The frame that can be click and dragged to move it and frame
function MemberRememberer:setupDragging(frame,draggableFrame)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    draggableFrame:SetMovable(true)
    frame:SetScript("OnDragStart", function()
        draggableFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        draggableFrame:StopMovingOrSizing()
    end)
end

---@param frame frame @The parent frame to attach the player frames to. Assumes there is a title frame of height 20 attached.
---@param numberOfPlayers integer @The number of player frames to attach, each right under the last.
function MemberRememberer:createPlayerFrames(frame,numberOfPlayers)
    self.playerFrames = self.playerFrames or {}
    self.buttonBackgrounds = self.buttonBackgrounds or {}
    self.descFrames = self.descFrames or {}
    self.noteFrame = self.noteFrame or CreateFrame("frame",nil,self)
    self:setupNoteFrame()

    while #self.playerFrames < numberOfPlayers and #self.playerFrames < MAX_LIST_SIZE do
        self.playerFrames[#self.playerFrames+1] = self:createNameFrame()
        self.buttonBackgrounds[#self.buttonBackgrounds+1] = self:createButtonBackground()
        self.descFrames[#self.descFrames+1] = self:createDescFrame(self.playerFrames[#self.playerFrames])
        self:createRatingButtons(self.playerFrames[#self.playerFrames],self.descFrames[#self.descFrames])
        self:createNoteButtons(self.playerFrames[#self.playerFrames],self.descFrames[#self.descFrames])
        if #self.playerFrames == 1 then
            self.playerFrames[1]:SetPoint("TOPLEFT",self.titleFrame,"BOTTOMLEFT",0,0)
            self.descFrames[1]:SetPoint("LEFT",self.playerFrames[1],"RIGHT",20,0)
            self.buttonBackgrounds[1]:SetPoint("LEFT",self.descFrames[1],"RIGHT",0,0)
            self:setRatingButtons(self.playerFrames[1])
            self:setNoteButtons(self.playerFrames[1],1)
        else
            self.playerFrames[#self.playerFrames]:SetPoint("TOP",self.playerFrames[#self.playerFrames-1],"BOTTOM",0,-10)
            self.descFrames[#self.descFrames]:SetPoint("LEFT",self.playerFrames[#self.playerFrames],"RIGHT",20,0)
            self.buttonBackgrounds[#self.buttonBackgrounds]:SetPoint("LEFT",self.descFrames[#self.descFrames-1],"RIGHT",0,0)
            self:setRatingButtons(self.playerFrames[#self.playerFrames])
            self:setNoteButtons(self.playerFrames[#self.playerFrames],#self.playerFrames)
        end
    end
end

function MemberRememberer:setupNoteFrame()
    self.noteFrame.activeNote = 0

    self.noteFrame:SetPoint("BOTTOM",self,"TOP",0,0)

    self.noteFrame.WIDTH = 220
    self.noteFrame.HEIGHT = 150
    self.noteFrame:SetSize(220,130)

    self:createTitleFrame(self.noteFrame,"Note")
    self.noteFrame.Background = self.noteFrame:CreateTexture(nil,"BACKGROUND")
    self.noteFrame.Background:SetAllPoints(self.noteFrame)
    self.noteFrame.Background:SetColorTexture(self.BACKGROUND_COLORS[1],self.BACKGROUND_COLORS[2],self.BACKGROUND_COLORS[3],1)

    self.noteFrame.textBox = CreateFrame("EditBox", nil, self.noteFrame)
    self.noteFrame.textBox:SetSize(190,130)
    self.noteFrame.textBox:SetFontObject("ChatFontNormal")
    self.noteFrame.textBox:SetPoint("TOP",self.noteFrame.titleFrame,"BOTTOM",0,0)
    self.noteFrame.textBox:SetPoint("Bottom",self.noteFrame,"Bottom",0,10)
    self.noteFrame.textBox:SetMultiLine(true)
    self.noteFrame.textBox:SetMaxLetters(130)
    self.noteFrame.textBox:SetAutoFocus(false)
    self.noteFrame:Hide()
end

---@param playerFrame frame @The frame that the text is attached to
function MemberRememberer:createDescFrame(playerFrame)
    local frame = CreateFrame("Frame", nil, playerFrame)
    frame.skillText = frame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.attitudeText = frame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.skillText:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-2.5,-6)
    frame.attitudeText:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2.5,7)
    frame:SetSize(75,50)
    frame.Background = frame:CreateTexture(nil,"BACKGROUND")
    frame.Background:SetAllPoints(frame)
    frame.skillText:SetText("Skill:")
    frame.attitudeText:SetText("Attitude:")
    return frame
end

---@description Creates a name frame, sets up the background, points, size, etc, and returns it.
---@return frame @Returns a completely set up frame to put the names of the players in
function MemberRememberer:createNameFrame()
    local nameFrame = CreateFrame("Frame",nil,self)
    nameFrame.nameString = nameFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge",nil)
    nameFrame.nameString:SetPoint("CENTER",nameFrame,"CENTER",-12,0)
    nameFrame:SetSize(100,50)
    --nameFrame.nameString:SetText("Wwwwwwwwwwww")
    nameFrame.Background = nameFrame:CreateTexture(nil,"BACKGROUND")
    nameFrame.Background:SetAllPoints(nameFrame)
    return nameFrame
end

---@description Creates a background for behind the rating buttons
---@return frame @Returns a frame with the correct sized background for all of the rating buttons
function MemberRememberer:createButtonBackground()
    local buttonBackground = CreateFrame("Frame","ButtonBackground",self)
    buttonBackground:SetSize(self.WIDTH-395,50)
    buttonBackground.Background = buttonBackground:CreateTexture(nil, "BACKGROUND")
    buttonBackground.Background:SetAllPoints(buttonBackground)
    --buttonBackground.Background:SetColorTexture(self.BACKGROUND_COLORS[1]-0.1,self.BACKGROUND_COLORS[2]-0.1,self.BACKGROUND_COLORS[3]-0.1,self.BACKGROUND_COLORS[4])
    return buttonBackground
end

---@param playerframe frame @The frame that the rati/ng buttons are children of
---@param descFrame frame @The frame that the rating buttons are attached to
function MemberRememberer:createRatingButtons(playerFrame,descFrame)
    playerFrame.skillRatingButtons = playerFrame.skillRatingButtons or {}
    playerFrame.attitudeRatingButtons = playerFrame.attitudeRatingButtons or {}

    for i=1,5 do
        playerFrame.skillRatingButtons[i] = CreateFrame("Button",nil,playerFrame)
        playerFrame.attitudeRatingButtons[i] = CreateFrame("Button",nil,playerFrame)
        self:setDefaultButtonTextures(playerFrame.skillRatingButtons[i],"Interface\\Buttons\\UI-Checkbox",i,0,0,false)
        self:setDefaultButtonTextures(playerFrame.attitudeRatingButtons[i],"Interface\\Buttons\\UI-Checkbox",i,0,0,false)
        playerFrame.skillRatingButtons[i]:SetSize(25,25)
        playerFrame.attitudeRatingButtons[i]:SetSize(25,25)
        if i == 1 then
            playerFrame.skillRatingButtons[i]:SetPoint("TOPLEFT", descFrame,"TOPRIGHT",0,0)
            playerFrame.attitudeRatingButtons[i]:SetPoint("BOTTOMLEFT",descFrame,"BOTTOMRIGHT",0,0)
        else
            playerFrame.skillRatingButtons[i]:SetPoint("LEFT",playerFrame.skillRatingButtons[i-1],"RIGHT",2,0)
            playerFrame.attitudeRatingButtons[i]:SetPoint("LEFT",playerFrame.attitudeRatingButtons[i-1],"RIGHT",2,0)
        end
    end
end

---@param playerframe frame @The frame that the rati/ng buttons are children of
---@param descFrame frame @The frame that the rating buttons are attached to
function MemberRememberer:createNoteButtons(playerFrame, descFrame)
    playerFrame.noteButton = playerFrame.noteButton or CreateFrame("Button",nil,playerFrame)
    playerFrame.noteButton:SetNormalAtlas("Campaign-QuestLog-LoreBook",true)
    playerFrame.noteButton:SetHighlightAtlas("Campaign-QuestLog-LoreBook-Highlight","BLEND")
    playerFrame.noteButton:SetPushedAtlas("Campaign-QuestLog-LoreBook-Glow")

    playerFrame.noteButton:SetSize(35,35)
    playerFrame.noteButton:SetPoint("LEFT",descFrame,"RIGHT",140,0)
end
    

---@param button frame @The button to set to default
---@param buttonPath string @The url/path to the default texture to use. Needs to have an up, highlight, and down version.
---@param ratingNumber any @The number of the rating number (generally 1-5) Can also be any text or anything else that tostring() works on
---@param offx integer @The text x offset
---@param offy integer @The text y offset
---@param pushedTextOffset boolean @True if default pushedtextoffset, false if none
function MemberRememberer:setDefaultButtonTextures(button, buttonPath, ratingNumber, offx, offy, pushedTextOffset)
    local fs = self:CreateFontString(nil,"TEXT","GameFontNormal",button)
    local currentNum = tostring(ratingNumber)
    fs:SetPoint("CENTER",button,"CENTER",offx,offy)
    button:SetNormalTexture(buttonPath.."-Up")
    button:SetHighlightTexture(buttonPath.."-Highlight")
    button:SetPushedTexture(buttonPath.."-Down")
    button:SetFontString(fs)
    button:SetText(currentNum)
    if not pushedTextOffset then
        button:SetPushedTextOffset(0,0) --Makes it so the numbers don't move weirdly when clicked.
    end
end

---@param frame frame @The frame with the 5 skill & attitude buttons to set up the OnClick functionality for
function MemberRememberer:setRatingButtons(frame)
    frame.skillResult = 0
    frame.attitudeResult = 0
    for i=1,5 do
        frame.skillRatingButtons[i]:SetScript('OnClick', function()
            if frame.skillResult ~= i then
                frame.skillResult = i
                frame.skillRatingButtons[i]:SetButtonState("PUSHED","locked")
                for j=1,5 do
                    if i ~= j then
                        frame.skillRatingButtons[j]:SetButtonState("NORMAL")
                    end
                end
            else
                frame.skillResult = 0
                frame.skillRatingButtons[i]:SetButtonState("NORMAL")
            end
        end)

        frame.attitudeRatingButtons[i]:SetScript('OnClick', function()
            if frame.attitudeResult ~= i then
                frame.attitudeResult = i
                frame.attitudeRatingButtons[i]:SetButtonState("PUSHED","locked")
                for j=1,5 do
                    if i ~= j then
                        frame.attitudeRatingButtons[j]:SetButtonState("NORMAL")
                    end
                end
            else
                frame.attitudeResult = 0
                frame.attitudeRatingButtons[i]:SetButtonState("NORMAL")
            end
        end)
    end
end

---@param playerFrame frame @The player frame that everything is attached to
---@param currentFrame integer @The number of the playerFrame (1-5)
function MemberRememberer:setNoteButtons(playerFrame,currentFrame)
    playerFrame.noteButton:SetScript("OnClick", function()
        --Closing by clicking the same button
        if self.noteFrame.activeNote == currentFrame then
            playerFrame.note = self.noteFrame.textBox:GetText()
            playerFrame.noteButton:SetButtonState("NORMAL")
            self.noteFrame.activeNote = 0
            self.noteFrame:Hide()
            return
        end
        
        --Clicking a different button
        if self.noteFrame.activeNote ~= currentFrame then
            if self.noteFrame.activeNote ~= 0 then
                self.playerFrames[self.noteFrame.activeNote].note = self.noteFrame.textBox:GetText()
                self.playerFrames[self.noteFrame.activeNote].noteButton:SetButtonState("NORMAL")
            end
            if playerFrame.note then
                self.noteFrame.textBox:SetText(playerFrame.note)
            end
            self.noteFrame:ClearAllPoints()
            playerFrame.noteButton:SetButtonState("PUSHED","locked")
            self.noteFrame:SetPoint("LEFT", playerFrame.noteButton,"RIGHT",8,0)
            self.noteFrame.activeNote = currentFrame
            self.noteFrame:Show()
        end
    end)
end

---@param frame frame @The frame to create the accept/cancel buttons on
function MemberRememberer:createAcceptButtons(frame)
    local textOffX, textOffY = -18,5
    frame.acceptButton = CreateFrame("Button",nil,frame)
    self:setDefaultButtonTextures(frame.acceptButton, "Interface\\Buttons\\UI-Panel-Button","Accept",textOffX,textOffY,true)
    frame.acceptButton:SetSize(100,35)
    frame.acceptButton:SetPoint("BOTTOM", frame, "BOTTOM", -75-textOffX, 10-textOffY)

    frame.cancelButton = CreateFrame("Button",nil,frame)
    self:setDefaultButtonTextures(frame.cancelButton,"Interface\\Buttons\\UI-Panel-Button", "Cancel",textOffX,textOffY,true)
    frame.cancelButton:SetSize(100,35)
    frame.cancelButton:SetPoint("BOTTOM", frame, "BOTTOM", 75-textOffX, 10-textOffY)

    self:setupAcceptButtons(frame.acceptButton,frame.cancelButton)
end

---@param acceptButton frame @The accept button to set up
---@param cancelButton frame @The cancel button to set up
function MemberRememberer:setupAcceptButtons(acceptButton,cancelButton)
    acceptButton:SetScript('OnClick', function()
        self:saveRatings()
        self:Hide()
    end)

    cancelButton:SetScript('OnClick', function()
        self:Hide()
    end)
end

function MemberRememberer:saveRatings()
    if self.noteFrame.activeNote ~= 0 then
        self.playerFrames[self.noteFrame.activeNote].note = self.noteFrame.textBox:GetText()
        self.playerFrames[self.noteFrame.activeNote].noteButton:SetButtonState("NORMAL")
        self.noteFrame.activeNote = 0
    end
    for i=1,4 do
        if not MemberRememberer.playerFrames then
            return --Early out: Frames don't exist (why are you seeing the panel anyway)
        end
        if not MemberRememberer.playerFrames[i]:IsShown() then
            return --Finished saving all players
        end

        local name = MemberRememberer.playerFrames[i].name
        local skill = MemberRememberer.playerFrames[i].skillResult
        local attitude = MemberRememberer.playerFrames[i].attitudeResult
        local note = MemberRememberer.playerFrames[i].note

        local skillDB, attitudeDB, noteDB, playerNumber = self:getPlayer(MemberRememberer:addServerName(name))
        --If the player isn't in the database, add it
        local newPlayer = false
        if skillDB == 0 and attitudeDB == 0 and noteDB == "" and playerNumber == 0 then
            table.insert(MemberRemembererPlayerDB,{["player"] = self:addServerName(name), ["skill"] = skill, ["attitude"] = attitude, ["note"] = note})
            newPlayer = true
        end

        --If the player is in the database, update it
        if newPlayer == false then
            MemberRemembererPlayerDB[playerNumber].skill = skill
            MemberRemembererPlayerDB[playerNumber].attitude = attitude
            MemberRemembererPlayerDB[playerNumber].note = note
        end
    end
end

--TODO: Make gametooltip have the info it needs


---@param player string @The name of a player
---@return integer skill @The skill rating of the player. Returns 0 if none
---@return integer attitude @The attitude rating of the player. Returns 0 if none
---@return string note @The note on the player. Returns empty string if none
---@return integer playerNumber @The place in the table for the player found. Returns 0 if none
function MemberRememberer:getPlayer(player)
    local playerNumber = 0
    for i = 1, #MemberRemembererPlayerDB, 1 do
        if self:addServerName(player) == MemberRemembererPlayerDB[i].player then
            local skill = MemberRemembererPlayerDB[i].skill
            local attitude = MemberRemembererPlayerDB[i].attitude
            local note = MemberRemembererPlayerDB[i].note
            playerNumber = i
            return skill, attitude, note, playerNumber
        end
    end
    return 0, 0, "", 0
end

---@param originalName string @The name to remove the server from
---@return string name @The name w/ the server removed
function MemberRememberer:removeServerName(originalName)
    local name = string.match(originalName, "(.+)-")
    if not name then
        return originalName
    end
    return name
end

function MemberRememberer:addServerName(originalName)
    local name = ""
    if string.match(originalName,"(.+-.+)") then
        return originalName --Already has the correct name type
    end
    name = originalName .. "-" .. GetNormalizedRealmName()
    return name
end

MemberRememberer:OnLoad()