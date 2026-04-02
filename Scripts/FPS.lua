FPS = {}

function FPS:Create()
    self.fpsUpdateTimer = 0
    self.fpsUpdateInterval = 0.5
    self.currentFPS = 0
end

function FPS:Tick(deltaTime)
    self.fpsUpdateTimer = self.fpsUpdateTimer + deltaTime

    if self.fpsUpdateTimer >= self.fpsUpdateInterval then
        self.fpsUpdateTimer = 0

        if deltaTime > 0 then
            self.currentFPS = math.floor(1.0 / Engine.GetDeltaTime())
            self:SetText("FPS: " .. tostring(self.currentFPS))
        end
    end
end