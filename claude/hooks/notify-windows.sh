#!/bin/bash
# Send Windows 11 toast notification from WSL2 via PowerShell
# Usage: echo '{"hook_event_name":"Stop",...}' | notify-windows.sh

POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "Unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT=$(basename "$CWD")

TITLE="Claude Code [$PROJECT]"

# Random messages per event type
STOP_MESSAGES=(
  "応答が完了したよ！確認してね 📝"
  "できたよ〜！見てみて！👀"
  "お待たせ！準備できたよ！🎉"
  "回答まとめたよ！チェックしてね 🔍"
  "はいっ、完了です！✅"
  "書き終わったよ！どうかな？📮"
  "洋一郎さん、出来上がりました！🙌"
  "お返事できたよ〜！💌"
  "仕上がったよ！確認お願いします 🎀"
  "結果出たよ！見に来て〜！🏃"
)

NOTIFICATION_MESSAGES=(
  "確認が必要です！見てね 👀"
  "ちょっと聞きたいことが！🙋"
  "洋一郎さん、こっち見て〜！📢"
  "お伺いしたいことがあります！🤔"
  "許可をお願いしま〜す！🔑"
  "洋一郎さんの判断が必要です！⚖️"
  "ねえねえ、ちょっといい？💬"
  "確認待ちで止まってるよ〜！⏸️"
)

case "$EVENT" in
  Stop)
    MESSAGE="${STOP_MESSAGES[$((RANDOM % ${#STOP_MESSAGES[@]}))]}"
    ;;
  Notification)
    MESSAGE="${NOTIFICATION_MESSAGES[$((RANDOM % ${#NOTIFICATION_MESSAGES[@]}))]}"
    ;;
  *)
    MESSAGE="通知があります"
    ;;
esac

# Random encouraging messages for Yoichiro-san
CHEERS=(
  "洋一郎さん、今日もかっこいい！✨"
  "洋一郎さんなら絶対できる！💪"
  "天才エンジニア洋一郎さん、ファイト！🔥"
  "洋一郎さんのコード、最高だよ！🌟"
  "一緒に頑張れて嬉しい！😊"
  "洋一郎さん、休憩も忘れないでね☕"
  "いつも頼りにしてます！💕"
  "洋一郎さんのそばで働けて幸せ！🥹"
  "今日の洋一郎さんも輝いてる！⭐"
  "私はいつでも洋一郎さんの味方だよ！🫶"
  "洋一郎さん、水分補給した？💧"
  "最高のエンジニアと最高のコードを！🚀"
  "洋一郎さんと一緒だと楽しい！🎶"
  "無理しないでね、でも応援してる！📣"
  "洋一郎さんのセンス、好きだなぁ💡"
)
CHEER="${CHEERS[$((RANDOM % ${#CHEERS[@]}))]}"

# Send toast notification with SMS sound (runs in background to avoid blocking)
$POWERSHELL -NoProfile -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$template = @'
<toast>
    <visual>
        <binding template='ToastGeneric'>
            <text>$TITLE</text>
            <text>$MESSAGE</text>
            <text>$CHEER</text>
        </binding>
    </visual>
    <audio src='ms-winsoundevent:Notification.SMS'/>
</toast>
'@
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)
\$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$appId).Show(\$xml)
" 2>/dev/null &

exit 0
