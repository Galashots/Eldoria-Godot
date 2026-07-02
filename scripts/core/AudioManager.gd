extends Node

## Sound pass v1 (expansion backlog P0). A tiny, self-contained autoload that owns every
## AudioStreamPlayer in the game - no scene-file edits needed, since every player node is
## created in code here. Assets are self-synthesized WAVs under assets/audio/ (see
## assets/audio/gen_sfx.py for provenance/reproducibility - no third-party license concerns).
##
## Kid-audience volumes are deliberately soft/gentle per docs/design/NORTH_STAR.md: ambient
## loops quietly in the background, SFX are a touch louder but still soft, never harsh.

const AMBIENT_VOLUME_DB := -18.0
const SFX_VOLUME_DB := -10.0
const SFX_POOL_SIZE := 4

const SFX_STREAMS := {
    "swing": preload("res://assets/audio/swing.wav"),
    "slime_boing": preload("res://assets/audio/slime_boing.wav"),
    "coin_chime": preload("res://assets/audio/coin_chime.wav"),
    "quest_fanfare": preload("res://assets/audio/quest_fanfare.wav"),
    "ui_click": preload("res://assets/audio/ui_click.wav"),
}

const AMBIENT_STREAM := preload("res://assets/audio/ambient_meadow.wav")

var _ambient_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_index := 0
var _previous_coins := 0

func _ready() -> void:
    _ambient_player = AudioStreamPlayer.new()
    _ambient_player.stream = AMBIENT_STREAM
    _ambient_player.volume_db = AMBIENT_VOLUME_DB
    _ambient_player.bus = "Master"
    add_child(_ambient_player)
    # AudioStreamWAV doesn't loop by default here, so replay on finished rather than relying
    # on import-time loop flags - simplest reliable route.
    _ambient_player.finished.connect(_ambient_player.play)
    _ambient_player.play()

    for i in SFX_POOL_SIZE:
        var player := AudioStreamPlayer.new()
        player.volume_db = SFX_VOLUME_DB
        player.bus = "Master"
        add_child(player)
        _sfx_pool.append(player)

    _previous_coins = GameState.coins
    GameState.coins_changed.connect(_on_coins_changed)
    GameState.quest_changed.connect(_on_quest_changed)

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

func _on_coins_changed(coins: int) -> void:
    if coins_increased(_previous_coins, coins):
        play_sfx("coin_chime")
    _previous_coins = coins

func _on_quest_changed(_quest_id: String, state: String) -> void:
    if state == GameState.QUEST_COMPLETED:
        play_sfx("quest_fanfare")
