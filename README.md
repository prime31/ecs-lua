# ecs

ecs is an Entity Component System for Lua that's simple, flexible, and useful. Because of Lua's tabular nature, Entity Component Systems are a natural choice for simulating large and complex systems.

ecs also works well with objected oriented programming in Lua because Systems and Entities do not use metatables. This means you can subclass your Systems and Entities, and use existing Lua class frameworks with ecs, no problem.

## Overview
ecs has four important types: Worlds, Filters, Systems, and Entities. Entities, however, can be any Lua table, and Filters are just functions that take an Entity as a parameter.

### Entities
Entities are simply Lua tables of data that gets processed by Systems. Entities should contain primarily data rather than code, as it is the System's job to do logic on data. Henceforth, a key-value pair in an Entity will be referred to as a Component.

### Worlds
Worlds are the outermost containers in ecs that contain both Systems and Entities. In typical use, only one World is used at a time.

### Systems
Systems in ecs describe how to update Entities. Systems select certain Entities using a Filter, and then only update those select Entities. Some Systems don't update Entities, and instead just act as function callbacks every update. ecs provides functions for creating Systems, as well as creating Systems that can be used in an object oriented fashion.

### Filters
Filters are used to select Entities. Filters are just a simple Lua function that takes an Entity as a parameter and returns true/false.

### API
An API overview is available [here](API.md)

## Example
```lua
local ecs = require 'ecs'

local talkingSystem = ecs.newSystem()

function talkingSystem:filter(e)
	return e.name ~= nil and e.mass ~= nil and e.phrase ~= nil
end

function talkingSystem:process(e, dt)
	for _, e in ipairs(self.entities) do
		e.mass = e.mass + dt * 3
		print(("%s who weighs %d pounds, says %q."):format(e.name, e.mass, e.phrase)
	end
end

local joe = {
    name = "Joe",
    phrase = "I'm a plumber.",
    mass = 150,
    hairColor = "brown"
}

local world = ecs.newWorld(talkingSystem, joe)

for i = 1, 20 do
    world:update(1)
end
```

## Credits
ecs is a heavily modified fork of [Tiny-ecs](https://github.com/bakpakin/tiny-ecs)
