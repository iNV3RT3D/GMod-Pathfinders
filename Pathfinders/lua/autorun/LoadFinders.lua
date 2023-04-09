
if SERVER then

	include("pathfinders/PathfinderBase.lua")
	
	local modules = file.Find("pathfinders/pathfinder_modules/*.lua", "LUA")
	
	for _, filename in pairs(modules) do
		include("pathfinders/pathfinder_modules/"..filename)
	end

end