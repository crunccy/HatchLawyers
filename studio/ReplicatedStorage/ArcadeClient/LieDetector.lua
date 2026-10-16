local Scene=require(game.ReplicatedStorage.MinigameClient.Scene)
local M={}
function M.play(info,api)
 local s=Scene.new('LIE DETECTOR',{distance=12,height=2.8,aim=Vector3.new(0,1.5,0)})
 local machine=s:asset('LieDetectorMachine',CFrame.new()); s:face(machine.TitleBoard,'TRUTH OR LIE?')
 local button=machine.Plunger; local base=button:GetPivot()
 local band=s:part('Truth zone',Vector3.new(1,.85,.04),CFrame.new(0,1.75,1.14),Color3.fromRGB(98,205,48))
 local needle=s:part('Needle',Vector3.new(.09,1.05,.1),CFrame.new(0,1.75,1.21),Color3.fromRGB(255,200,40))
 local current=0; local tapped={}; local hits=0; local feedback=''
 s:input(function(i)
  local round=info.rounds[current]; if not round or tapped[current] then return end
  local t=Scene.now(); local elapsed=t-(info.startAt+(current-1)*(info.roundTime+info.gap))
  if elapsed<0 or elapsed>=info.roundTime then return end
  if Scene.isTap(i) or s:hit(i,{button}) then
   tapped[current]=true; s:animate(button,'Press',base); api.send('Tap',{t=t}); s.hint.Text='Checking…'
  end
 end)
 api.onAck(function(a)
  if s.closed or s.ended then return end
  if a.hit then hits+=1; feedback=if a.perfect then 'PERFECT!' else 'TRUTH!'; s:pulse(CFrame.new(0,2,1),Color3.fromRGB(98,205,48)) else feedback='Missed — try the next one!' end
  s.hint.Text=feedback; api.kit.sound(if a.hit then 'good' else 'bad')
 end)
 s:step(function()
  if s.ended then return end
  local elapsed=Scene.now()-info.startAt
  local r=math.floor(math.max(0,elapsed)/(info.roundTime+info.gap))+1
  if r>#info.rounds then s.hint.Text='Checking the final verdict…'; return end
  if r~=current then current=r; feedback=''; s.hint.Text='Press the red button when the needle is in GREEN' end
  local rd=info.rounds[r]; local t=elapsed-(r-1)*(info.roundTime+info.gap)
  band.Size=Vector3.new(rd.band*5.6,.85,.04); band.CFrame=CFrame.new(0,4000,0)*CFrame.new(rd.centre*2.8,1.75,1.14)
  if not tapped[r] then
   local x=math.sin(2*math.pi*(t/rd.period+rd.phase))
   needle.CFrame=CFrame.new(x*2.8,4001.75,1.21)
  end
  s.counter.Text=string.format('ROUND %d / %d    •    %d correct',r,#info.rounds,hits)
  if t>=info.roundTime and not tapped[r] then s.hint.Text='Next round…' end
 end)
 s:finish(api.result(function() return s.closed end)); while not s.closed do task.wait(.1) end
end
return M
