#!/usr/bin/env pwsh
# Pre-refactoring test validation script
# Run this before and after major refactoring to ensure game still works
# Usage: .\validate_game_state.ps1

param(
    [switch]$Quick = $false
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "GAME STATE VALIDATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Define the test to run
$testScene = "res://tests/unit/microgames/test_mg04_normal_choice.tscn"
$godotPath = "godot"  # Assumes godot is in PATH

# Find Godot executable
$godotExecutable = Get-Command -Name "godot.exe" -ErrorAction SilentlyContinue
if (-not $godotExecutable) {
    $godotExecutable = Get-Command -Name "godot" -ErrorAction SilentlyContinue
}

if (-not $godotExecutable) {
    Write-Host "❌ ERROR: Godot executable not found in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Using Godot: $($godotExecutable.Source)" -ForegroundColor Green

# Run the test
Write-Host "`n→ Running game state validation test..." -ForegroundColor Yellow
Write-Host "  Scene: $testScene`n" -ForegroundColor Yellow

$process = & $godotExecutable.Source --headless --script "$testScene" 2>&1
Write-Host $process

# Check for success markers
if ($process -match "Passed: [1-9]" -and $process -match "============================================================") {
    Write-Host "`n✅ VALIDATION PASSED - Game is in valid state" -ForegroundColor Green
    Write-Host "Safe to commit refactoring changes.`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ VALIDATION FAILED - Game issues detected" -ForegroundColor Red
    Write-Host "Do not commit until issues are resolved.`n" -ForegroundColor Red
    exit 1
}
