Explosion = {}

function Explosion:Create()
    self.timer = 0
    self.lifetime = 1.0
end

function Explosion:Tick(deltaTime)
    self.timer = self.timer + deltaTime
    if self.timer >= self.lifetime then
        self:SetPendingDestroy(true)
    end
end