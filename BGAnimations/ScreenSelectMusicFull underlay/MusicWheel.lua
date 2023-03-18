local WheelSize = 13
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelItem = { Width = 212, Height = 120 }
local WheelSpacing = 250
local WheelRotation = 0.1

local Songs = {}
local Targets = {}

-- Not load anything if no group sorts are available (catastrophic event or no songs)
if next(SortGroups) == nil then
    return Def.Actor {}
else

local SongIndex = 1
local IsBusy = false

-- Default is to start at All for now
Songs = SortGroups[1].SubGroups[1].Songs

-- Update Songs item targets
local function UpdateItemTargets(val)
    for i = 1, WheelSize do
        Targets[i] = val + i - WheelCenter
        -- Wrap to fit to Songs list size
        while Targets[i] > #Songs do Targets[i] = Targets[i] - #Songs end
        while Targets[i] < 1 do Targets[i] = Targets[i] + #Songs end
    end
end

local function InputHandler(event)
	local pn = event.PlayerNumber
    if not pn then return end
    
    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then return end

    local button = event.button
    
    -- If an unjoined player attempts to join and has enough credits, join them
    if (button == "Center" or (not IsGame("pump") and button == "Start")) and 
        not GAMESTATE:IsSideJoined(pn) and GAMESTATE:GetCoins() >= GAMESTATE:GetCoinsNeededToJoin() then
        GAMESTATE:JoinPlayer(pn)
        -- The command above does not deduct credits so we'll do it ourselves
        GAMESTATE:InsertCoin(-(GAMESTATE:GetCoinsNeededToJoin()))
        MESSAGEMAN:Broadcast("PlayerJoined", { Player = pn })
    end

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if not IsBusy then
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
            SongIndex = SongIndex - 1
            if SongIndex < 1 then SongIndex = #Songs end
            
            GAMESTATE:SetCurrentSong(Songs[SongIndex])
            UpdateItemTargets(SongIndex)
            MESSAGEMAN:Broadcast("Scroll", { Direction = -1 })

        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
            SongIndex = SongIndex + 1
            if SongIndex > #Songs then SongIndex = 1 end
            
            GAMESTATE:SetCurrentSong(Songs[SongIndex])
            UpdateItemTargets(SongIndex)
            MESSAGEMAN:Broadcast("Scroll", { Direction = 1 })
            
        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            MESSAGEMAN:Broadcast("MusicWheelStart")

        elseif button == "Back" then
            SCREENMAN:GetTopScreen():Cancel()
        end
    end

	MESSAGEMAN:Broadcast("UpdateMusic")
end

-- Manages banner on sprite
local function UpdateBanner(self, Song)
    self:LoadFromSongBanner(Song):scaletoclipped(WheelItem.Width, WheelItem.Height)
end

local t = Def.ActorFrame {
    InitCommand=function(self)
        self:y(SCREEN_HEIGHT / 2 + 155):fov(90):SetDrawByZPosition(true)
        :vanishpoint(SCREEN_CENTER_X, SCREEN_BOTTOM - 150)
        UpdateItemTargets(SongIndex)
    end,

    OnCommand=function(self)
        GAMESTATE:SetCurrentSong(Songs[SongIndex])
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)

        self:easeoutexpo(1):y(SCREEN_HEIGHT / 2 - 150)
    end,
    
    -- Race condition workaround (yuck)
    MusicWheelStartMessageCommand=function(self) self:sleep(0.01):queuecommand("Confirm") end,
    ConfirmCommand=function(self) MESSAGEMAN:Broadcast("SongChosen") end,

    -- These are to control the functionality of the music wheel
    SongChosenMessageCommand=function(self)
        self:stoptweening():easeoutexpo(1):y(SCREEN_HEIGHT / 2 + 150)
        :playcommand("Busy")
    end,
    SongUnchosenMessageCommand=function(self)
        self:stoptweening():easeoutexpo(0.5):y(SCREEN_HEIGHT / 2 - 150)
        :playcommand("NotBusy")
    end,
    
    OpenGroupWheelMessageCommand=function(self) IsBusy = true end,
    CloseGroupWheelMessageCommand=function(self) 
        -- Grab the new list of songs from the selected group
        Songs = SortGroups[GroupIndex].SubGroups[SubGroupIndex].Songs
        -- Reset back to the first song of the list
        SongIndex = 1
        GAMESTATE:SetCurrentSong(Songs[SongIndex])
        -- Update wheel yada yada
        UpdateItemTargets(SongIndex)
        MESSAGEMAN:Broadcast("ForceUpdate")
        self:sleep(0.01):queuecommand("NotBusy")
    end,
    
    BusyCommand=function(self) IsBusy = true end,
    NotBusyCommand=function(self) IsBusy = false end,
    
    -- Play song preview (thanks Luizsan)
    Def.Actor {
        CurrentSongChangedMessageCommand=function(self)
            SOUND:StopMusic()
            self:stoptweening():sleep(0.25):queuecommand("PlayMusic")
        end,
        
        PlayMusicCommand=function(self)
            local Song = GAMESTATE:GetCurrentSong()
            if Song then
                SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(), Song:GetSampleLength(), 0, 1, false, false, false, Song:GetTimingData())
            end
        end
    },

    Def.Sound {
        File=THEME:GetPathS("MusicWheel", "change"),
        IsAction=true,
        ScrollMessageCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        MusicWheelStartMessageCommand=function(self) self:play() end
    },
}

-- The Wheel: originally made by Luizsan
for i = 1, WheelSize do

    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            -- Load banner
            UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
        end,
		
		ForceUpdateMessageCommand=function(self)
			-- Load banner
            UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
            
            --SCREENMAN:SystemMessage(SortGroups[GroupIndex].Name)

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
		end,

        ScrollMessageCommand=function(self,param)
            -- Save this so that we can resume the last selection after gameplay
            LastSongIndex = SongIndex
            
            self:stoptweening()

            -- Calculate position
            local xpos = SCREEN_CENTER_X + (i - WheelCenter) * WheelSpacing

            -- Calculate displacement based on input
            local displace = -param.Direction * WheelSpacing

            -- Only tween if a direction was specified
            local tween = param and param.Direction and math.abs(param.Direction) > 0
            
            -- Adjust and wrap actor index
            i = i - param.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- If it's an edge item, load a new banner. Edge items should never tween
            if i == 2 or i == WheelSize - 1 then
				UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
            elseif tween then
                self:easeoutexpo(0.4)
            end

            -- Animate!
            self:xy(xpos + displace, SCREEN_CENTER_Y)
            self:rotationy((SCREEN_CENTER_X - xpos - displace) * -WheelRotation)
            self:z(-math.abs(SCREEN_CENTER_X - xpos - displace) * 0.25)
            self:GetChild(""):GetChild("Index"):playcommand("Refresh")
        end,

        Def.Banner {
            Name="Banner",
        },

        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/SongFrame"),
        },

        Def.ActorFrame {
            Def.Quad {
                InitCommand=function(self)
                    self:zoomto(60, 18):addy(-50)
                    :diffuse(0,0,0,0.6)
                    :fadeleft(0.3):faderight(0.3)
                end
            },

            Def.BitmapText {
                Name="Index",
                Font="Montserrat semibold 40px",
                InitCommand=function(self)
                    self:addy(-50):zoom(0.4):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5)
                end,
                RefreshCommand=function(self,param) self:settext(Targets[i]) end
            }
        }
    }
end

return t

end