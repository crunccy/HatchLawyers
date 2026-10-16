local Scene=require(script.Parent.Scene)
local M={}
function M.start(info,send)
 local s=Scene.new('LUCKY BRIEFCASE',{distance=15,height=3.8,aim=Vector3.new(0,1.6,0)})
 local desk=s:asset('LuckyBriefcaseTable',CFrame.new()); s:face(desk.TitleBoard,'FOLLOW THE GOLD STAR')
 local cases,bases,slots,prizes={},{},{1,2,3},{}
 for i=1,3 do
  local m=s:asset('LuckyBriefcase',CFrame.new((i-2)*3.3,1.2,0)); cases[i]=m; bases[i]=m.Lid:GetPivot()
  local prize=s:part('Prize',Vector3.new(.75,.75,.14),CFrame.new((i-2)*3.3,1.5,0),Color3.fromRGB(255,200,40)); prizes[i]=prize; prize.Transparency=1
  local l=s:face(prize,if i==info.big then '★' else '$'); l.Parent.Enabled=false
 end
 local phase='wait'; local picked=false; local completed=0
 local closeAt=info.startAt+info.showTime; local swapAt=closeAt+info.closeTime
 local function prizesVisible(visible)
  for _,p in prizes do p.Transparency=if visible then 0 else 1; p:FindFirstChildWhichIsA('SurfaceGui').Enabled=visible end
 end
 s:input(function(i)
  if phase~='pick' or picked then return end
  local hit=s:hit(i,cases); if not hit then return end
  for slot,id in slots do if hit:IsDescendantOf(cases[id]) then picked=true; s:sound('pop'); s.hint.Text='Opening your case…'; send('Pick',info.id,slot); break end end
 end)
 s:step(function()
  if s.ended then return end
  local t=Scene.now()
  if phase=='wait' and t>=info.startAt then
   phase='show'; s.hint.Text='Remember the STAR case!'; prizesVisible(true)
   for i,m in cases do s:animate(m.Lid,'LidOpen',bases[i]) end
  end
  if phase=='show' and t>=closeAt then
   phase='shuffle'; prizesVisible(false); s.hint.Text='Keep your eyes on the star…'
   for i,m in cases do s:animate(m.Lid,'LidClose',bases[i]) end
  end
  if phase=='shuffle' and t>=swapAt then
   local done=math.min(#info.swaps,math.floor((t-swapAt)/info.swapTime))
   while completed<done do
    completed+=1; local pair=info.swaps[completed]; slots[pair[1]],slots[pair[2]]=slots[pair[2]],slots[pair[1]]
    for slot,id in slots do s:place(cases[id],CFrame.new((slot-2)*3.3,1.2,0)) end
   end
   if completed<#info.swaps then
    local pair=info.swaps[completed+1]; local u=math.clamp((t-swapAt-completed*info.swapTime)/info.swapTime,0,1); local pose=Scene.sample('Shuffle',u); local e=pose.X+.5
    for k=1,2 do local a,b=pair[k],pair[3-k]; local id=slots[a]
     s:place(cases[id],CFrame.new(((a-2)+(b-a)*e)*3.3,1.2+pose.Y,(if k==1 then 1 else -1)*pose.Z*3.15)*pose.Rotation)
    end
   end
   if t>=info.pickAt then phase='pick'; s.hint.Text='Which case holds the STAR? Tap to choose!' end
  end
  if phase=='show' then for i,p in prizes do p.CFrame=CFrame.new((i-2)*3.3,4002.15+math.sin(t*3)*.1,.2)*CFrame.Angles(0,math.sin(t*2)*.18,0) end end
 end)
 local game={scene=s,id=info.id}
 function game.result(a)
  if s.closed then return end; picked=true; phase='result'
  local id=slots[a.slot or 1]; local m=cases[id]; local hinge=m.Lid:GetPivot()
  s:animate(m.Lid,'LidOpen',hinge)
  local p=prizes[id]; p.CFrame=m:GetPivot()*CFrame.new(0,1,.1); p.Transparency=0; p:FindFirstChildWhichIsA('SurfaceGui').Enabled=true
  s.hint.Text=if a.big then 'YOU FOUND THE STAR!' else 'Your prize!'
  task.delay(.65,function() s:finish(a) end)
 end
 return game
end
return M
