extends Node

## Sound pass v1 (expansion backlog P0), extended by the "Region ambience pass" slice. A tiny,
## self-contained autoload that owns every AudioStreamPlayer in the game - no scene-file edits
## needed, since every player node is created in code here. Assets are self-synthesized WAVs
## under assets/audio/ (see assets/audio/gen_sfx.py for provenance/reproducibility - no
## third-party license concerns).
##
## Kid-audience volumes are deliberately soft/gentle per docs/design/NORTH_STAR.md: ambient
## loops quietly in the background, SFX are a touch louder but still soft, never harsh.
##
## Region ambience: the single global ambient loop is now region-aware. REGION_RECTS defines,
## in world pixel space, one rectangle per region matching tools/paint_map.gd's tile regions
## (16px tiles) - the one place region geometry lives. A cheap ~0.5s poll (_region_poll_timer)
## checks the player's position against those rects via the pure, unit-tested
## region_for_position() and cross-fades to that region's track using two ambient players
## (ping-ponged) so there's never a hard cut or silence gap.

const AMBIENT_VOLUME_DB := -18.0
const SFX_VOLUME_DB := -10.0
const SFX_POOL_SIZE := 4
const REGION_POLL_INTERVAL_SEC := 0.5
const CROSSFADE_DURATION_SEC := 1.75
const DEFAULT_REGION := "village_green"

const SFX_STREAMS := {
    "swing": preload("res://assets/audio/swing.wav"),
    "slime_boing": preload("res://assets/audio/slime_boing.wav"),
    "coin_chime": preload("res://assets/audio/coin_chime.wav"),
    "quest_fanfare": preload("res://assets/audio/quest_fanfare.wav"),
    "ui_click": preload("res://assets/audio/ui_click.wav"),
}

## One ambient loop per region. Falls back to the original meadow bed for anywhere not covered
## by a more specific rect (open field between regions), and is also the DEFAULT_REGION track.
const REGION_STREAMS := {
    "village_green": preload("res://assets/audio/village_hearth.wav"),
    "flower_meadow": preload("res://assets/audio/meadow_birds.wav"),
    "forest_edge": preload("res://assets/audio/forest_wind.wav"),
    "lake": preload("res://assets/audio/lake_water.wav"),
    "rocky_border": preload("res://assets/audio/ambient_meadow.wav"),
}

## Region rectangles in world pixel space (16px tiles), matching tools/paint_map.gd's regions
## exactly - the one place this geometry is defined for both painting and audio. Checked in
## this order (first match wins), so the more specific interior regions (lake, forest edge,
## village green, flower meadow) are listed before the map-spanning rocky border ring.
const REGION_RECTS := {
    "lake": Rect2(1344.0, 768.0, 416.0, 320.0),          # tiles (84,48)-(110,68)
    "forest_edge": Rect2(32.0, 96.0, 608.0, 2064.0),      # tiles (2,6)-(39,134)
    "village_green": Rect2(768.0, 512.0, 1424.0, 432.0),  # tiles (48,32)-(136,58)
    "flower_meadow": Rect2(880.0, 944.0, 1024.0, 544.0),  # tiles (55,59)-(118,92)
    "rocky_border": Rect2(0.0, 0.0, 3520.0, 2240.0),      # whole map (2-tile edge ring; used as
                                                           # the outermost fallback match)
}

var _ambient_players: Array[AudioStreamPlayer] = []
var _active_ambient_index := 0
var _current_region := ""
var _fade_elapsed := 0.0
var _fading := false
var _region_poll_timer: Timer

var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_index := 0
var _previous_coins := 0

func _ready() -> void:
    for i in 2:
        var player := AudioStreamPlayer.new()
        player.volume_db = -80.0
        player.bus = "Master"
        add_child(player)
        _ambient_players.append(player)

    _current_region = DEFAULT_REGION
    var starting_player: AudioStreamPlayer = _ambient_players[_active_ambient_index]
    starting_player.stream = REGION_STREAMS[DEFAULT_REGION]
    starting_player.volume_db = AMBIENT_VOLUME_DB
    starting_player.finished.connect(starting_player.play)
    starting_player.play()

    _region_poll_timer = Timer.new()
    _region_poll_timer.wait_time = REGION_POLL_INTERVAL_SEC
    _region_poll_timer.autostart = true
    _region_poll_timer.timeout.connect(_on_region_poll_timeout)
    add_child(_region_poll_timer)

    for i in SFX_POOL_SIZE:
        var player := AudioStreamPlayer.new()
        player.volume_db = SFX_VOLUME_DB
        player.bus = "Master"
        add_child(player)
        _sfx_pool.append(player)

    _previous_coins = GameState.coins
    GameState.coins_changed.connect(_on_coins_changed)
    GameState.quest_changed.connect(_on_quest_changed)

func _process(delta: float) -> void:
    if not _fading:
        return
    _fade_elapsed += delta
    var t := clampf(_fade_elapsed / CROSSFADE_DURATION_SEC, 0.0, 1.0)
    var outgoing_index := 1 - _active_ambient_index
    _ambient_players[_active_ambient_index].volume_db = crossfade_volume_db(t, AMBIENT_VOLUME_DB, true)
    _ambient_players[outgoing_index].volume_db = crossfade_volume_db(t, AMBIENT_VOLUME_DB, false)
    if t >= 1.0:
        _fading = false
        _ambient_players[outgoing_index].stop()

func _on_region_poll_timeout() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node2D
    if player == null:
        return
    var region := region_for_position(player.global_position, REGION_RECTS, DEFAULT_REGION)
    if region == _current_region:
        return
    _crossfade_to_region(region)

func _crossfade_to_region(region: String) -> void:
    _current_region = region
    var incoming_index := 1 - _active_ambient_index
    var incoming_player: AudioStreamPlayer = _ambient_players[incoming_index]
    var outgoing_player: AudioStreamPlayer = _ambient_players[_active_ambient_index]

    if outgoing_player.finished.is_connected(outgoing_player.play):
        outgoing_player.finished.disconnect(outgoing_player.play)

    incoming_player.stream = REGION_STREAMS.get(region, REGION_STREAMS[DEFAULT_REGION])
    incoming_player.volume_db = -80.0
    if not incoming_player.finished.is_connected(incoming_player.play):
        incoming_player.finished.connect(incoming_player.play)
    incoming_player.play()

    _active_ambient_index = incoming_index
    _fade_elapsed = 0.0
    _fading = true

## Plays a one-shot SFX by name, pulled from the small pooled AudioStreamPlayer set so
## overlapping sounds (e.g. two quick swings) don't cut each other off. Unknown names are a
## silent no-op with a warning, so a typo never crashes gameplay.
func play_sfx(sfx_name: String) -> void:
    if not SFX_STREAMS.has(sfx_name):
        push_warning("AudioManager.play_sfx: unknown sfx name '%s'" % sfx_name)
        return

    var player: AudioStreamPlayer = _sfx_pool[_next_sfx_index]
    _next_sfx_index = (_next_sfx_index + 1) % _sfx_pool.size()
    player.stream = SFX_STREAMS[sfx_name]
    player.play()

## Pure helper (unit-tested) for the "did coins increase" check - separated from the signal
## handler so it's testable without a live GameState/signal round trip.
static func coins_increased(previous_coins: int, new_coins: int) -> bool:
    return new_coins > previous_coins

## Pure, unit-tested rectangle lookup (region ambience pass): returns the name of the first
## region rect (in insertion order) whose Rect2 contains pos, or default_region if none match.
## Separated from _on_region_poll_timeout() so it's testable without a live scene tree/player.
static func region_for_position(pos: Vector2, region_rects: Dictionary, default_region: String) -> String:
    for region_name: String in region_rects.keys():
        var rect: Rect2 = region_rects[region_name]
        if rect.has_point(pos):
            return region_name
    return default_region

## Pure, unit-tested cross-fade easing: given progress t in [0, 1] and the ambient target
## volume in dB, returns the current dB for the incoming track (rising) or outgoing track
## (falling). Linear in dB (not linear in amplitude) is a deliberate, simple choice - it's a
## very short (~1.75s), soft-volume fade, so the perceptual difference from an equal-power
## curve is negligible at this scale. -80 dB stands in for "silent" without a hard cut.
static func crossfade_volume_db(t: float, target_volume_db: float, is_incoming: bool) -> float:
    var clamped_t := clampf(t, 0.0, 1.0)
    var progress := clamped_t if is_incoming else (1.0 - clamped_t)
    return lerpf(-80.0, target_volume_db, progress)

func _on_coins_changed(coins: int) -> void:
    if coins_increased(_previous_coins, coins):
        play_sfx("coin_chime")
    _previous_coins = coins

func _on_quest_changed(_quest_id: String, state: String) -> void:
    if state == GameState.QUEST_COMPLETED:
        play_sfx("quest_fanfare")
