local P=game:GetService("Players")
local W=game:GetService("Workspace")
local U=game:GetService("UserInputService")
local R=game:GetService("RunService")
local C=game:GetService("CoreGui")
local LP=P.LocalPlayer
local CAM=workspace.CurrentCamera

local AB=false
local E1=false
local E2=false
local E3=false
local H1=false
local B1=false
local H2=false

local FN=20
local FF=400
local PN=320
local PF=160
local TC=false
local CT=nil
local CD=0
local CC=Color3.fromHSV(0,1,1)
local FT=0.5
local OT=0.3
local SM=0.2
local PR=true

local AE={}
local PD={}

-- ═══════════════════════════════════════════════════════
-- FAST SPAWN PIPELINE
-- ═══════════════════════════════════════════════════════
local eQlist={}
local eQset={}
local eQscheduled=false

local function gF(d)
    if d<=FN then return PN end
    if d>=FF then return PF end
    local t=(d-FN)/(FF-FN)
    t=t*t
    return PN+(PF-PN)*t
end

local DK={door=true,window=true,wall=true,floor=true,ceiling=true,prop=true,decoration=true,furniture=true,stairs=true,railing=true,pipe=true,vent=true,crate=true,barrel=true,container=true}

local function hN(n)
    n=n:lower()
    for w in pairs(DK) do if string.find(n,w,1,true) then return true end end
    return false
end

local function iD(m)
    if hN(m.Name) then return true end
    local p=m.Parent
    local d=0
    while p and d<4 do
        local n=p.Name
        if n=="activemap" or n=="map" or n=="decor" or n=="decorations" then return true end
        if hN(n) then return true end
        p=p.Parent
        d=d+1
    end
    return false
end

local function iSB(m)
    if not m or m==LP.Character then return false end
    if not m:FindFirstChild("HumanoidRootPart") then return false end
    if P:GetPlayerFromCharacter(m) then return false end
    return true
end

local function iCM(m)
    if not m or m==LP.Character then return false end
    if P:GetPlayerFromCharacter(m) then return true end
    if iD(m) then return false end
    if m:FindFirstChild("Humanoid") then return true end
    local hH=m:FindFirstChild("Head")~=nil
    local hA=m:FindFirstChild("AnimationController")~=nil
    if (hH or hA) and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart) then return true end
    local n=m.Name:lower()
    if (string.find(n,"character",1,true) or string.find(n,"player",1,true) or string.find(n,"bot",1,true)) and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart) then return true end
    return false
end

local function gT(m)
    if not m or m==LP.Character then return nil end
    local pl=P:GetPlayerFromCharacter(m)
    if pl then return "player",pl end
    if iSB(m) then return "bot",m end
    if iCM(m) then return "custom",m end
    return nil
end

local function gN(m,t,r)
    if t=="player" and r then return r.Name end
    if t=="bot" and r then return r.Name or "Bot" end
    if t=="custom" and r then return r.Name or "Model" end
    return m.Name or "?"
end

local function gB(m)
    local p=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
    if p then return p end
    for _,c in ipairs(m:GetChildren()) do if c:IsA("BasePart") then return c end end
    return nil
end

local function cB(m,n)
    local p=gB(m)
    if not p then return nil end
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,200,0,50)
    bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true
    bb.Parent=p
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,0,1,0)
    tl.BackgroundTransparency=1
    tl.Text=n
    tl.TextColor3=Color3.new(1,1,1)
    tl.TextSize=10
    tl.Font=Enum.Font.GothamBold
    tl.TextStrokeTransparency=0.5
    tl.Parent=bb
    return bb
end

local function aE(m,t,r)
    if PD[m] or AE[m] then return end
    PD[m]=true
    task.spawn(function()
        local n=gN(m,t,r)
        if not m.Parent then PD[m]=nil return end
        local hl=Instance.new("Highlight")
        hl.FillColor=CC
        hl.OutlineColor=Color3.new(1,1,1)
        hl.FillTransparency=FT
        hl.OutlineTransparency=OT
        hl.Adornee=m
        hl.Parent=m
        local bb=cB(m,n)
        AE[m]={hl,bb}
        PD[m]=nil
    end)
end

local function rE(m)
    local d=AE[m]
    if d then
        if d[1] then d[1]:Destroy() end
        if d[2] then d[2]:Destroy() end
        AE[m]=nil
    end
    PD[m]=nil
end

local function cA()
    for m in pairs(AE) do rE(m) end
end

local function uC()
    for _,d in pairs(AE) do
        if d and d[1] then
            d[1].FillColor=CC
            d[1].FillTransparency=FT
            d[1].OutlineTransparency=OT
        end
    end
end

function pM(m)
    if not m or m==LP.Character then return end
    local t,r=gT(m)
    if not t then
        if AE[m] then rE(m) end
        return
    end
    local en=false
    if t=="player" and E1 then en=true
    elseif t=="bot" and E2 then en=true
    elseif t=="custom" and E3 then en=true
    end
    if not en then
        if AE[m] then rE(m) end
        return
    end
    local ex=AE[m]
    if ex then
        local hl,bb=ex[1],ex[2]
        local br=(not hl or not hl.Parent)
        if not br and bb then
            local p=bb.Parent
            if not p or not p:IsDescendantOf(m) then br=true end
        end
        if not br then return end
        rE(m)
    end
    aE(m,t,r)
end

-- ═══════════════════════════════════════════════════════
-- AIM CACHE (set-based for O(1))
-- ═══════════════════════════════════════════════════════
local CP={}
local CB={}
local CBset={}
local CM={}
local CMset={}
local AR=false

local function rP()
    local n={}
    for _,pl in ipairs(P:GetPlayers()) do
        if pl~=LP and pl.Character then
            local ch=pl.Character
            local rt=ch:FindFirstChild("HumanoidRootPart")
            if rt then
                local ap=rt
                if H1 then
                    local hd=ch:FindFirstChild("Head")
                    if hd then ap=hd end
                end
                n[#n+1]={aimPart=ap,type="player",ref=pl,model=ch}
            end
        end
    end
    CP=n
end

local function aSB(m)
    if not B1 then return end
    if not m or not m.Parent then return end
    local e=CBset[m]
    if e then
        if e.aimPart and e.aimPart.Parent then return end
        local root=m:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local ap=root
        if H2 then
            local hd=m:FindFirstChild("Head")
            if hd and hd:IsA("BasePart") then ap=hd end
        end
        e.aimPart=ap
        return
    end
    if not iSB(m) then return end
    local root=m:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local ap=root
    if H2 then
        local hd=m:FindFirstChild("Head")
        if hd and hd:IsA("BasePart") then ap=hd end
    end
    local entry={aimPart=ap,type="bot",ref=m,model=m}
    CB[#CB+1]=entry
    CBset[m]=entry
end

local function rSB(m)
    local e=CBset[m]
    if not e then return end
    CBset[m]=nil
    for i=1,#CB do if CB[i]==e then table.remove(CB,i) break end end
end

local function aCM(m)
    if not B1 or not E3 then return end
    if not m or not m.Parent then return end
    if P:GetPlayerFromCharacter(m) then return end
    local e=CMset[m]
    if e then
        if e.aimPart and e.aimPart.Parent then return end
        local root=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
        if not root then return end
        e.aimPart=root
        if H2 then
            local hd=m:FindFirstChild("Head") or m:FindFirstChild("head")
            if hd and hd:IsA("BasePart") then e.aimPart=hd end
        end
        return
    end
    if not iCM(m) then return end
    local root=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
    if not root then return end
    local ap=root
    if H2 then
        local hd=m:FindFirstChild("Head") or m:FindFirstChild("head")
        if hd and hd:IsA("BasePart") then ap=hd end
    end
    local entry={aimPart=ap,type="custom",ref=m,model=m}
    CM[#CM+1]=entry
    CMset[m]=entry
end

local function rCM(m)
    local e=CMset[m]
    if not e then return end
    CMset[m]=nil
    for i=1,#CM do if CM[i]==e then table.remove(CM,i) break end end
end

local function rA()
    if AR then return end
    AR=true
    task.spawn(function()
        rP()
        local nb={}
        local nbs={}
        if B1 then
            local l=W:GetDescendants()
            local b=120
            for i=1,#l,b do
                local s=math.min(i+b-1,#l)
                for j=i,s do
                    local o=l[j]
                    if o:IsA("Model") and iSB(o) then
                        local root=o:FindFirstChild("HumanoidRootPart")
                        if root then
                            local ap=root
                            if H2 then
                                local hd=o:FindFirstChild("Head")
                                if hd and hd:IsA("BasePart") then ap=hd end
                            end
                            local entry={aimPart=ap,type="bot",ref=o,model=o}
                            nb[#nb+1]=entry
                            nbs[o]=entry
                        end
                    end
                end
                R.Heartbeat:Wait()
            end
        end
        CB=nb
        CBset=nbs
        local nc={}
        local ncs={}
        if B1 and E3 then
            local l=W:GetDescendants()
            local b=120
            for i=1,#l,b do
                local s=math.min(i+b-1,#l)
                for j=i,s do
                    local o=l[j]
                    if o:IsA("Model") and not P:GetPlayerFromCharacter(o) and iCM(o) then
                        local root=o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart
                        if root then
                            local ap=root
                            if H2 then
                                local hd=o:FindFirstChild("Head") or o:FindFirstChild("head")
                                if hd and hd:IsA("BasePart") then ap=hd end
                            end
                            local entry={aimPart=ap,type="custom",ref=o,model=o}
                            nc[#nc+1]=entry
                            ncs[o]=entry
                        end
                    end
                end
                R.Heartbeat:Wait()
            end
        end
        CM=nc
        CMset=ncs
        AR=false
    end)
end

-- ═══════════════════════════════════════════════════════
-- UNIFIED HANDLER: ESP + AIM в одном проходе
-- ═══════════════════════════════════════════════════════
local function handleNew(o)
    if not o or not o.Parent then return end
    local m
    if o:IsA("Model") then
        m=o
    elseif o:IsA("Humanoid") or o:IsA("BasePart") then
        m=o.Parent
        if not m or not m:IsA("Model") then return end
    else
        return
    end
    if E1 or E2 or E3 then pM(m) end
    if B1 then aSB(m) aCM(m) end
end

local function eQ(o)
    if eQset[o] then return end
    eQset[o]=true
    eQlist[#eQlist+1]=o
    if eQscheduled then return end
    eQscheduled=true
    task.defer(function()
        eQscheduled=false
        local items=eQlist
        eQlist={}
        eQset={}
        for i=1,#items do
            handleNew(items[i])
        end
    end)
end

local function sT()
    W.DescendantAdded:Connect(function(o)
        if not (E1 or E2 or E3 or B1) then return end
        local cn=o.ClassName
        if cn=="Model" or cn=="Humanoid" or cn=="BasePart" or cn=="MeshPart" then
            eQ(o)
        end
    end)
    W.DescendantRemoving:Connect(function(o)
        if o:IsA("Model") then
            if AE[o] then rE(o) end
            rSB(o)
            rCM(o)
        elseif o:IsA("Humanoid") then
            local m=o.Parent
            if m and m:IsA("Model") then
                if AE[m] then rE(m) end
                rSB(m)
                rCM(m)
            end
        end
    end)
end

local function sA()
    rP()
    P.PlayerAdded:Connect(function(pl)
        rP()
        pl.CharacterAdded:Connect(function(ch)
            rP()
            -- Instant process on character spawn
            task.defer(function()
                if ch and ch.Parent then
                    if E1 or E2 or E3 then pM(ch) end
                end
            end)
        end)
        pl.CharacterRemoving:Connect(rP)
    end)
    P.PlayerRemoving:Connect(rP)
    for _,pl in ipairs(P:GetPlayers()) do
        pl.CharacterAdded:Connect(function(ch)
            rP()
            task.defer(function()
                if ch and ch.Parent then
                    if E1 or E2 or E3 then pM(ch) end
                end
            end)
        end)
        pl.CharacterRemoving:Connect(rP)
    end
end
sA()

-- ═══════════════════════════════════════════════════════
-- CATCH-UP SCAN (lightweight, every 0.35s)
-- ═══════════════════════════════════════════════════════
local catchT=0
R.Heartbeat:Connect(function(dt)
    catchT=catchT+dt
    if catchT<0.35 then return end
    catchT=0
    if not (E1 or E2 or E3 or B1) then return end
    -- Scan Workspace direct children only (fast)
    local ch=W:GetChildren()
    for i=1,#ch do
        local c=ch[i]
        if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then
            if (E1 or E2 or E3) and not AE[c] and not PD[c] then
                pM(c)
            end
            if B1 then
                if not CBset[c] and not CMset[c] and not P:GetPlayerFromCharacter(c) then
                    aSB(c)
                    aCM(c)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- ESP REFRESH (batched)
-- ═══════════════════════════════════════════════════════
local FS=false
local RQ=false

local function rF()
    if not E1 and not E2 and not E3 then cA() return end
    if FS then RQ=true return end
    FS=true
    task.spawn(function()
        for _,pl in ipairs(P:GetPlayers()) do
            if pl~=LP and pl.Character then pM(pl.Character) end
        end
        local hs={}
        local ms={}
        for _,o in ipairs(W:GetDescendants()) do
            if o:IsA("Humanoid") then hs[#hs+1]=o
            elseif o:IsA("Model") then ms[#ms+1]=o end
        end
        local tot=#hs
        local i=1
        while i<=tot do
            local s=math.min(i+59,tot)
            for j=i,s do
                local m=hs[j].Parent
                if m and m:IsA("Model") then pM(m) end
            end
            i=s+1
            if i<=tot then R.Heartbeat:Wait() end
        end
        tot=#ms
        i=1
        while i<=tot do
            local s=math.min(i+79,tot)
            for j=i,s do pM(ms[j]) end
            i=s+1
            if i<=tot then R.Heartbeat:Wait() end
        end
        FS=false
        if RQ then RQ=false rF() end
    end)
end

-- ═══════════════════════════════════════════════════════
-- AIM TARGETING
-- ═══════════════════════════════════════════════════════
local function gCT()
    local cl=nil
    local bs=math.huge
    local vp=CAM.ViewportSize
    local cx,cy=vp.X/2,vp.Y/2
    local ch=LP.Character
    local rt=ch and ch:FindFirstChild("HumanoidRootPart")
    local pp=rt and rt.Position or CAM.CFrame.Position
    local tg={}
    for i=#CP,1,-1 do
        local t=CP[i]
        if not t.aimPart or not t.aimPart.Parent then table.remove(CP,i)
        else tg[#tg+1]=t end
    end
    if B1 then
        for m,e in pairs(CBset) do
            if not e.aimPart or not e.aimPart.Parent then rSB(m)
            else tg[#tg+1]=e end
        end
        if E3 then
            for m,e in pairs(CMset) do
                if not e.aimPart or not e.aimPart.Parent then rCM(m)
                else tg[#tg+1]=e end
            end
        end
    end
    for _,t in ipairs(tg) do
        local ap=t.aimPart
        local pos=ap.Position
        local sp,os=CAM:WorldToViewportPoint(pos)
        if os then
            local dx,dy=sp.X-cx,sp.Y-cy
            local ds=math.sqrt(dx*dx+dy*dy)
            local ddx,ddy,ddz=pp.X-pos.X,pp.Y-pos.Y,pp.Z-pos.Z
            local wd=math.sqrt(ddx*ddx+ddy*ddy+ddz*ddz)
            local ef=gF(wd)
            if ds<=ef then
                local sc=ds+wd*0.04
                if sc<bs then
                    bs=sc
                    cl=t
                    CD=wd
                end
            end
        end
    end
    return cl
end

local function lT()
    if CT and CT.aimPart and CT.aimPart.Parent then
        local ap=CT.aimPart
        local tp=ap.Position
        if PR then
            local v=ap.Velocity or Vector3.new(0,0,0)
            local pd=math.clamp(0.05+(CD/2000),0.02,0.1)
            tp=tp+(v*pd)
        end
        CAM.CFrame=CAM.CFrame:Lerp(CFrame.new(CAM.CFrame.Position,tp),SM)
    else
        CT=nil
    end
end

R.RenderStepped:Connect(function()
    if not AB then return end
    if U:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not CT or not CT.aimPart or not CT.aimPart.Parent then CT=gCT() end
        if CT then lT() end
    else
        CT=nil
    end
end)

-- ═══════════════════════════════════════════════════════
-- REPAIR CYCLE (every ~0.4s)
-- ═══════════════════════════════════════════════════════
local rc=0
R.Heartbeat:Connect(function()
    rc=rc+1
    if rc<24 then return end
    rc=0
    for m,d in pairs(AE) do
        if not m.Parent then rE(m)
        else
            local hl,bb=d[1],d[2]
            local br=(not hl or not hl.Parent)
            if not br and bb then
                local p=bb.Parent
                if not p or not p:IsDescendantOf(m) then br=true end
            end
            if br then rE(m) pM(m) end
        end
    end
    for m,e in pairs(CBset) do
        if not m.Parent then rSB(m)
        elseif not e.aimPart or not e.aimPart.Parent then
            local root=m:FindFirstChild("HumanoidRootPart")
            if root then
                local ap=root
                if H2 then
                    local hd=m:FindFirstChild("Head")
                    if hd and hd:IsA("BasePart") then ap=hd end
                end
                e.aimPart=ap
            else rSB(m) end
        end
    end
    for m,e in pairs(CMset) do
        if not m.Parent then rCM(m)
        elseif not e.aimPart or not e.aimPart.Parent then
            local root=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if root then
                local ap=root
                if H2 then
                    local hd=m:FindFirstChild("Head") or m:FindFirstChild("head")
                    if hd and hd:IsA("BasePart") then ap=hd end
                end
                e.aimPart=ap
            else rCM(m) end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- GUI (unchanged)
-- ═══════════════════════════════════════════════════════

local SG=Instance.new("ScreenGui")
SG.Name="MEDW_Menu"
SG.Parent=C
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.ResetOnSpawn=false

local BG=Color3.fromRGB(15,16,20)
local HDR=Color3.fromRGB(18,19,24)
local BORD=Color3.fromRGB(32,33,38)
local TXT=Color3.fromRGB(232,233,238)
local TXT2=Color3.fromRGB(138,140,150)
local TXT3=Color3.fromRGB(80,82,90)
local ACCENT=Color3.fromRGB(122,140,255)
local TRACK_OFF=Color3.fromRGB(40,41,48)

local MF=Instance.new("Frame")
MF.Size=UDim2.new(0,280,0,300)
MF.Position=UDim2.new(0,40,0,40)
MF.BackgroundColor3=BG
MF.BorderSizePixel=0
MF.ClipsDescendants=true
MF.Active=true
MF.Draggable=true
MF.Parent=SG
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,10)
local MFStroke=Instance.new("UIStroke")
MFStroke.Color=BORD
MFStroke.Thickness=1
MFStroke.Parent=MF

local HD=Instance.new("Frame")
HD.Size=UDim2.new(1,0,0,36)
HD.BackgroundColor3=HDR
HD.BorderSizePixel=0
HD.Parent=MF

local MARK=Instance.new("Frame")
MARK.Size=UDim2.new(0,20,0,20)
MARK.Position=UDim2.new(0,12,0.5,-10)
MARK.BackgroundColor3=ACCENT
MARK.BorderSizePixel=0
MARK.Parent=HD
Instance.new("UICorner",MARK).CornerRadius=UDim.new(0,6)
local MARKT=Instance.new("TextLabel")
MARKT.Size=UDim2.new(1,0,1,0)
MARKT.BackgroundTransparency=1
MARKT.Text="M"
MARKT.TextColor3=Color3.fromRGB(255,255,255)
MARKT.Font=Enum.Font.GothamBold
MARKT.TextSize=10
MARKT.Parent=MARK

local TITLE=Instance.new("TextLabel")
TITLE.Size=UDim2.new(0,100,0,14)
TITLE.Position=UDim2.new(0,38,0,6)
TITLE.BackgroundTransparency=1
TITLE.Text="MEDW"
TITLE.TextColor3=TXT
TITLE.Font=Enum.Font.GothamBold
TITLE.TextSize=11
TITLE.TextXAlignment=Enum.TextXAlignment.Left
TITLE.TextYAlignment=Enum.TextYAlignment.Center
TITLE.Parent=HD

local SUB=Instance.new("TextLabel")
SUB.Size=UDim2.new(0,100,0,12)
SUB.Position=UDim2.new(0,38,0,18)
SUB.BackgroundTransparency=1
SUB.Text="esp + aimlock"
SUB.TextColor3=TXT3
SUB.Font=Enum.Font.Gotham
SUB.TextSize=9
SUB.TextXAlignment=Enum.TextXAlignment.Left
SUB.TextYAlignment=Enum.TextYAlignment.Center
SUB.Parent=HD

local CBtn=Instance.new("TextButton")
CBtn.Size=UDim2.new(0,22,0,22)
CBtn.Position=UDim2.new(1,-32,0.5,-11)
CBtn.BackgroundColor3=Color3.fromRGB(26,27,32)
CBtn.BorderSizePixel=0
CBtn.Text="−"
CBtn.TextColor3=TXT2
CBtn.Font=Enum.Font.GothamBold
CBtn.TextSize=14
CBtn.AutoButtonColor=false
CBtn.Parent=HD
Instance.new("UICorner",CBtn).CornerRadius=UDim.new(0,6)

local TB=Instance.new("Frame")
TB.Size=UDim2.new(1,0,0,28)
TB.Position=UDim2.new(0,0,0,36)
TB.BackgroundColor3=BG
TB.BorderSizePixel=0
TB.Parent=MF

local TSEP=Instance.new("Frame")
TSEP.Size=UDim2.new(1,0,0,1)
TSEP.Position=UDim2.new(0,0,0,64)
TSEP.BackgroundColor3=BORD
TSEP.BorderSizePixel=0
TSEP.Parent=MF

local TUND=Instance.new("Frame")
TUND.Size=UDim2.new(1/3,0,0,2)
TUND.Position=UDim2.new(0,0,0,62)
TUND.BackgroundColor3=ACCENT
TUND.BorderSizePixel=0
TUND.Parent=MF
Instance.new("UICorner",TUND).CornerRadius=UDim.new(1,0)

local tabNames={"Visuals","Aim","Config"}
local tabBtns={}

for i,name in ipairs(tabNames) do
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1/3,0,1,0)
    btn.Position=UDim2.new((i-1)/3,0,0,0)
    btn.BackgroundTransparency=1
    btn.Text=name
    btn.TextColor3=(i==1) and TXT or TXT3
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=10
    btn.AutoButtonColor=false
    btn.Parent=TB
    tabBtns[i]=btn
end

local CA=Instance.new("Frame")
CA.Size=UDim2.new(1,0,1,-124)
CA.Position=UDim2.new(0,0,0,65)
CA.BackgroundTransparency=1
CA.Parent=MF

local panes={}
for i=1,3 do
    local p=Instance.new("Frame")
    p.Size=UDim2.new(1,0,1,0)
    p.BackgroundTransparency=1
    p.Visible=(i==1)
    p.Parent=CA
    panes[i]=p
end

local function switchTab(i)
    for j,p in ipairs(panes) do p.Visible=(j==i) end
    for j,b in ipairs(tabBtns) do
        b.TextColor3=(j==i) and TXT or TXT3
    end
    TUND.Position=UDim2.new((i-1)/3,0,0,62)
end

for i,b in ipairs(tabBtns) do
    b.MouseButton1Click:Connect(function() switchTab(i) end)
end

local function mkRow(parent,y,label)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-24,0,28)
    row.Position=UDim2.new(0,12,0,y)
    row.BackgroundTransparency=1
    row.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.62,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.TextColor3=TXT2
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextYAlignment=Enum.TextYAlignment.Center
    lbl.Parent=row
    return row
end

local function mkToggle(parent,y,label,ini,cb)
    local row=mkRow(parent,y,label)
    local sw=Instance.new("TextButton")
    sw.Size=UDim2.new(0,30,0,16)
    sw.Position=UDim2.new(1,-30,0.5,-8)
    sw.BackgroundColor3=ini and ACCENT or TRACK_OFF
    sw.BorderSizePixel=0
    sw.Text=""
    sw.AutoButtonColor=false
    sw.Parent=row
    Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame")
    kn.Size=UDim2.new(0,10,0,10)
    kn.Position=ini and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,3,0.5,-5)
    kn.BackgroundColor3=Color3.fromRGB(255,255,255)
    kn.BorderSizePixel=0
    kn.Parent=sw
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local st=ini
    sw.MouseButton1Click:Connect(function()
        st=not st
        sw.BackgroundColor3=st and ACCENT or TRACK_OFF
        kn.Position=st and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,3,0.5,-5)
        cb(st)
    end)
    return sw
end

local function mkSlider(parent,y,label,mn,mx,ini,cb,fillColor)
    local row=mkRow(parent,y,label)
    local track=Instance.new("Frame")
    track.Size=UDim2.new(0,110,0,4)
    track.Position=UDim2.new(1,-110,0.5,-2)
    track.BackgroundColor3=TRACK_OFF
    track.BorderSizePixel=0
    track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local rel=(ini-mn)/(mx-mn)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(rel,0,1,0)
    fill.BackgroundColor3=fillColor or ACCENT
    fill.BorderSizePixel=0
    fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton")
    knob.Size=UDim2.new(0,10,0,10)
    knob.Position=UDim2.new(rel,-5,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(240,240,245)
    knob.BorderSizePixel=0
    knob.Text=""
    knob.AutoButtonColor=false
    knob.Parent=track
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local dg=false
    local function upd(ip)
        local rx=ip.X-track.AbsolutePosition.X
        local w=track.AbsoluteSize.X
        local v=math.clamp(rx/w,0,1)*(mx-mn)+mn
        v=math.round(v*100)/100
        local rv=(v-mn)/(mx-mn)
        fill.Size=UDim2.new(rv,0,1,0)
        knob.Position=UDim2.new(rv,-5,0.5,-5)
        cb(v)
    end
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dg=true upd(inp.Position) end
    end)
    U.InputChanged:Connect(function(inp)
        if dg and inp.UserInputType==Enum.UserInputType.MouseMovement then upd(inp.Position) end
    end)
    U.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then upd(inp.Position) dg=true end
    end)
    return fill,knob
end

mkToggle(panes[1],8,"Player ESP",E1,function(v) E1=v rF() end)
mkToggle(panes[1],38,"Bot ESP",E2,function(v) E2=v rF() end)
mkToggle(panes[1],68,"Model ESP",E3,function(v) E3=v rF() if B1 then rA() end end)

mkToggle(panes[2],8,"Aimlock",AB,function(v) AB=v if v then rP() end end)
mkToggle(panes[2],38,"Head Aim (P)",H1,function(v) H1=v rP() CT=nil end)
mkToggle(panes[2],68,"Bot Aim",B1,function(v) B1=v if v then rA() else CB={} CBset={} CM={} CMset={} end CT=nil end)
mkToggle(panes[2],98,"Head Aim (B)",H2,function(v) H2=v if B1 then rA() end CT=nil end)
mkToggle(panes[2],128,"Predict",PR,function(v) PR=v end)

mkSlider(panes[3],8,"Fill",0,1,FT,function(v) FT=v uC() end)
mkSlider(panes[3],38,"Outline",0,1,OT,function(v) OT=v uC() end)
mkSlider(panes[3],68,"Smooth",0.05,0.95,SM,function(v) SM=v end)

do
    local row=mkRow(panes[3],98,"Highlight")
    local track=Instance.new("Frame")
    track.Size=UDim2.new(0,110,0,4)
    track.Position=UDim2.new(1,-110,0.5,-2)
    track.BackgroundColor3=TRACK_OFF
    track.BorderSizePixel=0
    track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(0.66,0,1,0)
    fill.BackgroundColor3=CC
    fill.BorderSizePixel=0
    fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("TextButton")
    knob.Size=UDim2.new(0,10,0,10)
    knob.Position=UDim2.new(0.66,-5,0.5,-5)
    knob.BackgroundColor3=Color3.fromRGB(240,240,245)
    knob.BorderSizePixel=0
    knob.Text=""
    knob.AutoButtonColor=false
    knob.Parent=track
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local dg=false
    local function upd(ip)
        local rx=ip.X-track.AbsolutePosition.X
        local w=track.AbsoluteSize.X
        local v=math.clamp(rx/w,0,1)
        CC=Color3.fromHSV(v,1,1)
        fill.BackgroundColor3=CC
        fill.Size=UDim2.new(v,0,1,0)
        knob.Position=UDim2.new(v,-5,0.5,-5)
        uC()
    end
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dg=true upd(inp.Position) end
    end)
    U.InputChanged:Connect(function(inp)
        if dg and inp.UserInputType==Enum.UserInputType.MouseMovement then upd(inp.Position) end
    end)
    U.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then upd(inp.Position) dg=true end
    end)
end

local FT2=Instance.new("Frame")
FT2.Size=UDim2.new(1,0,0,42)
FT2.Position=UDim2.new(0,0,1,-42)
FT2.BackgroundColor3=HDR
FT2.BorderSizePixel=0
FT2.Parent=MF

local FSEP=Instance.new("Frame")
FSEP.Size=UDim2.new(1,0,0,1)
FSEP.Position=UDim2.new(0,0,0,0)
FSEP.BackgroundColor3=BORD
FSEP.BorderSizePixel=0
FSEP.Parent=FT2

local DOT=Instance.new("Frame")
DOT.Size=UDim2.new(0,8,0,8)
DOT.Position=UDim2.new(0,14,0.5,-4)
DOT.BackgroundColor3=Color3.fromRGB(90,92,100)
DOT.BorderSizePixel=0
DOT.Parent=FT2
Instance.new("UICorner",DOT).CornerRadius=UDim.new(1,0)

local DLW=Instance.new("TextLabel")
DLW.Size=UDim2.new(0,100,0,42)
DLW.Position=UDim2.new(0,28,0,0)
DLW.BackgroundTransparency=1
DLW.Text="TARGET"
DLW.TextColor3=TXT3
DLW.Font=Enum.Font.GothamBold
DLW.TextSize=10
DLW.TextXAlignment=Enum.TextXAlignment.Left
DLW.TextYAlignment=Enum.TextYAlignment.Center
DLW.Parent=FT2

local DL=Instance.new("TextLabel")
DL.Size=UDim2.new(0,150,0,42)
DL.Position=UDim2.new(1,-164,0,0)
DL.BackgroundTransparency=1
DL.Text="—"
DL.TextColor3=TXT3
DL.Font=Enum.Font.GothamBold
DL.TextSize=20
DL.TextXAlignment=Enum.TextXAlignment.Right
DL.TextYAlignment=Enum.TextYAlignment.Center
DL.Parent=FT2

R.RenderStepped:Connect(function()
    if AB and CT and CT.aimPart and CT.aimPart.Parent then
        local rt=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if rt then
            local d=(rt.Position-CT.aimPart.Position).Magnitude
            DL.Text=math.floor(d).." m"
            DL.TextColor3=ACCENT
            DOT.BackgroundColor3=ACCENT
        else
            DL.Text="—"
            DL.TextColor3=TXT3
            DOT.BackgroundColor3=Color3.fromRGB(90,92,100)
        end
    else
        DL.Text="—"
        DL.TextColor3=TXT3
        DOT.BackgroundColor3=Color3.fromRGB(90,92,100)
    end
end)

local CCB=Instance.new("TextButton")
CCB.Size=UDim2.new(0,34,0,34)
CCB.BackgroundColor3=BG
CCB.BorderSizePixel=0
CCB.Visible=false
CCB.Text="−"
CCB.TextColor3=TXT
CCB.Font=Enum.Font.GothamBold
CCB.TextSize=18
CCB.AutoButtonColor=false
CCB.ZIndex=10
CCB.Parent=SG
Instance.new("UICorner",CCB).CornerRadius=UDim.new(0,17)
local CCBSTR=Instance.new("UIStroke")
CCBSTR.Color=BORD
CCBSTR.Thickness=1
CCBSTR.Parent=CCB

local function sCP()
    local bp=CBtn.AbsolutePosition
    if bp.X>0 and bp.Y>0 then
        local ox=(34-22)/2
        local oy=(34-22)/2
        CCB.Position=UDim2.new(0,bp.X-ox,0,bp.Y-oy)
    end
end

CBtn.MouseButton1Click:Connect(function()
    sCP()
    CCB.Visible=true
    MF.Visible=false
end)

CCB.MouseButton1Click:Connect(function()
    CCB.Visible=false
    MF.Visible=true
end)

MF:GetPropertyChangedSignal("Position"):Connect(function()
    if CCB.Visible then sCP() end
end)

MF.Visible=true
CCB.Visible=false

sT()
rF()
