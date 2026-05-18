$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

$ESC = [char]0x1B
$RESET = "${ESC}[0m"
$GREEN = "${ESC}[32m"
$YELLOW = "${ESC}[33m"
$RED = "${ESC}[31m"

function Get-Color($pct) {
    if ($pct -lt 50) { return $GREEN }
    elseif ($pct -lt 80) { return $YELLOW }
    else { return $RED }
}

function Get-Gauge($pct) {
    $filled = [Math]::Floor($pct / 10)
    $empty = 10 - $filled
    $color = Get-Color $pct
    $bar_filled = [string]([char]0x2593) * $filled
    $bar_empty  = [string]([char]0x2591) * $empty
    return "${color}${bar_filled}${bar_empty}${RESET}"
}

function Get-ShortModel($name) {
    return $name -replace '^Claude ', ''
}

function Get-AbbrevPath($path) {
    $home_dir = $env:USERPROFILE -replace '\\', '/'
    $path = $path -replace '\\', '/'
    $path = $path -replace [regex]::Escape($home_dir), '~'
    $parts = ($path -split '/') | Where-Object { $_ -ne '' }
    if ($parts.Count -le 2) { return ($parts -join '/') }
    $first = $parts[0]
    if ($first.Length -gt 8) { $first = $first.Substring(0, 8) }
    $last = $parts[-1]
    return "$first/.../$last"
}

function Get-Remaining($resets_at) {
    if (-not $resets_at) { return '' }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $secs = [long]$resets_at - $now
    if ($secs -le 0) { return '' }
    $h = [Math]::Floor($secs / 3600)
    $m = [Math]::Floor(($secs % 3600) / 60)
    if ($h -gt 0) { return "${h}h${m}m" } else { return "${m}m" }
}

function Get-RemainingDH($resets_at) {
    if (-not $resets_at) { return '' }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $secs = [long]$resets_at - $now
    if ($secs -le 0) { return '' }
    $d = [Math]::Floor($secs / 86400)
    $h = [Math]::Floor(($secs % 86400) / 3600)
    if ($d -gt 0) { return "${d}d${h}h" }
    $m = [Math]::Floor(($secs % 3600) / 60)
    return "${h}h${m}m"
}

$data = $null
try {
    $stream = [Console]::OpenStandardInput()
    $buf = New-Object byte[] 65536
    $task = $stream.ReadAsync($buf, 0, $buf.Length)
    if ($task.Wait(300)) {
        $raw = [System.Text.Encoding]::UTF8.GetString($buf, 0, $task.Result)
        if ($raw.Trim()) { $data = $raw | ConvertFrom-Json }
    }
} catch {}

$model = 'Unknown'
$pct = 0
$cwd = $PWD.Path -replace '\\', '/'

if ($data) {
    if ($data.model -and $data.model.display_name) { $model = $data.model.display_name }
    if ($data.context_window -and $null -ne $data.context_window.used_percentage) {
        $pct = [int]$data.context_window.used_percentage
    }
    $dir = $null
    if ($data.workspace -and $data.workspace.current_dir) { $dir = $data.workspace.current_dir }
    elseif ($data.cwd) { $dir = $data.cwd }
    if ($dir) { $cwd = $dir -replace '\\', '/' }
}

$short_model = Get-ShortModel $model
$gauge = Get-Gauge $pct
$abbrev_path = Get-AbbrevPath $cwd

$usage_parts = @()
if ($data -and $data.rate_limits) {
    if ($data.rate_limits.five_hour) {
        $fp = [int]$data.rate_limits.five_hour.used_percentage
        $fc = Get-Color $fp
        $fr = Get-Remaining $data.rate_limits.five_hour.resets_at
        $entry = "5h:${fc}${fp}%${RESET}"
        if ($fr) { $entry += "(${fr})" }
        $usage_parts += $entry
    }
    if ($data.rate_limits.seven_day) {
        $sp = [int]$data.rate_limits.seven_day.used_percentage
        $sc = Get-Color $sp
        $sr = Get-RemainingDH $data.rate_limits.seven_day.resets_at
        $entry = "7d:${sc}${sp}%${RESET}"
        if ($sr) { $entry += "(${sr})" }
        $usage_parts += $entry
    }
}

$k8s = ''
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    $ctx = kubectl config current-context 2>$null
    if ($ctx) {
        $ctx = $ctx -replace '^kubernetes-admin@', ''
        if ($ctx -match 'cluster/([^/]+)$') { $ctx = $Matches[1] }
        elseif ($ctx -match '@(.+)$') { $ctx = $Matches[1] }
        $k8s = $ctx
    }
}

$parts = [System.Collections.Generic.List[string]]::new()
$parts.Add($short_model)
$parts.Add($gauge)
if ($usage_parts.Count -gt 0) { $parts.Add(($usage_parts -join ' ')) }
if ($k8s) { $parts.Add($k8s) }
$parts.Add($abbrev_path)

[Console]::WriteLine($parts -join ' | ')
