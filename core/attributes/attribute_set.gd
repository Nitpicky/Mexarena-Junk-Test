class_name AttributeSet
extends RefCounted
## The attributes held by one unit (or anything else), one per id.
##
## Adding an attribute copies the template, or merges it into the one already
## there. Once bound to an EventBus, the behaviors of every attribute hear
## match events, and durations count down on DURATION_TICK_EVENT.

signal attribute_added(attribute: Attribute)
signal attribute_removed(attribute: Attribute)
## Any value, current amount or attribute list change.
signal changed

## Durations count down when this event targets the holder.
const DURATION_TICK_EVENT := &"turn_ended"

## Whoever holds the set (usually a Unit). Behaviors receive it.
var holder: Object
## Whatever owns the bus (usually the match). Behaviors receive it.
var context: Object

var _bus: EventBus
var _attributes: Dictionary = {} # StringName -> Attribute (insertion ordered)
var _subscriptions: Dictionary = {} # StringName -> Array of [type, Callable]


func _init(p_holder: Object = null) -> void:
	holder = p_holder


## Connects behaviors and durations to a bus. Call unbind() when done.
func bind(bus: EventBus, p_context: Object) -> void:
	unbind()
	_bus = bus
	context = p_context
	if _bus == null:
		return
	_bus.subscribe(DURATION_TICK_EVENT, _on_duration_tick, -100)
	for attribute: Attribute in _attributes.values():
		_subscribe(attribute)


func unbind() -> void:
	if _bus:
		for id: StringName in _subscriptions.keys():
			_unsubscribe(id)
		_bus.unsubscribe(DURATION_TICK_EVENT, _on_duration_tick)
	_bus = null


## Adds a copy of `template`, or merges it into the attribute with the same id.
## Returns the attribute now on the holder.
func add(template: Attribute) -> Attribute:
	if template == null or template.id == &"":
		push_warning("AttributeSet: attribute without id ignored")
		return null
	var incoming := template.duplicate(true) as Attribute
	var existing: Attribute = _attributes.get(incoming.id)
	if existing:
		existing.merge_from(incoming)
		_clamp_pools()
		changed.emit()
		_emit(GameEvents.ATTRIBUTE_MERGED, existing)
		return existing
	_attributes[incoming.id] = incoming
	if incoming.is_pool and incoming.current < 0.0:
		incoming.current = value(incoming.id)
	_subscribe(incoming)
	for behavior: AttributeBehavior in incoming.behaviors:
		if behavior:
			behavior.on_added(incoming, holder, context)
	_clamp_pools()
	attribute_added.emit(incoming)
	changed.emit()
	_emit(GameEvents.ATTRIBUTE_ADDED, incoming)
	return incoming


func remove(id: StringName) -> void:
	var attribute: Attribute = _attributes.get(id)
	if attribute == null:
		return
	_unsubscribe(id)
	_attributes.erase(id)
	for behavior: AttributeBehavior in attribute.behaviors:
		if behavior:
			behavior.on_removed(attribute, holder, context)
	_clamp_pools()
	attribute_removed.emit(attribute)
	changed.emit()
	_emit(GameEvents.ATTRIBUTE_REMOVED, attribute)


func has(id: StringName) -> bool:
	return _attributes.has(id)


func get_attribute(id: StringName) -> Attribute:
	return _attributes.get(id)


func all() -> Array[Attribute]:
	var result: Array[Attribute] = []
	for attribute: Attribute in _attributes.values():
		result.append(attribute)
	return result


## Effective value: base_value with every modifier from the other attributes.
## Returns `default` when the holder lacks this attribute.
func value(id: StringName, default: float = 0.0) -> float:
	var attribute: Attribute = _attributes.get(id)
	if attribute == null:
		return default
	return ModifierStack.compute(attribute.base_value, modifiers_for(id))


## For pools: the current amount. For anything else: the effective value.
func current(id: StringName, default: float = 0.0) -> float:
	var attribute: Attribute = _attributes.get(id)
	if attribute == null:
		return default
	return attribute.current if attribute.is_pool else value(id)


## Changes a pool's current amount, clamped to [0, value]. Returns the real change.
func add_current(id: StringName, delta: float) -> float:
	var attribute: Attribute = _attributes.get(id)
	if attribute == null or not attribute.is_pool:
		return 0.0
	var before := attribute.current
	attribute.current = clampf(before + delta, 0.0, value(id))
	if not is_equal_approx(before, attribute.current):
		changed.emit()
	return attribute.current - before


func set_base(id: StringName, new_value: float) -> void:
	var attribute: Attribute = _attributes.get(id)
	if attribute == null:
		return
	attribute.base_value = new_value
	_clamp_pools()
	changed.emit()


## Every modifier, from any other attribute, that targets `id`.
func modifiers_for(id: StringName) -> Array[AttributeModifier]:
	var result: Array[AttributeModifier] = []
	for attribute: Attribute in _attributes.values():
		if attribute.id == id:
			continue
		for modifier: AttributeModifier in attribute.modifiers:
			if modifier and modifier.target_id == id:
				result.append(modifier)
	return result


func _clamp_pools() -> void:
	for attribute: Attribute in _attributes.values():
		if attribute.is_pool:
			attribute.current = clampf(attribute.current, 0.0, value(attribute.id))


func _subscribe(attribute: Attribute) -> void:
	if _bus == null:
		return
	var subscriptions: Array = []
	for behavior: AttributeBehavior in attribute.behaviors:
		if behavior == null:
			continue
		for type: StringName in behavior.listens_to():
			var callable := _dispatch.bind(behavior, attribute)
			_bus.subscribe(type, callable, behavior.priority)
			subscriptions.append([type, callable])
	_subscriptions[attribute.id] = subscriptions


func _unsubscribe(id: StringName) -> void:
	if _bus:
		for pair: Array in _subscriptions.get(id, []):
			_bus.unsubscribe(pair[0], pair[1])
	_subscriptions.erase(id)


func _dispatch(event: GameEvent, behavior: AttributeBehavior, attribute: Attribute) -> void:
	if _attributes.get(attribute.id) != attribute:
		return
	if behavior.applies(event, holder):
		behavior.handle(event, attribute, holder, context)


func _on_duration_tick(event: GameEvent) -> void:
	if event.target != holder:
		return
	var expired: Array[StringName] = []
	for attribute: Attribute in _attributes.values():
		if attribute.duration > 0:
			attribute.duration -= 1
			if attribute.duration == 0:
				expired.append(attribute.id)
	for id: StringName in expired:
		remove(id)
	changed.emit()


func _emit(type: StringName, attribute: Attribute) -> void:
	if _bus:
		_bus.emit_new(type, null, holder, {"attribute": attribute})
