@tool
extends EditorPlugin
## EditorPlugin to auto-generate Ignore The Expert placeholder assets on project open

func _enter_tree():
	# Generate assets when plugin loads in editor
	if IgnoreExpertAssetBootstrap:
		print("[IgnoreExpertAssets Plugin] Ensuring placeholder assets exist...")
		IgnoreExpertAssetBootstrap.ensure_assets()
		print("[IgnoreExpertAssets Plugin] Asset check complete.")
	else:
		push_warning("[IgnoreExpertAssets Plugin] IgnoreExpertAssetBootstrap class not found")


func _exit_tree():
	pass
