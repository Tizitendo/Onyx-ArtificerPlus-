-- ArtificerPlus v0.1.0
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

function setup_arti()
    player = Player.get_client()
    local skills = gm.variable_global_get("class_skill")
    local artiC2 = skills[126] -- alt utility
    local artiV2 = skills[127] -- alt special
    local artiV2Boosted = skills[128] -- alt special scepter

    local speed_multi = 2.0
    gm.sprite_set_speed(gm.constants.sArtiShoot1_1A, speed_multi, 1)
    gm.sprite_set_speed(gm.constants.sArtiShoot1_2A, speed_multi, 1)
    gm.sprite_set_speed(gm.constants.sArtiShoot1_1B, speed_multi, 1)
    gm.sprite_set_speed(gm.constants.sArtiShoot1_2B, speed_multi, 1)

    gm.array_set(artiC2, 6, 480.0) -- cooldown
    gm.array_set(artiV2, 6, 300.0) -- cooldown
    gm.array_set(artiV2Boosted, 6, 300.0) -- cooldown
end

gm.pre_script_hook(gm.constants.callback_execute, function(self, other, result, args)

    if args[1].value == 26 and self.class == 13.0 then -- onPlayerStep
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
        if BufferedUtil > 0 and player:get_active_skill(2).skill_id == 125 then
            BufferedUtil = 0
            self.pHspeed = self.pHspeed * 1.5
            self.pVspeed = self.pVspeed * 1.2
        end
    end

    -- Skill setup
    if args[1].value == 25 then -- onPlayerInit
        setup_arti()
    end
end)

-- check if util is used
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
