-- Our main table which will contain all sorted groups.
SortGroups = {}

local function GetValue(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

local function HasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

local function SortSongsByTitle(a, b)
    return ToLower(a:GetTranslitFullTitle()) < ToLower(b:GetTranslitFullTitle())
end

function PlayableSongs(SongList)
	local SongTable = {}
	for Song in ivalues(SongList) do
        local Steps = SongUtil.GetPlayableSteps(Song)
		if #Steps > 0 then
			SongTable[#SongTable+1] = Song
		end
	end
	return SongTable
end

function RunGroupSorting()
    Trace("Creating group sorts....")
    
	if not (SONGMAN and GAMESTATE) then
        Warn("SONGMAN or GAMESTATE were not ready! Aborting!")
        return
    end
	
	-- Empty current table
	SortGroups = {}
    
    -- ======================================== All songs ========================================
    local AllSongs = PlayableSongs(SONGMAN:GetAllSongs())
    
    SortGroups[#SortGroups + 1] = {
        Name = "All",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        SubGroups = {
            {   
                Name = "All",
                Banner = THEME:GetPathG("", "Common fallback banner"),
                Songs = AllSongs
            }
        }
    }
    
    Trace("Group added: " .. SortGroups[#SortGroups].Name .. "/" .. 
    SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups].Name)

    -- ======================================== Song groups ========================================
	local SongGroups = {}
    SortGroups[#SortGroups + 1] = {
        Name = "Group",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        SubGroups = {}
    }

	-- Iterate through the song groups and check if they have AT LEAST one song with valid charts.
	-- If so, add them to the group.
	for GroupName in ivalues(SONGMAN:GetSongGroupNames()) do
		for Song in ivalues(SONGMAN:GetSongsInGroup(GroupName)) do
			local Steps = SongUtil.GetPlayableSteps(Song)
			if #Steps > 0 then
				SongGroups[#SongGroups + 1] = GroupName
				break
			end
		end
	end
    
	for i, v in ipairs(SongGroups) do
		SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups + 1] = {
			Name = SongGroups[i],
			Banner = SONGMAN:GetSongGroupBannerPath(SongGroups[i]),
			Songs = PlayableSongs(SONGMAN:GetSongsInGroup(SongGroups[i]))
		}
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name .. "/" .. 
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups].Name)
	end
    
    --[[ Remove these for now since ToUpper crashes with Hangul chars
    -- ======================================== Song titles ========================================
    local Alphabet = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"}
    local TitleGroups = {}
    local SongInserted = false
    SortGroups[#SortGroups + 1] = {
        Name = "Title",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        SubGroups = {}
    }
    
    for j, Song in ipairs(AllSongs) do
        SongInserted = false
        for i, Letter in ipairs(Alphabet) do
            
            if ToUpper(Song:GetDisplayMainTitle():sub(1, 1)) == Letter then
                if TitleGroups[Letter] == nil then TitleGroups[Letter] = {} end
                table.insert(TitleGroups[Letter], Song)
                SongInserted = true
                break
            end
		end
        
        if SongInserted == false then
            if TitleGroups["#"] == nil then TitleGroups["#"] = {} end
            table.insert(TitleGroups["#"], Song)
        end
    end
    
    for i, v in pairs(Alphabet) do
        if TitleGroups[v] ~= nil then
            table.sort(TitleGroups[v], SortSongsByTitle)
            SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups + 1] = {
                Name = v,
                Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
                Songs = TitleGroups[v],
            }
        end
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name .. "/" .. 
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups].Name)
	end
    
    -- ======================================== Song artists ========================================
    local ArtistGroups = {}
    local SongInserted = false
    SortGroups[#SortGroups + 1] = {
        Name = "Artist",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        SubGroups = {}
    }
    
    for j, Song in ipairs(AllSongs) do
        SongInserted = false
        
        for i, Letter in ipairs(Alphabet) do
            if ToUpper(Song:GetDisplayArtist():sub(1, 1)) == Letter then
                if ArtistGroups[Letter] == nil then ArtistGroups[Letter] = {} end
                table.insert(ArtistGroups[Letter], Song)
                SongInserted = true
                break
            end
		end
        
        if SongInserted == false then
            if ArtistGroups["#"] == nil then ArtistGroups["#"] = {} end
            table.insert(ArtistGroups["#"], Song)
        end
    end
    
    for i, v in pairs(Alphabet) do
        if ArtistGroups[v] ~= nil then
            table.sort(ArtistGroups[v], SortSongsByTitle)
            SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups + 1] = {
                Name = v,
                Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
                Songs = ArtistGroups[v],
            }
        end
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name .. "/" .. 
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups].Name)
	end
    ]]
    
    -- ======================================== Single levels ========================================
    local LevelGroups = {}
    SortGroups[#SortGroups + 1] = {
        Name = "Single",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        SubGroups = {}
    }
    
    for j, Song in ipairs(AllSongs) do
        for i, Chart in ipairs(SongUtil.GetPlayableSteps(Song)) do
            if ToEnumShortString(ToEnumShortString(Chart:GetStepsType())) == "Single" then
                local ChartLevel = Chart:GetMeter()
                if LevelGroups[ChartLevel] == nil then LevelGroups[ChartLevel] = {} end
                if not HasValue(LevelGroups[ChartLevel], Song) then
                table.insert(LevelGroups[ChartLevel], Song) end
            end
		end
    end
    
    for i, v in PairsByKeys(LevelGroups) do
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups + 1] = {
            Name = "Single " .. i,
            Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
            Songs = v,
        }
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name .. "/" .. 
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups].Name)
	end
    
    -- ======================================== Double levels ========================================
    LevelGroups = {}
    SortGroups[#SortGroups + 1] = {
        Name = "Double",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        SubGroups = {}
    }
    
    for j, Song in ipairs(AllSongs) do
        for i, Chart in ipairs(SongUtil.GetPlayableSteps(Song)) do
            if ToEnumShortString(ToEnumShortString(Chart:GetStepsType())) == "Double" then
                local ChartLevel = Chart:GetMeter()
                if LevelGroups[ChartLevel] == nil then LevelGroups[ChartLevel] = {} end
                if not HasValue(LevelGroups[ChartLevel], Song) then
                table.insert(LevelGroups[ChartLevel], Song) end
            end
		end
    end
    
    for i, v in PairsByKeys(LevelGroups) do
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups + 1] = {
            Name = "Double " .. i,
            Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
            Songs = v,
        }
        
        Trace("Group added: " .. SortGroups[#SortGroups].Name .. "/" .. 
        SortGroups[#SortGroups].SubGroups[#SortGroups[#SortGroups].SubGroups].Name)
	end
	
	Trace("Group sorting done!")
end