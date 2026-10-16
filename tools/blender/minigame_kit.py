"""Five cinematic brick minigames. Blender is the source for geometry AND sampled prop clips.
All authored coordinates below use Roblox axes (X right, Y up, +Z toward the camera).
Run: Blender --background --python tools/blender/minigame_kit.py
"""
import bpy, json, math, os
from mathutils import Matrix, Vector, Euler
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'../..'))
OUT=os.path.join(ROOT,'art/minigames'); os.makedirs(OUT,exist_ok=True)
sc=bpy.data.scenes.new('MinigameKitV2'); sc.render.fps=60
if bpy.context.window: bpy.context.window.scene=sc
C=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
DATA={'version':2,'models':{},'groups':{},'clips':{}}
ROOTS={}; OBJS={}; serial=0
CREAM=(246,226,180); WHITE=(250,246,224); WOOD=(214,140,70); DARK=(122,70,34)
INK=(40,40,52); BLUE=(60,160,235); CYAN=(90,218,232); GREEN=(98,205,48)
RED=(240,70,70); YELLOW=(255,200,40); PURPLE=(143,93,215)

def model(name,offset):
 root=bpy.data.objects.new(name,None); sc.collection.objects.link(root); root.location=C@Vector(offset)
 ROOTS[name]=root; DATA['models'][name]=[]; DATA['groups'][name]={}; return name

def part(m,n,p,s,c,rot=(0,0,0),kind='Block',g=None):
 global serial
 serial+=1
 r=Euler(tuple(math.radians(a) for a in rot),'XYZ').to_matrix()
 if kind=='Cylinder':
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.5,depth=1)
  o=bpy.context.object
  # Roblox cylinders run along X; Blender cylinders run along Z.
  meshrot=Matrix.Rotation(math.pi/2,4,'Y'); o.data.transform(meshrot)
 else:
  bpy.ops.mesh.primitive_cube_add(size=1); o=bpy.context.object
 o.name=f'{m}/{n}/{serial}'; o.parent=ROOTS[m]; o.location=C@Vector(p)
 # Convert mesh coordinates too, so the exported box and Blender model agree exactly.
 o.data.transform(C.to_4x4()); o.rotation_euler=(C@r@C.transposed()).to_euler(); o.scale=(s[0],s[2],s[1])
 o.color=tuple(v/255 for v in c)+(1,)
 row={'n':n,'p':p,'s':s,'r':[round(r[i][j],6) for i in range(3) for j in range(3)],'c':c,'shape':kind}
 if g: row['g']=g
 DATA['models'][m].append(row); OBJS[(m,n)]=o
 return o

def stud(m,x,y,z,c=WHITE,g=None): return part(m,'Stud',(x,y,z),(.10,.27,.27),c,(0,0,90),'Cylinder',g)
def rim(m,n,p,w,h,c):
 x,y,z=p
 for dx in [-w/2,w/2]: part(m,n,(x+dx,y,z),(.17,h,.19),c)
 for dy in [-h/2,h/2]: part(m,n,(x,y+dy,z),(w,.17,.19),c)
def group(m,n,p): DATA['groups'][m][n]=p

room=model('ArcadeStage',(0,0,18))
part(room,'Floor',(0,-1.15,0),(40,.4,28),CREAM)
part(room,'Platform',(0,-.83,0),(18,.25,11),BLUE)
part(room,'PlatformTop',(0,-.66,0),(17.5,.12,10.5),CYAN)
for x in range(-8,9):
 for z in [-5,5]: stud(room,x,-.55,z,WHITE)
part(room,'Backdrop',(0,5.1,-7),(30,12,.5),CREAM)
for x in [-10,-5,0,5,10]:
 part(room,'WallPanel',(x,5,-6.67),(4.6,7.5,.15),(224,239,221))
 rim(room,'PanelFrame',(x,5,-6.55),4.6,7.5,WHITE)
for x in [-8.5,8.5]:
 part(room,'Pillar',(x,4,-5.9),(.8,9.5,.8),WHITE)
 part(room,'PillarBase',(x,-.3,-5.9),(1.2,.6,1.2),YELLOW)
 part(room,'PillarCap',(x,8.8,-5.9),(1.3,.4,1.3),YELLOW)
part(room,'WallStripe',(0,.5,-6.6),(30,.35,.16),YELLOW)

bench=model('GavelBench',(-19,0,0))
part(bench,'Cabinet',(0,-.25,0),(10.8,1.0,6.4),RED)
part(bench,'BaseTrim',(0,-.7,0),(11.1,.2,6.6),WHITE)
for row in range(3):
 y=.1+(2-row)*1.2; z=(row-1)*2.05
 part(bench,'Terrace',(0,y-.18,z),(10.7,.75,1.98),WOOD)
 part(bench,'FrontTrim',(0,y-.35,z+1),(10.6,.18,.12),YELLOW)
 for col in range(3):
  x=(col-1)*3.25
  part(bench,'Socket',(x,y+.23,z),(2.45,.1,1.55),INK)
  for xx in [-1.32,1.32]: part(bench,'SocketRim',(x+xx,y+.3,z),(.16,.18,1.8),BLUE)
  for zz in [-.86,.86]: part(bench,'SocketRim',(x,y+.3,z+zz),(2.8,.18,.16),BLUE)
  for xx in [-1.3,1.3]: stud(bench,x+xx,y+.42,z+.6,YELLOW)
for x in [-5.45,5.45]:
 part(bench,'SidePost',(x,1.7,-2.65),(.55,4.7,.65),BLUE)
 part(bench,'SideCap',(x,4.15,-2.65),(.8,.3,.8),YELLOW)
part(bench,'TitleBoard',(0,5.6,-3.0),(8.8,.95,.35),RED)
rim(bench,'TitleTrim',(0,5.6,-2.79),8.8,.95,WHITE)

for name,judge,offset in [('BonkRobber',False,(-9,0,0)),('BonkJudge',True,(-7,0,0))]:
 m=model(name,offset)
 part(m,'Torso',(0,.45,0),(.95,.8,.65),INK)
 part(m,'Head',(0,1.13,0),(1.05,.8,.75),(255,210,153))
 if judge:
  part(m,'Wig',(0,1.58,-.04),(1.23,.25,.82),WHITE)
  for x in [-.63,.63]:
   for y in [.9,1.16,1.42]: part(m,'WigCurl',(x,y,0),(.27,.24,.82),WHITE)
  part(m,'Collar',(0,.78,.37),(.55,.18,.12),WHITE)
 else:
  part(m,'Mask',(0,1.18,.4),(1.12,.25,.1),INK)
  part(m,'Hat',(0,1.62,0),(1.13,.3,.85),RED)
  part(m,'HatBrim',(0,1.48,.1),(1.3,.12,1.05),RED)
  for y in [.25,.55]: part(m,'ShirtStripe',(0,y,.35),(.96,.13,.08),WHITE)
 for x in [-.25,.25]:
  part(m,'EyeWhite',(x,1.2,.46),(.22,.22,.09),WHITE)
  part(m,'Eye',(x,1.2,.52),(.09,.13,.06),INK)
 part(m,'Mouth',(0,.94,.4),(.28,.06,.08),INK)
 for x in [-.66,.66]: part(m,'Hand',(x,.44,.14),(.3,.4,.4),WHITE)

mallet=model('GavelMallet',(-5,0,0))
part(mallet,'Head',(0,0,0),(1.6,.65,.7),WOOD)
for x in [-.85,.85]: part(mallet,'EndCap',(x,0,0),(.25,.85,.9),RED)
part(mallet,'Handle',(0,-1.05,0),(.3,1.8,.3),DARK)
for y in [-.6,-.9,-1.2,-1.5]: part(mallet,'GripBand',(0,y,0),(.36,.09,.36),YELLOW)
part(mallet,'GripEnd',(0,-1.94,0),(.46,.22,.46),BLUE)

lt=model('LuckyBriefcaseTable',(0,0,0))
part(lt,'Cabinet',(0,-.2,0),(10.8,1.1,4.6),BLUE)
part(lt,'Rim',(0,.4,0),(11.1,.18,4.9),WHITE)
part(lt,'Felt',(0,.52,0),(10.6,.1,4.4),GREEN)
for x in [-3.3,0,3.3]:
 part(lt,'Pad',(x,.61,0),(2.9,.09,2.4),WHITE)
 part(lt,'PadInset',(x,.67,0),(2.65,.05,2.15),(68,157,56))
 for dx in [-1.35,1.35]: stud(lt,x+dx,.75,1.03,YELLOW)
part(lt,'TitleBoard',(0,4.4,-2.5),(9.6,.85,.35),BLUE)
rim(lt,'TitleRim',(0,4.4,-2.29),9.6,.85,WHITE)
for x in [-5,5]: part(lt,'SignPost',(x,1.75,-2.45),(.35,3.4,.35),YELLOW)

case=model('LuckyBriefcase',(9,0,0)); group(case,'Lid',(0,.43,-.85))
part(case,'Body',(0,0,0),(2.45,.85,1.75),WOOD)
part(case,'Inside',(0,.44,0),(2.15,.06,1.45),INK)
for x in [-1.1,1.1]:
 for z in [-.78,.78]: part(case,'Corner',(x,-.26,z),(.3,.28,.25),YELLOW)
for x in [-.75,.75]:
 part(case,'Clasp',(x,.2,.91),(.24,.45,.12),YELLOW)
 part(case,'Lock',(x,.22,.99),(.07,.1,.04),INK)
part(case,'LidTop',(0,.55,0),(2.48,.24,1.78),RED,g='Lid')
part(case,'LidInset',(0,.7,0),(2.15,.08,1.42),WOOD,g='Lid')
for x in [-.52,.52]: part(case,'HandleFoot',(x,.89,0),(.16,.35,.23),YELLOW,g='Lid')
part(case,'Handle',(0,1.05,0),(1.2,.16,.23),DARK,g='Lid')
for x in [-.82,-.4,0,.4,.82]: stud(case,x,.81,.48,YELLOW,g='Lid')

lie=model('LieDetectorMachine',(18,0,0)); group(lie,'Plunger',(0,.67,1.55))
part(lie,'Cabinet',(0,.75,-.25),(8,2.7,2.2),GREEN)
part(lie,'Foot',(0,-.55,0),(8.4,.25,3.8),BLUE)
part(lie,'ControlDeck',(0,.32,1.0),(8.15,.4,1.9),WHITE)
part(lie,'Monitor',(0,1.72,.9),(6.7,1.35,.15),INK)
rim(lie,'MonitorRim',(0,1.72,1.01),6.85,1.48,WHITE)
for x in [-2.8,-2.4,-2,-1.6,-1.2,-.8,-.4,0,.4,.8,1.2,1.6,2,2.4,2.8]:
 part(lie,'Tick',(x,1.23,1.1),(.035,.18,.06),WHITE)
part(lie,'PlungerBase',(0,.53,1.55),(1.6,.16,1.2),INK)
part(lie,'Button',(0,.78,1.55),(1.3,.4,1.0),RED,g='Plunger')
part(lie,'ButtonHighlight',(0,1.01,1.55),(1.12,.06,.82),(255,124,91),g='Plunger')
for x in [-3.5,3.5]:
 part(lie,'Antenna',(x,2.45,-.4),(.18,1.15,.18),BLUE)
 part(lie,'AntennaCap',(x,3.05,-.4),(.45,.3,.45),YELLOW)
 for y in [2.2,2.45,2.7]: part(lie,'Coil',(x,y,-.4),(.55,.12,.55),CYAN)
for x in [-2.6,2.6]:
 part(lie,'Dial',(x,.73,1.55),(.24,.7,.7),BLUE,(0,0,90),'Cylinder')
part(lie,'TitleBoard',(0,3,-1.0),(6.3,.65,.25),GREEN)

stack=model('StackPedestal',(-13,0,-13))
part(stack,'Base',(0,-.18,0),(7.2,.9,3.9),PURPLE)
part(stack,'Pad',(0,.33,0),(6.5,.16,3.4),WHITE)
part(stack,'Guide',(0,.44,0),(3.1,.06,2.3),YELLOW)
for x in [-5.25,5.25]:
 part(stack,'TowerPost',(x,4.5,-2),(.45,10.5,.5),BLUE)
 for i in range(21): part(stack,'LevelTick',(x, .6+i*.43,-1.7),(.65 if i%5==0 else .35,.045,.1),WHITE)
part(stack,'TitleBoard',(0,9.5,-2.3),(8.5,.8,.3),PURPLE)
scase=model('StackCase',(-7,0,-13))
part(scase,'Body',(0,0,0),(3,.38,1.8),WOOD)
part(scase,'Lid',(0,.22,0),(3.05,.08,1.85),RED)
for x in [-1.3,1.3]: part(scase,'Corner',(x,0,.93),(.25,.4,.08),YELLOW)
part(scase,'Handle',(0,.03,.99),(.65,.12,.15),DARK)
part(scase,'Latch',(0,.12,1.02),(.2,.18,.1),YELLOW)

file=model('FilingMachine',(5,0,-13))
part(file,'ConveyorBase',(0,.6,-.8),(11.4,1.1,2.2),BLUE)
part(file,'Belt',(0,1.22,-.8),(10.4,.12,1.8),INK)
for x in range(-5,6): part(file,'Roller',(x,1.3,-.8),(.12,.12,1.65),WHITE)
for z in [-1.85,.25]: part(file,'BeltRail',(0,1.25,z),(11.5,.3,.18),YELLOW)
part(file,'Feeder',(-5.1,2.15,-1),(1.1,2.7,2),GREEN)
part(file,'Shredder',(5.1,1.8,-.7),(1.3,2.4,2.15),RED)
part(file,'ShredderMouth',(5.1,2.3,.42),(.95,.55,.1),INK)
for x in [4.7,4.95,5.2,5.45]: part(file,'ShredderTooth',(x,2.5,.5),(.14,.32,.16),WHITE)
part(file,'TitleBoard',(0,3.9,-2),(8.4,.75,.3),BLUE)
for x in [-4.7,4.7]: part(file,'TitlePost',(x,2.8,-2),(.25,2.2,.25),YELLOW)
binm=model('FileBin',(13,0,-13)); group(binm,'Lid',(0,.95,-.65))
part(binm,'Body',(0,.3,0),(1.95,1.15,1.45),BLUE)
part(binm,'DarkSlot',(0,.95,0),(1.65,.06,1.2),INK)
part(binm,'Label',(0,.38,.76),(1.55,.6,.08),WHITE)
part(binm,'Lid',(0,1.04,0),(2.02,.16,1.52),BLUE,g='Lid')
folder=model('CaseFile',(16,0,-13))
part(folder,'Folder',(0,.8,0),(1.5,1.55,.16),YELLOW)
part(folder,'Tab',(-.36,1.62,0),(.68,.22,.16),YELLOW)
part(folder,'Document',(0,.88,.1),(1.2,1.15,.04),WHITE)
for y,w in [(1.15,.85),(.94,.8),(.73,.6)]: part(folder,'Writing',(0,y,.14),(w,.05,.025),INK)
part(folder,'Seal',(.37,.5,.16),(.35,.3,.04),RED)

# Curves are authored as Blender keyframes and sampled into transforms used by Roblox.
# Each clip is local to an authored hinge / prop pivot, never an approximation of a mesh export.
clips={
 'LidOpen':[(0,(0,0,0),(0,0,0)),(.12,(0,0,0),(-100,0,0)),(.24,(0,0,0),(-84,0,0)),(.34,(0,0,0),(-88,0,0))],
 'LidClose':[(0,(0,0,0),(-88,0,0)),(.17,(0,0,0),(7,0,0)),(.25,(0,0,0),(0,0,0))],
 'StackDrop':[(0,(0,.45,0),(0,0,0)),(.18,(0,-.035,0),(0,0,0)),(.28,(0,0,0),(0,0,0))],
 'FileFlight':[(0,(0,0,0),(0,0,0)),(.17,(.5,1.5,0),(0,0,12)),(.35,(1,0,0),(0,0,24))],
 'Press':[(0,(0,0,0),(0,0,0)),(.08,(0,-.22,0),(0,0,0)),(.18,(0,.04,0),(0,0,0)),(.28,(0,0,0),(0,0,0))],
 'Bonk':[(0,(1.2,2.5,.3),(-25,0,-25)),(.09,(0,0,0),(20,0,-8)),(.14,(0,-.05,0),(24,0,-8)),(.22,(.7,1.6,.2),(-20,0,-18)),(.4,(1.2,2.5,.3),(-25,0,-25))],
 'Pop':[(0,(0,-1.9,0),(0,0,0)),(.15,(0,.14,0),(0,0,3)),(.26,(0,0,0),(0,0,0))],
 'Duck':[(0,(0,0,0),(0,0,0)),(.18,(0,-1.9,0),(0,0,0))],
 'Shuffle':[(0,(-.5,0,0),(0,0,0)),(.5,(0,.62,.35),(0,0,-5)),(1,(.5,0,0),(0,0,0))],
}
for name,keys in clips.items():
 o=bpy.data.objects.new('CLIP_'+name,None); sc.collection.objects.link(o)
 for t,p,r in keys:
  o.location=C@Vector(p); rr=Euler(tuple(math.radians(v) for v in r),'XYZ').to_matrix()
  o.rotation_euler=(C@rr@C.transposed()).to_euler()
  o.keyframe_insert(data_path='location',frame=1+t*60); o.keyframe_insert(data_path='rotation_euler',frame=1+t*60)
 duration=keys[-1][0]; samples=[]
 for i in range(round(duration*60)+1):
  sc.frame_set(i+1); localp=C.transposed()@o.location; rr=C.transposed()@o.rotation_euler.to_matrix()@C
  samples.append({'t':round(i/60,5),'p':[round(v,5) for v in localp],'r':[round(rr[a][b],5) for a in range(3) for b in range(3)]})
 DATA['clips'][name]=samples
sc.frame_set(1); sc.frame_end=75
with open(os.path.join(ROOT,'tools/zones/minigame_kit.json'),'w') as f: json.dump(DATA,f,separators=(',',':'))
runtime=os.path.join(ROOT,'src/MinigameClient'); os.makedirs(runtime,exist_ok=True)
with open(os.path.join(runtime,'AssetData.lua'),'w') as f: f.write('-- Generated by tools/blender/minigame_kit.py; geometry and sampled Blender clips.\nreturn game:GetService("HttpService"):JSONDecode([==['+json.dumps(DATA,separators=(',',':'))+']==])\n')
sc.render.engine='BLENDER_WORKBENCH'; sc.display.shading.light='STUDIO'; sc.display.shading.color_type='OBJECT'
sc.display.shading.show_cavity=True; sc.display.shading.show_object_outline=True
sc.world=bpy.data.worlds.new('ArcadeWorld'); sc.world.color=(.12,.16,.2)
camd=bpy.data.cameras.new('Overview'); cam=bpy.data.objects.new('Overview',camd); sc.collection.objects.link(cam)
cam.location=(35,-60,38); cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler()
camd.type='ORTHO'; camd.ortho_scale=60; sc.camera=cam
sc.render.resolution_x=1600;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
sc.render.filepath=os.path.join(OUT,'MinigameKit.png')
bpy.data.libraries.write(os.path.join(OUT,'MinigameKit.blend'),{sc})
bpy.ops.render.render(write_still=True)
print('EXPORTED',sum(map(len,DATA['models'].values())),'parts',len(DATA['models']),'models',len(DATA['clips']),'Blender animation clips')
