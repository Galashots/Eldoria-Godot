extends CanvasLayer

signal dialogue_closed

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var message_label: Label = $Panel/MessageLabel

func _ready() -> void:
    visible = false

func show_dialogue(speaker_name: String, line: String) -> void:
    speaker_label.text = speaker_name
    message_label.text = line
    visible = true

func close_dialogue() -> void:
    if not visible:
        return

    visible = false
    dialogue_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if not visible or not event is InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    var dismiss_keys := [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]
    if key_event.keycode in dismiss_keys or key_event.physical_keycode in dismiss_keys:
        close_dialogue()
        get_viewport().set_input_as_handled()
