--math input and other shorthands
m,i,o,p,s,T,F = math,input,output,property,screen,true,false
ign,osn,igb,osb = i.getNumber, o.setNumber, i.getBool, o.setBool
pgn,pgb = p.getNumber, p.getBool
abs,cos,sin,floor,atan = m.abs, m.cos, m.sin, m.floor,m.atan
pi = m.pi
pi2 = pi*2

--vector functions
function vec(x,y,z)
return {x=x or 0,y=y or 0,z=z or 0}
end
function add(a,b)
return vec(a.x+b.x, a.y+b.y, a.z+b.z)
end
function multf(a,n)
return vec(a.x*n, a.y*n, a.z*n)
end
function invert(a)
return multf(a,-1)
end
function subt(a,b)
return add(a,invert(b))
end
function length(a)
return m.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)
end
function divf(a,n)
return multf(a,1/n)
end
function norm(a)
return divf(a,length(a))
end
function dot(a,b)
return a.x*b.x+a.y*b.y+a.z*b.z
end
function cross(a,b)
return vec(a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x)
end
--function project(a,b)
--return multf(norm(b), dot(a, norm(b)))
--end
--function reject(a,b)
--return subt(a, multf(norm(b), dot(a, norm(b))))
--end
--function reflect(a,b,factor)
--return subt(a, multf(reject(a, b), factor or 2))
--end
function stoc(hor,ver,d)
stocd=stocd or 1
return vec(m.sin(hor)*m.cos(ver)*d, m.cos(hor)*m.cos(ver)*d, m.sin(ver)*d)
end
function tolocal(a,r,f,u)
return vec(dot(r,a),dot(f,a),dot(u,a))
end
function torelative(a,r,f,u)
return add(add(multf(r,a.x), multf(f,a.y)), multf(u,a.z))
end

--functional functions
function edgeindex(input,findtop)
    local edge = nil
    for k, _ in pairs(input) do
        if edge == nil or (k > edge and findtop) or (k < edge and not findtop) then
            edge = k
        end
    end
    return edge
end
function lastpos(tgt)
	--debug.log("->"..tgt)
	--debug.log("->"..type(targetfiles[tgt]))
	--debug.log("->"..type(targetfiles[tgt].poss))
	--debug.log("->"..type(targetfiles[tgt].poss[edgeindex(targetfiles[tgt].poss,true)]))
	return targetfiles[tgt].poss[edgeindex(targetfiles[tgt].poss,true)]
end

--VICLINK (vehicle datalink)
vicstartfreq = pgn("VL Strt Frq")
vicuserf = pgn("VL You Frq")
vicendf = pgn("VL End Frq")
vicmyuser = property.getText("VL User")
viccurrentfreq=vicstartfreq

--radar & tgt handling info
mergedist = pgn("Merge Dist")
culltime = pgn("Cull Time")

--rawemissiontargets = {}
rawradartargets = {--"pos" stores position, "rel" stores relative vec, "tsd" stores time since detected
	{},
	{},
	{},
	{}
}

targetfiles = {}
friendlyfiles = {}
friendlyindex = {}

selectedtgt = 0
enemytransindex,friendlytransindex=0,0
existedticks,possculltimer = 0,0
function onTick()
	possculltimer = possculltimer + 1
	existedticks = existedticks + 1
	--my position vector
	mpos = vec(ign(1),ign(2),ign(3))
	touchin = ign(27) == 1
	if touchin and not touch and (#targetfiles > 0) then
		selectedtgt = selectedtgt%(#targetfiles)+1
		--debug.log("judcycled: "..selectedtgt)
	end
	touch = touchin

	ACM = ign(28) == 1

	--facing vectors
	rx,ry,rz=ign(4),ign(5),ign(6)
	cx,cy,cz=cos(rx),cos(ry),cos(rz)
	sx,sy,sz=sin(rx),sin(ry),sin(rz)
	right = vec(cy*cz, -sy, cy*sz)
	fwd = vec(sx*sz + cx*sy*cz, cx*cy, -sx*cz + cx*sy*sz)
	up = cross(right,fwd)

	---- VICLINK ----
	--get current friendly's pos, if it is anything except 0,0,0 then get their ASCII and put their pos in friendlyfiles table at index of their ASCII
	fpos = vec(ign(7),ign(9),ign(8))
	ftrk = vec(ign(21),ign(22),ign(23))
	--debug.log(fpos.x.." "..fpos.y.." "..fpos.z)
	if length(fpos)>0 then
		--debug.log("valid user:"..fpos.x.." "..fpos.y.." "..fpos.z)
		local userascii2 = {ign(10),ign(11)}
		user=""
		if userascii2[1]>=1000000 and userascii2[1]>=1000000 then
			userascii = tostring(userascii2[1]):sub(2,7)..tostring(userascii2[2]):sub(2,7)
			for i=1, #userascii, 3 do
				user = user..string.char(userascii:sub(i,i+3-1))
			end
			--debug.log("valid user:"..user)
		else
			user = "XXXX"
		end
		friendlyfiles[user]={pos=fpos,sel=ftrk}
		friendlymatch = nil
		for k,v in ipairs(friendlyindex) do
			if v == user then
				friendlymatch = k
			end
		end
		if friendlymatch then
			friendlyindex[friendlymatch] = user
		else
			friendlyindex[#friendlyindex+1] = user
		end
	end
	--put me in the friendlies table for the TWS :3
	friendlyfiles[vicmyuser] = {pos=mpos,sel=vec()}
	if targetfiles[selectedtgt] then
		friendlyfiles[vicmyuser].sel = lastpos(selectedtgt)
	end

	--output my ASCII on radio
	myuserascii = ""
	for i=1, #vicmyuser do
		myuserascii = myuserascii..string.format("%03d", vicmyuser:byte(i))
	end
	osn(1,tonumber("1"..myuserascii:sub(1,6)))
	osn(2,tonumber("1"..myuserascii:sub(7,12)))

	--increment freq scan
	viccurrentfreq=viccurrentfreq==vicendf and vicstartfreq or viccurrentfreq+1
	if viccurrentfreq==vicuserf then 
		viccurrentfreq=viccurrentfreq==vicendf and vicstartfreq or viccurrentfreq+1 
	end
	osn(3,viccurrentfreq)

    ---- Raw Radar Targets to TWS ----
	--data from new radar 1
	if ign(18) > 0 then
		rawradartargets[1].loc = stoc(ign(19)*pi2,ign(20)*pi2,ign(18))
		rawradartargets[1].rel = torelative(rawradartargets[1].loc,right,fwd,up)	--new1 r tgt d,a,e 18,19,20
		rawradartargets[1].pos = add(rawradartargets[1].rel, mpos)
	else
		rawradartargets[1] = {loc=vec(),rel=vec(),pos=vec()}
	end
	rawradartargets[1].tsd = ign(30)											--tsd: 31

	--data from new radar 2
	if ign(12) > 0 then
		rawradartargets[2].loc = stoc(ign(13)*pi2,ign(14)*pi2,ign(12))
		rawradartargets[2].rel = torelative(rawradartargets[2].loc,right,fwd,up)	--new2 r tgt d,a,e 12,13,14
		rawradartargets[2].pos = add(rawradartargets[2].rel, mpos)
	else
		rawradartargets[2] = {loc=vec(),rel=vec(),pos=vec()}
	end
	rawradartargets[2].tsd = ign(31)											--tsd: 31

	--data from new radar 3
	if ign(24) > 0 then
		rawradartargets[3].loc = stoc(ign(25)*pi2+pi,ign(26)*pi2,ign(24))
		rawradartargets[3].rel = torelative(rawradartargets[3].loc,right,fwd,up)	--new3 r tgt d,a,e 24,25,26
		rawradartargets[3].pos = add(rawradartargets[3].rel, mpos)
	else
		rawradartargets[3] = {loc=vec(),rel=vec(),pos=vec()}
	end
	rawradartargets[3].tsd = ign(32)											--tsd: 32

	--data from old radar / short range STT radar
	rawradartargets[4].pos = vec(ign(15),ign(16),ign(17))
	if length(rawradartargets[4].pos) > 0 then
		rawradartargets[4].rel = subt(mpos,rawradartargets[4].pos)			--verold r tgt xyz 15,16,17
		rawradartargets[4].loc = tolocal(rawradartargets[4].rel,right,fwd,up)
	else
		rawradartargets[4] = {loc=vec(),rel=vec(),pos=vec()}
	end
	rawradartargets[4].tsd = 0												--tsd: X

	--raw tgts to target files
	for k,rawtgt in ipairs(rawradartargets) do
		if (length(rawtgt.rel) > 0) and not (rawtgt.tsd > 0) then--there is actually a target and its on tick 1 of info
			local rawradarmatch = 0 --no match with a target file found yet
			for fileindex,file in ipairs(targetfiles) do
				if rawradarmatch == 0 then--we havent matched something
					if length(subt(lastpos(fileindex),rawtgt.pos)) <= mergedist then
						--length of rel vector from raw tgt to this tgt file is less than or equal to merge dist, eg match found
						rawradarmatch = fileindex
						--update found existing tgt file with raw tgt
						targetfiles[fileindex].poss[existedticks] = rawtgt.pos
						targetfiles[fileindex].t = 0

						--update velocity vector 1
						thresholdvec = nil
						thresholdindex = -1
						for pastposindex, pastpos in pairs(targetfiles[fileindex].poss) do
							thresholddistance = length(subt(pastpos, lastpos(fileindex)))
							
							if thresholddistance >= 50 and pastposindex > thresholdindex then --50 is minextrapdist
								thresholdvec = pastpos
								
								thresholdindex = pastposindex
							end
						end
						--update velocity vector 2
						if thresholdvec ~= nil then
							timediff = edgeindex(targetfiles[fileindex].poss,true) - thresholdindex
							if timediff > 0 then  -- Prevent division by zero
								targetfiles[fileindex].veltick = divf(subt(lastpos(fileindex), thresholdvec), timediff)
							end
						else
							targetfiles[fileindex].veltick = vec()
						end
					end
				else--we already have a match
					if length(subt(lastpos(fileindex),rawtgt.pos)) <= mergedist then
						--length of rel vector from raw tgt to this tgt file is less than or equal to merge dist, eg match found, also not a selected target
						table.remove(targetfiles,fileindex)--we already matched raw tgt to a file so we will delete this one
					end
				end
			end
			if rawradarmatch == 0 then
				--create target file
				targetfiles[#targetfiles+1] = {poss = {[existedticks] = rawtgt.pos},veltick = vec(),extrpos = vec(),t = 0}
			end
		end
	end
	-- target file culling
	culled = 0
	for k, v in ipairs(targetfiles) do
		thisnotculled = true
		if possculltimer > 120 then
			local length = 0
			for _ in pairs(targetfiles[k].poss) do
				length = length + 1
			end
			while length > 40 do
				targetfiles[k].poss[edgeindex(targetfiles[k].poss,false)] = nil
				length = length - 1
				culled = culled + 1
			end
			--debug.log("culled "..culled.." positions of target "..k)
		end
		
		targetfiles[k].t = targetfiles[k].t + 1


		--also extrapolation teehee
		targetfiles[k].extrpos = add(lastpos(k), multf(targetfiles[k].veltick, targetfiles[k].t))

		if (v.t >= culltime) then--and not (k == selectedtgt) then
			--debug.log("tmdout "..k)
			if thisnotculled then
				table.remove(targetfiles,k)
				thisnotculled = false
			end
		else
			if lastpos(k).z <= -1 then
				targetfiles[k].poss[edgeindex(targetfiles[k].poss,true)].z = 5
			end
			for i,r in pairs(friendlyfiles) do
				if thisnotculled then
					if length(subt(r.pos,lastpos(k)))<=mergedist then
						--debug.log("friendly killed "..k)
						if thisnotculled then
							table.remove(targetfiles,k)
							thisnotculled = false
						end
					end
				end
			end
		end
	end
	if culled > 0 then possculltimer = 0 end

	---- OUTPUTS ----
	--targets
	--debug.log("qu:"..#targetfiles)
	if targetfiles[enemytransindex] then
		--debug.log("ind:"..enemytransindex)
		--debug.log(enemytransindex.." age "..targetfiles[enemytransindex].t)
		osn(14,lastpos(enemytransindex).x)
		--debug.log("lsx:"..lastpos(enemytransindex).x)
		osn(15,lastpos(enemytransindex).y)
		osn(16,lastpos(enemytransindex).z)
		
		--osn(14,targetfiles[enemytransindex].poss[edgeindex(targetfiles[enemytransindex].poss,true)].x)
		--osn(15,targetfiles[enemytransindex].poss[edgeindex(targetfiles[enemytransindex].poss,true)].y)
		--osn(16,targetfiles[enemytransindex].poss[edgeindex(targetfiles[enemytransindex].poss,true)].z)
		--osn(14,targetfiles[enemytransindex].extrpos.x)
		--osn(15,targetfiles[enemytransindex].extrpos.y)
		--osn(16,targetfiles[enemytransindex].extrpos.z)
	end
	if targetfiles[enemytransindex+1] then
		osn(17,lastpos(enemytransindex+1).x)
		osn(18,lastpos(enemytransindex+1).y)
		osn(19,lastpos(enemytransindex+1).z)
		--osn(17,targetfiles[enemytransindex+1].poss[edgeindex(targetfiles[enemytransindex+1].poss,true)].x)
		--osn(18,targetfiles[enemytransindex+1].poss[edgeindex(targetfiles[enemytransindex+1].poss,true)].y)
		--osn(19,targetfiles[enemytransindex+1].poss[edgeindex(targetfiles[enemytransindex+1].poss,true)].z)
		--osn(17,targetfiles[enemytransindex+1].extrpos.x)
		--osn(18,targetfiles[enemytransindex+1].extrpos.y)
		--osn(19,targetfiles[enemytransindex+1].extrpos.z)
	end
	osn(26,enemytransindex)
	enemytransindex = enemytransindex + 2
	if enemytransindex > #targetfiles then
		enemytransindex = 1
	end

	--friendlies
	yup = friendlyfiles[friendlyindex[friendlytransindex]]
	if yup then
		yup2 = yup.pos
		yup3 = yup.sel
		osn(20,yup2.x)
		osn(21,yup2.y)
		osn(22,yup2.z)
		osn(23,yup3.x)
		osn(24,yup3.y)
		osn(25,yup3.z)
	end
	osn(28,friendlytransindex)
	friendlytransindex = friendlytransindex + 1
	if friendlytransindex > #friendlyindex then
		friendlytransindex = 1
	end

	--output selected tgt
	--debug.log("E")
	if ACM then
		osn(30,rawradartargets[3].pos.x)
		osn(31,rawradartargets[3].pos.y)
		osn(32,rawradartargets[3].pos.z)
	else
		if targetfiles[selectedtgt] then
			osn(30,lastpos(selectedtgt).x)
			osn(31,lastpos(selectedtgt).y)
			osn(32,lastpos(selectedtgt).z)
			--osn(30,targetfiles[selectedtgt].poss[edgeindex(targetfiles[selectedtgt].poss,true)].x)
			--osn(31,targetfiles[selectedtgt].poss[edgeindex(targetfiles[selectedtgt].poss,true)].y)
			--osn(32,targetfiles[selectedtgt].poss[edgeindex(targetfiles[selectedtgt].poss,true)].z)
			--osn(30,targetfiles[selectedtgt].extrpos.x)
			--osn(31,targetfiles[selectedtgt].extrpos.y)
			--osn(32,targetfiles[selectedtgt].extrpos.z)
			osn(11,targetfiles[selectedtgt].t)
		else
			osn(30,0)
			osn(31,0)
			osn(32,0)
			osn(11,0)
		end
	end
	--debug.log("F")
	--old radar slew
	osn(7,0)
	osn(8,0)
	--old radar fov
	osn(9,1)
	osn(10,1)
end

--[[
--debug.log("TWS\nraw radar target loop start")
--debug.log("->k: "..k)
debug.log("k:"..k..",type:"..type(rawtgt).."\nlength(rawtgt.rel) = "..length(rawtgt.rel).." rawtgt.tsd = "..rawtgt.tsd)
--debug.log("->there is actually a target and it's on tick 1 of info")
debug.log("loc x: "..rawtgt.loc.x.." y: "..rawtgt.loc.y.." z: "..rawtgt.loc.z.."\nrel x: "..rawtgt.rel.x.." y: "..rawtgt.rel.y.." z: "..rawtgt.rel.z.."\nglo x: "..rawtgt.pos.x.." y: "..rawtgt.pos.y.." z: "..rawtgt.pos.z)
--debug.log("->target file loop start")
--debug.log("-->k: "..fileindex.."\n-->match: "..match)
--debug.log("-->yes, match == 0")
--debug.log("-->rel vec of rawtgt to tgtfile <= mergedist, match found\n-->targetfiles["..fileindex.."] set to rawtgt.pos")
--debug.log("-->no, match ~= 0")
--debug.log("-->rel vec of rawtgt to tgtfile <= mergedist, match found\n-->targetfiles["..fileindex.."] removed")
--debug.log("->no match for rawtgt.pos found, added as new tgt at end of targetfiles table")
--debug.log("#targetfiles is now: "..(#targetfiles))

--debug.log("culling:\ntargetfiles loop start")
--debug.log("->k: "..k)
--debug.log("->timeout culled tgt: "..k)
--debug.log("->updated tgtfiles["..k.."] z to 5")
debug.log("tgt: "..k.." alt: "..v.pos.z)
--debug.log("->friendlies loop start")
--debug.log("-->friendly proximity culled tgt: "..k)
debug.log(#targetfiles.." target files")
debug.log("x: "..v.pos.x.." y: "..v.pos.y.." z: "..v.pos.z)
]]