function Start-ApiTrace {
    param (
        [string]$SessionName = "ApiTraceSession",
        [string]$LogLevel = "0x10"
    )

    if (-not $SessionName) {
        Write-Host "Session name cannot be empty." -ForegroundColor Red
        return
    }

    if ($LogLevel -notmatch "^0x[0-9A-Fa-f]+$") {
        Write-Host "Invalid log level. It must be a hexadecimal value." -ForegroundColor Red
        return
    }

    try {
        Write-Host "Starting API call tracing with session name '$SessionName'..." -ForegroundColor Cyan
        $command = "logman start $SessionName -p Microsoft-Windows-Kernel-Process $LogLevel -ets"
        Invoke-Expression $command
        Write-Host "Tracing started successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error starting ETW tracing: $_" -ForegroundColor Red
    }
}

function Stop-ApiTrace {
    param (
        [string]$SessionName = "ApiTraceSession"
    )

    if (-not $SessionName) {
        Write-Host "Session name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        Write-Host "Stopping API call tracing with session name '$SessionName'..." -ForegroundColor Cyan
        $command = "logman stop $SessionName -ets"
        Invoke-Expression $command

        $logFilePath = "C:\\Windows\\System32\\winevt\\Logs\\$SessionName.evtx"
        if (Test-Path $logFilePath) {
            Write-Host "API call logs found at: $logFilePath" -ForegroundColor Green
            Get-WinEvent -Path $logFilePath | Select-Object -First 10 | Format-Table TimeCreated, Message
        } else {
            Write-Host "No logs found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error stopping tracing or accessing logs: $_" -ForegroundColor Red
    }
}

function Show-CLIGUI {
    try {

        $menuOptions = @(
            "Start API Call Tracing",
            "Stop Tracing and Display Results",
            "Exit"
        )

        $selection = $menuOptions | Out-GridView -Title "API Tracing Tool" -PassThru

        switch ($selection) {
            "Start API Call Tracing" {
                $sessionName = Read-Host "Enter session name (default: ApiTraceSession)"
                $logLevel = Read-Host "Enter log level (default: 0x10)"

                if (-not $logLevel -or $logLevel -notmatch "^0x[0-9A-Fa-f]+$") {
                    Write-Host "Invalid log level. Using default value '0x10'." -ForegroundColor Yellow
                    $logLevel = "0x10"
                }

                if (-not $sessionName) {
                    $sessionName = "ApiTraceSession"
                }

                Start-ApiTrace -SessionName $sessionName -LogLevel $logLevel
                Show-CLIGUI
            }
            "Stop Tracing and Display Results" {
                $sessionName = Read-Host "Enter session name to stop (default: ApiTraceSession)"
                if (-not $sessionName) {
                    $sessionName = "ApiTraceSession"
                }
                Stop-ApiTrace -SessionName $sessionName
                Show-CLIGUI
            }
            "Exit" {
                Write-Host "Exiting..." -ForegroundColor Green
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Yellow
                Show-CLIGUI
            }
        }
    } catch {
        Write-Host "Error displaying graphical interface: $_" -ForegroundColor Red
    }
}

function Start-ApiTracerTool {
    Write-Host "Welcome to the API Call Tracing Tool." -ForegroundColor Cyan
    Write-Host "Ensure you have administrative privileges to run this tool." -ForegroundColor Yellow
    Show-CLIGUI
}

Start-ApiTracerTool
