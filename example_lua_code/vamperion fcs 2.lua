--this IS the latest version
m,i,o,p = math,input,output,property
ign,osn,igb = i.getNumber, o.setNumber, i.getBool
pgn,pgb = p.getNumber, p.getBool

pitchtunes = {p=pgn("P pitch"),i=pgn("I pitch"),d=pgn("D pitch")}
rolltunes = {p=pgn("P roll"),i=pgn("I roll"),d=pgn("D roll")}
yawtunes = {p=pgn("P yaw"),i=pgn("I yaw"),d=pgn("D yaw")}

unloadedgains = {
	pitch=pgn("Control gain pitch"),
	roll=pgn("Control gain roll"),
	yaw=pgn("Control gain yaw")}
loadedgains = {
	pitch=pgn("Control gain pitch loaded"),
	roll=pgn("Control gain roll loaded"),
	yaw=pgn("Control gain yaw loaded")}
unloadedtrims = {
	pitch=pgn("Pitch trim"),
	roll=pgn("Roll trim"),
	yaw=pgn("Yaw trim")}

activationdelays = {
	pitch=pgn("Pitch PID activation delay ticks"),
	roll=pgn("Roll PID activation delay ticks"),
	yaw=pgn("Yaw PID activation delay ticks")}

gains = {}

deadzone = pgn("Deadzone")

runpids = pgb("Use PIDs?")

function threshold(a,min,max)
	return a > min and a < max
end
function clamp(a,min,max)
	return m.min(m.max(a,min),max)
end

function addAxes(a,b)
	return {pitch=a.pitch + b.pitch,roll=a.roll + b.roll,yaw=a.yaw + b.yaw}
end

function lerp(a,b,t) return a * (1-t) + b * t end

function capacitor(f,g,h,j)
	if not dltb then
		dltb = {}
		dltb[j] = {i1=0,i2=0}
	elseif not dltb[j] then
		dltb[j] = {i1=0,i2=0}
	end
	if f then
		if dltb[j].i1 >= g then
			dltb[j].i2 = h
			return true
		else
			dltb[j].i1 = dltb[j].i1 + 1
			return false
		end
	else
		if dltb[j].i2 == 0 then
			return false
		else
			dltb[j].i2 = dltb[j].i2 - 1
			return true
		end
	end
end
function pid(k,l,n,j)
	if not pdtl then
		pdtl = {}
		pdtl[j] = {e=0,i=0,d=0,ep=0,ip=0}
	elseif not pdtl[j] then
		pdtl[j] = {e=0,i=0,d=0,ep=0,ip=0}
	end
	pdtl[j].e = k - l
	pdtl[j].i = pdtl[j].ip + pdtl[j].e
	pdtl[j].d = pdtl[j].e - pdtl[j].ep
	pdtl[j].controlOutput = n.p * pdtl[j].e + n.i * pdtl[j].i + n.d * pdtl[j].d
	pdtl[j].ep = pdtl[j].e
	pdtl[j].ip = pdtl[j].i
	return pdtl[j].controlOutput
end

sumangspdaxes = {pitch=5,roll=0,yaw=0}
lastorient = {pitch=-5,roll=0,yaw=0}
outputaxes = {pitch=0,roll=0,yaw=0}

pitchever = false

maxmissiles = 8

function onTick()
	manaxes = {pitch=ign(2), roll=ign(1), yaw=ign(3)}--yaw=0}
	angspdaxes = {pitch=-ign(4), roll=-ign(5), yaw=ign(6)}
	--spd = ign(7)
	--if spd <= 145 then
	--	spdfactor = 20
	--else
	--	spdfactor = 0.51/(1-3.64*(2.71828^(-0.01*spd)))
	--end
	--debug.log("spdfactor: "..spdfactor)
	missilesfactor = ign(8)/8
	--debug.log("missilesfactor: "..missilesfactor)
	gains = {
		pitch=lerp(unloadedgains.pitch,loadedgains.pitch,missilesfactor),
		roll=lerp(unloadedgains.roll,loadedgains.roll,missilesfactor),
		yaw=lerp(unloadedgains.yaw,loadedgains.yaw,missilesfactor)}
	--gains = {
	--	pitch=ign(10),
	--	roll=ign(9),
	--	yaw=ign(11)}
	--trims = {
	--	pitch=0,
	--	roll=0,
	--	yaw=0}
	--debug.log("pitch gain: "..gains.pitch)
	--debug.log("pitch gain: "..gains.roll)
	--debug.log("pitch gain: "..gains.yaw)

	trims = {
		pitch=unloadedtrims.pitch*gains.pitch,
		roll=unloadedtrims.roll*gains.roll,
		yaw=unloadedtrims.yaw*gains.yaw}
	
	--gains = {
	--	pitch=gains.pitch*spdfactor,
	--	roll=gains.roll*spdfactor,
	--	yaw=gains.yaw*spdfactor}

	sumangspdaxes = addAxes(sumangspdaxes,angspdaxes)

	--pitch
	PImanual = manaxes.pitch * gains.pitch
	PIpid = pid(lastorient.pitch, sumangspdaxes.pitch, pitchtunes, "ppid")
	PInokeypress = threshold(manaxes.pitch, -deadzone, deadzone)
	if capacitor(not PInokeypress, 0, activationdelays.pitch, "pcap") then
		if PInokeypress then
			outputaxes.pitch = trims.pitch - angspdaxes.pitch*10
		else
			outputaxes.pitch = trims.pitch + PImanual
		end
		lastorient.pitch = sumangspdaxes.pitch
	elseif runpids then
		outputaxes.pitch = trims.pitch + PIpid
	else
		outputaxes.pitch=trims.pitch
	end

	--roll
	ROmanual = manaxes.roll * gains.roll
	ROpid = pid(lastorient.roll, sumangspdaxes.roll, rolltunes, "rpid")
	ROnokeypress = threshold(manaxes.roll, -deadzone, deadzone)
	if capacitor(not ROnokeypress, 0, activationdelays.roll, "rcap") then
		if ROnokeypress then
			outputaxes.roll = trims.roll - angspdaxes.roll*2
		else
			outputaxes.roll = trims.roll + ROmanual
		end
		lastorient.roll = sumangspdaxes.roll
	elseif runpids then
		outputaxes.roll = trims.roll + ROpid
	else
		outputaxes.roll=trims.roll
	end

	--yaw
	YAmanual = manaxes.yaw * gains.yaw
	YApid = pid(lastorient.yaw, sumangspdaxes.yaw, yawtunes, "ypid")
	YAnokeypress = threshold(manaxes.yaw, -deadzone, deadzone)
	if capacitor(not YAnokeypress or not PInokeypress or not ROnokeypress, 0, activationdelays.yaw, "ycap") then
		if YAnokeypress then
			outputaxes.yaw = trims.yaw - angspdaxes.yaw*5
		else
			outputaxes.yaw = trims.yaw + YAmanual
		end
		lastorient.yaw = sumangspdaxes.yaw
	elseif runpids then
		outputaxes.yaw = trims.yaw + YApid
	else
		outputaxes.yaw=trims.yaw
	end

	--control mix and output:
	osn(1,-outputaxes.pitch + outputaxes.roll)
	osn(2,-outputaxes.pitch)
	osn(3,-outputaxes.pitch - outputaxes.roll)
	osn(4,outputaxes.pitch + outputaxes.roll)
	osn(5,outputaxes.pitch)
	osn(6,outputaxes.pitch - outputaxes.roll)
	osn(7,outputaxes.yaw)
	osn(8,-outputaxes.yaw)
	osn(9,outputaxes.roll/10)
end