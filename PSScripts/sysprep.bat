reg add "HKLM\SYSTEM\Setup\Status\Sysprepstatus" /v CleanupState /t REG_DWORD /d 00000002 /F

reg add "HKLM\SYSTEM\Setup\Status\Sysprepstatus" /v GeneralizationState /t REG_DWORD /d 00000007 /F

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v SkipRearm /t REG_DWORD /d 00000001

msdtc -uninstall

timeout 120

msdtc -install

timeout 120

rmdir /Q /S "C:\Windows\System32\Sysprep\Panther" 
del /Q "C:\Windows\System32\Sysprep\Sysprep_succeeded.tag"

ECHO Beginning Sysprep. The system will shutdown when complete.

"C:\Windows\System32\Sysprep\Sysprep.exe" /oobe /generalize /shutdown