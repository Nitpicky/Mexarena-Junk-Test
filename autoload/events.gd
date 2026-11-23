extends Node
## Global signal bus (autoload: Events).
##
## Only declare signals here. No state, no logic.
## Use it when two scenes that do not know about each other need to talk.
## If one node owns the other, connect a direct signal instead.

## Emitted by SceneRouter right before it switches to a sandbox scene.
@warning_ignore("unused_signal")
signal sandbox_opened(sandbox_name: String)
