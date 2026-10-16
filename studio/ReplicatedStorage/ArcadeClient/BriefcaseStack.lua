local Scene=require(game.ReplicatedStorage.MinigameClient.Scene)
local M={}
local function tri(u) local f=u%1; return if f<.5 then -1+4*f else 3-4*f end
function M.play(info,api)
 local s=Scene.new('BRIEFCASE STACK',{distance=14,height=3.1,aim=Vector3.new(0,1.3,0)})
 local stand=s:asset('StackPedestal',CFrame.new()); s:face(stand.TitleBoard,'STACK TO THE TOP')
 local left,right=-info.width/2,info.width/2
 local level,slideAt,period,phase=1,info.slideAt,info.period,info.phase
 local waiting=false; local over=false; local moving
 local function case(width,x,y)
  return s:asset('StackCase',CFrame.new(x*.5,y,0),Vector3.new(math.max(.03,width/6),1,1))
 end
 local function spawn() moving=case(right-left,0,.65+(level-1)*.43+.45) end
 spawn(); s.counter.Text='0 / '..info.levels; s.hint.Text='Tap the moving case or press SPACE to drop it'
 s:input(function(i)
  if waiting or over or Scene.now()<slideAt then return end
  if Scene.isTap(i) or s:hit(i,{moving}) then waiting=true; api.send('Drop',{t=Scene.now()}); s.hint.Text='Dropping…' end
 end)
 api.onAck(function(a)
  if s.closed or s.ended or a.level~=level then return end
  local oldWidth=right-left
  if moving then moving:Destroy() end
  if a.fell then
   over=true; local dropped=case(oldWidth,a.x,.65+(level-1)*.43)
   s:animate(dropped,'Duck',dropped:GetPivot(),.35); s.hint.Text='The case missed!'; api.kit.sound('bad'); return
  end
  local y=.65+(a.level-1)*.43
  local landed=case(a.right-a.left,(a.left+a.right)/2,y)
  s:animate(landed,'StackDrop',landed:GetPivot())
  local l0,r0=a.x-oldWidth/2,a.x+oldWidth/2
  if not a.perfect then
   for _,edge in {{l0,a.left},{a.right,r0}} do
    if edge[2]-edge[1]>.03 then local cut=case(edge[2]-edge[1],(edge[1]+edge[2])/2,y); s:animate(cut,'Duck',cut:GetPivot(),.3); task.delay(.8,function() cut:Destroy() end) end
   end
  end
  left,right=a.left,a.right; s.counter.Text=string.format('%d / %d',a.level,info.levels)
  s.hint.Text=if a.perfect then 'PERFECT! Keep going!' else 'Nice! Line up the next case'
  api.kit.sound(if a.perfect then 'perfect' else 'thud')
  if a.perfect then s:pulse(CFrame.new((left+right)*.25,y,0)) end
  s.aim=Vector3.new(0,math.max(1.3,y),0)
  if a.top then over=true; s.hint.Text='FULL TOWER!'; return end
  if a.next then level,slideAt,period,phase=a.next.level,a.next.slideAt,a.next.period,a.next.phase; waiting=false; spawn() end
 end)
 s:step(function()
  if not over and not waiting and moving and moving.Parent then
   local t=math.max(0,Scene.now()-slideAt); local x=info.travel*tri(t/period+phase)
   s:place(moving,CFrame.new(x*.5,.65+(level-1)*.43+.45,0))
  end
 end)
 s:finish(api.result(function() return s.closed end)); while not s.closed do task.wait(.1) end
end
return M
