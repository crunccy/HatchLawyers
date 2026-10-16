local Scene=require(game.ReplicatedStorage.MinigameClient.Scene)
local M={}
local colors={Color3.fromRGB(240,70,70),Color3.fromRGB(98,205,48),Color3.fromRGB(60,160,235),Color3.fromRGB(255,200,40)}
local names={'● RED','■ GREEN','◆ BLUE','★ GOLD'}
local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four}
function M.play(info,api)
 local s=Scene.new('FILING FRENZY',{distance=17,height=4.1,aim=Vector3.new(0,1.8,0)})
 local machine=s:asset('FilingMachine',CFrame.new()); s:face(machine.TitleBoard,'SORT THE CASE FILES')
 local bins,bases,files,state,pending={},{},{},{},{}
 local front,filed,misses=1,0,0
 for i=1,info.colors do
  local m=s:asset('FileBin',CFrame.new((i-(info.colors+1)/2)*2.65,.1,2.2)); bins[i]=m; bases[i]=m.Lid:GetPivot()
  for _,p in m:GetDescendants() do if p:IsA('BasePart') and p.Name~='Label' then p.Color=colors[i] end end
  local face=m:FindFirstChild('Label'); if face then s:face(face,tostring(i)..'  '..names[i]) end
 end
 local function advance() while state[front] do front+=1 end end
 local function sort(bin)
  local i=front; local p=info.papers[i]
  if not p or not files[i] or state[i] or Scene.now()<info.startAt+p.at then return end
  state[i]='pending'; pending[i]=bin; advance(); api.send('Sort',{i=i,bin=bin,t=Scene.now()})
  s:animate(bins[bin].Lid,'LidOpen',bases[bin]); task.delay(.35,function() if not s.closed then s:animate(bins[bin].Lid,'LidClose',bases[bin]) end end)
 end
 s:input(function(input)
  for i,m in bins do if input.KeyCode==keys[i] or s:hit(input,{m}) then sort(i); return end end
 end)
 api.onAck(function(a)
  if s.closed or s.ended then return end
  local i=a.i or a.shred; if not i then return end
  if a.shred then for j=1,i do state[j]='done'; if j~=i and files[j] then files[j]:Destroy() end end end
  state[i]='done'; misses=a.misses or misses; if a.ok then filed+=1 end; advance()
  local m=files[i]
  if m then
   local start=os.clock(); local from=m:GetPivot(); local bin=pending[i]
   local dest=if bin then bins[bin]:GetPivot()*CFrame.new(0,.6,0) else CFrame.new(5.1,4000.5,-.8)
   s:step(function()
    if not m.Parent then return end
    local t=math.clamp((os.clock()-start)/.35,0,1); local pose=Scene.sample('FileFlight',t*.35); m:PivotTo(from:Lerp(dest,pose.X)*CFrame.new(0,pose.Y,0)*pose.Rotation)
    if t>=1 then m:Destroy() end
   end)
  end
  api.kit.sound(if a.ok then 'good' else 'bad')
  s.counter.Text=string.format('%d FILED    •    %d / %d mistakes',filed,misses,info.misses)
 end)
 s:step(function()
  if s.ended then return end
  local t=Scene.now()-info.startAt
  for i,p in info.papers do
   if t>=p.at and not state[i] then
    if not files[i] then
     local m=s:asset('CaseFile',CFrame.new()); files[i]=m
     for _,v in m:GetChildren() do if v:IsA('BasePart') and (v.Name=='Folder' or v.Name=='Tab' or v.Name=='Seal') then v.Color=colors[p.color] end end
     local seal=m:FindFirstChild('Seal'); if seal then s:face(seal,({'●','■','◆','★'})[p.color]) end
    end
    local u=math.clamp((t-p.at)/p.travel,0,1)
    s:place(files[i],CFrame.new(-4.6+9.2*u,1.3,-.65)*CFrame.Angles(0,0,math.sin(t*4+i)*.025))
   end
  end
  local p=info.papers[front]
  s.hint.Text=if p and files[front] then 'File the oldest folder → '..names[p.color] else 'Tap a matching bin • Keyboard: 1 / 2 / 3'
 end)
 s:finish(api.result(function() return s.closed end)); while not s.closed do task.wait(.1) end
end
return M
