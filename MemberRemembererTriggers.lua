--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...);
end

MemberRememberer:RegisterEvent("CHALLENGE_MODE_RESET")
MemberRememberer:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local inActiveDungeon = false
local activeDungeon = 0
local activeGroup = {}
local groupType = ""

MemberRememberer:SetScript("OnEvent", function(MemberRememberer,event,...)
    if event == "CHALLENGE_MODE_RESET" then
        --debugPrint("CHALLENGE_MODE_RESET happened")

        if not GetHomePartyInfo() then
            --debugPrint("Not with people")
            return --Early out: Not w/ people
        end

        _,groupType,_,_,_, _,_,activeDungeon,_,_ = GetInstanceInfo()
        if groupType ~= "party" then
            return
        end
        inActiveDungeon = true

        --Under the assumption atm that challenge mode is ONLY M+, which has only one group of 5 (including you)
        activeGroup = GetHomePartyInfo()

        --First delete all names
        for i=1,4 do
            MemberRememberer.playerFrames[i].nameString:SetText("")
            MemberRememberer.playerFrames[i]:Show()
        end

        --Add in the names
        for i=1,4 do
            if not activeGroup[i] then
                for j=i,4 do
                    MemberRememberer.playerFrames[j]:Hide()
                    MemberRememberer.playerFrames[j].skillResult = 0
                    MemberRememberer.playerFrames[j].attitudeResult = 0
                    MemberRememberer.playerFrames[j].note = ""
                end
                break
            end
            MemberRememberer.playerFrames[i].nameString:SetText(MemberRememberer:removeServerName(activeGroup[i])) --Set their name in the UI
            local skill, attitude, note, _ = MemberRememberer:getPlayer(activeGroup[i]) --Check if they're in the database. Returns their values. 0s if not.
            MemberRememberer.playerFrames[i].name = MemberRememberer:addServerName(activeGroup[i])
            MemberRememberer.playerFrames[i].skillResult = skill
            MemberRememberer.playerFrames[i].attitudeResult = attitude
            MemberRememberer.playerFrames[i].note = note
            if skill ~= 0 then
                MemberRememberer.playerFrames[i].skillRatingButtons[skill]:SetButtonState("PUSHED","locked")
            end
            for j=1,5 do
                if skill ~= j then
                        MemberRememberer.playerFrames[i].skillRatingButtons[j]:SetButtonState("NORMAL")
                end
            end
            if attitude ~= 0 then
                    MemberRememberer.playerFrames[i].attitudeRatingButtons[attitude]:SetButtonState("PUSHED","locked")
            end
            for j=1,5 do
                    if attitude ~= j then
                        MemberRememberer.playerFrames[i].attitudeRatingButtons[j]:SetButtonState("NORMAL")
                    end
            end
        end
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        
        -----Possible firings----- 
        --Any general loadscreen (Ignore all of them)
            --Dealt with by checking currentDungeon vs activeDungeon.
        --Leaving a dungeon
            --Dealt with by checking currentDungeon vs activeDungeon and if you were inActiveDungeon before.
        --Entering the same dungeon with the same group (still in progress)
            --Dealt with by making sure you're in the same dungeon, also with the same party.
        --Entering the same dungeon with a different group (New)
            --Dealt with by seeing you're in the same dungeon but with a different party. IE: Do nothing.
        --Entering a different dungeon
            --Dealt with by checking currentDungeon vs activeDungeon
        --Summoned to another dungeon from active dungeon
            --Dealt with by checking currentDungeon vs activeDungeon and if you were inActiveDungeon before.


        local _,currentGroupType,_,_,_, _,_,currentDungeon,_,_ = GetInstanceInfo()
        --debugPrint(inActiveDungeon)
        --debugPrint(currentDungeon)
        if currentDungeon ~= activeDungeon and inActiveDungeon == true then
            MemberRememberer:Show()
            inActiveDungeon = false
            return
        end

        if currentDungeon ~= activeDungeon then
            inActiveDungeon = false
            return
        end

        if GetHomePartyInfo() and GetHomePartyInfo() == activeGroup and currentDungeon == activeDungeon and inActiveDungeon == false then
            MemberRememberer:Hide()
            inActiveDungeon = true
            return
        end
    end


end)

MemberRememberer.noteFrame.textBox:SetScript("OnEscapePressed", function()
    MemberRememberer.noteFrame.textBox:ClearFocus()
    MemberRememberer.noteFrame.textBox:SetAutoFocus(false)
end)

MemberRememberer.noteFrame.textBox:SetScript("OnEnterPressed", function()
    MemberRememberer.noteFrame.textBox:ClearFocus()
    MemberRememberer.noteFrame.textBox:SetAutoFocus(false)
end)