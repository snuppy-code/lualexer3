m,i,o,p,s,T,F = math,input,output,property,screen,true,false
ign,osn,igb,osb = i.getNumber, o.setNumber, i.getBool, o.setBool
pgn,pgb = p.getNumber, p.getBool
abs,cos,sin,floor,atan = m.abs, m.cos, m.sin, m.floor,m.atan
pi = m.pi
pi2 = pi*2

text,textbox,line,rect,rectF,circl,clear,setcolor = s.drawText,s.drawTextBox,s.drawLine,s.drawRect,s.drawRectF,s.drawCircle,s.drawClear,s.setColor

function vec(x,y,z,w) --defines a vector
return {x=x or 0,y=y or 0,z=z or 0, w=w or 0}
end

function add(a,b) --adds 2 vectors
return vec(a.x+b.x, a.y+b.y, a.z+b.z)
end

function mult(a,b) --multiplies 2 vectors
return vec(a.x*b.x, a.y*b.y, a.z*b.z)
end

function multf(a,n) --multiplies a vector by a factor
return vec(a.x*n, a.y*n, a.z*n)
end

function invert(a) --inverts a vector
return multf(a,-1)
end

function subt(a,b) --subtracts a vector from another
return add(a,invert(b))
end

function length(a) --gets length of a vector
return m.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)
end

function divf(a,n) --divides vector by a factor
return multf(a,1/n)
end

function norm(a) --normalizes a vector
return divf(a,length(a))
end

function dot(a,b) --dot product between 2 vectors
return a.x*b.x+a.y*b.y+a.z*b.z
end

function cross(a,b) --cross product between 2 vectors
return vec(a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x)
end

function spherical_to_cart(hor,ver,d) --spherical to cartesian conversion
local d=d or 1
return vec(m.sin(hor)*m.cos(ver)*d, m.cos(hor)*m.cos(ver)*d, m.sin(ver)*d)
end

function vecDelta(a,spot) --gets delta of a vector
	if not vecDeltaTable then
	vecDeltaTable = {}
	vecDeltaTable[spot] = {oldVec = vec(),deltaVec = vec()}
	elseif not vecDeltaTable[spot] then
	vecDeltaTable[spot] = {oldVec = vec(),deltaVec = vec()}
	end
	vecDeltaTable[spot].deltaVec = subt(a,vecDeltaTable[spot].oldVec)
	vecDeltaTable[spot].oldVec = a
	return vecDeltaTable[spot].deltaVec
end

--Advanced Functions
function to_local_frame(a,r,f,u) --converts a vector to local frame of reference
return vec(dot(r,a),dot(f,a),dot(u,a))
end

function to_global_frame(a,r,f,u) --converts a vector to global frame of reference, origin set at vehicle
return add(add(multf(r,a.x), multf(f,a.y)), multf(u,a.z))
end

function clamp(x,s,l) return x < s and s or x > l and l or x --clamp (used for seat to head position function)
end

function to_monitor(point,cam_offset,zoom,w,h) --calculates local point display on monitor
	local fov=zoom*(0.025-2.2)+2.2
	local center_x=w/2; local center_y=h/2
	local aspect=(center_x-128*0.025)/(center_y-128*0.025)
	local fov_y=m.tan(fov/2); local fov_x=fov_y*aspect
	local pcam=subt(point,cam_offset)
	local pixel_x,pixel_y=pcam.y>0 and center_x*(1+pcam.x/pcam.y/fov_x) or 0, pcam.y>0 and h-center_y*(1+pcam.z/pcam.y/fov_y) or 0
	return pixel_x,pixel_y
end

function dotline(x1,y1,x2,y2)
	segments = 11
	drawnyes = true
	
	xrel = x2-x1
	yrel = y2-y1
	
	xseg = xrel/segments
	yseg = yrel/segments
	
	for i = 1,segments do
		if drawnyes then
			line(x1+xseg*(i-1), y1+yseg*(i-1), x1+xseg*i, y1+yseg*i)
		end
		drawnyes = not drawnyes
	end
end

---- EVA SETUP VARS ----
points={}
max_points=100
t=3

camera_offset=vec(0,2.625,-0.5)
laser_offset=vec(0,3.125,-0.25)

laser_angles = {}
for i=1,t do
    laser_angles[i] = {hor=0,ver=0}
end

---- NON-EVA SETUP VARS ----
culltime = 10
friendlies = {}
tgtfiles = {}

function onTick()

	----  CONTROLS  ----
	ACM = ign(28) == 1
    zoom_in = 0.12
    laser_dist = ign(20)

	----  MY DATA  ----
	mypos = vec(ign(1),ign(3),ign(2))

	rx,ry,rz=ign(4),ign(5),ign(6)
	cx,cy,cz=cos(rx),cos(ry),cos(rz)
	sx,sy,sz=sin(rx),sin(ry),sin(rz)
	right = vec(cy*cz, -sy, cy*sz)
	fwd = vec(sx*sz + cx*sy*cz, cx*cy, -sx*cz + cx*sy*sz)
	up = cross(right,fwd)

	myvel = multf(vecDelta(mypos,"myvel"),60)
	myacc = multf(vecDelta(myvel,"myacc"),60)

	myspd = length(myvel)
	myg = length(myacc)/9.81


	---- GET TARGETS & FRIENDLIES ----
	inindex = ign(19)
	intgt1 = vec(ign(7),ign(8),ign(9))
	if length(intgt1) > 0 then
		tgtfiles[inindex] = {pos=intgt1,t=0}
	end
	intgt1 = vec(ign(10),ign(11),ign(12))
	if length(intgt1) > 0 then
		tgtfiles[inindex+1] = {pos=intgt1,t=0}
	end

	inindex = ign(21)
	intgt1 = vec(ign(13),ign(14),ign(15))
	intgt2 = vec(ign(16),ign(17),ign(18))
	if length(intgt1) > 0 then--friendly position
		friendlies[inindex] = {pos=intgt1,sel=intgt2,t=0}
	end

	--cull/timeout targets
	for k,_ in pairs(tgtfiles) do
		tgtfiles[k].t = tgtfiles[k].t + 1
		if tgtfiles[k].t >= culltime then 
			tgtfiles[k] = nil
		end
	end
	--cull/timeout friendlies
	for k,_ in pairs(friendlies) do
		friendlies[k].t = friendlies[k].t + 1
		if friendlies[k].t >= culltime then 
			friendlies[k] = nil
		end
	end

	selectedtgt = vec(ign(23),ign(24),ign(25))
	--debug.log("tsdx: "..selectedtgt.x.." y: "..selectedtgt.y.." z: "..selectedtgt.z)
	

	---- LIDAR ----
	camera_right = right
	camera_forward = to_global_frame(spherical_to_cart(0,-0.6*pi/4,1),right,fwd,up)
	camera_up = cross(camera_right,camera_forward)

	--laser spot calculations
	for i=t,2,-1 do
		laser_angles[i].hor = laser_angles[i-1].hor
		laser_angles[i].ver = laser_angles[i-1].ver
	end

	laser_angles[1].hor = hor or 0
	laser_angles[1].ver = ver or 0

	if laser_dist >= 5 and laser_dist < 2000 then
		--calculate point in global frame
		laser_spot = add(to_global_frame(add(spherical_to_cart(laser_angles[t].hor,laser_angles[t].ver,laser_dist),laser_offset),right,fwd,up),mypos)
		laser_spot = vec(laser_spot.x,laser_spot.y,laser_spot.z < 0 and 0 or laser_spot.z) --if laser spot is below water level, set z to 0
		
		if #points > 0 then --if the table has points

			new,j = true,0
			while j < #points and new and j < max_points do --check if calculated point is new
				j = j + 1
				new = length(subt(points[j],laser_spot)) > 5 --new if distance is >5m
			end

			table_full = #points >= max_points

			if new then --if calculated point is new

				if table_full then
					for i=1,max_points-1 do --remove oldest point and shift all table contents down by 1
						points[i] = points[i+1]
					end
					points[max_points] = laser_spot --add new point (overwrite last spot in table)
				else
					points[#points+1] = laser_spot --add new point (extend the table)
				end

			end

		else --if the table is empty

			points[1] = laser_spot --add new point (first index)

		end

	end

	--outputs
	hor = math.rad(math.random(-40,40))
	ver = math.rad(math.random(-40,40))

	osn(1,hor*4/pi)
	osn(2,ver*4/pi)


end
function onDraw()
	w,h = s.getWidth(),s.getHeight()

	---- LIDAR ----
	for k,v in pairs(points) do --for all points
		relative_position = subt(v,mypos) --get relative positon
		dist = length(relative_position) --dist

		if dist<2000 then
			local_position = to_local_frame(relative_position,camera_right,camera_forward,camera_up)

			if local_position.y > 0 then
				pixel_x,pixel_y = to_monitor(local_position,camera_offset,zoom_in,w,h)
				setcolor(5-dist, dist-5, 0)

				if(v.z<0.5) then
					setcolor(clamp(200-dist/10,0,200), 0, clamp(dist/10,0,200), clamp(200-dist/20,0,200))
				else
					setcolor(clamp(200-dist/10,0,200), clamp(dist/10,0,200), 0, clamp(200-dist/20,0,200))
				end
				rectF(pixel_x-1,pixel_y,1,1)
			end
    	end
	end
	
	---- SYMBOLS ----
	--targets
	setcolor(80,13,1,230)
	for k,v in ipairs(tgtfiles) do
		relative_position = subt(v.pos,mypos)
		local_position = to_local_frame(relative_position,camera_right,camera_forward,camera_up)
		tgtpixelx, tgtpixely = to_monitor(local_position,camera_offset,zoom_in,w,h)

		
		thistargetalt=v.pos.z
		thistargetalt=m.max(m.min(thistargetalt/500,5),0)
		line(tgtpixelx-thistargetalt,tgtpixely-2,tgtpixelx+thistargetalt+1,tgtpixely-2)
		rect(tgtpixelx-1,tgtpixely-1,2,2)
	end
	
	--selected target
	setcolor(55,20,40,180)
	if length(selectedtgt) > 0 then
		relative_position = subt(selectedtgt,mypos)
		local_position = to_local_frame(relative_position,camera_right,camera_forward,camera_up)
		tgtpixelx, tgtpixely = to_monitor(local_position,camera_offset,zoom_in,w,h)
		
		dotline(w/2,h,tgtpixelx,tgtpixely)
		
		setcolor(46,0,25,240)
		rectF(tgtpixelx-2,tgtpixely-2,1,5)
		rectF(tgtpixelx+2,tgtpixely-2,1,5)
		rectF(tgtpixelx,tgtpixely,1,1)
	end
	
	--friendlies & their selecteds
	setcolor(0,40,255,230)
	for k,v in pairs(friendlies) do
		relative_position = subt(v.pos,mypos)
		local_position = to_local_frame(relative_position,camera_right,camera_forward,camera_up)
		fpixelx, fpixely = to_monitor(local_position,camera_offset,zoom_in,w,h)
		
		thistargetalt=v.pos.z
		thistargetalt=m.max(m.min(thistargetalt/500,5),0)
		line(fpixelx-thistargetalt,fpixely-2,fpixelx+thistargetalt+1,fpixely-2)

		rectF(fpixelx,fpixely-1,1,1)
		rectF(fpixelx+1,fpixely,1,1)
		rectF(fpixelx,fpixely+1,1,1)
		rectF(fpixelx-1,fpixely,1,1)

		if length(v.sel) > 0 then
			relative_position = subt(v.sel,mypos)
			local_position = to_local_frame(relative_position,camera_right,camera_forward,camera_up)
			ftrkpixelx, ftrkpixely = to_monitor(local_position,camera_offset,zoom_in,w,h)

			setcolor(30,90,255,155)
			dotline(fpixelx,fpixely,ftrkpixelx,ftrkpixely)

			setcolor(40,40,110,165)
			rectF(ftrkpixelx-2,ftrkpixely-2,1,5)
			rectF(ftrkpixelx+2,ftrkpixely-2,1,5)
			rectF(ftrkpixelx,ftrkpixely,1,1)
		end
	end
	
	---- HUD INFO ----
	


	if ACM then
		setcolor(255,0,0)
		rectF(0,0,1,h)
		rectF(w-1,0,1,h)
	end

end



