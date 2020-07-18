local ecs = {}

-- Local versions of standard lua functions
local tinsert = table.insert
local tremove = table.remove


-- Systems

-- Update function for all Systems
local function processingSystemUpdate(system, dt)
	local process = system.process

	if process then
		if system.nocache then
			local entities = system.world.entities
			local filter = system.filter
			if filter then
				for i = 1, #entities do
					local entity = entities[i]
					if filter(system, entity) then
						process(system, entity, dt)
					end
				end
			end
		else
			process(system, dt)
		end
	end
end

-- Sorts Systems by a function system.sortDelegate(entity1, entity2) on modify.
local function sortedSystemOnModify(system)
	local entities = system.entities
	local indices = system.indices
	local sortDelegate = system.sortDelegate
	if not sortDelegate then
		local compare = system.compare
		sortDelegate = function(e1, e2)
			return compare(system, e1, e2)
		end
		system.sortDelegate = sortDelegate
	end
	table.sort(entities, sortDelegate)
	for i = 1, #entities do
		indices[entities[i]] = i
	end
end

--- Creates a new System or System class. Systems have a process method called each tick. Systems have three extra callbacks:
--
--     function system:process(dt) -- Process self.entities
--	   function system:process(entity, dt) -- when system.nocache is set, entities are processed individually
--
-- Systems have their own `update` method, so don't implement a a custom `update` callback for Systems.
function ecs.newSystem(table)
	table = table or {}
	table.update = processingSystemUpdate
	return table
end

--- Creates a new Sorted System. Sorted Systems sort their Entities according to a user-defined method, `system:compare(e1, e2)`, which should return true if `e1` should come before `e2` and false otherwise.
function ecs.sortedSystem(table)
	table = table or {}
	table.update = processingSystemUpdate
	table.onModify = sortedSystemOnModify
	return table
end


--- World functions

-- Adds and removes Systems that have been marked from the World.
local function _manageSystems(world)
	local s2a, s2r = world.systemsToAdd, world.systemsToRemove

	-- Early exit
	if #s2a == 0 and #s2r == 0 then
		return
	end

	local worldEntityList = world.entities
	local systems = world.systems

	-- Remove Systems
	for i = 1, #s2r do
		local system = s2r[i]
		local index = system.index
		local onRemove = system.onRemove
		if onRemove and not system.nocache then
			local entityList = system.entities
			for j = 1, #entityList do
				onRemove(system, entityList[j])
			end
		end
		tremove(systems, index)
		for j = index, #systems do
			systems[j].index = j
		end
		local onRemoveFromWorld = system.onRemoveFromWorld
		if onRemoveFromWorld then
			onRemoveFromWorld(system, world)
		end
		s2r[i] = nil

		-- Clean up System
		system.world = nil
		system.entities = nil
		system.indices = nil
		system.index = nil
	end

	-- Add Systems
	for i = 1, #s2a do
		local system = s2a[i]
		if systems[system.index or 0] ~= system then
			if not system.nocache then
				system.entities = {}
				system.indices = {}
				system.modified = true
			end
			
			if system.active == nil then
				system.active = true
			end

			system.world = world
			local index = #systems + 1
			system.index = index
			systems[index] = system
			local onAddToWorld = system.onAddToWorld
			if onAddToWorld then
				onAddToWorld(system, world)
			end

			-- Try to add Entities
			if not system.nocache then
				local entityList = system.entities
				local entityIndices = system.indices
				local onAdd = system.onAdd
				local filter = system.filter
				if filter then
					for j = 1, #worldEntityList do
						local entity = worldEntityList[j]
						if filter(system, entity) then
							local entityIndex = #entityList + 1
							entityList[entityIndex] = entity
							entityIndices[entity] = entityIndex
							if onAdd then
								onAdd(system, entity)
							end
						end
					end
				end
			end
		end
		s2a[i] = nil
	end
	
	local count = #world.systemsToAdd
	for i = 0, count do world.systemsToAdd[i] = nil end

	count = #world.systemsToRemove
	for i = 0, count do world.systemsToRemove[i] = nil end
end

-- Adds, removes, and changes Entities that have been marked.
local function _manageEntities(world)
	local e2r = world.entitiesToRemove
	local e2c = world.entitiesToChange

	-- Early exit
	if #e2r == 0 and #e2c == 0 then
		return
	end

	local entities = world.entities
	local systems = world.systems

	-- Change Entities
	for i = 1, #e2c do
		local entity = e2c[i]
		-- Add if needed
		if not entities[entity] then
			local index = #entities + 1
			entities[entity] = index
			entities[index] = entity
		end
		for j = 1, #systems do
			local system = systems[j]
			if not system.nocache then
				local ses = system.entities
				local seis = system.indices
				local index = seis[entity]
				local filter = system.filter
				if filter and filter(system, entity) then
					if not index then
						system.modified = true
						index = #ses + 1
						ses[index] = entity
						seis[entity] = index
						local onAdd = system.onAdd
						if onAdd then
							onAdd(system, entity)
						end
					end
				elseif index then
					system.modified = true
					local tmpEntity = ses[#ses]
					ses[index] = tmpEntity
					seis[tmpEntity] = index
					seis[entity] = nil
					ses[#ses] = nil
					local onRemove = system.onRemove
					if onRemove then
						onRemove(system, entity)
					end
				end
			end
		end
		e2c[i] = nil
	end

	-- Remove Entities
	for i = 1, #e2r do
		local entity = e2r[i]
		e2r[i] = nil
		local listIndex = entities[entity]
		if listIndex then
			-- Remove Entity from world state
			local lastEntity = entities[#entities]
			entities[lastEntity] = listIndex
			entities[entity] = nil
			entities[listIndex] = lastEntity
			entities[#entities] = nil
			-- Remove from cached systems
			for j = 1, #systems do
				local system = systems[j]
				if not system.nocache then
					local ses = system.entities
					local seis = system.indices
					local index = seis[entity]
					if index then
						system.modified = true
						local tmpEntity = ses[#ses]
						ses[index] = tmpEntity
						seis[tmpEntity] = index
						seis[entity] = nil
						ses[#ses] = nil
						local onRemove = system.onRemove
						if onRemove then
							onRemove(system, entity)
						end
					end
				end
			end
		end
	end
	
	local count = #world.entitiesToChange
	for i = 0, count do world.entitiesToChange[i] = nil end

	count = #world.entitiesToRemove
	for i = 0, count do world.entitiesToRemove[i] = nil end
end


local World = {}
World.__index = World

--- Creates a new World.
-- Can optionally add default Systems. Returns the new World
function ecs.newWorld(...)
	local world = setmetatable({
		-- List of Entities to remove
		entitiesToRemove = {},

		-- List of Entities to change
		entitiesToChange = {},

		-- List of Entities to add
		systemsToAdd = {},

		-- List of Entities to remove
		systemsToRemove = {},

		-- Set of Entities
		entities = {},

		-- List of Systems
		systems = {}
	}, World)

	for i = 1, select('#', ...) do
		local sys = select(i, ...)
		if sys then world:addSystem(sys) end
	end

	_manageSystems(world)

	return world
end

--- Adds an Entity to the world.
-- Also call this on Entities that have changed Components such that they match different Filters. Returns the Entity.
function World:addEntity(entity)
	local e2c = self.entitiesToChange
	e2c[#e2c + 1] = entity
	return entity
end

--- Adds a System to the world. Returns the System.
function World:addSystem(system)
	assert(system.world == nil, "System already belongs to a World.")
	local s2a = self.systemsToAdd
	s2a[#s2a + 1] = system
	system.world = self
	return system
end

--- Removes an Entity from the World. Returns the Entity.
function World:removeEntity(entity)
	local e2r = self.entitiesToRemove
	e2r[#e2r + 1] = entity
	return entity
end

--- Removes a System from the world. Returns the System.
function World:removeSystem(system)
	local s2r = self.systemsToRemove
	s2r[#s2r + 1] = system
	return system
end

--- Updates the World by dt (delta time). Takes an optional parameter, `filter`, which is a Filter that selects Systems from the World, and updates only those Systems. If `filter` is not supplied, all Systems are updated. Put this function in your main loop.
function World:update(dt, filter)
	_manageSystems(self)
	_manageEntities(self)

	local systems = self.systems

	-- Iterate through Systems IN ORDER
	for i = 1, #systems do
		local system = systems[i]
		if system.active then
			-- Call the modify callback on Systems that have been modified so they can be sorted
			local onModify = system.onModify
			if onModify and system.modified then
				onModify(system, dt)
			end
			
			local preUpdate = system.preUpdate
			if preUpdate and
				((not filter) or filter(self, system)) then
				preUpdate(system, dt)
			end
		end
	end

	--  Iterate through Systems IN ORDER
	for i = 1, #systems do
		local system = systems[i]
		if system.active and ((not filter) or filter(self, system)) then
			-- Update Systems that have an update method (most Systems)
			local update = system.update
			if update then
				local interval = system.interval
				if interval then
					local bufferedTime = (system.bufferedTime or 0) + dt
					while bufferedTime >= interval do
						bufferedTime = bufferedTime - interval
						update(system, interval)
					end
					system.bufferedTime = bufferedTime
				else
					update(system, dt)
				end
			end

			system.modified = false
		end
	end

	-- Iterate through Systems IN ORDER AGAIN
	for i = 1, #systems do
		local system = systems[i]
		local postUpdate = system.postUpdate
		if postUpdate and system.active and
			((not filter) or filter(self, system)) then
			postUpdate(system, dt)
		end
	end

end

--- Removes all Entities from the World
function World:clearEntities()
	local el = self.entities
	for i = 1, #el do
		self:removeEntity(el[i])
	end
end

--- Removes all Systems from the World
function World:clearSystems()
	local systems = self.systems
	for i = #systems, 1, -1 do
		self:removeSystem(systems[i])
	end
end

--- Sets the index of a System in the World, and returns the old index. Changes the order in which they Systems processed, because lower indexed Systems are processed first. Returns the old system.index.
function World:setSystemIndex(system, index)
	local oldIndex = system.index
	local systems = self.systems

	if index < 0 then
		index = #self.systems + 1 + index
	end

	tremove(systems, oldIndex)
	tinsert(systems, index, system)

	for i = oldIndex, index, index >= oldIndex and 1 or -1 do
		systems[i].index = i
	end

	return oldIndex
end

return ecs
