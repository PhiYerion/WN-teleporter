ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Basic Teleporter"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true

telewin = {}

model = "models/props_combine/combine_interface001.mdl"

if (SERVER) then

    util.AddNetworkString("teleUse")
    util.AddNetworkString("addTelePartner")
    util.AddNetworkString("teleportPly")
    util.AddNetworkString("removeTeleporter")
    util.AddNetworkString("removePartnerTeleporter")
    
    function ENT:Use(client)
        if (client:GetPos():Distance(self:GetPos()) <= 128) then
            net.Start("teleUse")
                net.WriteEntity(self)
                net.WriteBool(self:GetNetVar("partnerTeleporter", false))
            net.Send(client)
        end
    end
    
    function ENT:Initialize()
        self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("partnerTeleporter", nil)
    end

    function ENT:SpawnFunction()
        local Teleporter = ents.Create("ix_basic_teleporter")
        Teleporter:SetPos(trace.HitPos)
        Teleporter:SetAngles(trace.HitNormal:Angle())
        Teleporter:Spawn()
        Teleporter:Activate()
        Teleporter:SetEnabled(true)
        hook.run("OnItemSpawned", Teleporter)
        return Teleporter
    end

    net.Receive("addTelePartner", function(_, ply)
        if ply:IsAdmin() then
            local teleporter = net.ReadEntity()
            local partner = ents.Create("ix_basic_teleporter")
            partner:SetPos(teleporter:GetPos() + Vector(0, 0, 100))
            partner:SetAngles(teleporter:GetAngles())
            partner:Spawn()
            partner:Initialize()
            partner:SetNetVar("partnerTeleporter", teleporter)
            teleporter:SetNetVar("partnerTeleporter", partner)
        else
            ply:Notify("You are not an admin!")
        end
    end)

    net.Receive("removeTeleporter", function(_,ply)
        if ply:IsAdmin() then
            net.ReadEntity():Remove()
        else
            ply:Notify("You are not an admin!")
        end
    end)

    net.Receive("removePartnerTeleporter", function(_,ply)
        if ply:IsAdmin() then
            net.ReadEntity():GetNetVar("partnerTeleporter"):Remove()
        else
            ply:Notify("You are not an admin!")
        end
    end)

    net.Receive("teleportPly", function(_, ply)
        local teleporter = net.ReadEntity()
        local partner = teleporter:GetNetVar("partnerTeleporter")
        if (partner) then
            ply:SetPos(partner:GetPos() + Vector(0, 0, 100))
        else
            ply:Notify("Partner not found!")
        end
    end)


else

    function openWin(entity, hasPartner)
        print('opening win called')
        surface.CreateFont("localFont", {
            font = "Roboto",
            size = 20,
            weight = 500,
            antialias = true,
            shadow = false
        })
        if IsValid(telewin.Menu) then
            telewin.Menu:Remove()
        end
        telewin.Menu = vgui.Create("DFrame")
        telewin.Menu:SetSize(ScrW() * 0.3, ScrH() * 0.3)
        telewin.Menu:Center()
        telewin.Menu:SetTitle("Teleporter")
        telewin.Menu:MakePopup(true)
        if LocalPlayer():IsAdmin() then
            if !hasPartner then
                local addPartner = vgui.Create("DButton", telewin.Menu)
                addPartner:Dock(TOP)
                addPartner:SetText("Add Partner")
                function addPartner:DoClick()
                    net.Start("addTelePartner")
                        net.WriteEntity(entity)
                    net.SendToServer()
                    telewin.Menu:Remove()
                end
            else
                local removePartner = vgui.Create("DButton", telewin.Menu)
                removePartner:Dock(TOP)
                removePartner:SetText("Remove Partner Teleporter")
                function removePartner:DoClick()
                    net.Start("removePartnerTeleporter")
                        net.WriteEntity(entity)
                    net.SendToServer()
                end
            end
            local removeButton = vgui.Create("DButton", telewin.Menu)
            removeButton:Dock(TOP)
            removeButton:SetText("Remove This Teleporter")
            function removeButton:DoClick()
                net.Start("removeTeleporter")
                    net.WriteEntity(entity)
                net.SendToServer()
            end
        end
        if (hasPartner) then
            local teleportButton = vgui.Create("DButton", telewin.Menu)
            teleportButton:Dock(TOP)
            teleportButton:SetText("Teleport")
            function teleportButton:DoClick()
                net.Start("teleportPly")
                    net.WriteEntity(entity)
                net.SendToServer()
                telewin.Menu:Remove()
            end
        end
    end
    net.Receive("teleUse", function()
        print('opening win')
        openWin(net.ReadEntity(), net.ReadBool())
    end)
end



