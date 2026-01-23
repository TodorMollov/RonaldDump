$path = "g:\work\RonaldDump\microgames\mg01_ignore_the_expert\MicrogameIgnoreTheExpert.gd"
(Get-Content -Raw $path).Replace("`t", "  ") | Set-Content -NoNewline $path
