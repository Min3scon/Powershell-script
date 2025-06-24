Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Hide PowerShell console window
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
$consolePtr = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consolePtr, 0)

# Download GIF and MP3 if missing
$gifPath = "$env:TEMP\rickroll.gif"
if (-not (Test-Path $gifPath)) {
    Invoke-WebRequest -Uri "https://media.tenor.com/onTlUVMtWy4AAAAM/rickroll-rick.gif" -OutFile $gifPath -UseBasicParsing
}

$mp3Path = "$env:TEMP\sound.mp3"
if (-not (Test-Path $mp3Path)) {
    Invoke-WebRequest -Uri "https://audio.jukehost.co.uk/gW1i5EkMPBjmlK0bZrsBhIsfWDSLgjCX" -OutFile $mp3Path -UseBasicParsing
}

# Increase volume (send volume up key 50 times)
$wshell = New-Object -ComObject wscript.shell
for ($i=0; $i -lt 10; $i++) {
    $wshell.SendKeys([char]175)  # VK_VOLUME_UP
    Start-Sleep -Milliseconds 20
}

# Create Windows Form
$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.Location = [System.Drawing.Point]::new(0,0)
$form.Size = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Size

# Create PictureBox with GIF
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = 'Fill'
$pictureBox.SizeMode = 'Zoom'
$pictureBox.ImageLocation = $gifPath
$pictureBox.Load()

$form.Controls.Add($pictureBox)

# Setup Windows Media Player COM for audio looping
$wmp = New-Object -ComObject WMPlayer.OCX
$media = $wmp.newMedia($mp3Path)
$wmp.currentPlaylist.clear()
$wmp.currentPlaylist.appendItem($media)
$wmp.settings.setMode("loop", $true)
$wmp.controls.play()

# Show the form
$form.Add_Shown({ $form.Activate() })
$form.Show()

# Run the form (blocks here)
[void][System.Windows.Forms.Application]::Run($form)
