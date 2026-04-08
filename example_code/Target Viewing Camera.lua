ign=input.getNumber
osn=output.setNumber
igb=input.getBool
osb=output.setBool
pgn=property.getNumber
pgb=property.getBool
pgt=property.getText
m=math
pi=m.pi
pi2=pi*2
sin=m.sin
cos=m.cos
tan=m.tan
asin=m.asin
acos=m.acos
atan=m.atan
function vec(a,b,c,d)return{x=a
or 0,y=b
or 0,z=c
or 0,w=d
or 0}
end

function add(e,f)
return vec(e.x+f.x,e.y+f.y,e.z+f.z)
end

function mult(e,f)
return vec(e.x*f.x,e.y*f.y,e.z*f.z)
end

function multf(e,g)
return vec(e.x*g,e.y*g,e.z*g)
end

function invert(e)
return multf(e,-1)
end

function subt(e,f)
return add(e,invert(f))
end

function length(e)
return m.sqrt(e.x*e.x+e.y*e.y+e.z*e.z)
end

function divf(e,g)
return multf(e,1/g)
end

function norm(e)
return divf(e,length(e))
end

function dot(e,f)
return e.x*f.x+e.y*f.y+e.z*f.z 
end

function cross(e,f)
return vec(e.y*f.z-e.z*f.y,e.z*f.x-e.x*f.z,e.x*f.y-e.y*f.x)
end

function spherical_to_cart(h,i,j)
local j=j
or 1
return vec(m.sin(h)*m.cos(i)*j,m.cos(h)*m.cos(i)*j,m.sin(i)*j)
end

function vecDelta(e,k)
if not vecDeltaTable then
vecDeltaTable={}vecDeltaTable[k]={oldVec=vec()
,deltaVec=vec()
}
elseif not vecDeltaTable[k]then
vecDeltaTable[k]={oldVec=vec()
,deltaVec=vec()
}
end
vecDeltaTable[k].deltaVec=subt(e,vecDeltaTable[k].oldVec)vecDeltaTable[k].oldVec=e
return vecDeltaTable[k].deltaVec 
end

function to_local_frame(e,l,n,o)
return vec(dot(l,e),dot(n,e),dot(o,e))
end

function to_global_frame(e,l,n,o)
return add(add(multf(l,e.x),multf(n,e.y)),multf(o,e.z))
end

function cart_to_spherical(e)
return length(e),m.atan(e.x,e.y),m.asin(e.z/length(e))
end

function mat3(p)
local m={}
for q=1,3 do
m[q]={}
for r=1,3 do
m[q][r]=p and p[q*3-3+r]or 0 
end
end
return m 
end

function mat3_mul(s,t)
local m={}
for q=1,3 do
m[q]={}
for r=1,3 do
m[q][r]=0
for u=1,3 do
m[q][r]=m[q][r]+s[q][u]*t[u][r]end
end
end
return m 
end

function mat3_mul_vec(v,w)
local x={}
x.x=w.x*v[1][1]+w.y*v[2][1]+w.z*v[3][1]x.y=w.x*v[1][2]+w.y*v[2][2]+w.z*v[3][2]x.z=w.x*v[1][3]+w.y*v[2][3]+w.z*v[3][3]return x end

function clamp(a, min, max) return m.max(min, m.min(a, max)) end
function lerp(a,b,t) return a * (1-t) + b * t end

camera_offset = vec(0,1.5,-1)--vec(pgn("CAM X offset"),pgn("CAM Y offset"),pgn("CAM Z offset"))
t=4
hor_comp,ver_comp=0,0
zoom,manualzoom,addonzoom,manualzoominteg=0.5,0.88,0,0
function onTick()
    rx,ry,rz=ign(4),ign(5),ign(6)

    cx,cy,cz=cos(rx),cos(ry),cos(rz)
    sx,sy,sz=sin(rx),sin(ry),sin(rz)

    nright = vec(cy*cz,-sy,cy*sz)
    fwd = vec(sx*sz+cx*sy*cz,cx*cy,-sx*cz+cx*sy*sz)
    nfwd = cross(nright,fwd)
    nup = invert(fwd)

    angular_vel = multf(vec(ign(10),ign(12),ign(11)),pi2/60)
    angular_acc = vecDelta(angular_vel,"angular_acc")

    angle_extr_vel = multf(angular_vel,t) -- extrapolate velocity

    angle_extr_acc = add(angle_extr_vel,multf(angular_acc,0.5*t^2)) -- extrapolate velocity and acceleration

	angle_extr = length(angular_acc)>0.001 and angle_extr_acc or (length(angular_vel)>0.001 and angle_extr_vel or vec(0,0,0))
	
    mat_x = mat3({1,0,0,
                0,cos(angle_extr.x),-sin(angle_extr.x),
                0,sin(angle_extr.x),cos(angle_extr.x)})

    mat_y = mat3({cos(angle_extr.y),0,sin(angle_extr.y),
                0,1,0,
                -sin(angle_extr.y),0,cos(angle_extr.y)})

    mat_z = mat3({cos(angle_extr.z),-sin(angle_extr.z),0,
                sin(angle_extr.z),cos(angle_extr.z),0,
                0,0,1})

    rotation_extrinsic = mat3_mul(mat3_mul(mat_z,mat_y),mat_x)
    rotation_intrinsic = mat3_mul(mat3_mul(mat_x,mat_y),mat_z)

    rotation_final = rotation_extrinsic
    
    right_new = mat3_mul_vec(rotation_final,nright)
    fwd_new = mat3_mul_vec(rotation_final,nfwd)
    up_new = mat3_mul_vec(rotation_final,nup)

	camera_pos = vec(ign(1),ign(3),ign(2))

	tgt_pos = vec(ign(13),ign(14),ign(15))
	
	tgt_pos_rel = subt(tgt_pos,camera_pos)
	
	tgt_pos_local = subt(to_local_frame(tgt_pos_rel,right_new,fwd_new,up_new),camera_offset)
	
	_,hor,ver = cart_to_spherical(tgt_pos_local)

    SOI = ign(16) == 2--Sensor Of Interest 1-3, false or true
    oldradartrack = ign(17) > 0--Old radar tracking 0-1, false-true
    puremanual = ign(20) > 0--Manual Zoom button
    
    if SOI then
        zoomkey=ign(18)--Manual Zoom key
    else
        zoomkey=0
    end

    --if zoomkey < 0.01 and zoomkey > -0.01 then
	--	manualzoominteg = manualzoominteg-manualzoominteg/5
	--else
	--	zoominteg = clamp((zoominteg+zoomkey/160),-0.1,0.1)
	--end
    --if manualzoom >= 1 then zoominteg = 0 end
    --manualzoom=clamp(manualzoom+(zoomkey/55*manualzoom/2.4)+zoominteg*manualzoom/2.4,0.1,50)

    if puremanual then
	    manualzoom = clamp(manualzoom+zoomkey*0.004,0.3,1)
        zoomout = (atan(lerp(tan(0.0125), tan(1.1), manualzoom)) - 0.0125) / (1.1 - 0.0125)
    else
        tgtage = m.min(ign(19),99)--Ticks since selected tgt detect upper clamped to 90
        tgt_dist = length(tgt_pos_rel)

        addonzoom = clamp(addonzoom+zoomkey*0.001,-0.1,0.3)
        zoomout = (0.99/(1+0.4*2.7^(-0.014*tgt_dist)))
        if (addonzoom + zoomout) > 1 then
            addonzoom = 1-zoomout
        elseif (addonzoom + zoomout) < 0 then
            addonzoom = -zoomout
        end
        zoomout = zoomout + addonzoom - tgtage/4000
    end

	osn(1,-hor/pi2)
	osn(2,ver/pi2*2.942+0.7355)
    osn(3,zoomout)
end

function onDraw()
    w,h = screen.getWidth(),screen.getHeight()
    if SOI then
        screen.setColor(1,1,1,200)
	    screen.drawRectF(2,h-6,12,5)
        screen.setColor(85,160,35)
        screen.drawText(2,h-6,"SOI")
    end
end