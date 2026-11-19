# PostToolUse hook: verify-meeting-notice
#
# Runs after Claude edits or writes a file. When the file is index.html it checks that the
# "IT meeting" announcement (a dialog shown once after 10 seconds on the page) is still
# wired up correctly, so a later edit cannot silently break it.
# Exit codes (Claude Code hook contract): 0 = fine or not relevant, 2 = problem (stderr goes to Claude).
#
# A Claude Code hook cannot run inside the website itself, so the popup lives in index.html
# (setupNotice()). This hook is the guard that keeps it correct. It only READS files.

$ErrorActionPreference = "Stop"

try {
    $evt = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$path = $evt.tool_input.file_path
if (-not $path -or $path -notmatch '(^|[\\/])index\.html$' -or -not (Test-Path -LiteralPath $path)) {
    exit 0
}

$src = Get-Content -LiteralPath $path -Raw -Encoding UTF8
$problems = New-Object System.Collections.Generic.List[string]

if ($src -notmatch 'id="notice"') { exit 0 }     # feature not present yet: nothing to verify

$message = 'IT meeting next Wed 10am at room 888'
if (-not $src.Contains('message: "' + $message + '"')) {
    $problems.Add("The announcement message must be exactly: $message")
}
if ($src -notmatch 'afterMs:\s*10000\b') {
    $problems.Add("The announcement delay must be 10 seconds (afterMs: 10000).")
}
if ($src -notmatch 'role="alertdialog"') {
    $problems.Add("The announcement needs role=""alertdialog"" (with aria-labelledby and aria-describedby) so screen readers announce it.")
}
if ($src -notmatch 'id="notice-ok"') {
    $problems.Add("The announcement needs a visible OK button (#notice-ok) to dismiss it.")
}
if ($src -notmatch 'function setupNotice\(\)[\s\S]*Escape') {
    $problems.Add("setupNotice() must close the dialog with the Escape key.")
}
if ($src -notmatch 'document\.hidden') {
    $problems.Add("The 10-second timer should only count while the tab is visible (check document.hidden).")
}
# Project rules: no window.alert()/confirm(), no browser storage.
if ($src -match '(^|[^\w.])(window\.)?(alert|confirm)\s*\(') {
    $problems.Add("alert()/confirm() are forbidden in this project; use the in-page dialog.")
}
if ($src -match 'localStorage|sessionStorage|indexedDB|document\.cookie') {
    $problems.Add("Browser storage APIs are not allowed (the announcement must not be remembered across visits).")
}

if ($problems.Count -gt 0) {
    [Console]::Error.WriteLine("verify-meeting-notice hook: $($problems.Count) problem(s) in index.html")
    foreach ($p in $problems) { [Console]::Error.WriteLine(" - $p") }
    exit 2
}
exit 0
