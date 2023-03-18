local WheelSize = 13
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelItem = { Width = 212, Height = 120 }
local WheelSpacing = 250
local WheelRotation = 0.1

-- So that we can grab the Cur screen and use it outside an actor
local ScreenSelectMusic

-- Used for quitting the game
local IsHome = GAMESTATE:GetCoinMode() == "CoinMode_Home"
local IsEvent = GAMESTATE:IsEventMode()
local TickCount = 0 -- Used for InputEventType_Repeat

local IsOptionsList = { PLAYER_1 = false, PLAYER_2 = false }
local IsSelectingGroup = false
local IsBusy = false
local IsFocusedMain = false

-- Create the variables necessary for both wheels
local CurMainIndex = 1
local CurSubIndex = 1
local MainTargets = {}
local SubTargets = {}

-- This is to determine where are the original groups located
-- TODO: Not hardcode this
local OrigGroupIndex = 2

local function BlockScreenInput(State)
    SCREENMAN:set_input_redirected(PLAYER_1, State)
    SCREENMAN:set_input_redirected(PLAYER_2, State)
end

-- If no songs don't load anything
if SONGMAN:GetNumSongs() == 0 then
    return Def.Actor {}
else

-- Update Group item targets
local function UpdateMainItemTargets(val)
    for i = 1, WheelSize do
        MainTargets[i] = val + i - WheelCenter
        -- Wrap to fit to Songs list size
        while MainTargets[i] > #SortGroups do MainTargets[i] = MainTargets[i] - #SortGroups end
        while MainTargets[i] < 1 do MainTargets[i] = MainTargets[i] + #SortGroups end
    end
end

local function UpdateSubItemTargets(val)
    for i = 1, WheelSize do
        SubTargets[i] = val + i - WheelCenter
        -- Wrap to fit to Songs list size
        while SubTargets[i] > #SortGroups[CurMainIndex].SubGroups do SubTargets[i] = SubTargets[i] - #SortGroups[CurMainIndex].SubGroups end
        while SubTargets[i] < 1 do SubTargets[i] = SubTargets[i] + #SortGroups[CurMainIndex].SubGroups end
    end
end

-- Manages banner on sprite
function UpdateBanner(self, Banner)
    if Banner == "" then Banner = THEME:GetPathG("Common fallback", "banner") end
    self:Load(Banner):scaletofit(-WheelItem.Width / 2, -WheelItem.Height / 2, WheelItem.Width / 2, WheelItem.Height / 2)
end

local function InputHandler(event)
	local pn = event.PlayerNumber
    if not pn then return end
    
    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then 
        TickCount = 0 
        MESSAGEMAN:Broadcast("ExitTickDown")
        return
    end
    
    local button = event.button
    
    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end
    
    if IsSelectingGroup then
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
            if IsFocusedMain then
                CurMainIndex = CurMainIndex - 1
                if CurMainIndex < 1 then CurMainIndex = #SortGroups end
                UpdateMainItemTargets(CurMainIndex)
                
                if CurSubIndex < 1 then CurSubIndex = #SortGroups[CurMainIndex].SubGroups end
                UpdateSubItemTargets(CurSubIndex)
                
                MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
                MESSAGEMAN:Broadcast("ScrollSub", { Direction = 0 })
            else
                CurSubIndex = CurSubIndex - 1
                if CurSubIndex < 1 then CurSubIndex = #SortGroups[CurMainIndex].SubGroups end
                
                UpdateSubItemTargets(CurSubIndex)
                
                MESSAGEMAN:Broadcast("ScrollSub", { Direction = -1 })
            end
            
        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
            if IsFocusedMain then
                CurMainIndex = CurMainIndex + 1
                if CurMainIndex > #SortGroups then CurMainIndex = 1 end
                UpdateMainItemTargets(CurMainIndex)
                
                if CurSubIndex > #SortGroups[CurMainIndex].SubGroups then CurSubIndex = 1 end
                UpdateSubItemTargets(CurSubIndex)
                
                MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
                MESSAGEMAN:Broadcast("ScrollSub", { Direction = 0 })
            else
                CurSubIndex = CurSubIndex + 1
                if CurSubIndex > #SortGroups[CurMainIndex].SubGroups then CurSubIndex = 1 end
                
                UpdateSubItemTargets(CurSubIndex)
                
                MESSAGEMAN:Broadcast("ScrollSub", { Direction = 1 })
            end
        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            if IsFocusedMain then 
                IsFocusedMain = false
                if CurSubIndex > #SortGroups[CurMainIndex].SubGroups then CurSubIndex = 1 end
                UpdateSubItemTargets(CurSubIndex)
                MESSAGEMAN:Broadcast("RefreshHighlight") 
            else
                GroupIndex = CurMainIndex
                SubGroupIndex = CurSubIndex
                MESSAGEMAN:Broadcast("CloseGroupWheel")
            end
            
        elseif button == "UpRight" or button == "UpLeft" or button == "Up" then
            if not IsFocusedMain then 
                IsFocusedMain = true
                MESSAGEMAN:Broadcast("RefreshHighlight")
            elseif IsHome or IsEvent then 
                MESSAGEMAN:Broadcast("ExitPressed")
            end
        end

        if IsHome or IsEvent then
            if event.type == "InputEventType_Repeat" then
                if button == "UpLeft" or button == "UpRight" or button == "Up" then
                    TickCount = TickCount + 1
                    MESSAGEMAN:Broadcast("ExitTickUp")
                    if TickCount == 15 then
                        BlockScreenInput(false)
                        SCREENMAN:GetTopScreen():Cancel()
                    end
                end
            end
        end
    end
end

local t = Def.ActorFrame {
    InitCommand=function(self)
        self:fov(90):SetDrawByZPosition(true)
        :vanishpoint(SCREEN_CENTER_X, SCREEN_CENTER_Y):diffusealpha(0)
        UpdateMainItemTargets(CurMainIndex)
        UpdateSubItemTargets(CurSubIndex)
    end,

    OnCommand=function(self)
        BlockScreenInput(false)
        ScreenSelectMusic = SCREENMAN:GetTopScreen()
        ScreenSelectMusic:AddInputCallback(InputHandler)
    end,
    
    OffCommand=function(self) BlockScreenInput(false) end,
    
    SongChosenMessageCommand=function(self) self:queuecommand("Busy") end,
    SongUnchosenMessageCommand=function(self) self:sleep(0.01):queuecommand("NotBusy") end,
    
    OptionsListOpenedMessageCommand=function(self, params) IsOptionsList[params.Player] = true end,
    OptionsListClosedMessageCommand=function(self, params) IsOptionsList[params.Player] = false end,

    CodeMessageCommand=function(self, params)
        if params.Name == "GroupSelectPad1" or params.Name == "GroupSelectPad2" or 
        params.Name == "GroupSelectButton1" or params.Name == "GroupSelectButton2" then
            if not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then
                -- Prevent the song list from moving when transitioning
                BlockScreenInput(true)
                IsSelectingGroup = true
                MESSAGEMAN:Broadcast("OpenGroupWheel")
                self:finishtweening():easeoutexpo(1):diffusealpha(1)
            end
        end
    end,
    
    BusyCommand=function(self) IsBusy = true end,
    NotBusyCommand=function(self) IsBusy = false end,
    
    CloseGroupWheelMessageCommand=function(self)
        self:stoptweening():easeoutexpo(0.25):diffusealpha(0)
        
        BlockScreenInput(false)
        IsSelectingGroup = false
        
        -- The built in wheel needs to be told the group has been changed
        ScreenSelectMusic:PostScreenMessage("SM_SongChanged", 0 )
        MESSAGEMAN:Broadcast("StartSelectingSong")
    end,
    
    Def.Sprite {
        Name="Highlight",
        Texture=THEME:GetPathG("", "MusicWheel/FrameHighlight"),
        InitCommand=function(self)
            self:x(SCREEN_CENTER_X):y(SCREEN_CENTER_Y + (IsFocusedMain and -80 or 80)):z(1)
        end,
        RefreshHighlightMessageCommand=function(self)
            self:stoptweening():easeoutexpo(0.4):y(SCREEN_CENTER_Y + (IsFocusedMain and -80 or 80))
        end
    },

    Def.Sound {
        File=THEME:GetPathS("MusicWheel", "change"),
        IsAction=true,
        ScrollMainMessageCommand=function(self) self:play() end,
        ScrollSubMessageCommand=function(self, params) if params.Direction ~= 0 then self:play() end end
    },

    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        CloseGroupWheelMessageCommand=function(self) self:play() end
    },
}

-- The Wheel: originally made by Luizsan
-- First wheel will be responsible for the main options
for i = 1, WheelSize do
    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            -- Update banner text
            self:GetChild("BannerText"):settext(SortGroups[MainTargets[i]].Name)

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("ScrollMain", {Direction = 0})
        end,

        ScrollMainMessageCommand=function(self, params)
            self:stoptweening()

            -- Calculate position
            local xpos = SCREEN_CENTER_X + (i - WheelCenter) * WheelSpacing

            -- Calculate displacement based on input
            local displace = -params.Direction * WheelSpacing

            -- Only tween if a direction was specified
            local tween = params and params.Direction and math.abs(params.Direction) > 0
            
            -- Adjust and wrap actor index
            i = i - params.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- If it's an edge item, update banner text. Edge items should never tween
            if i == 1 or i == WheelSize then
				self:GetChild("BannerText"):settext(SortGroups[MainTargets[i]].Name)
            elseif tween then
                self:easeoutexpo(0.4)
            end

            -- Animate!
            self:xy(xpos + displace, SCREEN_CENTER_Y - 80)
            self:rotationy((SCREEN_CENTER_X - xpos - displace) * -WheelRotation)
            self:z(-math.abs(SCREEN_CENTER_X - xpos - displace) * 0.25)
        end,
        
        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/GradientBanner"),
            InitCommand=function(self) self:scaletoclipped(WheelItem.Width , WheelItem.Height) end
        },

        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/GroupFrame"),
        },
        
        Def.BitmapText {
            Name="BannerText",
            Font="Montserrat semibold 40px",
            InitCommand=function(self)
                self:zoom(0.75):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5)
            end,
        }
    }
end

-- Second wheel will be responsible for the sub groups
for i = 1, WheelSize do
    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            if CurMainIndex == OrigGroupIndex then
                self:GetChild("Banner"):visible(true)
                UpdateBanner(self:GetChild("Banner"), SortGroups[CurMainIndex].SubGroups[SubTargets[i]].Banner)
            else
                self:GetChild("Banner"):visible(false)
            end

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("ScrollSub", {Direction = 0})
        end,

        ScrollSubMessageCommand=function(self, params)
            self:stoptweening()

            -- Calculate position
            local xpos = SCREEN_CENTER_X + (i - WheelCenter) * WheelSpacing

            -- Calculate displacement based on input
            local displace = -params.Direction * WheelSpacing

            -- Only tween if a direction was specified
            local tween = params and params.Direction and math.abs(params.Direction) > 0
            
            -- Adjust and wrap actor index
            i = i - params.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- Edge items should never tween
            if i == 1 or i == WheelSize then
				
            elseif tween then
                self:easeoutexpo(0.4)
            end

            -- Animate!
            self:xy(xpos + displace, SCREEN_CENTER_Y + 80)
            self:rotationy((SCREEN_CENTER_X - xpos - displace) * -WheelRotation)
            self:z(-math.abs(SCREEN_CENTER_X - xpos - displace) * 0.25)
            
            -- Force update banners because of how the sub wheel is now refreshed
            if CurMainIndex == OrigGroupIndex then
                self:GetChild("Banner"):visible(true)
                UpdateBanner(self:GetChild("Banner"), SortGroups[CurMainIndex].SubGroups[SubTargets[i]].Banner)
            else
                self:GetChild("Banner"):visible(false)
            end
            
            -- Refresh actors below
            self:GetChild("GroupInfo"):playcommand("Refresh")
            self:GetChild(""):GetChild("Index"):playcommand("Refresh")
        end,
        
        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/GradientBanner"),
            InitCommand=function(self) self:scaletoclipped(WheelItem.Width, WheelItem.Height) end
        },
        
        Def.Banner {
            Name="Banner",
        },

        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/GroupFrame"),
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
                RefreshCommand=function(self, params) self:settext(SubTargets[i]) end
            }
        },
        
        Def.BitmapText {
            Name="GroupInfo",
            Font="Montserrat semibold 40px",
            InitCommand=function(self)
                self:y(CurMainIndex == OrigGroupIndex and 64 or -8):zoom(0.5):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5)
                :maxwidth(420):vertalign(0):wrapwidthpixels(420):vertspacing(-16)
            end,
            RefreshCommand=function(self, params) 
                self:settext(SortGroups[CurMainIndex].SubGroups[SubTargets[i]].Name) 
                :y(CurMainIndex == OrigGroupIndex and 64 or -8)
            end
        }
    }
end

t[#t+1] = Def.ActorFrame {
    Def.BitmapText {
        Font="Montserrat semibold 20px",
        Name="ExitText",
        InitCommand=function(self)
            self:diffusealpha(0)
            :xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 125)
            :settext("Exiting...")
        end,
        ExitPressedMessageCommand=function(self)
            self:stoptweening():sleep(0.1)
            :linear(0.25)
            :diffusealpha(1)
        end,
        ExitTickDownMessageCommand=function(self)
            self:stoptweening()
            :easeoutexpo(0.25)
            :diffusealpha(0)
        end
    },

    Def.Quad {
        Name="ExitBar",
        InitCommand=function(self)
            self:zoomto(200,15)
            :cropright(1)
            :xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 100)
            :diffuse(color("#f7931e")):diffusebottomedge(color("#ed1e79"))
        end,
        ExitTickUpMessageCommand=function(self)
            self:stoptweening()
            :linear(0.2)
            :cropright(1 - (TickCount + 1) / 15)
        end,
        ExitTickDownMessageCommand=function(self)
            self:stoptweening()
            :easeoutexpo(0.25)
            :cropright(1)
        end
    },

    Def.Quad {
        Name="ExitBarEnd",
        InitCommand=function(self)
            self:zoomto(5,15)
            :xy(SCREEN_CENTER_X - 100, SCREEN_CENTER_Y - 100)
            :diffuse(1,1,1,0)
        end,
        ExitPressedMessageCommand=function(self)
            self:sleep(0.2)
            :diffusealpha(1)
            :easeoutquad(0.5)
            :x(SCREEN_CENTER_X + 100)
        end,
        ExitTickDownMessageCommand=function(self)
            self:stoptweening()
            :easeoutquad(0.25)
            :diffusealpha(0)
            :x(SCREEN_CENTER_X - 100)
        end
    }
}

return t

end