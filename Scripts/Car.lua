Car = {}

function Car:Create()
    self.moveSpeed = 20
    self.acceleration = 10
    self.turnSpeed = 80
    self.currentSpeed = 0
    self.velocity = Vec(0, 0, 0)
    self.gravity = -25
    self.isGrounded = false
    self.yaw = 0
end

function Car:Start()
    self.cameraMount = self:FindChild("CameraMount")
    self:EnablePhysics(false)
    self.yaw = self:GetRotationEuler().y
end

function Car:Tick(deltaTime)
    -- GRAVITY
    self.velocity.y = self.velocity.y + self.gravity * deltaTime

    local pos = self:GetWorldPosition()
    local verticalTarget = pos + Vec(0, self.velocity.y * deltaTime, 0)
    local vSweep = self:SweepToWorldPosition(verticalTarget)
    if vSweep.hitNode ~= nil then
        verticalTarget.y = pos.y
        if self.velocity.y < 0 then
            self.velocity.y = 0
            self.isGrounded = true
        end
    else
        self.isGrounded = false
    end
    self:SetWorldPosition(verticalTarget)

    if ActiveCar ~= self then return end

    local throttle = 0
    local turn = 0

    if Input.IsGamepadDown(Gamepad.Up) then throttle = 1 end
    if Input.IsGamepadDown(Gamepad.Down) then throttle = -1 end
    if Input.IsGamepadDown(Gamepad.Y) then turn = -1 end
    if Input.IsGamepadDown(Gamepad.A) then turn = 1 end

    -- ACCELERATION BRRRR
    if throttle ~= 0 then
        self.currentSpeed = self.currentSpeed + throttle * self.acceleration * deltaTime
        self.currentSpeed = math.max(-self.moveSpeed, math.min(self.moveSpeed, self.currentSpeed))
    else
        if self.currentSpeed > 0 then
            self.currentSpeed = math.max(0, self.currentSpeed - self.acceleration * deltaTime)
        elseif self.currentSpeed < 0 then
            self.currentSpeed = math.min(0, self.currentSpeed + self.acceleration * deltaTime)
        end
    end

    -- TURNING
    if math.abs(self.currentSpeed) > 0.5 then
        local turnDir = turn * self.turnSpeed * deltaTime
        if self.currentSpeed < 0 then turnDir = -turnDir end
        self.yaw = self.yaw + turnDir
        self:SetRotationEuler(Vec(0, self.yaw, 0))
    end

    -- going foward :D
    local yawRad = math.rad(self.yaw)
    local forward = Vec(math.sin(yawRad), 0, math.cos(yawRad))
    local currentPos = self:GetWorldPosition()
    local horizontalTarget = currentPos + forward * self.currentSpeed * deltaTime
    horizontalTarget.y = currentPos.y

    local hSweep = self:SweepToWorldPosition(horizontalTarget)
    if hSweep.hitNode ~= nil then
        local targetNode = hSweep.hitNode
        local maxDepth = 5
        local foundProp = false
        while targetNode ~= nil and maxDepth > 0 do
            if targetNode:HasTag("prop") then
                foundProp = true
                break
            end
            targetNode = targetNode:GetParent()
            maxDepth = maxDepth - 1
        end

        if foundProp then
            targetNode:EnablePhysics(true)
            targetNode:AddImpulse(forward * math.abs(self.currentSpeed) * 2)
            self.currentSpeed = self.currentSpeed * 0.7
            self:SetWorldPosition(horizontalTarget)
        else
            self.currentSpeed = 0
        end
    else
        self:SetWorldPosition(horizontalTarget)
    end

    if self.cameraMount ~= nil then
        local mountPos = self.cameraMount:GetWorldPosition()
    end
end