# PostToolUse hook: verify-chatbot
#
# Runs after Claude edits or writes a file. When the file is index.html it checks that the
# IT-assistant chatbot's click-to-speak greeting is still wired up, so a later edit cannot
# silently break it. Exit codes (Claude Code hook contract):
#   0 = fine (or not relevant), 2 = problem found: stderr is fed back to Claude to fix.
#
# Input: the hook event as JSON on stdin (tool_name, tool_input.file_path, ...).
# This script only READS files. It never changes the project.

$ErrorActionPreference = "Stop"

try {
    $raw = [Console]::In.ReadToEnd()
    $evt = $raw | ConvertFrom-Json
} catch {
    exit 0                                   # not a JSON event: nothing to check
}

$path = $evt.tool_input.file_path
if (-not $path -or $path -notmatch '(^|[\\/])index\.html$' -or -not (Test-Path -LiteralPath $path)) {
    exit 0                                   # only index.html matters
}

$src = Get-Content -LiteralPath $path -Raw -Encoding UTF8
$greeting = 'I am your IT assistant, how can I help you?'
$problems = New-Object System.Collections.Generic.List[string]

# Only check once the chatbot exists in the file.
if ($src -notmatch 'id="chat-fab"') { exit 0 }

if (-not $src.Contains('const GREETING = "' + $greeting + '"')) {
    $problems.Add("The greeting constant must be exactly: $greeting")
}
if ($src -notmatch 'new SpeechSynthesisUtterance\(') {
    $problems.Add("Voice output is missing: no SpeechSynthesisUtterance (Web Speech API) call found.")
}
if ($src -notmatch 'function openChat\(\)[\s\S]{0,600}speak\(GREETING\)') {
    $problems.Add("openChat() must call speak(GREETING) so clicking the avatar plays the voice message.")
}
if ($src -notmatch 'fab\.addEventListener\("click"') {
    $problems.Add("The avatar button (#chat-fab) has no click handler.")
}
if ($src -notmatch 'id="chat-fab"[^>]*aria-label=') {
    $problems.Add("The avatar button needs an aria-label (it has no visible text).")
}
if ($src -notmatch 'id="chat-voice"') {
    $problems.Add("The voice on/off button (#chat-voice) is missing; users must be able to mute speech.")
}

# Security: chat output must use textContent, not innerHTML (task titles are user data).
$start = $src.IndexOf('function setupChat()')
if ($start -ge 0) {
    $chat = $src.Substring($start)
    $count = ([regex]::Matches($chat, 'innerHTML')).Count
    if ($count -gt 2) {                      # two uses are allowed: the static avatar markup
        $problems.Add("setupChat() uses innerHTML $count times; chat messages must be written with textContent to avoid XSS.")
    }
}

# Project rule: no browser storage.
if ($src -match 'localStorage|sessionStorage|indexedDB|document\.cookie') {
    $problems.Add("Browser storage APIs are not allowed in this project.")
}

if ($problems.Count -gt 0) {
    [Console]::Error.WriteLine("verify-chatbot hook: $($problems.Count) problem(s) in index.html")
    foreach ($p in $problems) { [Console]::Error.WriteLine(" - $p") }
    exit 2
}
exit 0
