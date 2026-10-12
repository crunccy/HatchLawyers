param([string]$File, [string]$Code, [string]$Type = "execute_code", [int]$TimeoutSec = 120)
# Talks to the BlenderMCP add-on's local socket directly (no MCP server needed): sends one command and prints the
# reply. Use when the blender MCP server isn't connected but Blender is open with the add-on's server started
# (N panel > BlenderMCP > Connect to Claude / Start Server, port 9876).
#   ./send.ps1 -File script.py           runs a Python file in Blender (execute_code)
#   ./send.ps1 -Type get_scene_info      any other add-on command, no params
$payload = @{ type = $Type; params = @{} }
if ($Type -eq "execute_code") {
    $src = if ($File) { [IO.File]::ReadAllText($File, [Text.Encoding]::UTF8) } else { $Code }
    $payload.params.code = $src
}
$json = $payload | ConvertTo-Json -Compress -Depth 5
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect("127.0.0.1", 9876)
$stream = $client.GetStream()
$bytes = [Text.Encoding]::UTF8.GetBytes($json)
$stream.Write($bytes, 0, $bytes.Length)
$stream.ReadTimeout = $TimeoutSec * 1000
$ms = New-Object System.IO.MemoryStream
$buf = New-Object byte[] 65536
while ($true) {
    $n = $stream.Read($buf, 0, $buf.Length)
    if ($n -le 0) { break }
    $ms.Write($buf, 0, $n)
    $text = [Text.Encoding]::UTF8.GetString($ms.ToArray())
    try { $null = $text | ConvertFrom-Json; break } catch { }
}
$client.Close()
$text = [Text.Encoding]::UTF8.GetString($ms.ToArray())
$obj = $text | ConvertFrom-Json
if ($obj.status -ne "success") { "ERROR: " + $obj.message } elseif ($obj.result.result) { $obj.result.result } else { $obj.result | ConvertTo-Json -Depth 4 -Compress }
