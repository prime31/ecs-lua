# ecs

`ecs` is a _luafied_ Entity Component System. Lua isn't like other languages so the design of an ECS should support the features of lua. While `ecs` has the main paradigms of standard Entity Component Systems, it differs quite a bit in the details. A standard ECS is often created for raw speed, cache locality and other performance reasons. With lua, we dont have structs so there is no point in matching the way standard Entity Component Systems are designed since we just don't have that kind of control over the memory layout.

`ecs` is more flexible and would be better described as a way to centralize, organize, sort and filter the objects in your game. `ecs` lets you have lightweight entities (a plain old table is an entity) with components (any key/value pair in the table is a component) that can all be batch processed by a system. You can also have "heavy entities" with the more traditional `update` and `draw` methods.

For example, you may have tens to hundreds of bullets if you were making a shooter so these make sense as lightweight entity tables all processed in a batch by a system. The player is a much more complex beast and there is only one of them so making player be a "heavy entity" with an `update` and `draw` method makes more sense. The flexibility to choose is yours.

## Overview
`ecs` has four important types: Worlds, Filters, Systems, and Entities.

### Worlds
Worlds are the outermost containers in `ecs` that contain both Systems and Entities. In typical use, only one World is used at a time.

### Entities
Entities are simply Lua tables of data that gets processed by Systems. Entities should contain only data rather than code, as it is the System's job to do logic on data. Henceforth, a key-value pair in an Entity will be referred to as a Component.

### Systems
Systems in `ecs` describe how to update Entities. Systems select certain Entities using a Filter, and then only update those select Entities. Much like Entities, Systems are just a plain old Lua table with two required methods: `process` and `filter`. There are several optional methods that can be implemented to get various state change information as well, such as `onAdd`, `onRemove`, `onAddToWorld` and `onRemoveFromWorld`.

### Filters
Filters are used to select Entities. Filters are just a simple Lua function that takes an Entity as a parameter and returns true/false.

### API
An API overview is available [here](API.md)

## Example

```lua
local ecs = require 'ecs'

-- create a system
local talkingSystem = ecs.newSystem()

-- this system will only process enttiies that have a name and mass
function talkingSystem:filter(e)
	return e.name ~= nil and e.mass ~= nil
end

-- called once per frame, this is where we will process the entities. self.entities contains the
-- filtered, sorted list of entities.
function talkingSystem:process(e, dt)
	for _, e in ipairs(self.entities) do
		e.mass = e.mass + dt * 3
		print(("%s who weighs %d pounds"):format(e.name, e.mass)
	end
end

local joe = {
    name = "Joe",
    mass = 150,
    hairColor = "brown"
}

local world = ecs.newWorld(talkingSystem, joe)

for i = 1, 20 do
    -- normally, this would be called in your update method with a delta time
    world:update(1)
end
```

## Credits
ecs is a modified fork of [Tiny-ecs](https://github.com/bakpakin/tiny-ecs)
