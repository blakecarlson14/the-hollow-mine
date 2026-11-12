extends SceneTree
## Entry point for procedural asset generation. Run from the project folder:
##   godot --headless --path . --script res://tools/gen_art.gd
## then `godot --headless --path . --import` so Godot imports the new files.


func _init() -> void:
	print("Generating tiles...")
	preload("res://tools/gen_tiles.gd").generate()
	print("Generating sprites...")
	preload("res://tools/gen_sprites.gd").generate()
	print("Generating backgrounds...")
	preload("res://tools/gen_backgrounds.gd").generate()
	print("Generating font, lights, particles...")
	preload("res://tools/gen_misc.gd").generate()
	print("Generating boot splash...")
	preload("res://tools/gen_splash.gd").generate()
	print("Generating audio...")
	preload("res://tools/gen_audio.gd").generate()
	print("Done.")
	quit()
