VoidBox = {}

function VoidBox:Create()
end

function VoidBox:Start()
    self:EnableOverlaps(true)
    self:EnableCollision(false)
end

function VoidBox:BeginOverlap(this, other)
    if other == nil then return end

    local targetNode = other
    local maxDepth = 5
    while targetNode ~= nil and maxDepth > 0 do
        if targetNode:HasTag("prop") then
            targetNode:SetPendingDestroy(true)
            Log.Debug("VoidBox destroyed: " .. targetNode:GetName())
            return
        end
        targetNode = targetNode:GetParent()
        maxDepth = maxDepth - 1
    end
end