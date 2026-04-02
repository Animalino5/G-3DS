DayNightCycle = {}

function DayNightCycle:Create()
    self.time = 0

    self.cycleDuration = 600  

    self.maxIntensity = 1.0
    self.minIntensity = 0.05
end

function DayNightCycle:Start()
    
    self.light1 = self:FindChild("Light1")
    self.light2 = self:FindChild("Light2")

    self.time = math.random() * self.cycleDuration
end

function DayNightCycle:Tick(deltaTime)

    self.time = self.time + deltaTime

    if self.time > self.cycleDuration then
        self.time = self.time - self.cycleDuration
    end

    local t = self.time / self.cycleDuration

    local brightness = math.sin(t * math.pi)

    local intensity = self.minIntensity + 
        (self.maxIntensity - self.minIntensity) * brightness

    if self.light1 ~= nil then
        self.light1:SetIntensity(intensity)
    end

    if self.light2 ~= nil then
        self.light2:SetIntensity(intensity)
    end


    local dayColor = Vec(0.5, 0.7, 1.0, 1)

    local nightColor = Vec(0.02, 0.02, 0.08, 1)

    local r = nightColor.x + (dayColor.x - nightColor.x) * brightness
    local g = nightColor.y + (dayColor.y - nightColor.y) * brightness
    local b = nightColor.z + (dayColor.z - nightColor.z) * brightness

    Renderer.SetClearColor(Vec(r, g, b, 1))
end