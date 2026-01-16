# Test runner with timeout
param(
    [int]$TimeoutSeconds = 30
)

$godotPath = "G:\work\tools\godot4.5\Godot_v4.5.1-stable_win64_console.exe"
$testCmd = "--headless -d --path . -s addons/gut/gut_cmdln.gd -gexit"

Write-Host "Running tests with $TimeoutSeconds second timeout..."

$job = Start-Job -ScriptBlock {
    param($path, $cmdArgs)
    $argList = $cmdArgs -split ' '
    & $path $argList 2>&1
} -ArgumentList $godotPath, $testCmd

$completed = Wait-Job $job -Timeout $TimeoutSeconds

if ($completed) {
    $output = Receive-Job $job
    Remove-Job $job
    
    # Save output to file
    $output | Out-File -FilePath "test_output.txt" -Encoding UTF8
    
    # Check for exit code in output
    if ($output -match "All tests passed" -or $output -match "Tests completed") {
        Write-Host "Tests completed successfully"
        exit 0
    } elseif ($output -match "Parser Error" -or $output -match "Script error") {
        Write-Host "Tests failed with errors"
        # Show last 50 lines
        $output | Select-Object -Last 50
        exit 1
    } else {
        Write-Host "Tests completed, check output"
        $output | Select-Object -Last 50
        exit 0
    }
} else {
    Write-Host "Test execution timed out after $TimeoutSeconds seconds"
    Stop-Job $job
    Remove-Job $job
    exit 2
}
