param(
    [ValidateSet("Stop", "Notification", "PermissionRequest")]
    [string]$Action = "Stop"
)

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Import-Module BurntToast -ErrorAction SilentlyContinue

function Limit($text, $max = 120) {
    if (!$text) { return "" }
    $text = $text.Trim()
    if ($text.Length -gt $max) {
        return $text.Substring(0, $max - 3) + "..."
    }
    return $text
}

$inputData = @($Input) -join "`n"

if ([string]::IsNullOrWhiteSpace($inputData)) {
    $lines = @()
    while ($line = [Console]::In.ReadLine()) {
        $lines += $line
    }
    $inputData = $lines -join "`n"
}

$title = "ClaudePulse"
$Message = ""

if (![string]::IsNullOrWhiteSpace($inputData)) {
    try {
        $json = $inputData | ConvertFrom-Json

        if ($json.cwd) {
            $projectName = Split-Path $json.cwd -Leaf
            $title = "ClaudePulse - $projectName"
        }

        if ($Action -eq "Stop") {
            if ($json.transcript_path -and (Test-Path $json.transcript_path)) {
                $transcriptLines = Get-Content $json.transcript_path -Tail 30 -Encoding UTF8

                for ($i = $transcriptLines.Count - 1; $i -ge 0; $i--) {
                    try {
                        $entry = $transcriptLines[$i] | ConvertFrom-Json -ErrorAction Stop
                        if ($entry.message.role -eq "assistant") {
                            $content = $entry.message.content

                            if ($content -is [string]) {
                                $Message = $content
                            }
                            elseif ($content -is [array]) {
                                $textPart = $content | Where-Object { $_.type -eq "text" } | Select-Object -First 1
                                if ($textPart) { $Message = $textPart.text }
                            }

                            if ($Message) { break }
                        }
                    }
                    catch { continue }
                }
            }

            if (!$Message -and $json.last_assistant_message) {
                $Message = $json.last_assistant_message
            }

            if (!$Message) { $Message = "Task completed" }
        }
        elseif ($Action -eq "Notification") {
            $parts = @()
            if ($json.title) { $parts += $json.title }
            if ($json.message) { $parts += $json.message }
            $Message = ($parts -join ": ")

            if (!$Message) { $Message = "Action required" }
        }
        elseif ($Action -eq "PermissionRequest") {
            if ($json.tool_name) {
                $Message = $json.tool_name
            }

            if (!$Message) { $Message = "Permission required" }
        }
    }
    catch {
        $Message = switch ($Action) {
            "Stop" { "Task completed" }
            "PermissionRequest" { "Permission required" }
            default { "Action required" }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = switch ($Action) {
        "Stop" { "Task completed" }
        "PermissionRequest" { "Permission required" }
        default { "Action required" }
    }
}

$Message = Limit $Message
$iconPath = Join-Path $PSScriptRoot "icon.png"
if (-not (Test-Path $iconPath)) { $iconPath = $null }

New-BurntToastNotification -Text $title, $Message -AppLogo $iconPath -Sound Default