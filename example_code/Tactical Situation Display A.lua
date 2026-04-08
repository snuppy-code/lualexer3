m,i,o,p,s,T,F = math,input,output,property,screen,true,false
ign,osn,igb,osb = i.getNumber, o.setNumber, i.getBool, o.setBool
pgn,pgb = p.getNumber, p.getBool
abs,cos,sin,floor,atan = m.abs, m.cos, m.sin, m.floor,m.atan
pi = m.pi
pi2 = pi*2

s = screen
text,textbox,line,rect,rectF,circl,clear,setcolor = s.drawText,s.drawTextBox,s.drawLine,s.drawRect,s.drawRectF,s.drawCircle,s.drawClear,s.setColor

function line2(x1,y1,x2,y2)
	dx=x2-x1
	dy=y2-y1
	if abs(dx) >= abs(dy) then
		step = abs(dx)
	else
		step = abs(dy)
	end
	dx = dx / step
	dy = dy / step
	x = x1
	y = y1
	i = 0
	while (i <= step) do
		rectF(x,y,1,1)
		x = x + dx
		y = y + dy
		i = i + 1
	end
end
function vec(x,y,z)
return {x=x or 0,y=y or 0,z=z or 0}
end
function cross(a,b)
return vec(a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x)
end
function length(a)
return m.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)
end
function dist(a,b)
return m.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end

--function delta(c,b)if not a then a={}a[b]={oldVar=0,deltaVar=0}elseif not a[b]then a[b]={oldVar=0,deltaVar=0}end;a[b].deltaVar=c-a[b].oldVar;a[b].oldVar=c;return a[b].deltaVar end
function clamp(a, min, max) return m.max(min, m.min(a, max)) end
function round(x) return floor(x + 0.5) end

function dotline(x1,y1,x2,y2)
	segments = -0.9*zoom+50.09
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

--radar & tgt info
--rangelim = 10256
--xfov = 0.03*pi
--sweeplim = 0.12*pi2+xfov
rangelim = 13333
xfov = 0.03*pi
sweeplim = 0.09*pi2+xfov
culltime = 10

friendlies = {}
tgtfiles = {}

drawmap=true
zoom,zoominteg=7,0
rwrbuffer = {}
for i = 1,100 do
	rwrbuffer[i] = false
end
function onTick()
	--some inputs
	mpos = vec(ign(1),ign(3),ign(2))
	forwangle = -ign(27)*pi2--(radar 1)
	forwangle2 = -ign(20)*pi2--(radar 2)
	rearangle = -ign(32)*pi2+pi--(radar 3)

	monitorpressed = ign(30) > 0
    tap=monitorpressed~=touch and monitorpressed
    touch=monitorpressed
	if tap then
		drawmap = not drawmap
	end

	---- RWR ----
	pinged = ign(31) == 1
	
	table.remove(rwrbuffer, 1)
    table.insert(rwrbuffer, pinged)
	
	--check for missile
	pingcountingvar = 0
	for i = 1,6 do
		if rwrbuffer[i] then
			pingcountingvar = pingcountingvar + 1
		end
	end
	if pingcountingvar >= 2 then
		missileincoming = true
	else
		missileincoming = false
	end
	--check for being tracked
	pingcountingvar = 0
	for i = 1,26 do
		if rwrbuffer[i] then
			pingcountingvar = pingcountingvar + 1
		end
	end
	if pingcountingvar >= 2 then--should be or <= 7 then but idkkkk
		tracked = true
	else
		tracked = false
	end
	--check for being rapidly scanned
	pingcountingvar = 0
	for i = 1,100 do
		if rwrbuffer[i] then
			pingcountingvar = pingcountingvar + 1
		end
	end
	if pingcountingvar >= 2 then
		rapidscanned = true
	else
		rapidscanned = false
	end

	selectedtgt = vec(ign(23),ign(24),ign(25))
	--debug.log("tsdx: "..selectedtgt.x.." y: "..selectedtgt.y.." z: "..selectedtgt.z)

	--facing vectors
	rx,ry,rz=ign(4),ign(5),ign(6)
	cx,cy,cz=cos(rx),cos(ry),cos(rz)
	sx,sy,sz=sin(rx),sin(ry),sin(rz)
	right = vec(cy*cz, -sy, cy*sz)
	fwd = vec(sx*sz + cx*sy*cz, cx*cy, -sx*cz + cx*sy*sz)
	up = cross(right,fwd)
	
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
	--Zooming functionality, assumes 100% sens -1 to 1
	SOI = ign(29) == 1
	if SOI then
		zoomkey=ign(26)
	else
		zoomkey=0
	end
	if zoomkey < 0.01 and zoomkey > -0.01 then
		zoominteg = zoominteg-zoominteg/5
	else
		zoominteg = clamp((zoominteg+zoomkey/160),-0.1,0.1)
	end
	if zoom >= 50 then zoominteg = 0 end
	zoom=clamp(zoom+(zoomkey/55*zoom/2.4)+zoominteg*zoom/2.4,0.1,50)

	heading = -atan(fwd.x,fwd.y)+pi

	viewedx,viewedy=mpos.x,mpos.y--will change to let you pan the map
end
function onDraw()
	w,h = s.getWidth(),s.getHeight()
	if w > 32 then--drawing on tsd monitor
		if drawmap then
			--map colors
			s.setMapColorOcean(0,0,0)
			s.setMapColorShallows(2,2,2)
			s.setMapColorLand(7,7,7)
			s.setMapColorGrass(8,10,8)
			s.setMapColorSand(6,6,4)
			s.setMapColorSnow(25,25,26)
			s.setMapColorRock(3,3,3)
			s.setMapColorGravel(4,4,4)--commented cuz miniifer keeps yoinking them

			s.drawMap(viewedx,viewedy,zoom)
		end
		--find my position on the map and the size of the radar circle on the map
		mpixelx, mpixely = map.mapToScreen(viewedx,viewedy,zoom,w,h,mpos.x,mpos.y)
		eachpixelkm = zoom/w
		zoomnorm = zoom/50
		maxrangepixels = (rangelim/1000)/eachpixelkm
		--range circles & text
		for i = 0,2 do
			rangeloopkm = 5+10*i
			setcolor(255,255,255,7-zoomnorm*3)
			circl(mpixelx,mpixely,rangeloopkm/eachpixelkm)
			setcolor(255,255,255,11-zoomnorm*2)
			text(mpixelx+rangeloopkm/eachpixelkm-(5*(#tostring(rangeloopkm))),mpixely,rangeloopkm)
		end
		--heading lines
		setcolor(255,255,255,4-zoomnorm*2)
		for i = 1,8 do
			line(mpixelx,mpixely,mpixelx+sin(i*pi2/8)*120/eachpixelkm,mpixely+cos(i*pi2/8)*120/eachpixelkm)
		end

		--lines for current radar look angles
		setcolor(80,255,0,38)
		line(mpixelx,mpixely,mpixelx + sin(forwangle+heading-xfov)*maxrangepixels, mpixely + cos(forwangle+heading-xfov)*maxrangepixels)
		line(mpixelx,mpixely,mpixelx + sin(forwangle+heading+xfov)*maxrangepixels, mpixely + cos(forwangle+heading+xfov)*maxrangepixels)
		
		line(mpixelx,mpixely,mpixelx + sin(forwangle2+heading-xfov)*maxrangepixels, mpixely + cos(forwangle2+heading-xfov)*maxrangepixels)
		line(mpixelx,mpixely,mpixelx + sin(forwangle2+heading+xfov)*maxrangepixels, mpixely + cos(forwangle2+heading+xfov)*maxrangepixels)
		
		line(mpixelx,mpixely,mpixelx + sin(rearangle+heading-xfov)*maxrangepixels, mpixely + cos(rearangle+heading-xfov)*maxrangepixels)
		line(mpixelx,mpixely,mpixelx + sin(rearangle+heading+xfov)*maxrangepixels, mpixely + cos(rearangle+heading+xfov)*maxrangepixels)

		--if radartype then
			----radar borders for SWEEP
			--setcolor(0,180,0,23)
			--line(mpixelx,mpixely,mpixelx + sin(-sweeplim+heading)*maxrangepixels, mpixely + cos(-sweeplim+heading)*maxrangepixels)
			--line(mpixelx,mpixely,mpixelx + sin(sweeplim+heading)*maxrangepixels, mpixely + cos(sweeplim+heading)*maxrangepixels)
			--do
			--	bordercurvestart = -heading-sweeplim+pi/2
			--	step2 = (-heading+sweeplim+pi/2 - bordercurvestart) / 18
			--	for i = 1, 18 do
			--		ang1 = bordercurvestart + step2 * i
			--		ang2 = bordercurvestart + step2 * (i - 1)
			--		line(mpixelx + cos(ang1) * maxrangepixels,
			--		mpixely + sin(ang1) * maxrangepixels,
			--		mpixelx + cos(ang2) * maxrangepixels,
			--		mpixely + sin(ang2) * maxrangepixels)
			--	end
			--end
		--else
		--originally there was radar type system, no longer in use so im just reusing code from it and keeping here inc i need it
		setcolor(0,255,0,8)
		circl(mpixelx,mpixely,maxrangepixels)
		line(mpixelx,mpixely,mpixelx + sin(-sweeplim+heading)*maxrangepixels, mpixely + cos(-sweeplim+heading)*maxrangepixels)
		line(mpixelx,mpixely,mpixelx + sin(sweeplim+heading)*maxrangepixels, mpixely + cos(sweeplim+heading)*maxrangepixels)
		--setcolor(0,255,0,4)
		--circl(mpixelx,mpixely,maxrangepixels-0.6)
		--setcolor(0,255,0,2)
		--circl(mpixelx,mpixely,maxrangepixels-1.2)
		--end

		--draw actual target files
		for k,v in ipairs(tgtfiles) do
			tgtpixelx, tgtpixely = map.mapToScreen(viewedx,viewedy,zoom,w,h,v.pos.x,v.pos.y)

			--if dist(v.pos,b) then
			--	setcolor(90,2,5)
			--	rectF(tgtpixelx-2,tgtpixely-3,5,1)
			--	setcolor(99,20,3)
			--else
			--	setcolor(80,13,1)
			--end
			setcolor(80,13,1)
			thistargetalt=v.pos.z
			thistargetalt=m.max(m.min(thistargetalt/500,5),0)
			line(tgtpixelx-thistargetalt,tgtpixely-2,tgtpixelx+thistargetalt+1,tgtpixely-2)
			rect(tgtpixelx-1,tgtpixely-1,2,2)
		end
		
		--draw selected target marker
		if length(selectedtgt) > 0 then
			tgtpixelx, tgtpixely = map.mapToScreen(viewedx,viewedy,zoom,w,h,selectedtgt.x,selectedtgt.y)
			
			setcolor(55,20,40,70)
			dotline(mpixelx,mpixely,tgtpixelx,tgtpixely)
			
			setcolor(46,0,25)
			rectF(tgtpixelx-2,tgtpixely-2,1,5)
			rectF(tgtpixelx+2,tgtpixely-2,1,5)
			rectF(tgtpixelx,tgtpixely,1,1)
		end

		--friendlies
		setcolor(0,40,255)
		for k,v in pairs(friendlies) do
			--debug.log("v.x: "..v.x.." v.y: "..v.y.." v.z: "..v.z)
			fpixelx, fpixely = map.mapToScreen(viewedx,viewedy,zoom,w,h,v.pos.x,v.pos.y)
			--ang,spd,alt
			--if ang then
			--	linex1,liney1 = rotate2((m.ceil(m.min(alt/1000,4))),1.5,ang)
			--	linex2,liney2 = rotate2(-(m.ceil(m.min(alt/1000,4))),1.5,ang)
			--
			--	linex3,liney3 = rotate2(0,1,ang)
			--	linex4,liney4 = rotate2(0,floor(m.max(spd,100)/100),ang)
			--
			--	line2(fpixelx+linex1, fpixely+liney1, fpixelx+linex2, fpixely+liney2)--alt line
			--	line2(fpixelx+linex3, fpixely+liney3, fpixelx+linex4, fpixely+liney4)--spd line
			--end
			thistargetalt=v.pos.z
			thistargetalt=m.max(m.min(thistargetalt/500,5),0)
			line(fpixelx-thistargetalt,fpixely-2,fpixelx+thistargetalt+1,fpixely-2)

			rectF(fpixelx,fpixely-1,1,1)
			rectF(fpixelx+1,fpixely,1,1)
			rectF(fpixelx,fpixely+1,1,1)
			rectF(fpixelx-1,fpixely,1,1)

			if length(v.sel) > 0 then
				ftrkpixelx, ftrkpixely = map.mapToScreen(viewedx,viewedy,zoom,w,h,v.sel.x,v.sel.y)
				
				setcolor(30,90,255,30)
				dotline(fpixelx,fpixely,ftrkpixelx,ftrkpixely)

				setcolor(40,40,110,30)
				rectF(ftrkpixelx-2,ftrkpixely-2,1,5)
				rectF(ftrkpixelx+2,ftrkpixely-2,1,5)
				rectF(ftrkpixelx,ftrkpixely,1,1)
				--line(fpixelx,fpixely,ftrkpixelx,ftrkpixely)
			end
		end

		if SOI then
			setcolor(1,1,1,200)
			rectF(13,2,12,5)
			setcolor(85,160,35)
			text(13,2,"SOI")
		end
		
		--missile
		--setcolor(255,0,0)
		--line(50,50,52,52)
		--line(50,49,49,50)

		--my target
		--setcolor(80,13,1)
		--rect(1,1,2,2)
		
		--friend target
		--setcolor(90,26,1)
		--rect(1,5,2,2)

		--debug text
		--setcolor(255,255,255)
		--text(5,5,"tgts: "..#tgtfiles)
	else--drawing on RWR monitor
		awdtext = ""
		if missileincoming then
			setcolor(255,0,0)
			awdtext = "MSSLE"
		elseif tracked then
			setcolor(239,38,0)
			awdtext = "TRACK"
		elseif rapidscanned then
			setcolor(255,135,0)
			awdtext = "WARN"
		end
		if missileincoming or tracked or rapidscanned then
			rectF(0,0,32,32)
			setcolor(230,230,230)
			text(4,12,awdtext)
		end
		if pinged then
			setcolor(230,230,230)
			text(6,2,"PING")
		end
	end
end