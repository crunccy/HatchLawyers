local Scene=require(script.Parent.Scene)
local M={}
function M.start(info,send)
 local s=Scene.new('GAVEL BONK',{distance=17,height=4.4,aim=Vector3.new(0,2.3,0)})
 local bench=s:asset('GavelBench',CFrame.new()); s:face(bench.TitleBoard,'BONK ROBBERS • SAVE JUDGES')
 s.hint.Text='Tap the robbers. Let the judges pass!'
 local mallet=s:asset('GavelMallet',CFrame.new(5,4,1)); local home=mallet:GetPivot()
 local holes={}; local nextPop=1; local current={}; local locked=false
 for i=1,info.holes do
  local row=math.floor((i-1)/3); local col=(i-1)%3
  holes[i]=CFrame.new((col-1)*3.25,.33+(2-row)*1.2,(row-1)*2.05)
 end
 local function hide(id)
  local p=current[id]; if not p then return end; current[id]=nil
  s:animate(p.model,'Duck',p.base); task.delay(.2,function() p.model:Destroy() end)
 end
 s:input(function(input)
  if locked then return end
  local models={}; for _,p in current do table.insert(models,p.model) end
  local hit=s:hit(input,models); if not hit then return end
  for id,p in current do
   if hit:IsDescendantOf(p.model) then
    locked=true; s:sound(if p.pop.kind=='Judge' then 'bad' else 'thud'); send('Bonk',info.id,p.pop.id)
    local impact=CFrame.new(0,4000,0)*holes[id]*CFrame.new(0,1.45,.3)
    s:animate(mallet,'Bonk',impact)
    task.delay(.1,function()
     if s.closed then return end
     s:pulse(holes[id]*CFrame.new(0,1.1,0),if p.pop.kind=='Judge' then Color3.fromRGB(240,70,70) else Color3.fromRGB(255,200,40)); hide(id)
     s.hint.Text=if p.pop.kind=='Judge' then 'Careful! Leave the judges alone' else 'BONK!'
    end)
    task.delay(.4,function() locked=false; if not s.closed then mallet:PivotTo(home) end end)
    break
   end
  end
 end)
 s:step(function()
  if s.ended then return end
  local elapsed=Scene.now()-info.startAt
  while nextPop<=#info.pops and elapsed>=info.pops[nextPop].t do
   local p=info.pops[nextPop]; nextPop+=1
   hide(p.hole)
   if elapsed<p.t+p.stay then
    local m=s:asset(if p.kind=='Judge' then 'BonkJudge' else 'BonkRobber',holes[p.hole])
    local base=m:GetPivot(); current[p.hole]={pop=p,model=m,base=base}; s:animate(m,'Pop',base)
   end
  end
  for id,p in current do if elapsed>=p.pop.t+p.pop.stay then hide(id) end end
  s.title.Text='GAVEL BONK  •  '..math.max(0,math.ceil(info.duration-math.max(0,elapsed)))..'s'
  if elapsed<0 then s.hint.Text='Tap the robbers. Let the judges pass!' end
 end)
 s:deadline(info.startAt+info.duration+6)
 local game={scene=s,id=info.id}
 function game.ack(a) if not s.closed then s.counter.Text=tostring(a.score)..' POINTS' end end
 function game.result(a) s:finish(a) end
 return game
end
return M
