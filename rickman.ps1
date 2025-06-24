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
    [DllImport("user32.dll")]
    public static extern IntPtr SetWindowLong(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
    [DllImport("user32.dll")]
    public static extern IntPtr GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
"@

$SW_HIDE = 0
$consolePtr = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consolePtr, $SW_HIDE)

# Set system volume to max (fallback to sending volume keys)
function Set-Volume100 {
    $wshell = New-Object -ComObject wscript.shell
    for ($i=0; $i -lt 50; $i++) { $wshell.SendKeys([char]174); Start-Sleep -Milliseconds 10 }  # Volume Down many times
    for ($i=0; $i -lt 50; $i++) { $wshell.SendKeys([char]175); Start-Sleep -Milliseconds 10 }  # Volume Up to max
}
Set-Volume100

# Paths and URLs
$gifPath = "$env:TEMP\rickroll.gif"
$mp3Path = "$env:TEMP\sound.mp3"
$urlAudio = "https://audio.jukehost.co.uk/gW1i5EkMPBjmlK0bZrsBhIsfWDSLgjCX"
$urlGif = "https://media.tenor.com/onTlUVMtWy4AAAAM/rickroll-rick.gif"

# Download GIF if missing
if (-not (Test-Path $gifPath)) {
    Invoke-WebRequest -Uri $urlGif -OutFile $gifPath -UseBasicParsing
}

# Download MP3 if missing
if (-not (Test-Path $mp3Path)) {
    Invoke-WebRequest -Uri $urlAudio -OutFile $mp3Path -UseBasicParsing
}

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.Location = [System.Drawing.Point]::new(0,0)
$form.Size = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Size

# Modify extended style to hide from Alt+Tab
$GWL_EXSTYLE = -20
$WS_EX_TOOLWINDOW = 0x00000080
$WS_EX_APPWINDOW = 0x00040000

$hwnd = $form.Handle
$style = [Win32]::GetWindowLong($hwnd, $GWL_EXSTYLE)
$style = $style -bor $WS_EX_TOOLWINDOW
$style = $style -band (-bnot $WS_EX_APPWINDOW)
[Win32]::SetWindowLong($hwnd, $GWL_EXSTYLE, $style)

# Create PictureBox with GIF
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Dock = 'Fill'
$pictureBox.SizeMode = 'Zoom'
$pictureBox.ImageLocation = $gifPath
$pictureBox.Load()
$form.Controls.Add($pictureBox)

# Block closing the form by cancelling FormClosing event
$form.Add_FormClosing({
    param($sender, $e)
    # Cancel the close event unconditionally
    $e.Cancel = $true
})

# Block Alt+Tab, Windows keys, Ctrl+Esc, Alt+F4, Escape keys etc
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    if (
        ($e.Alt -and $e.KeyCode -eq 'Tab') -or
        ($e.KeyCode -eq 'LWin') -or
        ($e.KeyCode -eq 'RWin') -or
        ($e.Control -and $e.KeyCode -eq 'Escape') -or
        ($e.Alt -and $e.KeyCode -eq 'F4') -or
        ($e.KeyCode -eq 'Escape')
    ) {
        $e.Handled = $true
        $e.SuppressKeyPress = $true
    }
})

# Re-activate the form if user tries to switch focus away
$form.Add_Deactivate({
    Start-Sleep -Milliseconds 100
    $form.Activate()
})

# Start playing audio after form shown
$form.Add_Shown({
    Start-Sleep -Seconds 1
    $wmp = New-Object -ComObject WMPlayer.OCX
    $media = $wmp.newMedia($mp3Path)
    $wmp.currentPlaylist.clear()
    $wmp.currentPlaylist.appendItem($media)
    $wmp.settings.setMode("loop", $true)
    $wmp.controls.play()
})

# Show the form (blocks here)
$form.ShowDialog()
