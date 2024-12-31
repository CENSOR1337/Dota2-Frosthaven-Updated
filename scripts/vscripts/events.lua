function CHoldout:OnNPCSpawned(event)
    local spawnedUnit = EntIndexToHScript(event.entindex)
    if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
        return
    end

    if spawnedUnit:IsRealHero() then
        spawnedUnit:SetNightTimeVisionRange(HERO_NIGHTTIME_VISION_RANGE)
    end

    if spawnedUnit:IsCreature() then
        spawnedUnit:SetHPGain(spawnedUnit:GetMaxHealth() * 0.3 * GAME_DIFFICULTY_FACTOR) -- LEVEL SCALING VALUE FOR HP
        spawnedUnit:SetManaGain(0)
        spawnedUnit:SetHPRegenGain(0)
        spawnedUnit:SetManaRegenGain(0)
        if spawnedUnit:IsRangedAttacker() then
            spawnedUnit:SetDamageGain(((spawnedUnit:GetBaseDamageMax() + spawnedUnit:GetBaseDamageMin()) / 2) * 0.1 *
                                          GAME_DIFFICULTY_FACTOR) -- LEVEL SCALING VALUE FOR DPS
        else
            spawnedUnit:SetDamageGain(((spawnedUnit:GetBaseDamageMax() + spawnedUnit:GetBaseDamageMin()) / 2) * 0.2 *
                                          GAME_DIFFICULTY_FACTOR) -- LEVEL SCALING VALUE FOR DPS
        end
        spawnedUnit:SetArmorGain(0)
        spawnedUnit:SetMagicResistanceGain(0)
        spawnedUnit:SetDisableResistanceGain(0)
        spawnedUnit:SetAttackTimeGain(0)
        spawnedUnit:SetMoveSpeedGain(0)
        spawnedUnit:SetBountyGain(0)
        spawnedUnit:SetXPGain(0)

        if (GAME_DIFFICULTY_FACTOR > 0) then
            spawnedUnit:CreatureLevelUp(1)
        end
    end

end

--------------------------------------------------------------------------------

function CHoldout:OnEntityKilled(event)
    local attackerUnit = EntIndexToHScript(event.entindex_attacker or -1)
    local killedUnit = EntIndexToHScript(event.entindex_killed)

    if killedUnit and killedUnit:IsRealHero() and (killedUnit:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
        self:OnEntityKilled_PlayerHero(event)
        return
    end

    -- lasthit sound and particle
    if killedUnit and killedUnit:IsCreature() then
        if attackerUnit and attackerUnit:IsRealHero() then
            EmitSoundOnClient("DarkMoonLastHit", attackerUnit:GetPlayerOwner())
            ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticleForPlayer(
                "particles/dark_moon/darkmoon_last_hit_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, killedUnit,
                attackerUnit:GetPlayerOwner()))
        end
    end

    if killedUnit:GetUnitName() == "npc_dota_creature_rubick_melee_creep" then
        if RollPercentage(5) then
            local newItem = CreateItem("item_health_potion", nil, nil)
            newItem:SetPurchaseTime(0)
            if newItem:IsPermanent() and newItem:GetShareability() == ITEM_FULLY_SHAREABLE then
                item:SetStacksWithOtherOwners(true)
            end
            local drop = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), newItem)
            drop.Holdout_IsLootDrop = true

            local dropTarget = killedUnit:GetAbsOrigin() + RandomVector(RandomFloat(50, 350))
            newItem:LaunchLoot(true, 300, 0.75, dropTarget, nil )
        end
        if RollPercentage(5) then
            local newItem = CreateItem("item_mana_potion", nil, nil)
            newItem:SetPurchaseTime(0)
            if newItem:IsPermanent() and newItem:GetShareability() == ITEM_FULLY_SHAREABLE then
                item:SetStacksWithOtherOwners(true)
            end
            local drop = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), newItem)
            drop.Holdout_IsLootDrop = true

            local dropTarget = killedUnit:GetAbsOrigin() + RandomVector(RandomFloat(50, 350))
            newItem:LaunchLoot(true, 300, 0.75, dropTarget, nil )
        end
    end

    if killedUnit:GetUnitName() == "npc_dota_boss_rubick" then
        self:_AwardPoints()
        self:_Victory()
    end
end

--------------------------------------------------------------------------------

function CHoldout:OnEntityKilled_PlayerHero(event)
    local killedUnit = EntIndexToHScript(event.entindex_killed)
    local attackerUnit = EntIndexToHScript(event.entindex_attacker)

    -- local newItem = CreateItem("item_tombstone", killedUnit, killedUnit)
    -- newItem:SetPurchaseTime(0)
    -- newItem:SetPurchaser(killedUnit)
    -- local tombstone = SpawnEntityFromTableSynchronous("dota_item_tombstone_drop", {})
    -- tombstone:SetContainedItem(newItem)
    -- tombstone:SetAngles(0, RandomFloat(0, 360), 0)
    -- FindClearSpaceForUnit(tombstone, killedUnit:GetAbsOrigin(), true)

    CreateModifierThinker(killedUnit,self,"modifier_tombstone2",{},killedUnit:GetOrigin(),killedUnit:GetTeamNumber(),false)

    self:ResetKillsWithoutDying(killedUnit:GetPlayerOwnerID())

    if attackerUnit then
        if attackerUnit:GetUnitName() == "npc_dota_boss_rubick" then
            self:OnBossKilledPlayer()
        end

        local gameEvent = {}
        gameEvent["player_id"] = killedUnit:GetPlayerID()
        gameEvent["teamnumber"] = DOTA_TEAM_GOODGUYS
        gameEvent["locstring_value"] = attackerUnit:GetUnitName()
        gameEvent["message"] = "#Frosthaven_KilledByCreature"
        FireGameEvent("dota_combat_event_message", gameEvent)

        -- self:FireDeathTaunt( attackerUnit )
    end
end

--------------------------------------------------------------------------------

-- When game state changes set state in script
function CHoldout:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()

    if nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        if self._bDevMode then
            self:ForceAssignHeroes()
        end
    end

    if nNewState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
        -- Add Instruction Panel call here
        self:ForceAssignHeroes() -- @fixme: this doesn't work
    elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        self:RefreshShrines()
        self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds

        if self._bDevMode and self._nDevRoundNumber ~= nil then
            self:_TestRoundConsoleCommand(nil, self._nDevRoundNumber, self._nDevRoundDelay)
        end

    end
end

--------------------------------------------------------------------------------------------------------
-- abilityname
-- caster_entindex

function CHoldout:OnNonPlayerUsedAbility(event)
    local casterUnit = EntIndexToHScript(event.caster_entindex)
    if casterUnit then
        if casterUnit.SpellCastResult ~= nil then
            casterUnit.SpellCastResult(event.abilityname)
        end
    end
end

--------------------------------------------------------------------------------------------------------

function CHoldout:OnPlayerUsedAbility(event)
    local casterUnit = EntIndexToHScript(event.caster_entindex)
    if casterUnit and self._hRubick ~= nil then
        if casterUnit == self._hRubick then
            self._hRubick.SpellCastResult(event.abilityname)
        else
            if self._hRubick.EnemySpellCastResult ~= nil then
                self._hRubick.EnemySpellCastResult(casterUnit, event.abilityname)
            end
        end
    end
end

--------------------------------------------------------------------------------------------------------

function CHoldout:OnItemPickedUp(event)
    if event.itemname == "item_throw_snowball" or event.itemname == "item_summon_snowman" or event.itemname ==
        "item_decorate_tree" or event.itemname == "item_festive_firework" then
        local nAssociatedConsumable = GIFT_ASSOCIATED_CONSUMABLES[event.itemname]
        local hHeroWhoLooted = EntIndexToHScript(event.HeroEntityIndex)
        -- print( string.format( "\"%s\" picked up item named \"%s\"", hHeroWhoLooted:GetUnitName(), event.itemname ) )
        -- print( string.format( "   item has associated consumable #: %d", nAssociatedConsumable ) )

        if hHeroWhoLooted then
            local gameEvent = {}
            gameEvent["player_id"] = hHeroWhoLooted:GetPlayerID()
            gameEvent["teamnumber"] = DOTA_TEAM_GOODGUYS
            gameEvent["locstring_value"] = event.itemname
            gameEvent["message"] = "#Frosthaven_PickedUpGift"
            FireGameEvent("dota_combat_event_message", gameEvent)
        end

        -- Award every player a consumable
        local hAllHeroes = HeroList:GetAllHeroes()
        for i = 1, #hAllHeroes do
            local hHero = hAllHeroes[i]
            if hHero and hHero:IsRealHero() and hHero:IsTempestDouble() == false then
                local nPlayerID = hHero:GetPlayerID()
                PlayerResource:RecordConsumableAbilityChargeChange(nPlayerID, nAssociatedConsumable, 1)

                EmitSoundOnClient("GiftReceived", hHero:GetPlayerOwner())
            end
        end
    end
end

--------------------------------------------------------------------------------------------------------
function CHoldout:OnPlayerPickHero(event)
end

-- Neutral Items drop system
--------------------------------------------------------------------------------------------------------

local function tableLength(t)
    local nCount = 0
    for _ in pairs(t) do
        nCount = nCount + 1
    end
    return nCount
end

--------------------------------------------------------------------------------------------------------
local neutralItemsData = {}
local currentTier = 1
local spawnIndex = 0
local lastTier = 0

local neutralItemNameMap = {}
local function isNeutralItem(itemName)
    return neutralItemNameMap[itemName] ~= nil
end

local neutralItems = LoadKeyValues("scripts/npc/neutral_items.txt")
if (neutralItems) then
    for key, value in pairs(neutralItems) do
        local items = value["items"]
        neutralItemsData[key] = {
            items = items,
            amount = tableLength(items),
        }
        for itemname, _ in pairs(items) do
            neutralItemNameMap[itemname] = true
        end
    end
    lastTier = tableLength(neutralItemsData)
end

local function getNeutralItemsFormTier(tier)
    return neutralItemsData[tostring(tier)]
end

local function rollChanceByPercent(chance)
    local rFloath = math.random() * 100
    return chance >= rFloath
end

local function dropTheNeutralItem(event)
    if (currentTier > lastTier) then return end
    local neutralItems = getNeutralItemsFormTier(currentTier)
    if (spawnIndex > neutralItems.amount) then
        return
    end

    local attackerUnit = EntIndexToHScript(event.entindex_attacker or -1)
    local killedUnit = EntIndexToHScript(event.entindex_killed)

    if not (killedUnit) then return end
    if not (killedUnit:IsCreature()) then return end
    if not (attackerUnit) then return end
    if not (attackerUnit:IsRealHero()) then return end

    local chance = killedUnit:IsCreepHero() and 25 or 1.5
    if not (rollChanceByPercent(chance)) then return end

    local neutralItemDrop = GetPotentialNeutralItemDrop(currentTier, attackerUnit:GetTeam())
    DropNeutralItemAtPositionForHero(neutralItemDrop, killedUnit:GetAbsOrigin(), attackerUnit, 0, true)
    spawnIndex = spawnIndex + 1
    if (spawnIndex >= neutralItems.amount) then
        currentTier = currentTier + 1
        spawnIndex = 0
    end
end
-- Event handler for item pickup
local function OnItemPickedUp(event)
    local itemname = event.itemname
    local playerId = event.PlayerID
    local itemEntityIndex = event.ItemEntityIndex

    if not (isNeutralItem(itemname)) then return end
    local item = EntIndexToHScript(itemEntityIndex)
    if not (item) then return end

    item:SetPurchaser(nil)
    item:SetShareability(1)
    item:SetStacksWithOtherOwners(true)
end

-- Drop neutral item --
ListenToGameEvent("dota_item_picked_up", OnItemPickedUp, nil)
ListenToGameEvent("entity_killed", dropTheNeutralItem, nil)

--- Drop NeutralItem Command
local function dropTheNeutralItemCommand(cmdName)
    local attackerUnit = PlayerResource:GetSelectedHeroEntity(0)
    if not (attackerUnit) then return end
    if (currentTier > lastTier) then return end
    local neutralItems = getNeutralItemsFormTier(currentTier)
    if spawnIndex > neutralItems.amount then
        return
    end

    local neutralItemDrop = GetPotentialNeutralItemDrop(currentTier, attackerUnit:GetTeam())
    DropNeutralItemAtPositionForHero(neutralItemDrop, attackerUnit:GetAbsOrigin(), attackerUnit, 0, true)
    spawnIndex = spawnIndex + 1
    if (spawnIndex >= neutralItems.amount) then
        currentTier = currentTier + 1
        spawnIndex = 0
    end
end

Convars:RegisterCommand("holdout_neutral_drop", dropTheNeutralItemCommand, "Spawn a neutral item.", FCVAR_CHEAT)