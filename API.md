## Filters

A Filter is a function that selects which Entities apply to a System. Filters take two parameters, the System and the Entity, and return a boolean value indicating if the Entity should be processed by the System. A truthy value includes the entity, while a falsey (nil or false) value excludes the entity.

Filters must be added to Systems by setting the `filter` field of the System

```lua
function someSystem:filter(e)
	return e.name ~= nil and e.mass ~= nil and e.phrase ~= nil
end
```

## Systems

A System is a wrapper around function callbacks for manipulating Entities. Systems are implemented as tables that contain at least one method: an update function that takes parameters like so:

`function system:process(dt)`

The entities currently available for any system to process are in the table `self.entities`.

There are also a few other optional callbacks:

  * `function system:filter(entity)` - Returns true if this System should include this Entity, otherwise should return false. If this isn't specified, no Entities are included in the System.
  * `function system:onAdd(entity)` - Called when an Entity is added to the System.
  * `function system:onRemove(entity)` - Called when an Entity is removed from the System.
  * `function system:onAddToWorld(world)` - Called when the System is added to the World, before any entities are added to the system.
  * `function system:onRemoveFromWorld(world)` - Called when the System is
removed from the world, after all Entities are removed from the System.
  * `function system:preUpdate(dt)` - Called on each system before `process` is called on any system
  * `function system:postUpdate(dt)` - Called on each system after `process` is called on each system
  
  The idea behind `preUpdate` and `postUpdate` is to allow for systems that modify the behavior of other systems. Say there is a DrawingSystem, which draws sprites to the screen, and a PostProcessingSystem, that adds some blur and bloom effects. In the `preUpdate` method of the PostProcessingSystem, the System could set the drawing target for the DrawingSystem to a special buffer instead the screen. In the `postUpdate` method, the PostProcessingSystem could then modify the buffer and render it to the screen. In this setup, the PostProcessingSystem would be added to the World after the DrawingSystem (a similar but less flexible behavior could be accomplished with a single custom update function in the DrawingSystem).

All Systems also have a few important fields that are initialized when the system is added to the World. A few are important, and few should be less commonly used.

  * The `world` field points to the World that the System belongs to. Useful for adding and removing Entities from the world dynamically via the System.
  * The `active` flag is whether or not the System is updated automatically. Defaults to true.
  * The `entities` field is an ordered list of Entities in the System. This list can be used to quickly iterate through all Entities in a System.
  * The `interval` field is an optional field that makes Systems update at certain intervals using buffered time, regardless of World update frequency. For example, to make a System update once a second, set the System's interval
to 1.
  * The `index` field is the System's index in the World. Lower indexed Systems are processed before higher indices. The `index` is a read only
field; to set the `index`, use `world:setSystemIndex(system)`.
  * The `indices` field is a table of Entity keys to their indices in the `entities` list. Most Systems can ignore this.
  * The `modified` flag is an indicator if the System has been modified in the last update

There is another option to (hopefully) increase performance in systems that have items added to or removed from them often, and have lots of entities in them.  Setting the `nocache` field of the system might improve performance. It is still experimental. There are some restriction to systems without caching, however:

  * There is no `entities` table.
  * Callbacks such onAdd and onRemove will never be called
  * Noncached systems cannot be sorted (There is no entities list to sort).


#### Creating Systems

`function ecs.newSystem(table)`
- Creates a new System or System class. Systems have a process method called each tick.

    * `function system:process(dt)` Process self.entities in your own loop
	* `function system:process(entity, dt)` when system.nocache is set, entities are processed individually

`function ecs.sortedSystem(table)`
- Creates a new Sorted System. Sorted Systems sort their Entities according to a user-defined method, `system:compare(e1, e2)`, which should return true if `e1` should come before `e2` and false otherwise.


### World

A World is a container that manages Entities and Systems. Typically, a program uses one World at a time.

For all World functions except `ecs.newWorld(...)`, object-oriented syntax is used. For example `world:addEntity(e)`

`function ecs.newWorld(...)`
- Creates a new World. Can optionally add default Systems. Returns the new World.

`function World:addEntity(entity)`
- Adds an Entity to the world. Also call this on Entities that have changed Components such that they match different Filters. Returns the Entity.

`function World:addSystem(system)`
- Adds a System to the world. Returns the System.

`function World:removeEntity(entity)`
- Removes an Entity from the World. Returns the Entity.

`function World:removeSystem(system)`
- Removes a System from the world. Returns the System.

`function World:update(dt, filter)`
- Updates the World by dt (delta time). Takes an optional parameter, `filter`, which is a Filter that selects Systems from the World, and updates only those Systems. If `filter` is not supplied, all Systems are updated. Put this function in your main loop.

`function World:clearEntities()`
- Removes all Entities from the World

`function World:clearSystems()`
- Removes all Systems from the World

`function World:setSystemIndex(system, index)`
- Sets the index of a System in the World, and returns the old index. Changes the order in which they Systems processed, because lower indexed Systems are processed first. Returns the old system.index.
