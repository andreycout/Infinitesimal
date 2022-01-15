local FrameW = 512
local FrameH = 76

return Def.ActorFrame {
    InitCommand=function(self)
        local Song = GAMESTATE:GetCurrentSong()
        if Song then
            local TitleText = Song:GetDisplayFullTitle()
            if TitleText == "" then TitleText = "Unknown" end

            local AuthorText = Song:GetDisplayArtist()
            if AuthorText == "" then AuthorText = "Unknown" end

            local BPMRaw = Song:GetDisplayBpms()
            local BPMLow = math.ceil(BPMRaw[1])
            local BPMHigh = math.ceil(BPMRaw[2])
            local BPMDisplay = (BPMLow == BPMHigh and BPMHigh or BPMLow .. "-" .. BPMHigh)

            if Song:IsDisplayBpmRandom() or BPMDisplay == 0 then BPMDisplay = "???" end
            
            self:GetChild("Title"):settext(TitleText)
            self:GetChild("Artist"):settext(AuthorText)
            self:GetChild("Length"):settext(SecondsToMMSS(Song:MusicLengthSeconds()))
            self:GetChild("BPM"):settext(BPMDisplay .. " BPM")
        else
            self:GetChild("Title"):settext("")
            self:GetChild("Artist"):settext("")
            self:GetChild("Length"):settext("")
            self:GetChild("BPM"):settext("")
        end
    end,
    
    Def.Sprite {
        Texture=THEME:GetPathG("", "Evaluation/EvalSongInfo")
    },
    
    Def.BitmapText {
        Font="Montserrat semibold 40px",
        Name="Title",
        InitCommand=function(self)
            self:zoom(0.7):valign(0)
            :maxwidth(FrameW * 0.85 / self:GetZoom())
            :diffuse(Color.Black)
            :y(-28)
        end
    },
    
    Def.BitmapText {
        Font="Montserrat normal 40px",
        Name="Artist",
        InitCommand=function(self)
            self:zoom(0.5):valign(1)
            :maxwidth(FrameW * 0.5 / self:GetZoom())
            :diffuse(Color.Black)
            :y(14)
        end
    },

    Def.BitmapText {
        Font="Montserrat normal 20px",
        Name="Length",
        InitCommand=function(self)
            self:zoom(0.8):halign(1):valign(1)
            :maxwidth(FrameW * 0.2 / self:GetZoom())
            :diffuse(Color.Black)
            :xy(FrameW / 2 - 36, 14)
        end
    }, 

    Def.BitmapText {
        Font="Montserrat normal 20px",
        Name="BPM",
        InitCommand=function(self)
            self:zoom(0.8):halign(0):valign(1)
            :maxwidth(FrameW * 0.175 / self:GetZoom())
            :diffuse(Color.Black)
            :xy(-FrameW / 2 + 36, 14)
        end
    }
}