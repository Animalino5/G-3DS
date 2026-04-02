Startup = {}

function Startup:Start()
    Renderer.EnableConsole(false)
    if _G.GameStarted then return end
    _G.GameStarted = true
    Engine.GetWorld(1):LoadScene("SC_Default")
    Engine.GetWorld(2):LoadScene("SC_TitleBot")
end