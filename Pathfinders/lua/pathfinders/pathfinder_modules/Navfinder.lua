
if SERVER then
	--local Finder = Pathfind:CreatePathfinder()
	
	function Finders:NavInitialize( finder, startarea, endarea, walkablefunc, heuristic, weightfunc )
		walkablefunc = walkablefunc or function() return true end
		weightfunc = weightfunc or function() return 1 end
		heuristic = heuristic or function(cur, targ) return (navmesh.GetNavAreaByID(cur):GetCenter():Distance(navmesh.GetNavAreaByID(targ):GetCenter())) end
		finder:Initialize(
			startarea:GetID(), --Start area, ends up used a table index, which CNavAreas don't like, so use the ID instead
			endarea:GetID(), --End area, same thing as above
			function(id) --define a function that returns a table of other nodes, also converted to just their IDs
				neighbors = navmesh.GetNavAreaByID(id):GetAdjacentAreas()
				for i, area in pairs(neighbors) do
					neighbors[i] = area:GetID()
				end
				return neighbors
			end,
			walkablefunc, --Function to check if area is walkable, true if valid, false if invalid
			heuristic, --Heuristic estimate between two nodes, using distance for this one.
			weightfunc --Function to change weight of node, returning higher value makes them avoided more, lower values more perfered, normally at 1
		) 
	end
	
	--Finders:NavInitialize(Finder, navmesh.GetNearestNavArea(Entity(1):GetPos()), navmesh.GetNearestNavArea(Entity(1):GetEyeTrace().HitPos))
	
end