param([string]$Root, [int]$Port = 8767, [int]$Seconds = 600)
# Local receiver for tools/studio_sync/ExportSnapshot.lua: Roblox Studio POSTs each script's source to
# http://localhost:<Port>/save?path=<relative path> and this writes it under $Root (the repo's studio/ folder).
# Only paths inside $Root are accepted; it stops by itself after $Seconds or on GET /done.
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
$rootFull = [System.IO.Path]::GetFullPath($Root)
$deadline = (Get-Date).AddSeconds($Seconds)
$count = 0
while ((Get-Date) -lt $deadline -and $listener.IsListening) {
    $task = $listener.GetContextAsync()
    while (-not $task.AsyncWaitHandle.WaitOne(500)) { if ((Get-Date) -ge $deadline) { break } }
    if (-not $task.IsCompleted) { break }
    $ctx = $task.Result
    $req = $ctx.Request
    $status = 200
    $msg = "ok"
    if ($req.Url.AbsolutePath -eq "/done") {
        $ctx.Response.StatusCode = 200
        $ctx.Response.Close()
        break
    }
    if ($req.HttpMethod -eq "POST" -and $req.Url.AbsolutePath -eq "/save") {
        $rel = [System.Uri]::UnescapeDataString($req.QueryString["path"])
        $target = [System.IO.Path]::GetFullPath((Join-Path $rootFull $rel))
        if (-not $target.StartsWith($rootFull)) {
            $status = 400; $msg = "outside root"
        } else {
            $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($target)) | Out-Null
            [System.IO.File]::WriteAllText($target, $body, (New-Object System.Text.UTF8Encoding($false)))
            $count++
        }
    } else {
        $status = 404; $msg = "no"
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
    $ctx.Response.StatusCode = $status
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
}
$listener.Stop()
"received $count files"
