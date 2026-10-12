# Void-Music-Player
Tried making a music player with the Godot game engine

# Building
Building this will require ideally Godot 4.7-stable or later to run. After 
cloning the repo a run of 'scons' in the MusicPlayerGDextension/ of the repo
will build the gd extension and it should run out of the box in the godot editor.
You might need to initialise the submodules with 'git submodule update --init --recursive'

##NOTE:
	Currently only the builds of TagLib for linux have been added so it will not work on
	windows or mac
