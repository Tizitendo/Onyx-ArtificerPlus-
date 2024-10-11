-- ArtificerPlus v1.0.3
-- Onyx
log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            for _, c in ipairs(m.Classes) do
                if m[c] then
                    _G[c] = m[c]
                end
            end
        end
    end
end)

artistar = {}
StarCount = 0
player = nil
artiX2 = nil
BufferedX2 = nil

__initialize = function()
    Artificer = Survivor.find("ror-arti")
    artiX2 = Skill.find("ror-artiX2")

    Artificer:onInit(function(self)
        player = Player.get_client()
        local artiC2 = Skill.find("ror-artiC2")
        local artiV2 = Skill.find("ror-artiX2")
        local artiV2Boosted = Skill.find("ror-artiV2Boosted")
        artiC2.cooldown = 480.0
        --artiV2.cooldown = 300.0
        --artiV2Boosted.cooldown = 300.0
        artiV2.allow_buffered_input = true
        artiV2Boosted.allow_buffered_input = true

        local speed_multi = 2.0
        gm.sprite_set_speed(gm.constants.sArtiShoot1_1A, speed_multi, 1)
        gm.sprite_set_speed(gm.constants.sArtiShoot1_2A, speed_multi, 1)
        gm.sprite_set_speed(gm.constants.sArtiShoot1_1B, speed_multi, 1)
        gm.sprite_set_speed(gm.constants.sArtiShoot1_2B, speed_multi, 1)
    end)

    Artificer:onStep(function(inst)
        self = inst.value

        -- Hover
        if self.moveUpHold == 1.0 and self.pVspeed > 0.0 then
            self.pVspeed = self.pVspeed * 0.9
        end

        -- hold special to slow down + artistar control
        for i = 0, 4 do
            if artistar[i] ~= nil then
                if self.v_skill_buffered > 0.0 then
                    self.pHspeed = 0.0
                    artistar[i].pMmax = 6
                else
                    artistar[i].pMmax = 2.5
                end
            end
        end
    end)

    Callback.add("onStageStart", "resetnanospear", function() 
        artiX2.required_stock = 1 
    end)
end

-- increase surge distance
gm.post_script_hook(gm.constants._skill_system_update_skill_used, function(self, other, result, args)
    if self.class == 13.0 and self.c_skill == true and player:get_skill(2).identifier == "artiC2" then
        function IncreaseSurgeDistance()
            self.pHspeed = self.pHspeed * 1.5
            self.pVspeed = self.pVspeed * 1.2
        end
        Alarm.create(IncreaseSurgeDistance, 1)
    end
end)

-- Fix Nanospear with backup mag
gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    if result.value.object_index == gm.constants.oEfArtiNanobolt then
        artiX2.required_stock = artiX2.max_stock + 1
        BufferedX2 = result.value
    end
    if result.value.object_index == gm.constants.oEfExplosion and self.parent ~= nil and self.parent.name == "Artificer" then
        function ResetSpear()
            if Instance.exists(BufferedX2) == false then
                artiX2.required_stock = 1
            end
        end
        Alarm.create(ResetSpear, 30)
    end
end)

-- arti star better control
gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    if result.value.object_index == gm.constants.oEfArtiStar then
        artistar[StarCount] = result.value
        StarCount = StarCount + 1
        if StarCount > 3 then
            StarCount = 0
        end
    end
end)
