
if SERVER then

	Pathfind = {}
	FinderClass = {}
	FinderClass.Nodes = {}
	FinderClass.Goal = nil
	FinderClass.Open = {}
	FinderClass.Path = {}
	FinderClass.Pathing = false
	FinderClass.Neighbour_iterator = nil
	FinderClass.Walkable_checks = nil
	FinderClass.Weight_checks = nil
	FinderClass.Heuristic = nil
	FinderClass.Checked = 0
	
	Finders = {}
	
	print("Pathfinder Base Loaded")
	
	function FinderClass:Initialize(start_node, target_node, neighbour_iterator, walkable_checks, heuristic, weight_checks)
		self.Nodes = {
			[start_node] = {
				parent = nil, 
				open = true,
				f = 0, 
				g = 0, 
				h = 
				heuristic(start_node, target_node)
			}
		}
		self.Open = {
			[start_node] = true
		}
		self.Goal = target_node
		self.Neighbour_iterator = neighbour_iterator
		self.Walkable_checks = walkable_checks
		self.Weight_checks = weight_checks
		self.Heuristic = heuristic
		self.Pathing = true
	end
	
	function FinderClass:Step( steps )
		local stepsleft = steps or 1
		while stepsleft > 0 do
			stepsleft = stepsleft - 1
			if !self.Pathing then return false end
			local lowestFScore = math.huge
			current_node, current_data = nil, nil
			for Node, NodeM in pairs(self.Open) do
				local NodeData = self.Nodes[Node]
				if NodeData.open and (NodeData.f < lowestFScore) then
					current_node = Node
					lowestFScore = NodeData.f
					current_data = NodeData
				end
			end
			if current_node then
				self.Checked = self.Checked + 1
				if current_node == self.Goal then
					self.Path = {}
					while (current_data.parent != nil) do
						table.insert(self.Path, navmesh.GetNavAreaByID(current_node))
						
						current_node = current_data.parent
						current_data = self.Nodes[current_node]
					end
					table.insert(self.Path, navmesh.GetNavAreaByID(current_node))
					self.Pathing = false
					return true
				end
				self.Open[current_node] = nil
				current_data.open = false
				local neighbor_data
				local neighbors = self.Neighbour_iterator(current_node, current_status)
				for _, neighbor_node in pairs(neighbors) do
					neighbor_data = self.Nodes[neighbor_node]
					if not neighbor_data then
						if self.Walkable_checks(current_node, neighbor_node) then
							neighbor_data = {
								parent = current_node,
								open = true,
								g = current_data.g + self.Heuristic(current_node, neighbor_node) * self.Weight_checks(current_node, neighbor_node),
								h = self.Heuristic(current_node, self.Goal)
							}
							self.Open[neighbor_node] = true
							neighbor_data.f = neighbor_data.g + neighbor_data.h
							self.Nodes[neighbor_node] = neighbor_data
						end
					elseif neighbor_data.open and self.Walkable_checks(current_node, neighbor_node) and self.Nodes[neighbor_data.parent].g > current_data.g then
						neighbor_data.parent = current_node
						neighbor_data.g = current_data.g + self.Heuristic(current_node, neighbor_node) * self.Weight_checks(current_node, neighbor_node)
						neighbor_data.h = self.Heuristic(current_node, self.Goal)
						neighbor_data.f = neighbor_data.g + neighbor_data.h
					end
				end
			else
				return false
			end
		end
	end
	
	function Pathfind.CreatePathfinder()
		local finder = table.Copy(FinderClass)
		
		return finder
	end
end