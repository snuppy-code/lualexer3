igb,osb,ign,osn = input.getBool, output.setBool,input.getNumber,output.setNumber
selectedhardpoint = 1
hardpoints = {
    [1] = 0,
    [2] = 1,
    [3] = 8,
    [4] = 2,
    [5] = 7,
    [6] = 3,
    [7] = 6,
    [8] = 4,
    [9] = 5
}

function onTick()
	touchin = igb(1)
	if touchin and not touch then
		selectedhardpoint = selectedhardpoint%(#hardpoints)+1
	end
	touch = touchin
    osb(hardpoints[selectedhardpoint],true)

    equipped = 0
    for i = 1,(#hardpoints-1) do
        if not (ign(i) == 0) then
            equipped = equipped + 1
        end
    end
    osn(1,equipped)
end