# 3t Systems - William Foster - 8/21/2016
$Static = Import-CSV C:\static.csv

# Get connected adapter
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

# Convert subnet mask into prefix (255.255.0.0 -> 16)
$BinNum = $Static.SubnetMask -split '\.' | ForEach-Object {[System.Convert]::ToString($_,2).PadLeft(8,'0')}
$BinJoin = $binNum -join ""  
$CIDR = [regex]::matches($BinJoin,"1").count

# Set network adapter settings
$adapter | New-NetIPAddress `
    -AddressFamily "IPv4" `
    -IPAddress $Static.IP `
    -PrefixLength $CIDR `
    -DefaultGateway $Static.DefaultGateway
# Set DNS servers
$adapter | Set-DnsClientServerAddress -ServerAddresses $Static.DNS
