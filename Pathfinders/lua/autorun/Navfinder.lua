
if SERVER then
	local Heaps = {}
	Heaps.Items = {}
	Heaps.ItemCount = 0
	Heaps.CompareFunc = nil
	--Heaps.self = Heaps
	function Heaps:Parent(Item)
		return (Item.HeapIndex-1)/2
	end
	
	function Heaps:ChildL(Item)
		return 2*(Item.HeapIndex)+1
	end
	function Heaps:ChildR(Item)
		return 2*(Item.HeapIndex)+2 
	end
	function Heaps:Add(item)
		item.HeapIndex = self.ItemCount
		self.Items[self.ItemCount] = item
		self.ItemCount = self.ItemCount + 1
		self:SortUp(item)
	end
	function Heaps:Swap(Item1, Item2)
		local Item1ID = Item1.HeapIndex
		local Item2ID = Item2.HeapIndex
		self.Items[Item1ID] = Item2
		self.Items[Item2ID] = Item1
		Item1.HeapIndex = Item2ID
		Item2.HeapIndex = Item1ID
	end
	function Heaps:SortUp(Item)
		while (true) do
			local parentIndex = self:Parent(Item)
			parentIndex = math.ceil(parentIndex)
			local parentItem = self.Items[parentIndex]
			
			--PrintTable(Item)
			--if(parentItem)then PrintTable(parentItem) end
			if(parentItem and self:compare(Item, parentItem))then
				self:Swap(parentItem, Item)
			else
				break
			end
		end
	end
	function Heaps:SortDown(Item)
		while true do
			local IndexL = self:ChildL(Item)
			local IndexR = self:ChildR(Item)
			local SwapIndex = 0

			if(IndexL < self.ItemCount)then
				SwapIndex = IndexL
				
				if(IndexR < self.ItemCount)then
					if(self:compare(self.Items[IndexR], self.Items[IndexL]))then
						SwapIndex = IndexR
					end
				end
				
				if (self:compare(self.Items[SwapIndex], Item)) then
					self:Swap(Item, self.Items[SwapIndex])
				else
					return
				end
			else
				return
			end
		end
	end
	
	function Heaps:compare(Item1, Item2)
		return self.CompareFunc(Item1, Item2)
	end
	
	function Heaps:Remove(Item)
		local firstItem = self.Items[0]
		local Index = Item.HeapIndex
		self.ItemCount = self.ItemCount - 1
		self.Items[Index] = self.Items[self.ItemCount]
		self.Items[Index].HeapIndex = Index
		self:SortDown(self.Items[Index])
		self.Items[self.ItemCount] = nil
		return Item
	end

	
	function Heaps:RemoveLowest()
		local firstItem = self.Items[0]
		local ret = self:Remove(firstItem)
		return ret
	end

	Pathfind = {}
	local NavFinderClass = {}
	NavFinderClass.Open = {}
	NavFinderClass.Closed = {}
	NavFinderClass.Areas = {}
	NavFinderClass.Goal = nil
	NavFinderClass.Path = {}
	NavFinderClass.Pathing = false
	
	function Pathfind.CreateHeap()
		local heap = table.Copy(Heaps)
		
		return heap
	end
	
	local NavClass = {}
	NavClass.CNavArea = nil
	NavClass.gCost = math.huge
	NavClass.hCost = math.huge
	NavClass.IsOpen = true
	NavClass.IsClosed = false
	NavClass.CameFrom = nil
	
	function NavClass:FCost()
		return self.gCost + self.hCost
	end
	
	function NavFinderClass:GetAreaData(Area)
		local Data = self.Areas[Area:GetID()]
		if(Data) then 
			return Data 
		else 
			return false 
		end
	end
	
	function NavFinderClass:RemoveOpen(Area)
		Area.IsOpen = false
		--table.RemoveByValue( self.Open, Area )
	end
	function NavFinderClass:AddOpen(Area)
		Area.IsOpen = true
		--table.insert(self.Open, Area)
	end
	
	function NavFinderClass:RemoveClosed(ID)
		Area.IsClosed = false
		table.RemoveByValue( self.Closed, Area )
	end
	function NavFinderClass:AddClosed(Area)
		Area.IsClosed = true
		table.insert(self.Closed, Area)
	end
	
	function NavFinderClass:PathFindBegin(Start, End)
		self.Pathing = true
	
		self.Open = {}
		self.Closed = {}
		self.Areas = {}
		self.Goal = nil
		self.Path = {}
	
	
		local StData = self:CreateNavClass(Start)
		StData.gCost = 0
		StData.hCost = Start:GetCenter():Distance( End:GetCenter() )
		self.Closed = {}
		self.Open = {}
		self.Open = Pathfind.CreateHeap()
		self.Open.CompareFunc = function(Item1, Item2) 
			return (Item1.gCost+Item1.hCost)<(Item2.gCost+Item2.hCost)
		end
		self.Open:Add(StData)
		self.Areas[Start:GetID()] = StData
		
		self.Goal = End
	end
	
	function NavFinderClass:PathFindStep(steps, filter, filterparams)
		local CurStep = 0
		while CurStep<steps do
			CurStep = CurStep + 1
		
			local Current = nil
			
			if(self.Pathing == false)then
				return "No Path In Progress"
			end
			
			if(table.IsEmpty(self.Open.Items))then
				self.Pathing = false
				return "Failed"
			end
			
			Current = self.Open:RemoveLowest()
			
			self:RemoveOpen(Current)
			self:AddClosed(Current)
			
			--PrintTable(Current)
			
			if(Current.CNavArea:GetID() == self.Goal:GetID())then ---Have we already reached the goal? if so, say so---
				self.Path = {}
				
				while Current.CameFrom != nil do
					table.insert(self.Path, 1, Current.CNavArea)
					Current = Current.CameFrom
				end
				
				table.insert(self.Path, 1, Current.CNavArea)
				---debugoverlay.Box( Vector origin, Vector mins, Vector maxs, number lifetime = 1, table color = Color( 255, 255, 255 ) )
				
				--PrintTable(self.Path)
				
				self.Pathing = false
				return "Reached Goal"
			end
			
			for k, neighborN in pairs(Current.CNavArea:GetAdjacentAreas()) do
				
				local neighbor = self:GetAreaData(neighborN)
				
				if(!neighbor)then   ---If the area had no assigned NavClass, create one
					neighbor = self:CreateNavClass(neighborN)
					self.Open:Add(neighbor)
				end
				if(neighbor.IsClosed)then  ---Check if we already used this area---
					continue
				end
				if( filter and !filter(Current.CNavArea, neighbor.CNavArea, filterparams) )then  ---Allow for custom func filter for valid areas---
					self:RemoveOpen(neighbor)
					self:AddClosed(neighbor)
					self.Open:Remove(neighbor)
					continue
				end
				
				local newCost = Current.gCost + (Current.CNavArea:GetCenter():Distance( neighbor.CNavArea:GetCenter() ))

				if( ( newCost < neighbor.gCost ) || !neighbor.IsOpen)then ---Update costs if less then before
					neighbor.gCost = newCost
					neighbor.hCost = self.Goal:GetCenter():Distance( neighbor.CNavArea:GetCenter() )
					neighbor.CameFrom = Current
					
					if(!neighbor.IsOpen)then
						self.Open:Add(neighbor)
						self:AddOpen(neighbor)
						self:RemoveClosed(neighbor)
					end
				end
			end
			
			--[[
			for I, A in pairs(self.Open.Items)do
				debugoverlay.Box( A.CNavArea:GetCenter(), Vector(-5,-5,-5), Vector(5,5,5), 0.03, Color(0,255,255) )
				if(A.CameFrom)then
					debugoverlay.Line( A.CNavArea:GetCenter(), A.CameFrom.CNavArea:GetCenter(), 0.03, Color(0,255,255), true )
				end
			end
			]]--
			--[[
			for I, A in pairs(self.Closed)do
				debugoverlay.Box( A.CNavArea:GetCenter(), Vector(-5,-5,-5), Vector(5,5,5), 0.03, Color(255,0,0) )
				if(A.CameFrom)then
					debugoverlay.Line( A.CNavArea:GetCenter(), A.CameFrom.CNavArea:GetCenter(), 0.03, Color(255,0,0), true )
				end
			end
			]]--
		end
	end
	
	function Pathfind.CreateNavmeshPathfinder()
		local finder = table.Copy(NavFinderClass)
		
		return finder
	end
	
	function NavFinderClass:CreateNavClass(area)
		local navclass = table.Copy(NavClass)
		
		navclass.CNavArea = area
		self.Areas[area:GetID()] = navclass
		
		return navclass
	end
	
	local pather = Pathfind.CreateNavmeshPathfinder()
	
	local End = navmesh.GetNearestNavArea( Entity(1):GetPos() )
	local Start = navmesh.GetNearestNavArea( Entity( 1 ):GetEyeTrace().HitPos )
	
	--pather:PathFindBegin(Start, End)
	--pather:PathFind(Start, End)
	
	local Timer = CurTime()
	
	--[[
	hook.Add("Think", "TestCalcPath", function()
		if (CurTime()-Timer)>0.5 then
			Timer = CurTime()
			local status = pather:PathFindStep(1)
			if( status == "Reached Goal")then
				for I, C in pairs(pather.Path)do
					debugoverlay.Box( C:GetCenter(), Vector(-5,-5,-5), Vector(5,5,5), 5, Color(0,255,0) )
					if (I-1)>0 then
						debugoverlay.Line( C:GetCenter(), pather.Path[I-1]:GetCenter(), 5, Color(0,255,0), true )
					end
				end
			end
			if( status == "Failed")then
				print("failed")
			end
			--print(status)
		end
	end)
	]]--
end