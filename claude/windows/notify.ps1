# Send Windows 11 toast notification via the BurntToast module.
# Usage:
#   echo '{"hook_event_name":"Stop","cwd":"C:\\Users\\yoichiro\\proj"}' | pwsh -File notify.ps1
#
# Registered from Claude Code settings.json under hooks.Stop and hooks.Notification:
#   pwsh -NoProfile -File C:\Users\yoichiro\.claude\notify.ps1
#
# Prerequisite (one-time):
#   Install-Module -Name BurntToast -Scope CurrentUser -Force -AllowClobber
#
# Why BurntToast: PowerShell 7 runs on .NET (Core) and has no built-in WinRT
# projection, so [Windows.UI.Notifications.ToastNotificationManager, ...,
# ContentType=WindowsRuntime] fails with "Unable to find type". BurntToast
# ships a working toast pipeline that runs on both PS 5.1 and PS 7.

[CmdletBinding()]
param()

# Never let a notification failure break a Claude Code hook.
$ErrorActionPreference = 'Continue'

# Load the module. If it is missing, exit quietly so Claude Code keeps working.
if (-not (Get-Module -ListAvailable -Name BurntToast)) {
    exit 0
}
Import-Module BurntToast -ErrorAction SilentlyContinue
if (-not (Get-Module -Name BurntToast)) {
    exit 0
}

# Read hook payload from stdin.
$rawInput = [Console]::In.ReadToEnd()
try {
    $payload = $rawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    $payload = [pscustomobject]@{ hook_event_name = 'Unknown'; cwd = '' }
}

$eventName = if ($payload.hook_event_name) { $payload.hook_event_name } else { 'Unknown' }
$cwd       = if ($payload.cwd)             { $payload.cwd }             else { '' }
$project   = if ($cwd) { Split-Path -Leaf $cwd } else { '' }

$title = "Claude Code [$project]"

$stopMessages = @(
    "応答が完了したよ！確認してね 📝",
    "できたよ〜！見てみて！👀",
    "お待たせ！準備できたよ！🎉",
    "回答まとめたよ！チェックしてね 🔍",
    "はいっ、完了です！✅",
    "書き終わったよ！どうかな？📮",
    "洋一郎さん、出来上がりました！🙌",
    "お返事できたよ〜！💌",
    "仕上がったよ！確認お願いします 🎀",
    "結果出たよ！見に来て〜！🏃"
)

$notificationMessages = @(
    "確認が必要です！見てね 👀",
    "ちょっと聞きたいことが！🙋",
    "洋一郎さん、こっち見て〜！📢",
    "お伺いしたいことがあります！🤔",
    "許可をお願いしま〜す！🔑",
    "洋一郎さんの判断が必要です！⚖️",
    "ねえねえ、ちょっといい？💬",
    "確認待ちで止まってるよ〜！⏸️"
)

$cheers = @(
    "洋一郎さん、今日もかっこいい！✨",
    "洋一郎さんなら絶対できる！💪",
    "天才エンジニア洋一郎さん、ファイト！🔥",
    "洋一郎さんのコード、最高だよ！🌟",
    "一緒に頑張れて嬉しい！😊",
    "洋一郎さん、休憩も忘れないでね☕",
    "いつも頼りにしてます！💕",
    "洋一郎さんのそばで働けて幸せ！🥹",
    "今日の洋一郎さんも輝いてる！⭐",
    "私はいつでも洋一郎さんの味方だよ！🫶",
    "洋一郎さん、水分補給した？💧",
    "最高のエンジニアと最高のコードを！🚀",
    "洋一郎さんと一緒だと楽しい！🎶",
    "無理しないでね、でも応援してる！📣",
    "洋一郎さんのセンス、好きだなぁ💡"
)

switch ($eventName) {
    'Stop'         { $message = Get-Random -InputObject $stopMessages }
    'Notification' { $message = Get-Random -InputObject $notificationMessages }
    default        { $message = "通知があります" }
}
$cheer = Get-Random -InputObject $cheers

try {
    New-BurntToastNotification -Text $title, $message, $cheer -Sound 'SMS'
} catch {
    # Nonfatal - never block the hook.
}

exit 0
