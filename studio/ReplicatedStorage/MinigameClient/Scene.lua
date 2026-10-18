-- Shared client-only cinematic stage. Geometry and prop motion originate in Blender.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local Input = game:GetService('UserInputService')
local CAS = game:GetService('ContextActionService')
local Lighting = game:GetService('Lighting')
local Data = require(script.Parent:WaitForChild('AssetData'))
local ZFight = require(RS:WaitForChild('Shared'):WaitForChild('ZFight'))
local Scene = {}; Scene.__index = Scene
local active
local origin = CFrame.new(0,4000,0)
local function cf(p,r) return CFrame.new(p[1],p[2],p[3],table.unpack(r)) end
local function label(parent,text,y,h)
 local l=Instance.new('TextLabel'); l.BackgroundTransparency=1; l.AnchorPoint=Vector2.new(.5,.5)
 l.Position=UDim2.fromScale(.5,y); l.Size=UDim2.fromScale(.86,h); l.Text=text; l.TextScaled=true
 l.FontFace=Font.new('rbxasset://fonts/families/FredokaOne.json'); l.TextColor3=Color3.new(1,1,1)
 local st=Instance.new('UIStroke'); st.Thickness=2.5; st.Color=Color3.fromRGB(40,40,52); st.Parent=l
 local cap=Instance.new('UITextSizeConstraint'); cap.MaxTextSize=38; cap.MinTextSize=12; cap.Parent=l
 l.Parent=parent; return l
end
function Scene.cancel() if active then active:close() end end
function Scene.new(title,opts)
 Scene.cancel(); opts=opts or {}
 local self=setmetatable({connections={},steps={},animations={},hidden={},closed=false,ended=false,aim=opts.aim or Vector3.new(0,2,0),distance=opts.distance or 16,height=opts.height or 4.6},Scene); active=self
 self.root=Instance.new('Folder'); self.root.Name='CinematicMinigame'; self.root.Parent=workspace
 self.gui=Instance.new('ScreenGui'); self.gui.Name='MinigameCinema'; self.gui.ResetOnSpawn=false; self.gui.IgnoreGuiInset=true; self.gui.DisplayOrder=120; self.gui:SetAttribute('NoSkin',true)
 local pg=Players.LocalPlayer:WaitForChild('PlayerGui'); self.gui.Parent=pg
 self.title=label(self.gui,title,.075,.055); self.counter=label(self.gui,'',.14,.035); self.hint=label(self.gui,'Get ready…',.9,.045)
 local function hide(g)
  if g==self.gui or not g:IsA('LayerCollector') then return end
  self.hidden[g]=g.Enabled; g.Enabled=false
  table.insert(self.connections,g:GetPropertyChangedSignal('Enabled'):Connect(function() if not self.closed and g.Enabled then g.Enabled=false end end))
 end
 for _,g in pg:GetDescendants() do hide(g) end
 table.insert(self.connections,pg.DescendantAdded:Connect(hide))
 self.camera=workspace.CurrentCamera; self.saved={self.camera.CameraType,self.camera.CameraSubject,self.camera.CFrame,self.camera.FieldOfView}
 self.camera.CameraType=Enum.CameraType.Scriptable
 self.age=0; self.shake=0
 self.fx=Instance.new('ColorCorrectionEffect'); self.fx.Name='MinigameColor'; self.fx.Saturation=.12; self.fx.Contrast=.06; self.fx.Parent=Lighting
 self.dof=Instance.new('DepthOfFieldEffect'); self.dof.Name='MinigameFocus'; self.dof.InFocusRadius=9; self.dof.FarIntensity=.22; self.dof.NearIntensity=0; self.dof.Parent=Lighting
 CAS:BindActionAtPriority('MinigameFreeze',function() return Enum.ContextActionResult.Sink end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Thumbstick1)
 local character=Players.LocalPlayer.Character; self.humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if self.humanoid then self.movement={self.humanoid.WalkSpeed,self.humanoid.JumpPower,self.humanoid.JumpHeight,self.humanoid.AutoRotate}; self.humanoid.WalkSpeed=0; self.humanoid.JumpPower=0; self.humanoid.JumpHeight=0; self.humanoid.AutoRotate=false end
 table.insert(self.connections,Players.LocalPlayer.CharacterRemoving:Connect(function() self:close() end))
 self:asset('ArcadeStage',CFrame.new())
 Run:BindToRenderStep('MinigameCinema',Enum.RenderPriority.Camera.Value+2,function(dt)
  if self.closed then return end
  self.age+=dt
  local aspect=self.camera.ViewportSize.X/math.max(1,self.camera.ViewportSize.Y)
  local distance=self.distance*math.max(1,1.55/aspect)+1.5*math.exp(-self.age*3)
  local aim=origin.Position+self.aim
  local target=CFrame.lookAt(aim+Vector3.new(0,self.height,distance),aim)
  if self.age<=dt then self.camera.CFrame=target else self.camera.CFrame=self.camera.CFrame:Lerp(target,1-math.exp(-dt*9)) end
  self.camera.CameraType=Enum.CameraType.Scriptable; self.camera.FieldOfView=42
  self.dof.FocusDistance=(self.camera.CFrame.Position-aim).Magnitude
  for _,fn in self.steps do local ok,err=pcall(fn,dt); if not ok then warn('[Minigame scene] '..tostring(err)); self:close(); break end end
 end)
 task.delay(240,function() if not self.closed then self:close() end end)
 return self
end
function Scene:part(name,size,at,color)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=origin*at; p.Color=color or Color3.new(1,1,1)
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.Material=Enum.Material.Plastic; p.TopSurface=Enum.SurfaceType.Studs; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=self.root; return p
end
function Scene:asset(name,at,scale)
 local m=Instance.new('Model'); m.Name=name; local groups={}; scale=scale or Vector3.one
 for _,row in Data.models[name] do
  local p=self:part(row.n,Vector3.new(table.unpack(row.s))*scale,CFrame.new(),Color3.fromRGB(table.unpack(row.c)))
  if row.shape=='Cylinder' then p.Shape=Enum.PartType.Cylinder; p.TopSurface=Enum.SurfaceType.Smooth end
  local pos=Vector3.new(table.unpack(row.p))*scale
  p.CFrame=origin*at*CFrame.new(pos)*cf({0,0,0},row.r)
  if row.g then
   if not groups[row.g] then local g=Instance.new('Model'); g.Name=row.g; g.Parent=m; groups[row.g]=g end
   p.Parent=groups[row.g]
  else p.Parent=m end
 end
 for _=1,2 do if ZFight.fix({m},{noYield=true})==0 then break end end -- flickering coplanar faces (bug 6)
 m.WorldPivot=origin*at; m.Parent=self.root
 for name,g in groups do g.WorldPivot=origin*at*CFrame.new(Vector3.new(table.unpack(Data.groups[m.Name][name]))*scale) end
 return m
end
function Scene:place(m,at) m:PivotTo(origin*at) end
function Scene:face(p,text,color)
 local g=Instance.new('SurfaceGui'); g.Face=Enum.NormalId.Back; g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud=70; g.LightInfluence=0; g.Parent=p
 local l=label(g,text,.5,.85); l.Size=UDim2.fromScale(.92,.85); if color then l.TextColor3=color end; return l
end
function Scene:step(fn) table.insert(self.steps,fn) end
-- If the server's result never comes (a dropped message), end the round anyway shortly after it should have ended,
-- instead of holding the player in the scene until the 240 s fallback.
function Scene:deadline(t) self:step(function() if not self.ended and Scene.now()>t then self:finish(nil) end end) end
function Scene:input(fn)
 table.insert(self.connections,Input.InputBegan:Connect(function(input,processed)
  if not self.closed and not self.ended and not Input:GetFocusedTextBox() and (not processed or Scene.isTap(input)) then fn(input) end
 end))
end
function Scene:hit(input,targets)
 if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return nil end
 -- (input.Position is in viewport space - it leaves out the top bar - so ScreenPointToRay aimed 58 px too high)
 local ray=self.camera:ViewportPointToRay(input.Position.X,input.Position.Y)
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances=targets
 local result=workspace:Raycast(ray.Origin,ray.Direction*200,params); return result and result.Instance
end
function Scene.sample(clip,t)
 local frames=Data.clips[clip]; local duration=frames[#frames].t
 t=math.clamp(t,0,duration); local idx=math.min(#frames-1,math.floor(t*60)+1)
 local a,b=frames[idx],frames[idx+1]; local alpha=math.clamp((t-a.t)/math.max(.001,b.t-a.t),0,1)
 return cf(a.p,a.r):Lerp(cf(b.p,b.r),alpha)
end
function Scene:animate(m,clip,base,speed)
 local frames=Data.clips[clip]; if not frames then return end
 local token={}; self.animations[m]=token; base=base or m:GetPivot(); speed=speed or 1
 task.spawn(function()
  local start=os.clock(); local duration=frames[#frames].t
  repeat
   if self.closed or not m.Parent or self.animations[m]~=token then return end
   local t=math.min((os.clock()-start)*speed,duration); local idx=math.min(#frames-1,math.floor(t*60)+1)
   local a,b=frames[idx],frames[idx+1]; local alpha=math.clamp((t-a.t)/math.max(.001,b.t-a.t),0,1)
   m:PivotTo(base*cf(a.p,a.r):Lerp(cf(b.p,b.r),alpha))
   if t>=duration then break end
   Run.RenderStepped:Wait()
  until false
 end)
end
function Scene:sound(name)
 local kit=RS:FindFirstChild('ArcadeClient'); if kit and kit:FindFirstChild('Kit') then require(kit.Kit).sound(name) end
end
function Scene:pulse(at,color)
 for i=1,10 do
  local angle=i*math.pi*.2; local p=self:part('Confetti',Vector3.new(.16,.3,.08),at,color or Color3.fromRGB(255,200,40))
  local start=os.clock(); local base=p.CFrame; local conn
  conn=Run.RenderStepped:Connect(function()
   local t=os.clock()-start
   if self.closed or t>.7 then conn:Disconnect(); p:Destroy(); return end
   p.CFrame=base*CFrame.new(math.cos(angle)*t*4,t*5-t*t*10,math.sin(angle)*t*2)*CFrame.Angles(t*6,t*4,0); p.Transparency=t/.7
  end)
 end
end
function Scene:finish(result)
 if self.closed or self.ended then return end; self.ended=true
 self.counter.Text=(result and (result.reward or result.text)) or 'Round over!'
 self.hint.Text='Nice playing!'; self:pulse(CFrame.new(0,3,0))
 task.delay(1.2,function()
  if self.closed then return end
  local b=Instance.new('TextButton'); b.Name='Continue'; b.Text='CONTINUE'; b.FontFace=self.hint.FontFace; b.TextSize=22; b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Color3.fromRGB(98,205,48); b.AnchorPoint=Vector2.new(.5,.5); b.Position=UDim2.fromScale(.5,.9); b.Size=UDim2.fromOffset(210,50); b.Parent=self.gui
  local c=Instance.new('UICorner'); c.CornerRadius=UDim.new(0,14); c.Parent=b; self.hint.Visible=false
  table.insert(self.connections,b.Activated:Connect(function() self:close() end))
 end)
 task.delay(12,function() self:close() end)
end
function Scene:close()
 if self.closed then return end; self.closed=true
 Run:UnbindFromRenderStep('MinigameCinema'); CAS:UnbindAction('MinigameFreeze')
 for _,c in self.connections do c:Disconnect() end
 for g,enabled in self.hidden do if g.Parent then g.Enabled=enabled end end
 self.camera.CameraType=self.saved[1]; self.camera.CameraSubject=self.saved[2]; self.camera.CFrame=self.saved[3]; self.camera.FieldOfView=self.saved[4]
 if self.humanoid and self.humanoid.Parent then self.humanoid.WalkSpeed=self.movement[1]; self.humanoid.JumpPower=self.movement[2]; self.humanoid.JumpHeight=self.movement[3]; self.humanoid.AutoRotate=self.movement[4] end
 self.fx:Destroy(); self.dof:Destroy(); self.root:Destroy(); self.gui:Destroy(); if active==self then active=nil end
end
Scene.now=function() return workspace:GetServerTimeNow() end
Scene.isTap=function(i) return i.KeyCode==Enum.KeyCode.Space or i.KeyCode==Enum.KeyCode.E or i.KeyCode==Enum.KeyCode.ButtonA end
return Scene
