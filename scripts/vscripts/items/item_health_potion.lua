item_health_potion = class({})

--------------------------------------------------------------------------------

function item_health_potion:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

--------------------------------------------------------------------------------

function item_health_potion:OnSpellStart()
	if IsServer() then
		if self:GetCaster() and self:GetCaster():GetUnitName() == "npc_dota_hero_rubick" then
            -- @UpdateModified Begin: fix SpendCharge missing parameter
			self:SpendCharge(0.01)
            -- @UpdateModified End
			return
		end

		local hp_restore_pct = self:GetSpecialValueFor( "hp_restore_pct" )
		self:GetCaster():EmitSoundParams( "DOTA_Item.FaerieSpark.Activate", 0, 0.5, 0)

		local flHealAmount = self:GetCaster():GetMaxHealth() * hp_restore_pct / 100

		self:GetCaster():Heal( flHealAmount, self )

		local nFXIndex = ParticleManager:CreateParticle( "particles/items3_fx/fish_bones_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

        -- @UpdateModified Begin: fix SpendCharge missing parameter
		self:SpendCharge(0.01)
        -- @UpdateModified End
	end
end

--------------------------------------------------------------------------------