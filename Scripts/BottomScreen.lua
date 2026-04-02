BottomScreen = {}

function BottomScreen:Create()
    self.currentTab = 2
    self.spawnCooldown = 0
    self.spawnCooldownTime = 0.5
    self.maxDots = 40
    self.objDots = {}
end

function BottomScreen:Start()
    local tabBar = self:FindChild("TabBar")
    self.mapTab = tabBar:FindChild("MapTab")
    self.objectsTab = tabBar:FindChild("ObjectsTab")
    self.weaponsTab = tabBar:FindChild("WeaponsTab")

    self.mapPanel = self:FindChild("MapPanel")
    self.objectsPanel = self:FindChild("ObjectsPanel")
    self.weaponsPanel = self:FindChild("WeaponsPanel")

    self.spawnBoxBtn = self.objectsPanel:FindChild("SpawnBoxBtn")
    self.spawnBarrelBtn = self.objectsPanel:FindChild("SpawnBarrelBtn")
    self.spawnCarBtn = self.objectsPanel:FindChild("SpawnCarBtn")
    self.spawnBallBtn = self.objectsPanel:FindChild("SpawnBallBtn")
    self.spawnNPCBtn = self.objectsPanel:FindChild("SpawnNPCBtn")
    self.spawnLampBtn = self.objectsPanel:FindChild("SpawnLampBtn")
    self.spawnChairBtn = self.objectsPanel:FindChild("SpawnChairBtn")
    self.spawnMarioBtn = self.objectsPanel:FindChild("SpawnMarioBtn")

    self.toolGunBtn = self.weaponsPanel:FindChild("ToolGunBtn")
    self.gunBtn = self.weaponsPanel:FindChild("GunBtn")
    self.physGunBtn = self.weaponsPanel:FindChild("PhysGunBtn")

    self.playerDot = self.mapPanel:FindChild("PlayerDot")

    for i = 1, self.maxDots do
        local dot = self:GetWorld():SpawnNode("Quad")
        dot:Attach(self.mapPanel)
        dot:SetDimensions(6, 6)
        dot:SetColor(Vec(1, 0.8, 0, 1))  -- yellow
        dot:SetOpacityFloat(0)
        table.insert(self.objDots, dot)
    end

    self:SwitchTab(2)
end

function BottomScreen:Tick(deltaTime)
    self.spawnCooldown = math.max(0, self.spawnCooldown - deltaTime)

    if Input.IsTouchDown(1) then
        local tx, ty = Input.GetTouchPosition()

        if self:IsTouchingNode(self.mapTab, tx, ty) then
            self:SwitchTab(1)
        elseif self:IsTouchingNode(self.objectsTab, tx, ty) then
            self:SwitchTab(2)
        elseif self:IsTouchingNode(self.weaponsTab, tx, ty) then
            self:SwitchTab(3)
        end

    if self.currentTab == 2 then
        if self:IsTouchingNode(self.spawnBoxBtn, tx, ty) then
        self:SpawnObject("OBJ_box")
        elseif self:IsTouchingNode(self.spawnBarrelBtn, tx, ty) then
        self:SpawnObject("OBJ_barrel")
        elseif self:IsTouchingNode(self.spawnCarBtn, tx, ty) then
        self:SpawnObject("OBJ_Car")
        elseif self:IsTouchingNode(self.spawnBallBtn, tx, ty) then
        self:SpawnObject("OBJ_Ball")
        elseif self:IsTouchingNode(self.spawnNPCBtn, tx, ty) then
        self:SpawnObject("OBJ_FriendNPC")
        elseif self:IsTouchingNode(self.spawnLampBtn, tx, ty) then
        self:SpawnObject("OBJ_Lamp")
        elseif self:IsTouchingNode(self.spawnChairBtn, tx, ty) then
        self:SpawnObject("OBJ_Chair")
        elseif self:IsTouchingNode(self.spawnMarioBtn, tx, ty) then
        self:SpawnObject("OBJ_Mario")
        end
    end

        if self.currentTab == 3 then
            if self:IsTouchingNode(self.toolGunBtn, tx, ty) then
                ActiveWeapon = "toolgun"
                Log.Debug("Tool Gun selected")
            elseif self:IsTouchingNode(self.gunBtn, tx, ty) then
                ActiveWeapon = "gun"
                Log.Debug("Gun selected")
            elseif self:IsTouchingNode(self.physGunBtn, tx, ty) then
                ActiveWeapon = "physgun"
                Log.Debug("Phys Gun selected")
            end
        end
    end

    if self.currentTab == 1 then
        self:UpdateMinimap()
    end
end

function BottomScreen:UpdateMinimap()
    local gameWorld = Engine.GetWorld(1)
    local player = gameWorld:FindNode("Player")
    if player == nil then return end

    local mapMinX, mapMaxX = -96, 96
    local mapMinZ, mapMaxZ = -96, 96
    local panelW, panelH = 220, 220

    local function worldToMap(wx, wz)
        local px = ((wx - mapMinX) / (mapMaxX - mapMinX)) * panelW
        local py = ((wz - mapMinZ) / (mapMaxZ - mapMinZ)) * panelH
        return px, py
    end

    -- move player dot
    local pp = player:GetPosition()
    local px, py = worldToMap(pp.x, pp.z)
    self.playerDot:SetX(px)
    self.playerDot:SetY(py)

    -- find all prop tagged objects
    local allNodes = gameWorld:FindNodesWithTag("prop")

    -- update object dots
    for i = 1, self.maxDots do
        local dot = self.objDots[i]
        if allNodes[i] ~= nil then
            local op = allNodes[i]:GetPosition()
            local dx, dy = worldToMap(op.x, op.z)
            dot:SetX(dx)
            dot:SetY(dy)
            dot:SetOpacityFloat(1)
        else
            dot:SetOpacityFloat(0)
        end
    end
end

function BottomScreen:IsTouchingNode(node, tx, ty)
    if node == nil then return false end
    local rect = node:GetRect()
    return tx >= rect.x and tx <= rect.x + rect.w and
           ty >= rect.y and ty <= rect.y + rect.h
end

function BottomScreen:SpawnObject(assetName)
    if self.spawnCooldown > 0 then return end
    self.spawnCooldown = self.spawnCooldownTime

    local world1 = Engine.GetWorld(1)
    local player = world1:FindNode("Player")
    if player == nil then
        Log.Debug("Player not found!")
        return
    end

    local yawRad = math.rad(player:GetRotationEuler().y)
    local forward = Vec(-math.sin(yawRad), 0, -math.cos(yawRad))
    local spawnPos = player:GetWorldPosition() + forward * 5 + Vec(0, 2, 0)

    local scene = LoadAsset(assetName)
    if scene ~= nil then
        world1:SpawnScene(scene, spawnPos)
    else
        Log.Debug(assetName .. " not found!")
    end
end

function BottomScreen:SwitchTab(tabIndex)
    self.currentTab = tabIndex

    self.mapPanel:SetOpacityFloat(0)
    self.objectsPanel:SetOpacityFloat(0)
    self.weaponsPanel:SetOpacityFloat(0)

    if tabIndex == 1 then
        self.mapPanel:SetOpacityFloat(1)
    elseif tabIndex == 2 then
        self.objectsPanel:SetOpacityFloat(1)
    elseif tabIndex == 3 then
        self.weaponsPanel:SetOpacityFloat(1)
    end
end