local t = Def.ActorFrame {
    Def.Sound {
        File=THEME:GetPathS("", "OpenCommandWindow"),
        CodeMessageCommand=function(self, params)
            if params.Name == "OpenOpList" then
                SCREENMAN:GetTopScreen():OpenOptionsList(params.PlayerNumber)
                self:play()
            end
        end
    },

    Def.Sound {
        File=THEME:GetPathS("", "CloseCommandWindow"),
        OptionsListClosedMessageCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "MoveCommandWindow"),
        OptionsListRightMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListLeftMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListQuickChangeMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("", "StartCommandWindow"),
        -- No idea why we need all of this. OptionsList sucks.
        OptionsListStartMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListResetMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListPopMessageCommand=function(self) self:queuecommand("Refresh") end,
        OptionsListPushMessageCommand=function(self) self:queuecommand("Refresh") end,
        RefreshCommand=function(self) self:play() end
    }
}

-- Special thanks to RhythmLunatic/Accelerator and ROAD24
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    -- This will allow us to determine the position of the list
    local OptionsListActor, OptionsListMenu
    
    t[#t+1] = Def.ActorFrame {
        InitCommand=function(self,params)
            self:xy(pn == PLAYER_1 and -200 or SCREEN_RIGHT + 200, SCREEN_CENTER_Y - 70)
        end,
        
        OnCommand=function(self)
            OptionsListActor = SCREENMAN:GetTopScreen():GetChild("OptionsList" .. pname(pn))
        end,
        
        -- Move the list around when opened/closed
        OptionsListOpenedMessageCommand=function(self, params)
            if params.Player == pn then
                self:stoptweening():easeoutexpo(0.5):x(pn == PLAYER_1 and 200 or SCREEN_RIGHT - 200)
            end
        end,
        
        OptionsListClosedMessageCommand=function(self, params)
            if params.Player == pn then 
                self:stoptweening():easeoutexpo(0.5):x(pn == PLAYER_1 and -200 or SCREEN_RIGHT + 200)
            end
        end,
        
        -- Make us able to view what menu we're in later (and also adjust its position)
        OptionsMenuChangedMessageCommand=function(self, params)
            if params.Player == pn then 
                OptionsListMenu = params.Menu
                
                self:playcommand("Adjust", params)
            end
        end,
        
        OptionsListLeftMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListRightMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListStartMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListQuickChangeMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        
        -- To avoid overflowing the list, we will hide the outer parts and
        -- dynamically move the entire list's vertical position relative
        -- to what the player is currently selecting
        AdjustCommand=function(self, params)
            if params.Player == pn then
                -- Edge case since we don't need to scroll in Speed Mods
                if params.Selection + 1 > 9  and OptionsListMenu ~= "AutoVelocity" then
                    OptionsListActor:stoptweening():linear(0.1):y(SCREEN_CENTER_Y - 180 - (26 * (params.Selection - 9)))
                else
                    OptionsListActor:stoptweening():linear(0.1):y(SCREEN_CENTER_Y - 180)
                end
            end
        end,
        
        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/Options"),
            InitCommand=function(self) self:zoom(0.7) end
        },
        
        -- Masks that will hide the off limits portion of the list, shhh
        Def.Quad {
            InitCommand=function(self) self:setsize(206, 170):xy(0, -205):MaskSource() end,
        },
        
        Def.Quad {
            InitCommand=function(self) self:setsize(206, 268):xy(0, 296):MaskSource() end,
        }
    }
end

return t
