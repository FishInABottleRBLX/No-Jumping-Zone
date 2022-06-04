return {

    -- All data involving stages.
    StageInformation = {
        CurrentCheckpoint = 1,  -- The checkpoint the user is currently at.
        FarthestCheckpoint = 1, -- The farthest checkpoint the user has reached.
        CompletedStages = {1},   -- An array of all the stages the user has completed.
        CompletedBonusStages = {},  -- An array of all the bonus stages the user has completed.
        BonusStageName = "",    -- If the user is playing a bonus stage this will be the name of the bonus stage.
        BonusStageCheckpoint = 1,   -- The checkpoint within the bonus stage the user is inside.
    }
}
