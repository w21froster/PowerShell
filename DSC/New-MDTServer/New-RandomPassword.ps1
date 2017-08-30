# Written by William Foster
Function New-RandomPassword ($length=12)
{
    $Password = ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()~-_=+[{]}\|;:',<.>/?" `
        -Split "" | Where-Object {$_.Length -ge 1} | Get-Random -Count $Length) -Join ""
    Return $Password
}