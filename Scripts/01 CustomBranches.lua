-- Fallback fix
Branch.TitleMenu = function()
    -- home mode is the most assumed use of sm-ssc.
    if GAMESTATE:GetCoinMode() == "CoinMode_Home" then
        return "ScreenTitleMenu"
    end
    -- arcade junk:
    if GAMESTATE:GetCoinsNeededToJoin() > GAMESTATE:GetCoins() then
        -- if no credits are inserted, don't show the Join screen. SM4 has
        -- this as the initial screen, but that means we'd be stuck in a
        -- loop with ScreenInit. No good.
        return "ScreenLogo"
    else
        return "ScreenTitleJoin"
    end
end

function SelectMusicOrCourse()
    if GAMESTATE:IsCourseMode() then
        return "ScreenSelectCourse"
    elseif getenv("IsBasicMode") then
        return "ScreenSelectMusicBasic"
    else
        return "LuaSelectMusic"
    end
end

function ToLoadOrNotToLoad()
    if GAMESTATE:IsAnyHumanPlayerUsingMemoryCard() then
        return "ScreenProfileLoad"
    else
        return SelectMusicOrCourse()
    end
end

CustomBranch = {
    StartGame = function()
        if SONGMAN:GetNumSongs() == 0 and SONGMAN:GetNumAdditionalSongs() == 0 then
            return "ScreenHowToInstallSongs"
        end
        if PROFILEMAN:GetNumLocalProfiles() > 0 then
            return "ScreenSelectProfile"
        else
            return "ScreenSelectMusicBasic"
        end
    end,
    AfterSelectProfile = function()
        if PROFILEMAN:IsPersistentProfile(PLAYER_1) or PROFILEMAN:IsPersistentProfile(PLAYER_2) or GAMESTATE:IsAnyHumanPlayerUsingMemoryCard() then
            setenv("IsBasicMode", false)
        else
            setenv("IsBasicMode", true)
        end
        return ToLoadOrNotToLoad()
    end,
    AfterProfileSave = function()
        if GAMESTATE:IsEventMode() then
            return SelectMusicOrCourse()
        elseif STATSMAN:GetCurStageStats():AllFailed() or
            GAMESTATE:GetSmallestNumStagesLeftForAnyHumanPlayer() == 0 then
            return GameOverOrContinue()
        else
            return SelectMusicOrCourse()
        end
    end,

}
