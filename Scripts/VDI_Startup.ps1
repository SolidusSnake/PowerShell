schtasks.exe /END /TN "\Microsoft\NetBanner\NetBannerLogon"

taskkill.exe /f /im "Snagit32.exe"
taskkill.exe /f /im "SnagitEditor.exe"
taskkill.exe /f /im "WZQKPICK32.EXE"
taskkill.exe /f /im "ssh-broker-g3.exe"
taskkill.exe /f /im "ssh-broker-gui.exe"
taskkill.exe /f /im "TSCHelp.exe"
taskkill.exe /f /im "explorer.exe"

net use V: \\FQDN\DFSRoot\Profiles\PROFILE

Start-Sleep -Seconds 3

robocopy.exe V:\Desktop\VDI\RDC "C:\Users\PROFILE\AppData\Local\Microsoft\Remote Desktop Connection Manager" RDCMan.settings

# Combine taskbar buttons - "Never"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ -Name TaskbarGlomLevel -Value 2

# Show file extensions
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ -Name HideFileExt -Value 0

# Show hidden files
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ -Name Hidden -Value 1

# Remove taskbar search box
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0 -PropertyType DWORD

# NOT NECESSARY ANYMORE
#Set-Location -LiteralPath "HKCU:\SOFTWARE\Classes\*"
# New-Item "shell\Open with Notepad++\command" -Force
# New-ItemProperty -Name "(Default)" -Type String -Value "C:\Program Files (x86)\Notepad++\notepad++.exe %1" -LiteralPath "HKCU:\SOFTWARE\Classes\*\shell\Open with Notepad++\command"

# Set wallpaper from ugly DoD image to something cooler
$path = "V:\img2.jpg"

$setWallpaperSrc = @"
using System.Runtime.InteropServices;
public class wallpaper
{
    public const int SetDesktopWallpaper = 20;
    public const int UpdateIniFile = 0x01;
    public const int SendWinIniChange = 0x02;
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaper ( string path )
    {
        SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
    }
}
"@

Add-Type -TypeDefinition $setWallpaperSrc

[wallpaper]::SetWallpaper($path)
Start-Sleep -Seconds 1
C:\windows\system32\rundll32.exe user32.dll,UpdatePerUserSystemParameters

Start-Process "explorer.exe"

# Need to fix this to prevent cleartext passwords
#Start-Process "V:\Desktop\VDI\LogonScripts\mapdrive.exe"

$net = $(New-Object -ComObject wscript.network);
$net.MapNetworkDrive("Z:", "\\NETWORK\PATH", $false, "USER", "SUPER_SECRET_PASS");

Start-Sleep -Seconds 2

& "V:\quicknotes.txt"

# Set window size of a process
Add-Type @"
  using System;
  using System.Runtime.InteropServices;

  public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
  }

  public struct RECT
  {
    public int Left;        // x position of upper-left corner
    public int Top;         // y position of upper-left corner
    public int Right;       // x position of lower-right corner
    public int Bottom;      // y position of lower-right corner
  }

"@

$rcWindow = New-Object RECT
$rcClient = New-Object RECT

$proc = (Get-Process | where {$_.MainWindowTitle -like "*Notepad"}).MainWindowHandle

[Win32]::GetWindowRect($proc,[ref]$rcWindow)
[Win32]::GetClientRect($proc,[ref]$rcClient)

$width = 400
$height = 200

$dx = ($rcWindow.Right - $rcWindow.Left) - $rcClient.Right
$dy = ($rcWindow.Bottom - $rcWindow.Top) - $rcClient.Bottom

[Win32]::MoveWindow($proc, $rct.Left, $rct.Top, $width + $dx, $height + $dy, $true )
