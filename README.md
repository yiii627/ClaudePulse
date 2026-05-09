# ClaudePulse

[简体中文](README_zh.md) | English

Windows desktop notification script for Claude Code task status alerts.

## Installation

### 1. Install Notification Module

Run in PowerShell:

```powershell
Install-Module -Name BurntToast -Force
```

**If you encounter `No match was found` error:**

Check if PowerShell Gallery is registered:

```powershell
Get-PSRepository
```

If empty or missing `PSGallery`, register the repository:

```powershell
Register-PSRepository -Default
```

Then run the installation command again.

### 2. Configure Icon (Optional)

Name your icon file `icon.png` and place it in the same directory as the script.

## Testing

Before configuring Claude Code, test if the script works properly.

**Note:** Open a terminal in the script's directory and run the following commands.

```powershell
# Simulate Stop event
'{"last_assistant_message":"Task completed"}' | .\ClaudePulse.ps1 -Action Stop

# Simulate Notification event
'{"message":"Action required"}' | .\ClaudePulse.ps1 -Action Notification

# Simulate PermissionRequest event
'{"tool_name":"Bash","tool_input":"rm -rf /"}' | .\ClaudePulse.ps1 -Action PermissionRequest
```

If desktop notifications appear, the script is working correctly.

## Integration with Claude Code

Configure hooks in Claude Code's `settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "<full-script-path> -Action Stop",
            "timeout": 15
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt|elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "<full-script-path> -Action Notification",
            "timeout": 15
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "<full-script-path> -Action PermissionRequest",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

**Path Configuration:**

- Use absolute path to the script
- Windows path example: `D:\\env\\claude\\ClaudePulse\\ClaudePulse.ps1`
- Note: Backslashes must be escaped as double backslashes `\\`

**Matcher Configuration:**

The `matcher` field filters which notifications trigger the hook:
- `permission_prompt`: Triggers when Claude needs permission
- `elicitation_dialog`: Triggers when Claude needs user input
- Use `|` to combine multiple conditions

## How It Works

- Claude Code passes JSON data to the script via **stdin**
- `Stop` event: Prioritizes reading from transcript file for Claude's final response, falls back to `last_assistant_message` field if unavailable
- `Notification` event: Extracts notification content from `title` and `message` fields (joined with `: `)
- `PermissionRequest` event: Extracts tool name from `tool_name` field
- Messages longer than 120 characters are automatically truncated

## Features

- ✨ Clean and elegant notification interface
- 🔔 Custom sound support
- 🖼️ Custom icon support
- 📝 Auto-truncate long messages
- 🛡️ Safe handling of empty messages
- ⚡ Read JSON data from stdin
