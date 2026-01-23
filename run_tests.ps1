# Clean Godot GUT test runner for Windows PowerShell
param(
    [int]$TimeoutSeconds = 30
)

$godotPath = "G:\work\tools\godot4.5\Godot_v4.5.1-stable_win64_console.exe"
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Clean previous logs
Remove-Item "test_output.txt","test_error.txt" -Force -ErrorAction SilentlyContinue

function Write-Stamp([string]$Message, [string]$Color = "White") {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $Message"
    Write-Host $line -ForegroundColor $Color
}

Write-Stamp "Running tests headless with $TimeoutSeconds second feedback timeout..." "Cyan"

$process = Start-Process -FilePath $godotPath `
    -ArgumentList "--headless", "-d", "--path", $projectPath, "-s", "addons/gut/gut_cmdln.gd", "-gexit", "-glog", "res://gut_log.txt" `
    -RedirectStandardOutput "test_output.txt" `
    -RedirectStandardError "test_error.txt" `
    -PassThru `
    -NoNewWindow

$exited = $process.WaitForExit($TimeoutSeconds * 1000)

if ($exited) {
    Write-Stamp "✓ Tests completed" "Green"
} else {
    Write-Stamp "⚠ Tests still running after $TimeoutSeconds seconds — showing partial output" "Yellow"
    if (Test-Path "test_output.txt") {
        $partial = Get-Content "test_output.txt" -ErrorAction SilentlyContinue
        if ($partial) {
            Write-Stamp "=== PARTIAL OUTPUT (last 80 lines) ===" "Cyan"
            $partial | Select-Object -Last 80
        } else {
            Write-Stamp "(No output yet)" "DarkYellow"
        }
    }
    $process.WaitForExit()
    Write-Stamp "✓ Tests completed after extended run" "Green"
}

# Final output
Write-Stamp "=== FINAL OUTPUT (last 120 lines) ===" "Cyan"
if (Test-Path "gut_log.txt") {
    $log = Get-Content "gut_log.txt" -ErrorAction SilentlyContinue
    if ($log) {
        $log | Select-Object -Last 120
    }
} elseif (Test-Path "test_output.txt") {
    $out = Get-Content "test_output.txt" -ErrorAction SilentlyContinue
    if ($out) {
        $out | Select-Object -Last 120
    }
}

if (Test-Path "test_error.txt") {
    $errors = Get-Content "test_error.txt" -ErrorAction SilentlyContinue
    if ($errors) {
        Write-Stamp "=== ERRORS (last 40 lines) ===" "Red"
        $errors | Select-Object -Last 40
    }
}

Write-Stamp "Logs saved: gut_log.txt (if generated), test_output.txt, test_error.txt" "Cyan"
# Test runner with 30-second timeout - provides feedback even if tests run longer
# If VS Code/Godot still hangs:
# 1) Check lingering Godot: Get-Process Godot* ; Stop-Process -Name "Godot*" -Force
# 2) Direct command: & "G:\work\tools\godot4.5\Godot_v4.5.1-stable_win64_console.exe" --headless --path "G:\work\RonaldDump" -s addons/gut/gut_cmdln.gd -gexit

param(
    [int]$TimeoutSeconds = 30
)

$godotPath = "G:\work\tools\godot4.5\Godot_v4.5.1-stable_win64_console.exe"
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Clean previous logs
Remove-Item "test_output.txt","test_error.txt" -Force -ErrorAction SilentlyContinue

${script:statusFile} = "test_status.txt"
Remove-Item $script:statusFile -Force -ErrorAction SilentlyContinue

function Write-Stamp([string]$Message, [string]$Color = "White") {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $script:statusFile -Value $line -ErrorAction SilentlyContinue
}

Write-Stamp "Running tests headless with $TimeoutSeconds second feedback timeout..." "Cyan"

$process = Start-Process -FilePath $godotPath `
    -ArgumentList "--headless", "-d", "--path", $projectPath, "-s", "addons/gut/gut_cmdln.gd", "-gexit", "-glog", "res://gut_log.txt" `
    -RedirectStandardOutput "test_output.txt" `
    -RedirectStandardError "test_error.txt" `
    -PassThru `
    -NoNewWindow

$exited = $process.WaitForExit($TimeoutSeconds * 1000)

if ($exited) {
    Write-Stamp "✓ Tests completed" "Green"
} else {
    Write-Stamp "⚠ Tests still running after $TimeoutSeconds seconds — showing partial output" "Yellow"
    if (Test-Path "test_output.txt") {
        $partial = Get-Content "test_output.txt" -ErrorAction SilentlyContinue
        if ($partial) {
            Write-Stamp "=== PARTIAL OUTPUT (last 80 lines) ===" "Cyan"
            $partial | Select-Object -Last 80
        } else {
            Write-Stamp "(No output yet)" "DarkYellow"
        }
    }
    # Wait for completion

    $process.WaitForExit()
    Write-Stamp "✓ Tests completed after extended run" "Green"
}


# Final output
Write-Stamp "=== FINAL OUTPUT (last 120 lines) ===" "Cyan"
if (Test-Path "gut_log.txt") {
    $log = Get-Content "gut_log.txt" -ErrorAction SilentlyContinue
    if ($log) {
        $log | Select-Object -Last 120
    }
} else {
    $out = Get-Content "test_output.txt" -ErrorAction SilentlyContinue
    if ($out) {
        $out | Select-Object -Last 120
    }
}



