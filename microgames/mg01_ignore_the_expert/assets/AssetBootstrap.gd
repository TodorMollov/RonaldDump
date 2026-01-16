extends Node
class_name IgnoreExpertAssetBootstrap
## Auto-generates placeholder assets for Ignore The Expert microgame
## Can be called from editor plugin or at runtime

# Base64 encoded placeholder assets (minimal size for repo commit)

# Simple 64x64 PNG images (solid colors with basic shapes)
const RONALD_PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAE5SURBVHic7dKxSgNBFIXhs2sRrGwsrK0srK0srK0srK2tra2tra2tra2tra2tra2tra2trc3k+QELm8VisViKxT8fXJiZO/fMvbM3ERERERERERERERERUX/N1/l7gEngGtgB5oEJ4BxYBtaBa+AGeATugXvgHngEnoFX4A14B76AT+AH+AV+gT/gH/gHAZHRqTEDzANnwBFwCJwAR8ARcAQcAUfAMXAMHAPHwAlwApwCp8ApcAacAWfAOXAOnAMXwAVwCVwCV8AVcA3cADfALXAL3AH3wAPwCDwBz8AL8Aq8AW/AO/ABfAKfwBfwDXwDP8Av8Av8AgAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIqJ/Zvr/fwP4AF6AF+AVeAPegXfgA/gEPoFv4Af4BX6BfxAREREREREREREREf3HHxKaP4C7yE9dAAAAAElFTkSuQmCC"

const EXPERT_PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAE5SURBVHic7dOxTgJBFIXh/9YSEhsaGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbG5v8+yckJCwsLCwsLCx8+eAyzMydO+fOvXNnRERERERERERERERERET0v0xX+XsCmAPOgW1gHpgEzoBlYA24Bq6BW+AOuAfugQfgEXgCnoEX4BV4A96BD+AT+AK+gW/gB/gF/oB/EBAZnRpzwDxwARwDB8A+sAfsAXvAHnAA7AP7wD6wDxwC+8AhcAgcAUfAMXAMHAMnwAlwCpwCp8AZcAacA+fABXABXAKXwBVwBVwDN8ANcAvcArfAHXAHPACPwBPwDLwAr8Ab8A68Ax/AJ/AFfAM/wC/wB/yDgIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiP6b6f//DeADeAZegFfgDXgH3oEP4Av4Ar6BH+AX+AUBEREREREREREREdF//AG9bD+AuDDRGQAAAABJRU5ErkJggg=="

const SPEECH_PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAIpSURBVHic7ZyxTsQwEETXFPwBfAD//wX0FBQ0SBQ0FBQ0FBQ0NBQ0FBT0FBQUFBQ0FBQUNBQUFHReEp0UJ3vjZGfKkbL2rt8+r+04EREREREREREREREREdE/M1vnbwEmgGvgFpgGpoArYBZYAJaBVWANWAc2gE1gC9gGdoBdYA/YBw6AQ+AIOAaOgVPgDDgHLoAr4Bq4Ae6Ae+AB+AD+gF8QEBmdGlPANHABnABHwCFwABwC+8A+sA/sAwfAHrAH7AF7wD6wD+wDh8AhcAQcAcfACXAKnAFnwDlwAVwC18ANcAvcAXfAA/AIfAKfwBfwDXwDP8Av8Av8gYCIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiP6Z6f//G8An8AV8A9/AD/AL/AJ/ICAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiol6Y7vO3gE/gC/gGfoAf4Bf4A/5BQERERERERERERERERERERERERERERERERERERETUDzN9/v4H8Al8Ad/AD/AL/AH/ICAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiLqh5k+f/8T+AK+gW/gB/gFfoF/EBARERERERERERERERERERERERERERERERERERFRPyx0/H0f+AS+gG/gB/gFfoF/EBERERERERERERERERERERERERERERERERERER3R//AFdUM/gLiO2xYAAAAASUVORK5CYII="

# Minimal WAV files (8-bit mono 8000Hz very short clips)
# These are silent/minimal tone WAVs to keep size tiny

const SFX_TALK_WAV_BASE64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAIlYAAESsAAABAAgAZGF0YQIAAACA"

const SFX_CUTOFF_WAV_BASE64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAIlYAAESsAAABAAgAZGF0YQIAAACA"

const SFX_SUCCESS_WAV_BASE64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAIlYAAESsAAABAAgAZGF0YQIAAACA"

const SFX_FAIL_WAV_BASE64 = "UklGRiYAAABXQVZFZm10IBAAAAABAAEAIlYAAESsAAABAAgAZGF0YQIAAACA"


static func ensure_assets() -> void:
	"""Generate placeholder assets if they don't exist. Idempotent and safe."""
	var base_path = "res://microgames/mg01_ignore_the_expert/assets/"
	var physical_path = ProjectSettings.globalize_path(base_path)
	
	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute(physical_path)
	
	var assets = {
		"ronald.png": RONALD_PNG_BASE64,
		"expert.png": EXPERT_PNG_BASE64,
		"speech.png": SPEECH_PNG_BASE64,
		"sfx_talk.wav": SFX_TALK_WAV_BASE64,
		"sfx_cutoff.wav": SFX_CUTOFF_WAV_BASE64,
		"sfx_success.wav": SFX_SUCCESS_WAV_BASE64,
		"sfx_fail.wav": SFX_FAIL_WAV_BASE64
	}
	
	for filename in assets.keys():
		var full_path = base_path + filename
		
		# Check if file already exists
		if FileAccess.file_exists(full_path):
			continue
		
		# Decode base64 and write file
		var base64_data = assets[filename]
		var decoded = Marshalls.base64_to_raw(base64_data)
		
		if decoded.size() == 0:
			push_warning("[IgnoreExpertAssetBootstrap] Failed to decode: " + filename)
			continue
		
		var file = FileAccess.open(full_path, FileAccess.WRITE)
		if file:
			file.store_buffer(decoded)
			file.close()
			print("[IgnoreExpertAssetBootstrap] Generated: " + filename)
		else:
			push_warning("[IgnoreExpertAssetBootstrap] Failed to write: " + filename)


static func has_all_assets() -> bool:
	"""Check if all required assets exist"""
	var base_path = "res://microgames/mg01_ignore_the_expert/assets/"
	var required_files = [
		"ronald.png",
		"expert.png",
		"speech.png",
		"sfx_talk.wav",
		"sfx_cutoff.wav",
		"sfx_success.wav",
		"sfx_fail.wav"
	]
	
	for filename in required_files:
		if not FileAccess.file_exists(base_path + filename):
			return false
	
	return true
