ign = input.getNumber; osn = output.setNumber; igb = input.getBool; osb = output.setBool;
pgn = property.getNumber; pgb = property.getBool; pgt = property.getText; m = math; pi = m.pi; pi2 = pi*2

function vec(x,y,z) --defines a vector
return {x=x or 0,y=y or 0,z=z or 0}
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
function reject(a,b) --rejects a vector by another
return subt(a, multf(norm(b), dot(a, norm(b))))
end
function stoc(hor,ver,d) --spherical to cartesian conversion
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
function tolocal(a,r,f,u) --converts a vector to local frame of reference
return vec(dot(r,a),dot(f,a),dot(u,a))
end
function torelative(a,r,f,u) --converts a vector to global frame of reference, origin set at vehicle
return add(add(multf(r,a.x), multf(f,a.y)), multf(u,a.z))
end
function clamp(x,s,l) return x < s and s or x > l and l or x --clamp (used for seat to head position function)
end
function debugvec(v,name) --sends components of a vector to debug
debug.log("VECTOR ".. name .." COMPONENTS:")debug.log(v.x)debug.log(v.y)debug.log(v.z)debug.log("------------------")
end


function validowntarget()
    return ((mass<=2495 or mass>=2505) and mass>=minmass and xyz_acquired)
end


nc=pgn("Navigation Constant")
maxc=pgn("Max Control")
minmass=pgn("Minimum Mass")
hoff=pgn("Horizontal Offset")
voff=pgn("Vertical Offset")
maxdist=pgn("Max Distance from radio")
targettogoto=false

function onTick()
    
	--physics sensor to facing vectors
	rx,ry,rz=input.getNumber(4),input.getNumber(5),input.getNumber(6)
	cx,cy,cz=math.cos(rx),math.cos(ry),math.cos(rz)
	sx,sy,sz=math.sin(rx),math.sin(ry),math.sin(rz)

	right = vec(cy*cz, -sy, cy*sz)
	fwd = vec(sx*sz + cx*sy*cz, cx*cy, -sx*cz + cx*sy*sz)
	up = cross(right,fwd)
	--
  
	--Calculate missile position and velocity
	m_pos = vec(ign(1),ign(3),ign(2))
	m_vel = vecDelta(m_pos,"m_vel")
	offset = add(m_pos,invert(torelative(vec(0,1.25,0),right,fwd,up))) --Relative offset from phys sensor to back radar
    	--
	
	--Get radio position
	radio_pos = vec(ign(7),ign(8),ign(9))
    
	--Calculate TGT local position from radars
	rdrXdist = ign(12)
	rdrYdist = ign(13)
	st = ign(14) or 0
	mass = st*rdrXdist
	
	rdrXazim = ign(10)*pi2
	rdrYelev = ign(11)*pi2
		
	hh = m.sin(rdrXazim) * rdrXdist
	hv = m.sin(rdrYelev) * rdrYdist
	k1 = m.cos(rdrYelev) * rdrYdist
	l = (k1^2 - hh^2)^.5
	tgt_pos_local = vec(hh,l,hv)
	
	xyz_acquired = length(tgt_pos_local)>0
	--

	--Set target xyz
	p_tgt_pos = tgt_pos or vec()
	if validowntarget() then --If we are tracking something
        tgt_pos_global = add(offset,torelative(tgt_pos_local,right,fwd,up))

        if length(radio_pos)>0 then --If there's a position from radio
            if length(subt(tgt_pos,radio_pos))<=maxdist then --If the distance from our target to radio target is less than maxdist
                --guide to onboard position (close enough to radio pos, probably same target)
                targettogoto = true
                tgt_pos = tgt_pos_global
            else
                --guide to radio position (far from radio pos, go to radio pos instead)
                targettogoto = true
                tgt_pos = radio_pos
            end
        else --No position from radio
            --guide to onboard position (no radio pos, eg go maddog)
            targettogoto = true
            tgt_pos = tgt_pos_global
        end
    else --No onboard position and no radio position
        --guide to last known position
        tgt_pos = p_tgt_pos
    end

    --p_tgt_pos = tgt_pos or vec()
	--if validowntarget() then --If mass is above threshold, does not match tree mass, and a radar xyz is available
	--	tgt_pos = add(offset,torelative(tgt_pos_local,right,fwd,up))
	--	targettogoto = true
	--elseif length(radio_pos)>0 then --Else, check if there's a position from radio
	--	
	--	targettogoto = true
	--else --Else, assign it to last known tgt position
	--	
	--end
    
	--Calculate target position rates
	tgt_vel = vecDelta(tgt_pos,"tgt_vel")
	tgt_acc = vecDelta(tgt_vel,"tgt_acc")
	tgt_jer = vecDelta(tgt_acc,"tgt_jer")
	--
    
	--Calculate target relative position and relative velocity
	tgt_pos_rel = subt(tgt_pos,m_pos)
	tgt_pos_rel_n = norm(tgt_pos_rel)
	vel_rel = subt(tgt_vel,m_vel)
	--
	
	--Make acceleration and jerk normal to LOS
	tgt_acc_n = reject(tgt_acc,tgt_pos_rel_n)
	tgt_jer_n = reject(tgt_jer,tgt_pos_rel_n)
	--
    	
	--Calculate rotation vector
	omega = divf(cross(tgt_pos_rel,vel_rel),dot(tgt_pos_rel,tgt_pos_rel))
    
	--Acceleration normal to the instantaneous velocity difference
	TPN_term = multf(cross(vel_rel,omega),nc)
    
	--Acceleration normal to the instantaneous line of sight
	TPN_term = multf(cross(tgt_pos_rel_n,omega),-nc*length(vel_rel))
    
	--Acceleration orthogonal to the missile velocity
	m_vel_n = norm(m_vel)
	TPN_term = multf(cross(m_vel_n,omega),-nc*length(vel_rel))
	
	--TGT Acceleration Term
	Acc_term = multf(tgt_acc_n,nc/2)
	
	--TGT Jerk Term
	Jer_term = multf(tgt_jer_n,nc/6)
	
	--EPN
	Acmd = add(TPN_term,add(Acc_term,Jer_term))
	
	if length(tgt_pos_rel)<1000 and dot(tgt_pos_rel_n,m_vel)>1 then
		limiter = 1
	else
		--PP
		Acmd = tgt_pos_rel_n
		limiter = 4
	end
    
	--Firing and Control
	ctrl = tolocal(Acmd,right,fwd,up)
    
	fired = ign(15)>0 or false
	
	if fired and targettogoto then
		osn(1,clamp(-ctrl.x,-maxc/limiter,maxc/limiter)+hoff)
		osn(2,clamp(-ctrl.z,-maxc/limiter,maxc/limiter)+voff)
	else
		osn(1,hoff)
		osn(2,voff)
	end
    --
    
end