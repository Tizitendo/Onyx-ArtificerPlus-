-- ArtificerPlus v1.0.0
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
BufferedUtil = 0
player = nil

__initialize = function()
    Artificer = Survivor.find("ror-arti")

    Artificer:onInit(function(self)
        player = Player.get_client()
        local artiC2 = Skill.find("ror-artiC2")
        local artiV2 = Skill.find("ror-artiX2")
        local artiV2Boosted = Skill.find("ror-artiV2Boosted")
        artiC2.cooldown = 480.0
        artiV2.cooldown = 300.0
        artiV2Boosted.cooldown = 300.0
    
        local speed_multi = 2.0
        gm.sprite_set_speed(gm.constants.sArtiShoot1_1A, speed_multi, 1)
        gm.sprite_set_speed(gm.constants.sArtiShoot1_2A, speed_multi, 1)
        gm.sprite_set_speed(gm.constants.sArtiShoot1_1B, speed_multi, 1)
        gm.sprite_set_speed(gm.constants.sArtiShoot1_2B, speed_multi, 1)
    end)
    
    Artificer:onStep(function(self)
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
    
        -- increase surge distance
        if BufferedUtil > 0 and player:get_skill(2).identifier == "artiC2" then
            BufferedUtil = 0
            self.pHspeed = self.pHspeed * 1.5
            self.pVspeed = self.pVspeed * 1.2
        end
    end)

    gm.post_script_hook(gm.constants._skill_system_update_skill_used, function(self, other, result, args)
        if self.class == 13.0 and self.c_skill == true then
            BufferedUtil = 1
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
end