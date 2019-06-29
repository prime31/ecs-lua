local ecs = require 'ecs'


local talkingSystem = ecs.newSystem()

function talkingSystem:filter(e)
	return e.name ~= nil and e.mass ~= nil
end

function talkingSystem:preUpdate(dt)
	print('talkingSystem', 'preUpdate')
end

function talkingSystem:process(dt)
	print('talkingSystem', 'process', #self.entities, 'modified', self.modified)
	for _, e in ipairs(self.entities) do
		e.mass = e.mass + dt * 3
	end
end

function talkingSystem:postUpdate(dt)
	print('talkingSystem', 'postUpdate')
end


local noCacheSystem = ecs.newSystem()
noCacheSystem.nocache = true

function noCacheSystem:filter(e)
	return e.name ~= nil and e.mass ~= nil
end

function noCacheSystem:onModify(dt)
	print('noCacheSystem onModify', dt)
end

function noCacheSystem:process(e, dt)
	print('noCacheSystem', 'process', e, dt)
end



function makeJoe()
	return {
		name = "Joe",
		mass = 150,
		hairColor = "brown"
	}
end


local world = ecs.newWorld(talkingSystem, noCacheSystem)

world:addEntity(makeJoe())
world:addEntity(makeJoe())
local e = world:addEntity(makeJoe())

world:update(0.016)

world:setSystemIndex(noCacheSystem, 1)

world:addEntity(makeJoe())
world:addEntity(makeJoe())
world:removeEntity(e)

print('---------------')
world:update(0.016)

print('---------------')
world:update(0.016)

