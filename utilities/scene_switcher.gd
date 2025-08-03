extends Node2D

enum Scenes {
    # Debug scenes
    TEST_SCENE,
    TEMPLATE_SCENE,
    # Game scenes
    # Chapter 1
}

var current_scene := Scenes.TEST_SCENE

# TESTING SCENE LOADER
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("1"):
        load_scene(Scenes.TEST_SCENE)


func load_scene(scene: Scenes):
    match scene:
        Scenes.TEST_SCENE:
            get_tree().change_scene_to_file("res://all_scenes/test_scenes/scenes/test_scene.tscn")

    current_scene = scene