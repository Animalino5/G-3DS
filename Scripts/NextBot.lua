NextBot = {}

function NextBot:Create()
    self.moveSpeed = 8
    self.initTimer = 0
    self.debugTimer = 0
end

function NextBot:Start()
    Log.Debug("NextBot: Started!")
end

function NextBot:Tick(deltaTime)
    self.initTimer = self.initTimer + deltaTime
    if self.initTimer < 0.5 then return end

    self.debugTimer = self.debugTimer + deltaTime
    local doDebug = self.debugTimer >= 1.0
    if doDebug then self.debugTimer = 0 end

    local world = self:GetWorld()
    local props = world:FindNodesWithTag("prop")

    local validProps = {}
    for i = 1, #props do
        local p = props[i]
        if not p:IsPendingDestroy() and p ~= self then
            table.insert(validProps, p)
        end
    end

    if doDebug then
        Log.Debug("NextBot valid props: " .. #validProps)
    end

    if #validProps == 0 then
        Log.Debug("NextBot: All clean! Goodbye.")
        self:SetPendingDestroy(true)
        return
    end

    local myPos = self:GetWorldPosition()
    local closestProp = nil
    local closestDist = math.huge

    for i = 1, #validProps do
        local prop = validProps[i]
        local propPos = prop:GetWorldPosition()
        local diff = propPos - myPos
        local dist = math.sqrt(diff.x^2 + diff.y^2 + diff.z^2)
        if dist < closestDist then
            closestDist = dist
            closestProp = prop
        end
    end

    if closestProp == nil then return end

    if doDebug then
        Log.Debug("NextBot targeting: " .. closestProp:GetName() .. " dist: " .. closestDist)
    end

    local propPos = closestProp:GetWorldPosition()
    local diff = propPos - myPos
    local dist = math.sqrt(diff.x^2 + diff.y^2 + diff.z^2)
    if dist == 0 then return end

    local dir = Vec(diff.x / dist, diff.y / dist, diff.z / dist)
    local currentPos = self:GetWorldPosition()
    local target = currentPos + dir * self.moveSpeed * deltaTime

    local sweep = self:SweepToWorldPosition(target)

    if sweep.hitNode ~= nil then
        local targetNode = sweep.hitNode
        local maxDepth = 5
        while targetNode ~= nil and maxDepth > 0 do
            if targetNode:HasTag("prop") then
                targetNode:SetPendingDestroy(true)
                Log.Debug("NextBot destroyed: " .. targetNode:GetName())
                break
            end
            targetNode = targetNode:GetParent()
            maxDepth = maxDepth - 1
        end
    else
        self:SetWorldPosition(target)
        local angle = math.deg(math.atan2(dir.x, dir.z))
        self:SetRotationEuler(Vec(0, angle, 0))
    end
end
