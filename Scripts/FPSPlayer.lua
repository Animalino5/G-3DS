FPSPlayer = {}

function FPSPlayer:Create()
    self.moveSpeed = 10
    self.lookSpeed = 80
    self.yaw = 0
    self.pitch = 0
    self.pitchMin = -80
    self.pitchMax = 80
    self.velocity = Vec(0, 0, 0)
    self.gravity = -25
    self.jumpSpeed = 12
    self.isGrounded = false
    self.jumpCount = 0
    self.maxJumps = 1
    self.isFlying = false
    self.flySpeed = 15
    self.currentWeapon = "toolgun"
    self.triggerCooldown = 0
    self.triggerCooldownTime = 0.3
    self.heldNode = nil
    self.holdDistance = 5
    self.inCar = false
    self.currentCar = nil
    self.enterCarCooldown = 0
end

function FPSPlayer:Start()
    self.camera = self:FindChild("Camera")
    self.collider = self
    self:GetWorld():SetActiveCamera(self.camera)

    self.gunDisplay = self:GetWorld():FindNode("GunDisplay")
    self.physDisplay = self:GetWorld():FindNode("PhysDisplay")
    self.toolDisplay = self:GetWorld():FindNode("ToolDisplay")

    self:UpdateWeaponDisplay()
end

function FPSPlayer:GetForwardVector()
    local pitch = math.rad(self.pitch)
    local yawRad = math.rad(self.yaw)
    return Vec(
        -math.sin(yawRad) * math.cos(pitch),
        -math.sin(pitch),
        -math.cos(yawRad) * math.cos(pitch)
    )
end

function FPSPlayer:Tick(deltaTime)
    self.enterCarCooldown = math.max(0, self.enterCarCooldown - deltaTime)

    if Input.IsGamepadButtonJustDown(Gamepad.Select) then
        if self.inCar then
            self:ExitCar()
        else
            self:TryEnterCar()
        end
    end

    if self.inCar then
    local mount = self.currentCar:FindChild("CameraMount")
    if mount ~= nil then
        self:SetWorldPosition(mount:GetWorldPosition())
        local carRot = self.currentCar:GetRotationEuler()
        self.yaw = carRot.y + 180 
        self:SetRotationEuler(Vec(0, self.yaw, 0))
        self.camera:SetRotationEuler(Vec(0, 0, 0))
    end
    return
end

    local lookX = Input.GetGamepadAxis(Gamepad.AxisLX)
    local lookY = Input.GetGamepadAxis(Gamepad.AxisLY)

    if math.abs(lookX) < 0.1 then lookX = 0 end
    if math.abs(lookY) < 0.1 then lookY = 0 end

    self.yaw = self.yaw - lookX * self.lookSpeed * deltaTime
    self.pitch = self.pitch + lookY * self.lookSpeed * deltaTime
    self.pitch = math.max(self.pitchMin, math.min(self.pitchMax, self.pitch))

    self:SetRotationEuler(Vec(0, self.yaw, 0))
    self.camera:SetRotationEuler(Vec(self.pitch, 0, 0))

    local moveZ = 0
    local moveX = 0
    if Input.IsGamepadButtonDown(Gamepad.B) then moveZ = 1 end
    if Input.IsGamepadButtonDown(Gamepad.X) then moveZ = -1 end
    if Input.IsGamepadButtonDown(Gamepad.Y) then moveX = -1 end
    if Input.IsGamepadButtonDown(Gamepad.A) then moveX = 1 end

    local yawRad = math.rad(self.yaw)
    local forwardVec = Vec(math.sin(yawRad), 0, math.cos(yawRad))
    local rightVec = Vec(math.cos(yawRad), 0, -math.sin(yawRad))
    local move = (forwardVec * moveZ + rightVec * moveX) * self.moveSpeed * deltaTime

    if self.isFlying then
        local flyY = 0
        if Input.IsGamepadButtonDown(Gamepad.R1) then
            flyY = self.flySpeed * deltaTime
        else
            flyY = -5 * deltaTime
        end

        local pos = self:GetWorldPosition()
        local targetPos = pos + move + Vec(0, flyY, 0)

        if self.collider ~= nil then
            local sweepResult = self.collider:SweepToWorldPosition(targetPos)
            if sweepResult.hitNode ~= nil then
                targetPos.y = pos.y
                self.velocity.y = 0
                self.isGrounded = true
                self.isFlying = false
                self.jumpCount = 0
            end
        end

        self:SetWorldPosition(targetPos)
        return
    end

    self.velocity.y = self.velocity.y + self.gravity * deltaTime

    if Input.IsGamepadButtonJustDown(Gamepad.R1) then
        if self.jumpCount < self.maxJumps then
            self.velocity.y = self.jumpSpeed
            self.jumpCount = self.jumpCount + 1
        end
    end

    if self.isGrounded then
        self.jumpCount = 0
        self.isFlying = false
    end

    local pos = self:GetWorldPosition()
    local horizontalMove = move
    local verticalMove = Vec(0, self.velocity.y * deltaTime, 0)

    local horizontalTarget = pos + horizontalMove
    if self.collider ~= nil then
        local hSweep = self.collider:SweepToWorldPosition(horizontalTarget)
        if hSweep.hitNode ~= nil then
            horizontalTarget.x = pos.x
            horizontalTarget.z = pos.z
        end
    end

    local verticalTarget = horizontalTarget + verticalMove
    if self.collider ~= nil then
        local vSweep = self.collider:SweepToWorldPosition(verticalTarget)
        if vSweep.hitNode ~= nil then
            verticalTarget.y = horizontalTarget.y
            if self.velocity.y < 0 then
                self.velocity.y = 0
                self.isGrounded = true
            end
        else
            self.isGrounded = false
        end
    end

    self:SetWorldPosition(verticalTarget)

    self.triggerCooldown = math.max(0, self.triggerCooldown - deltaTime)
    local newWeapon = ActiveWeapon or "toolgun"
    if newWeapon ~= self.currentWeapon then
        self.currentWeapon = newWeapon
        self:UpdateWeaponDisplay()
    end

    if self.currentWeapon == "toolgun" then
        if Input.IsGamepadButtonJustDown(Gamepad.L1) then
            self:UseToolGun()
        end

    elseif self.currentWeapon == "physgun" then
        if Input.IsGamepadButtonJustDown(Gamepad.L1) then
            self:GrabWithPhysGun()
        end
        if Input.IsGamepadButtonJustUp(Gamepad.L1) then
            if self.heldNode ~= nil then
                self.heldNode:EnablePhysics(true)
                self.heldNode = nil
            end
        end
        if Input.IsGamepadButtonDown(Gamepad.L1) then
            self:TickPhysGun(deltaTime)
        end

        if Input.IsGamepadButtonJustDown(Gamepad.Down) and self.heldNode ~= nil then
        local pitch = math.rad(self.pitch)
        local yawRad = math.rad(self.yaw)
        local forward = Vec(
            -math.sin(yawRad) * math.cos(pitch),
            math.sin(pitch),
            -math.cos(yawRad) * math.cos(pitch)
        )
        self.heldNode:EnablePhysics(true)
        self.heldNode:SetLinearVelocity(forward * 25)
        self.heldNode = nil
        Log.Debug("LAUNCHED!")
    end

    elseif self.currentWeapon == "gun" then
    if Input.IsGamepadButtonJustDown(Gamepad.L1) then
        self:UseGun()
    end

    end
end

function FPSPlayer:UseToolGun()
    if self.triggerCooldown > 0 then return end
    self.triggerCooldown = self.triggerCooldownTime

    local worldPos, hitNode = self.camera:TraceScreenToWorld(200, 120, 0xFF)

    if hitNode ~= nil then
        Log.Debug("Hit: " .. hitNode:GetName())
        local targetNode = hitNode
        local maxDepth = 5
        while targetNode ~= nil and maxDepth > 0 do
            local name = targetNode:GetName()
            if name:sub(1, 4) == "OBJ_" then
                targetNode:SetPendingDestroy(true)
                Log.Debug("Deleted: " .. name)
                return
            end
            targetNode = targetNode:GetParent()
            maxDepth = maxDepth - 1
        end
    else
        Log.Debug("Hit nothing")
    end
end

function FPSPlayer:GrabWithPhysGun()
    local worldPos, hitNode = self.camera:TraceScreenToWorld(200, 120, 0xFF)

    if hitNode ~= nil then

        if hitNode:GetName() == "Capsule" then
            Log.Debug("Hit self, ignoring")
            return
        end

        Log.Debug("PhysGun hit: " .. hitNode:GetName())
        local targetNode = hitNode
        local maxDepth = 5
        while targetNode ~= nil and maxDepth > 0 do
            local name = targetNode:GetName()
            if name:sub(1, 4) == "OBJ_" then
                self.heldNode = targetNode
                local diff = targetNode:GetWorldPosition() - self:GetWorldPosition()
                self.holdDistance = math.sqrt(diff.x*diff.x + diff.y*diff.y + diff.z*diff.z)
                targetNode:SetLinearVelocity(Vec(0, 0, 0))
                targetNode:EnablePhysics(false)
                Log.Debug("Grabbed: " .. name)
                return
            end
            targetNode = targetNode:GetParent()
            maxDepth = maxDepth - 1
        end
        Log.Debug("Nothing grabbable found")
    end
end

function FPSPlayer:TickPhysGun(deltaTime)
    if self.heldNode == nil then return end

    local playerPos = self:GetWorldPosition()
    local camPos = Vec(playerPos.x, playerPos.y + 1.3, playerPos.z)
    local pitch = math.rad(self.pitch)
    local yawRad = math.rad(self.yaw)

    local forward = Vec(
        -math.sin(yawRad) * math.cos(pitch),
        math.sin(pitch),
        -math.cos(yawRad) * math.cos(pitch)
    )

    local targetPos = camPos + forward * self.holdDistance
    self.heldNode:SetWorldPosition(targetPos)
end

function FPSPlayer:UseGun()
    if self.triggerCooldown > 0 then return end
    self.triggerCooldown = self.triggerCooldownTime

    local worldPos, hitNode = self.camera:TraceScreenToWorld(200, 120, 0xFF)

    if hitNode ~= nil then
        if hitNode:GetName() == "Capsule" then return end

        Log.Debug("Gun hit: " .. hitNode:GetName())

        local targetNode = hitNode
        local maxDepth = 5
        while targetNode ~= nil and maxDepth > 0 do
            local name = targetNode:GetName()

    if name:sub(1, 10) == "OBJ_Barrel" then
        self:ExplodeBarrel(targetNode)
        return
            elseif name:sub(1, 4) == "OBJ_" then
                local pushDir = targetNode:GetWorldPosition() - self:GetWorldPosition()
                local len = math.sqrt(pushDir.x^2 + pushDir.y^2 + pushDir.z^2)
                if len > 0 then
                    pushDir = pushDir * (1/len)
                end
                targetNode:EnablePhysics(true)
                targetNode:AddImpulse(pushDir * 4)
                Log.Debug("Pushed: " .. name)
                return
            end

            targetNode = targetNode:GetParent()
            maxDepth = maxDepth - 1
        end
    end
end

function FPSPlayer:ExplodeBarrel(barrelNode, depth)
    depth = depth or 0
    if depth > 3 then return end

    local explodePos = barrelNode:GetWorldPosition()
    local explodeRadius = 10
    local explodeForce = 15

    Log.Debug("BOOM! depth: " .. depth)

    local world = self:GetWorld()
    local explosionScene = LoadAsset("OBJ_Explosion")
    if explosionScene ~= nil then
        world:SpawnScene(explosionScene, explodePos)
    end

    barrelNode:SetPendingDestroy(true)

    local props = world:FindNodesWithTag("prop")

    for i = 1, #props do
        local prop = props[i]
        if prop ~= barrelNode and not prop:IsPendingDestroy() then
            local propPos = prop:GetWorldPosition()
            local diff = propPos - explodePos
            local dist = math.sqrt(diff.x^2 + diff.y^2 + diff.z^2)

            if dist < explodeRadius and dist > 0 then
                local force = explodeForce * (1 - dist / explodeRadius)
                local pushDir = diff * (1 / dist)
                pushDir.y = pushDir.y + 0.5
                prop:EnablePhysics(true)
                prop:AddImpulse(pushDir * force)

                local propName = prop:GetName()
                if propName:sub(1, 10) == "OBJ_Barrel" then
                    self:ExplodeBarrel(prop, depth + 1)
                end
            end
        end
    end

    local playerPos = self:GetWorldPosition()
    local playerDiff = playerPos - explodePos
    local playerDist = math.sqrt(playerDiff.x^2 + playerDiff.y^2 + playerDiff.z^2)

    if playerDist < explodeRadius and playerDist > 0 then
        local force = (1 - playerDist / explodeRadius)
        self.velocity.y = explodeForce * force + 5
        self.isGrounded = false
    end
end

function FPSPlayer:UpdateWeaponDisplay()
    if self.gunDisplay == nil then return end

    self.gunDisplay:SetOpacityFloat(0)
    self.physDisplay:SetOpacityFloat(0)
    self.toolDisplay:SetOpacityFloat(0)

    if self.currentWeapon == "gun" then
        self.gunDisplay:SetOpacityFloat(1)
    elseif self.currentWeapon == "physgun" then
        self.physDisplay:SetOpacityFloat(1)
    elseif self.currentWeapon == "toolgun" then
        self.toolDisplay:SetOpacityFloat(1)
    end
end

function FPSPlayer:TryEnterCar()
    if self.enterCarCooldown > 0 then return end
    local world = self:GetWorld()
    local myPos = self:GetWorldPosition()

    local cars = world:FindNodesWithTag("car")
    for i = 1, #cars do
        local car = cars[i]
        local carPos = car:GetWorldPosition()
        local dist = math.sqrt(
            (carPos.x - myPos.x)^2 +
            (carPos.y - myPos.y)^2 +
            (carPos.z - myPos.z)^2
        )

        if dist < 5 then
            self.inCar = true
            self.currentCar = car
            ActiveCar = car  
            self.enterCarCooldown = 1.0
            Log.Debug("Entered car!")
            return
        end
    end
    Log.Debug("No car nearby")
end

function FPSPlayer:ExitCar()
    if self.currentCar ~= nil then
        local carPos = self.currentCar:GetWorldPosition()
        self:SetWorldPosition(Vec(carPos.x + 3, carPos.y + 1, carPos.z))
        self.currentCar = nil
    end
    ActiveCar = nil  
    self.inCar = false
    self.enterCarCooldown = 1.0
    Log.Debug("Exited car!")
end