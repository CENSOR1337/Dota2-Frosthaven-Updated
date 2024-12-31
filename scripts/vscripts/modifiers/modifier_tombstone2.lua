-- Thanks to: Sparking+

modifier_tombstone2 = class({})

function modifier_tombstone2:DeclareFunctions()
    local funcs =
    {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_RESPAWN,
        MODIFIER_PROPERTY_MODEL_CHANGE,
    }
    return funcs
end

function modifier_tombstone2:OnCreated(keys)
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
end

function modifier_tombstone2:OnIntervalThink()
    -- if not IsServer() then return end
    local units = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, 1, 48, FIND_ANY_ORDER, false)
    if units[1] then
        if not self.particle then
            self.particle = ParticleManager:CreateParticle("particles/econ/generic/generic_progress_meter/generic_progress_circle.vpcf", 0, self:GetParent())
            -- ParticleManager:SetParticleControl( self.particle,1,Vector(100,0,0) )
            ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetOrigin() + Vector(0, 0, 300))
        end
        self:IncrementStackCount()
        ParticleManager:SetParticleControl(self.particle, 1, Vector(100, self:GetStackCount() / 60, 0))
        if self:GetStackCount() >= 60 then
            self:GetCaster():RespawnHero(false, false)
        end
    else
        if self.particle then
            ParticleManager:DestroyParticle(self.particle, true)
            self.particle = nil
            self:SetStackCount(0)
        end
    end
end

function modifier_tombstone2:OnRespawn(keys)
    if keys.unit == self:GetCaster() then
        self:GetParent():Destroy()
    end
end

function modifier_tombstone2:GetModifierModelChange(keys)
    return "models/props_gameplay/tombstoneb01.vmdl"
end
