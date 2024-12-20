-- ArtificerPlus v1.3.2
-- Onyx
log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
params = {}
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        Hover = true,
        Rapidfire = false,
        SurgeBuff = false,
        SunControl = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local artistar = {}
local StarCount = 0
local player = nil
local artiX = nil
local artiX2 = nil
local BufferedX2 = nil

Initialize(function()
    Artificer = Survivor.find("ror-arti")

    Artificer:onInit(function(self)
        player = Player.get_client()

        artiX2 = Skill.find("ror-artiX2")
        artiX = Skill.find("ror-artiX")
        local artiC2 = Skill.find("ror-artiC2")
        local artiV2 = Skill.find("ror-artiV2")
        local artiV2Boosted = Skill.find("ror-artiV2Boosted")
        artiV2.allow_buffered_input = true
        artiV2Boosted.allow_buffered_input = true
        artiX.allow_buffered_input = false

        if params.SurgeBuff then
            artiC2.cooldown = 480.0
        end

        if params.Rapidfire then
            local speed_multi = 2.0
            gm.sprite_set_speed(gm.constants.sArtiShoot1_1A, speed_multi, 1)
            gm.sprite_set_speed(gm.constants.sArtiShoot1_2A, speed_multi, 1)
            gm.sprite_set_speed(gm.constants.sArtiShoot1_1B, speed_multi, 1)
            gm.sprite_set_speed(gm.constants.sArtiShoot1_2B, speed_multi, 1)
        end
    end)

    Artificer:onStep(function(inst)
        self = inst.value

        -- Hover
        if self.moveUpHold == 1.0 and self.pVspeed > 0.0 and params.Hover then
            self.pVspeed = self.pVspeed * 0.9
        end

        -- hold special to slow down + artistar control
        for i = 0, 4 do
            if artistar[i] ~= nil and params.SunControl then
                if self.v_skill_buffered > 0.0 then
                    self.pHspeed = 0.0
                    artistar[i].pMmax = 6
                else
                    artistar[i].pMmax = 2.5
                end
            end
        end

        -- Fix Nanobomb firing twice with backup mag
        if artiX.required_stock > 1 and not player.value.x_skill then
            artiX.required_stock = 1
        end
    end)
    Callback.add("onStageStart", "resetnanospear", function() 
        if artiX2 ~= nil then
            artiX2.required_stock = 1 
        end
        if artiX ~= nil then
            artiX.required_stock = 1
        end
    end)
end)

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

gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    -- Fix Nanospear with backup mag
    if result.value.object_index == gm.constants.oEfArtiNanobolt then
        artiX2.required_stock = artiX2.max_stock + 5
        BufferedX2 = result.value
    end
    if result.value.object_index == gm.constants.oEfExplosion and self ~= nil and self.parent ~= nil and self.parent.name == "Artificer" then
        function ResetSpear()
            if BufferedX2 ~= nil and Instance.exists(BufferedX2) == false then
                artiX2.required_stock = 1
            end
        end
        Alarm.create(ResetSpear, 60)
    end

    -- Nanobomb cooldown
    if result.value.object_index == gm.constants.oArtiNanobomb then
        artiX.required_stock = artiX.max_stock + 5
    end

    -- arti star better control
    if result.value.object_index == gm.constants.oEfArtiStar and params.SunControl then
        artistar[StarCount] = result.value
        StarCount = StarCount + 1
        if StarCount > 3 then
            StarCount = 0
        end
    end
end)

-- Add ImGui window
gui.add_imgui(function()
    if ImGui.Begin("ArtificerPlus") then
        params.Hover = ImGui.Checkbox("Arti Hover", params.Hover)
        params.Rapidfire = ImGui.Checkbox("Rapidfire", params.Rapidfire)
        params.SurgeBuff = ImGui.Checkbox("Buff Arti Surge", params.SurgeBuff)
        params.SunControl = ImGui.Checkbox("Hold special to control arti sun", params.SunControl)
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
