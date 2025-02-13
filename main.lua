log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        Hover = true,
        Rapidfire = false,
        SurgeBuff = false,
        SunControl = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

Initialize(function()
    local packetConfig = Packet.new()
    local PlayerPacket = Packet.new()
    local artistar = {}
    local StarCount = 0
    local player = nil
    local artiX = nil
    local artiX2 = nil
    local BufferedX2 = nil
    local Artificer = Survivor.find("ror-arti")

    Callback.add(Callback.TYPE.onGameStart, "ArtificerPlus-onGameStart", function()
        local function GameStart()
            local playerdata = Player.get_client():get_data()
            playerdata.Hover = params.Hover
            playerdata.Rapidfire = params.Rapidfire
            playerdata.SurgeBuff = params.SurgeBuff
            playerdata.SunControl = params.SunControl
            if gm._mod_net_isOnline() then
                local msg = packetConfig:message_begin()
                msg:write_instance(Player.get_client())
                msg:write_byte(params.Hover)
                msg:write_byte(params.Rapidfire)
                msg:write_byte(params.SurgeBuff)
                msg:write_byte(params.SunControl)

                if gm._mod_net_isClient() then
                    msg:send_to_host()
                end
                if gm._mod_net_isHost() then
                    msg:send_to_all()
                end
            end
        end
        Alarm.create(GameStart, 2)
    end)

    packetConfig:onReceived(function(msg)
        local msgplayer = msg:read_instance()
        local playerdata = msgplayer:get_data()
        playerdata.Hover = msg:read_byte()
        playerdata.Rapidfire = msg:read_byte()
        playerdata.SurgeBuff = msg:read_byte()
        playerdata.SunControl = msg:read_byte()

        if gm._mod_net_isHost() then
            local msg = packetConfig:message_begin()
            msg:write_instance(Player.get_client())
            msg:write_byte(playerdata.Hover)
            msg:write_byte(playerdata.Rapidfire)
            msg:write_byte(playerdata.SurgeBuff)
            msg:write_byte(playerdata.SunControl)
            msg:send_to_all()
        end
    end)

    PlayerPacket:onReceived(function(msg)
        local player = msg:read_instance()
        player.moveUpHold = msg:read_byte()
        player.v_skill = msg:read_byte()
    end)

    Callback.add(Callback.TYPE.onStep, "ArtificerPlus-onStep", function()
        if gm._mod_net_isOnline() then
            local player = Player.get_client()
            local msg = PlayerPacket:message_begin()
            msg:write_instance(player)
            msg:write_byte(player.moveUpHold)
            msg:write_byte(player.v_skill)
            if gm._mod_net_isHost() then
                msg:send_to_all()
            end
            if gm._mod_net_isClient() then
                msg:send_to_host()
            end
        end
    end)

    Artificer:onInit(function(self)
        local playerdata = self:get_data()
        artiX2 = Skill.find("ror-artiX2")
        artiX = Skill.find("ror-artiX")
        local artiC2 = Skill.find("ror-artiC2")
        local artiV2 = Skill.find("ror-artiV2")
        local artiV2Boosted = Skill.find("ror-artiV2Boosted")
        playerdata.artistar = {}

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
        local self = inst.value
        local playerdata = inst:get_data()

        -- Hover
        if gm.bool(self.moveUpHold) and self.pVspeed > 0.0 and playerdata.Hover then
            self.pVspeed = self.pVspeed * 0.9
        end

        -- hold special to slow down + artistar control
        if playerdata.SunControl then
            for _, star in ipairs(playerdata.artistar) do
                if star:exists() then
                    -- log.warning(self.v_skill_buffered)
                    -- log.warning(self.v_skill)
                    if gm.bool(self.v_skill) then
                        self.pHspeed = 0.0
                        star.pMmax = 6
                    else
                        star.pMmax = 2.5
                    end
                else
                    table.remove(star)
                end
            end
        end
    end)

    -- increase surge distance
    gm.post_script_hook(gm.constants._skill_system_update_skill_used, function(self, other, result, args)
        if self.class == 13.0 and self.c_skill == true and Instance.wrap(self):get_skill(2).identifier == "artiC2" and
            Instance.wrap(self):get_data().SurgeBuff then
            local function IncreaseSurgeDistance()
                self.pHspeed = self.pHspeed * 1.5
                self.pVspeed = self.pVspeed * 1.2
            end
            Alarm.create(IncreaseSurgeDistance, 1)
        end
    end)

    gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
        -- arti star better control
        -- self is different for client and server
        if result.value.object_index == gm.constants.oEfArtiStar then
            local function myFunc(result)
                local parentdata = Instance.wrap(result.parent):get_data()
                if gm.bool(parentdata.SunControl) then
                    table.insert(parentdata.artistar, Instance.wrap(result))
                end
            end
            Alarm.create(myFunc, 1, result.value)
        end
    end)
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
