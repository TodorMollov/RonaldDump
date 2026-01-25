extends Node
class_name IgnoreExpertAssetBootstrap
## Auto-generates placeholder assets for Ignore The Expert microgame

const RONALD_PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAE5SURBVHic7dKxSgNBFIXhs2sRrGwsrK0srK0srK0srK2tra2tra2tra2tra2tra2tra2trc3k+QELm8VisViKxT8fXJiZO/fMvbM3ERERERERERERERERUX/N1/l7gEngGtgB5oEJ4BxYBtaBa+AGeATugXvgHngEnoFX4A14B76AT+AH+AV+gT/gH/gHAZHRqTEDzANnwBFwCJwAR8ARcAQcAUfAMXAMHAPHwAlwApwCp8ApcAacAWfAOXAOnAMXwAVwCVwCV8AVcA3cADfALXAL3AH3wAPwCDwBz8AL8Aq8AW/AO/ABfAKfwBfwDXwDP8Av8Av8AgAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIqJ/Zvr/fwP4AF6AF+AVeAPegXfgA/gEPoFv4Af4BX6BfxAREREREREREREREf3HHxKaP4C7yE9dAAAAAElFTkSuQmCC"
const EXPERT_PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAE5SURBVHic7dOxTgJBFIXh/9YSEhsaGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbG5v8+yckJCwsLCwsLCx8+eAyzMydO+fOvXNnRERERERERERERERERET0v0xX+XsCmAPOgW1gHpgEzoBlYA24Bq6BW+AOuAfugQfgEXgCnoEX4BV4A96BD+AT+AK+gW/gB/gF/oB/EBAZnRpzwDxwARwDB8A+sAfsAXvAHnAA7AP7wD6wDxwC+8AhcAgcAUfAMXAMHAMnwAlwCpwCp8AZcAacA+fABXABXAKXwBVwBVwDN8ANcAvcArfAHXAHPACPwBPwDLwAr8Ab8A68Ax/AJ/AFfAM/wC/wB/yDgIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiP6b6f//DeADeAZegFfgDXgH3oEP4Av4Ar6BH+AX+AUBEREREREREREREdF//AG9bD+AuDDRGQAAAABJRU5ErkJggg=="
const SPEECH_PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAIpSURBVHic7ZyxTsQwEETXFPwBfAD//wX0FBQ0SBQ0FBQ0FBQ0NBQ0FBT0FBQUFBQ0FBQUNBQUFHReEp0UJ3vjZGfKkbL2rt8+r+04EREREREREREREREREdE/M1vnbwEmgGvgFpgGpoArYBZYAJaBVWANWAc2gE1gC9gGdoBdYA/YBw6AQ+AIOAaOgVPgDDgHLoAr4Bq4Ae6Ae+AB+AD+gF8QEBmdGlPANHABnABHwCFwABwC+8A+sA/sAwfAHrAH7AF7wD6wD+wDh8AhcAQcAcfACXAKnAFnwDlwAVwC18ANcAvcAXfAA/AIfAKfwBfwDXwDP8Av8Av8gYCIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiP6Z6f//G8An8AV8A9/AD/AL/AJ/ICAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiol6Y7vO3gE/gC/gGfoAf4Bf4A/5BQERERERERERERERERERERERERERERERERERERETUDzN9/v4H8Al8Ad/AD/AL/AH/ICAiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiLqh5k+f/8T+AK+gW/gB/gFfoF/EBARERERERERERERERERERERERERERERERERERFRPyx0/H0f+AS+gG/gB/gFfoF/EBERERERERERERERERERERERERERERERERERER3R//AFdUM/gLiO2xYAAAAASUVORK5CYII="

static func ensure_assets() -> void:
	var base_path = "res://microgames/mg01_ignore_the_expert/assets/"
	var fs_path = ProjectSettings.globalize_path(base_path)
	DirAccess.make_dir_recursive_absolute(fs_path)
	var assets = {
		"ronald.png": RONALD_PNG_BASE64,
		"expert.png": EXPERT_PNG_BASE64,
		"speech.png": SPEECH_PNG_BASE64
	}
	for filename in assets.keys():
		var full_path = base_path + filename
		if FileAccess.file_exists(full_path):
			continue
		var raw = Marshalls.base64_to_raw(assets[filename])
		if raw.is_empty():
			push_warning("[IgnoreExpertAssets] Failed decoding %s" % filename)
			continue
		var file = FileAccess.open(full_path, FileAccess.WRITE)
		if file:
			file.store_buffer(raw)
			file.close()
		else:
			push_warning("[IgnoreExpertAssets] Unable to write %s" % filename)
