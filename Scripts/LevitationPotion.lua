LevitationPotion = {}

function LevitationPotion:Create()
    self.velocity = Vec(0, 0, 0)
    self.gravity = -25
    self.state = "flying"
    self.radius = 10
    self.force = 15
    self.duration = 5
    self.timer = 0
    self.affected = {}
end

function LevitationPotion:Start()

    local camera = self:GetWorld():FindNode("Camera")
    if camera == nil then
        Log.Debug("Potion: Camera not found!")
        self.velocity = Vec(0, 0.3, 1) * 12
        return
    end

    local rot = camera:GetWorldRotation()
    local yaw = math.rad(rot.y)
    local pitch = math.rad(rot.x)

    local forward = Vec(
    -math.sin(yaw) * math.cos(pitch),
    -math.sin(pitch) + 0.2,
    -math.cos(yaw) * math.cos(pitch)
    )

    self.velocity = forward * 12
end

function LevitationPotion:Tick(deltaTime)

    -- FLYING STATE
    if self.state == "flying" then
        self.velocity.y = self.velocity.y + self.gravity * deltaTime

        local pos = self:GetWorldPosition()
        local target = pos + self.velocity * deltaTime

        local sweep = self:SweepToWorldPosition(target)

        if sweep.hitNode ~= nil then
            -- IMPACT BOOM BOOM BOOM PARTICLE WAAAH
            local world = self:GetWorld()  
            local explodePos = self:GetWorldPosition()
            local explosionScene = LoadAsset("OBJ_PotionParticle")
            if explosionScene ~= nil then
                world:SpawnScene(explosionScene, explodePos)
            end
            
            self.state = "active"
            self.timer = 0
            return
        end

        self:SetWorldPosition(target)
        return
    end

    -- ACTIVE FIELD
    if self.state == "active" then
        self.timer = self.timer + deltaTime

        local world = self:GetWorld()
        local myPos = self:GetWorldPosition()
        local props = world:FindNodesWithTag("prop")

        for i = 1, #props do
            local prop = props[i]
            if not prop:IsPendingDestroy() then
                local pos = prop:GetWorldPosition()
                local dx = pos.x - myPos.x
                local dy = pos.y - myPos.y
                local dz = pos.z - myPos.z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                if dist < self.radius then
                    prop:EnablePhysics(true)
                    if self.affected[prop] == nil then
                        self.affected[prop] = true
                    end
                    prop:SetLinearVelocity(Vec(0, self.force, 0))
                end
            end
        end

        if self.timer > self.duration then
            self:RestoreProps()
            self.state = "done"
        end

        return
    end

    -- CLEANUP
    if self.state == "done" then
        self:SetPendingDestroy(true)
    end
end

function LevitationPotion:RestoreProps()
    for prop, _ in pairs(self.affected) do
        if prop ~= nil and not prop:IsPendingDestroy() then
            prop:SetLinearVelocity(Vec(0, 0, 0))
        end
    end
end