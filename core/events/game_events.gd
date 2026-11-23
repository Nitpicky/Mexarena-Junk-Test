class_name GameEvents
extends RefCounted
## Names of the common event types. Constants only.
## Any module may use its own names too; listing them here just avoids typos.
## Convention: the unit an event is about is the event's `target`.

const MATCH_STARTED := &"match_started"
const MATCH_ENDED := &"match_ended" ## data: winning_team (-1 = draw)
const PLAYER_TURN_STARTED := &"player_turn_started" ## data: player
const PLAYER_TURN_ENDED := &"player_turn_ended" ## data: player
const TURN_STARTED := &"turn_started" ## target: unit
const TURN_ENDED := &"turn_ended" ## target: unit
const CARD_DRAWN := &"card_drawn" ## data: player, card
const CARD_PLAYED := &"card_played" ## target: summoned unit; data: player, card
const UNIT_SUMMONED := &"unit_summoned" ## target: unit; data: player, card
const UNIT_MOVED := &"unit_moved" ## target: unit; data: from, to
const ATTACKED := &"attacked" ## source: attacker; target: defender
const BEFORE_DAMAGE := &"before_damage" ## data: amount (editable), tags
const DAMAGED := &"damaged" ## data: amount, tags
const HEALED := &"healed" ## data: amount, tags
const UNIT_DIED := &"unit_died" ## source: killer or null; target: unit
const ATTRIBUTE_ADDED := &"attribute_added" ## target: holder; data: attribute
const ATTRIBUTE_MERGED := &"attribute_merged" ## target: holder; data: attribute
const ATTRIBUTE_REMOVED := &"attribute_removed" ## target: holder; data: attribute
const TEAM_ELIMINATED := &"team_eliminated" ## data: team
