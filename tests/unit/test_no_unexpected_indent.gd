# Intelligent test: No unexpected indentation in class body
# This test scans all .gd files for lines that start with an unexpected indent at the class level.
# It will fail if it finds any such lines, helping prevent future indentation errors.

extends "res://addons/gut/test.gd"


# Improved: Only flag unexpected indents at true class-level (not inside func/if/for/while)
func test_no_unexpected_indent_in_class_body():
	var root = ProjectSettings.globalize_path("res://")
	var files = _find_gd_files(root)
	var indent_pattern = r"^\s+[^\s]"
	var class_level_pattern = r"^class_name|^extends|^var |^const |^func |^enum |^@onready |^signal |^export |^tool |^static |^@"
	for file_path in files:
		var lines = FileAccess.open(file_path, FileAccess.READ).get_as_text().split("\n")
		var in_func = false
		for i in range(lines.size()):
			var line = lines[i]
			if line.strip().begins_with("func "):
				in_func = true
			elif line.strip() == "":
				continue
			elif not line.begins_with(" ") and not line.begins_with("\t"):
				in_func = false

			# Only flag unexpected indents at class-level, not inside functions
			if not in_func and line.match(indent_pattern) and not line.match(class_level_pattern):
				fail_test("Unexpected indent in class body at %s:%d: %s" % [file_path, i+1, line.strip()])

func _find_gd_files(dir_path):
	var files = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				files.append(dir_path + "/" + file_name)
			elif dir.current_is_dir():
				files += _find_gd_files(dir_path + "/" + file_name)
			file_name = dir.get_next()
	return files
