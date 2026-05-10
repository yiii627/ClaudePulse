# ClaudePulse

简体中文 | [English](README.md)

Windows 桌面通知脚本，用于 Claude Code 任务状态提醒。

## 安装

### 1. 安装通知模块

在 PowerShell 中运行：

```powershell
Install-Module -Name BurntToast -Force
```

**如果遇到 `No match was found` 错误：**

检查 PowerShell Gallery 是否已注册：

```powershell
Get-PSRepository
```

如果返回为空或没有 `PSGallery`，需要注册仓库：

```powershell
Register-PSRepository -Default
```

然后重新运行安装命令。

### 2. 配置图标（可选）

将图标文件命名为 `icon.png` 并放置在脚本同目录下。

## 测试

在配置 Claude Code 之前，建议先测试脚本是否正常工作。

**注意：** 请在脚本所在目录下打开终端运行以下命令。

```powershell
# 模拟 Stop 事件
'{"last_assistant_message":"Task completed"}' | .\ClaudePulse.ps1 -Action Stop

# 模拟 Notification 事件
'{"message":"Action required"}' | .\ClaudePulse.ps1 -Action Notification

# 模拟 PermissionRequest 事件
'{"tool_name":"Bash","tool_input":"rm -rf /"}' | .\ClaudePulse.ps1 -Action PermissionRequest
```

如果看到桌面通知弹出，说明脚本工作正常。

## 集成到 Claude Code

在 Claude Code 的 `settings.json` 中配置 hooks：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "<脚本完整路径> -Action Stop",
            "timeout": 15
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "<脚本完整路径> -Action Notification",
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
            "command": "<脚本完整路径> -Action PermissionRequest",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

**路径填写说明：**

- 使用脚本的绝对路径
- Windows 路径示例：`D:\\env\\claude\\ClaudePulse\\ClaudePulse.ps1`
- 注意：反斜杠需要转义为双反斜杠 `\\`

**Matcher 配置说明：**

`matcher` 字段用于过滤哪些通知会触发 Hook：
- `elicitation_dialog`：当 Claude 需要用户输入时触发

## 工作原理

- Claude Code 通过 **stdin** 将 JSON 数据传递给脚本
- `Stop` 事件：优先从 transcript 文件读取 Claude 的最终响应，如果不可用则从 `last_assistant_message` 字段提取
- `Notification` 事件：从 `title` 和 `message` 字段提取通知内容（用 `: ` 连接）
- `PermissionRequest` 事件：从 `tool_name` 字段提取工具名称
- 消息超过 120 字符时自动截断

## 特性

- ✨ 简洁优雅的通知界面
- 🔔 支持自定义音效
- 🖼️ 支持自定义图标
- 📝 自动截断过长消息
- 🛡️ 空消息安全处理
- ⚡ 从 stdin 读取 JSON 数据
