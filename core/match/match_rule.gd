class_name MatchRule
extends Resource
## Base for an optional rule module. A rule hooks itself on the match's event
## bus in setup(). Remove a rule from MatchConfig.rules and it is gone.


## Override: subscribe to the events the rule needs.
func setup(_game: TacticsMatch) -> void:
	pass
