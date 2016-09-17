get-childitem -Path "C:\Windows\Minidump" | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-30) } 
if (Test-Path C:\BrightWire\MemoryDumps -PathType Container) {copy-item C:\Windows\MiniDump\* C:\BrightWire\MemoryDumps\}
else {New-Item C:\BrightWire\MemoryDumps -ItemType Directory
      copy-item C:\Windows\MiniDump\* C:\BrightWire\MemoryDumps\}
