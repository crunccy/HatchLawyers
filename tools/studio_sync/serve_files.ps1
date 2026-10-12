param([string]$Root, [int]$Port = 8766, [int]$Seconds = 1800)
# Minimal static file server on localhost for handing repo files to Roblox Studio (HttpService:GetAsync from the
# Studio MCP's execute_luau). Serves only files directly inside $Root with these extensions; stops after $Seconds.
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
$deadline = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $deadline -and $listener.IsListening) {
    $task = $listener.GetContextAsync()
    while (-not $task.AsyncWaitHandle.WaitOne(500)) { if ((Get-Date) -ge $deadline) { break } }
    if (-not $task.IsCompleted) { break }
    $ctx = $task.Result
    $name = [System.IO.Path]::GetFileName($ctx.Request.Url.LocalPath)
    $path = Join-Path $Root $name
    if ((Test-Path $path) -and ($name -match '\.(txt|lua|json|png)$')) {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $ctx.Response.ContentType = if ($name -like '*.png') { 'image/png' } else { 'text/plain; charset=utf-8' }
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
}
$listener.Stop()
