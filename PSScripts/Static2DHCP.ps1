# 3t Systems - William Foster - 8/21/2016
# Get Network Adapter that is connected 
$ConnectedAdapter = Get-WmiObject win32_networkadapter -filter "netconnectionstatus = 2" | select InterfaceIndex
# Filter only the InterfaceIndex
$Index = $ConnectedAdapter.InterfaceIndex
# Retrieve WMI information from the Network Adapter and put the unfiltered information into a variable
$Interface = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter InterfaceIndex=$Index -ComputerName . | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*

if ($Interface.DHCPEnabled -like "False") {
    # Filter only the data we need and put it into a CSV
    $IP = $Interface.IPAddress.split(' ')[0] #Strip IPv6 by removing any characters after a whitespace.
    $SubnetMask = $Interface.IPSubnet.split(' ')[0] #Strip IPv6 subnet by removing any characters after a whitespace.
    $DGateway = $Interface.DefaultIPGateway
    $DNS = $Interface.DNSServerSearchOrder -Join ',' 

    $csvContents = @() # Create the empty array that will eventually be the CSV file

    $row = New-Object System.Object # Create an object to append to the array
    $row | Add-Member -MemberType NoteProperty -Name "IP" -Value "$IP"
    $row | Add-Member -MemberType NoteProperty -Name "SubnetMask" -Value "$SubnetMask"
    $row | Add-Member -MemberType NoteProperty -Name "DefaultGateway" -Value "$DGateway"
    $row | Add-Member -MemberType NoteProperty -Name "DNS" -Value "$DNS" 

    $csvContents += $row # append the new data to the array

    $csvContents | Export-CSV -Path C:\static.csv }

$Challenge = Test-Path "C:\static.csv" # Challenge path to make sure we have static IP backed up.
if ($Challenge -eq $True) {
    # Remove existing gateway
    If (($Interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
        $Interface | Remove-NetRoute -Confirm:$false
    }

    # Enable DHCP
    $Interface | Set-NetIPInterface -DHCP Enabled

    # Configure the  DNS Servers automatically
    $Interface | Set-DnsClientServerAddress -ResetServerAddresses
}
