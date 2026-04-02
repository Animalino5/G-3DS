TitleBot = {}

function TitleBot:Start()
    self.playBtn = self:FindChild("PlayBtn")
end

function TitleBot:Tick(deltaTime)
    if Input.IsTouchDown(1) then
        local tx, ty = Input.GetTouchPosition()
        if self.playBtn:ContainsPoint(tx, ty) then
            Engine.GetWorld(1):LoadScene("SC_Game", true)
            Engine.GetWorld(2):LoadScene("SC_Bot", true)
        end
    end
end