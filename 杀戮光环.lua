local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local KillAura = {
    Range = 40,
    Cooldown = 0.05,
    LastTime = 0,
    AttackBarrel = false,
    AttackCount = 2,
    LastAttackTime = {},  -- 每个僵尸独立冷却
}

function getTargets(Character, Range)
    local Targets = {}
    local zombiesFolder = Workspace:FindFirstChild("Zombies")
    if not zombiesFolder then return Targets end

    for _, v in pairs(zombiesFolder:GetChildren()) do
        if v:IsA("Model") then
            -- 不攻击自爆
            if v:GetAttribute("Type") == "Barrel" and not KillAura.AttackBarrel then
                continue
            end
            -- 跳过正在生成的
            local state = v:FindFirstChild("State")
            if state and state.Value == "Spawn" then
                continue
            end
            local HumanoidRootPart = v:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart then
                local Dist = (HumanoidRootPart.Position - Character.Position).Magnitude
                if Dist <= Range then
                    table.insert(Targets, { zombie = v, dist = Dist })
                end
            end
        end
    end

    table.sort(Targets, function(a, b) return a.dist < b.dist end)
    return Targets
end

function getWeapon()
    local Weapon = nil
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("Melee") then
            Weapon = v
            break
        end
    end
    return Weapon
end

function attackZombie(zombie, weapon)
    if not weapon then return end
    local remote = weapon:FindFirstChild("RemoteEvent")
    if not remote then return end

    local head = zombie:FindFirstChild("Head")
    if not head then return end

    local char = LocalPlayer.Character
    if not char then return end
    local headPart = char:FindFirstChild("Head")
    if not headPart then return end

    local HitPos = head.Position
    local Direction = (HitPos - headPart.Position).Unit

    -- 使用你原文件的数据包格式
    remote:FireServer("Swing", "Thrust")
    remote:FireServer("PrepareSwing")
    remote:FireServer("HitZombieM", zombie, HitPos, true, HitPos, "Head", Direction)
end

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - KillAura.LastTime < KillAura.Cooldown then return end

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local targets = getTargets(head, KillAura.Range)
    if #targets == 0 then return end

    local weapon = getWeapon()
    if not weapon then return end

    local toAttack = math.min(KillAura.AttackCount, #targets)

    for i = 1, toAttack do
        local zombie = targets[i].zombie
        -- 每个僵尸独立冷却0.05秒
        if not KillAura.LastAttackTime[zombie] or (now - KillAura.LastAttackTime[zombie] >= 0.05) then
            attackZombie(zombie, weapon)
            KillAura.LastAttackTime[zombie] = now
        end
    end

    KillAura.LastTime = now
end)