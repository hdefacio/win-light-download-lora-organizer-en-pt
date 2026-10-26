# Organizador de Downloads - Windows PowerShell 5.1+
# developed by hmnd-team
# Versao 3.1.2 - credito na barra de titulo da janela de destino; tres idiomas (EN/PT/ES); ingles padrao e preferencia salva.
# Somente bibliotecas nativas do Windows. Nao exige extensao nem Python.
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# A API do Windows permite localizar Downloads mesmo se a pasta foi redirecionada.
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
public static class DownloadsKnownFolder {
    [DllImport("shell32.dll")]
    private static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid id, uint flags, IntPtr token, out IntPtr path);
    [DllImport("ole32.dll")]
    private static extern void CoTaskMemFree(IntPtr ptr);
    public static string Find() {
        IntPtr ptr = IntPtr.Zero;
        Guid id = new Guid("374DE290-123F-4565-9164-39C4925E467B");
        int result = SHGetKnownFolderPath(id, 0, IntPtr.Zero, out ptr);
        if (result != 0 || ptr == IntPtr.Zero)
            return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads");
        try { return Marshal.PtrToStringUni(ptr); }
        finally { CoTaskMemFree(ptr); }
    }
}
'@

$script:configDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'OrganizadorDeDownloads'
$script:configFile = Join-Path $script:configDir 'config.json'
[void][System.IO.Directory]::CreateDirectory($script:configDir)
$script:watchFolder = [DownloadsKnownFolder]::Find()
$script:recentFolders = New-Object 'System.Collections.Generic.List[string]'
$script:tracked = @{}
$script:seen = @{}
$script:paused = $false
$script:isPromptOpen = $false
$script:exitRequested = $false
$script:movedCount = 0
$script:pollIntervalMs = 1200
$script:stableSeconds = 3.0

$script:language = 'en'  # Default for new installations and older config files.

# Interface strings are kept in one place. Developer credit is shown only in the destination dialog title.
$script:translations = @{
    en = @{
        appTitle = 'Download Organizer'
        watched = 'Monitored folder:'
        languageLabel = 'Language:'
        changeFolder = 'Change folder'
        openFolder = 'Open folder'
        pause = 'Pause'
        resume = 'Resume'
        exit = 'Exit'
        showWindow = 'Show window'
        trayExit = 'Quit'
        pausedStatus = 'Paused (new files will be checked when resumed)'
        activeStatus = 'Monitoring. Files moved this session: {0}'
        help = 'Closing or minimizing this window keeps the app running in the system tray.'
        watchPicker = 'Select the folder where your browser saves downloads'
        saveError = 'Could not save folder history:'
        moveError = 'Could not move the file:'
        moveErrorTitle = 'Move error'
        chooseFolderTitle = 'Choose a folder'
        missingDestination = 'Enter a destination folder before clicking OK.'
        destinationMissing = 'The destination folder does not exist. Choose an existing folder.'
        sourceMissing = 'The file is no longer in Downloads.'
        sourceEqualsDest = 'Source and destination are the same. Use "Keep in Downloads".'
        sourceInUse = 'The file is still in use. Try again in a moment.'
        promptTitle = 'New download - choose destination'
        promptHeading = 'Download complete and ready to organize:'
        chooseNew = 'Choose a new folder or enter its path:'
        browse = 'Browse...'
        moveAbove = 'Move to folder above'
        keep = 'Keep in Downloads'
        recent = 'Last 12 destinations - click OK to move directly:'
        removeTip = 'Remove from history (does not delete the folder)'
        xHelp = 'X removes a saved path without deleting the folder. OK moves the file to that path.'
        destinationPicker = 'Choose where to save this download'
    }
    pt = @{
        appTitle = 'Organizador de Downloads'
        watched = 'Pasta monitorada:'
        languageLabel = 'Idioma:'
        changeFolder = 'Trocar pasta'
        openFolder = 'Abrir pasta'
        pause = 'Pausar'
        resume = 'Continuar'
        exit = 'Encerrar'
        showWindow = 'Mostrar janela'
        trayExit = 'Sair'
        pausedStatus = 'Pausado (novos arquivos serão analisados ao continuar)'
        activeStatus = 'Monitorando. Arquivos movidos nesta sessão: {0}'
        help = 'Fechar ou minimizar a janela mantém o programa ativo perto do relógio.'
        watchPicker = 'Selecione a pasta que contém os downloads do navegador'
        saveError = 'Não foi possível salvar o histórico de pastas:'
        moveError = 'Não foi possível mover o arquivo:'
        moveErrorTitle = 'Erro ao mover'
        chooseFolderTitle = 'Escolha uma pasta'
        missingDestination = 'Informe uma pasta de destino antes de clicar em OK.'
        destinationMissing = 'A pasta de destino não existe. Escolha uma pasta existente.'
        sourceMissing = 'O arquivo desapareceu da pasta Downloads.'
        sourceEqualsDest = 'A origem e o destino são a mesma pasta. Use "Manter em Downloads".'
        sourceInUse = 'O arquivo ainda está em uso. Tente mover novamente em alguns instantes.'
        promptTitle = 'Novo download - escolher destino'
        promptHeading = 'Arquivo baixado e pronto para organizar:'
        chooseNew = 'Escolher uma pasta nova ou informar o caminho:'
        browse = 'Procurar...'
        moveAbove = 'Mover para a pasta acima'
        keep = 'Manter em Downloads'
        recent = 'Últimos 12 destinos - clique em OK para mover diretamente:'
        removeTip = 'Remover do histórico (não apaga a pasta)'
        xHelp = 'X tira do histórico sem apagar a pasta. OK move o arquivo para o destino indicado.'
        destinationPicker = 'Escolha a pasta para guardar este download'
    }
    es = @{
        appTitle = 'Organizador de Descargas'
        watched = 'Carpeta supervisada:'
        languageLabel = 'Idioma:'
        changeFolder = 'Cambiar carpeta'
        openFolder = 'Abrir carpeta'
        pause = 'Pausar'
        resume = 'Reanudar'
        exit = 'Salir'
        showWindow = 'Mostrar ventana'
        trayExit = 'Salir'
        pausedStatus = 'En pausa (se revisarán los archivos nuevos al reanudar)'
        activeStatus = 'Supervisando. Archivos movidos en esta sesión: {0}'
        help = 'Cerrar o minimizar la ventana mantiene el programa activo junto al reloj.'
        watchPicker = 'Seleccione la carpeta donde su navegador guarda las descargas'
        saveError = 'No se pudo guardar el historial de carpetas:'
        moveError = 'No se pudo mover el archivo:'
        moveErrorTitle = 'Error al mover'
        chooseFolderTitle = 'Elija una carpeta'
        missingDestination = 'Introduzca una carpeta de destino antes de pulsar OK.'
        destinationMissing = 'La carpeta de destino no existe. Elija una carpeta existente.'
        sourceMissing = 'El archivo ya no se encuentra en Descargas.'
        sourceEqualsDest = 'La carpeta de origen y destino es la misma. Use "Mantener en Descargas".'
        sourceInUse = 'El archivo sigue en uso. Intente moverlo más tarde.'
        promptTitle = 'Nueva descarga - elegir destino'
        promptHeading = 'Descarga terminada y lista para organizar:'
        chooseNew = 'Elija una carpeta nueva o introduzca la ruta:'
        browse = 'Examinar...'
        moveAbove = 'Mover a la carpeta indicada'
        keep = 'Mantener en Descargas'
        recent = 'Últimos 12 destinos - pulse OK para mover directamente:'
        removeTip = 'Quitar del historial (no elimina la carpeta)'
        xHelp = 'X quita la ruta sin borrar la carpeta. OK mueve el archivo a esa ruta.'
        destinationPicker = 'Elija una carpeta para guardar esta descarga'
    }
}

function T([string]$key) {
    if ($script:translations[$script:language].ContainsKey($key)) {
        return [string]$script:translations[$script:language][$key]
    }
    return [string]$script:translations['en'][$key]
}

function Save-Config {
    try {
        $obj = [ordered]@{
            pastaMonitorada = $script:watchFolder
            pastasRecentes = $script:recentFolders.ToArray()
            idioma = $script:language
        }
        $json = ConvertTo-Json -InputObject $obj -Depth 4
        [System.IO.File]::WriteAllText($script:configFile, $json, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        [void][System.Windows.Forms.MessageBox]::Show(
            "$(T 'saveError')`n$($_.Exception.Message)",
            (T 'appTitle'), 'OK', 'Warning')
    }
}

function Add-RecentFolder([string]$folder) {
    for ($i = $script:recentFolders.Count - 1; $i -ge 0; $i--) {
        if ([string]::Equals($script:recentFolders[$i], $folder, [System.StringComparison]::OrdinalIgnoreCase)) {
            $script:recentFolders.RemoveAt($i)
        }
    }
    $script:recentFolders.Insert(0, $folder)
    while ($script:recentFolders.Count -gt 12) {
        $script:recentFolders.RemoveAt($script:recentFolders.Count - 1)
    }
    Save-Config
}

# Atualiza todas as 12 linhas apos excluir um caminho. As linhas seguintes
# sobem imediatamente e os campos que sobrarem ficam vazios.
function Refresh-RecentFolderRows {
    if ($null -eq $script:recentTextBoxes -or $null -eq $script:recentDeleteButtons) { return }
    for ($i = 0; $i -lt 12; $i++) {
        if ($i -lt $script:recentFolders.Count) {
            $script:recentTextBoxes[$i].Text = $script:recentFolders[$i]
            $script:recentDeleteButtons[$i].Enabled = $true
        } else {
            $script:recentTextBoxes[$i].Text = ''
            $script:recentDeleteButtons[$i].Enabled = $false
        }
    }
}

function Remove-RecentFolderAtIndex([int]$index) {
    if ($index -lt 0 -or $index -ge $script:recentFolders.Count) { return }
    # Somente tira o endereco da lista; nao apaga a pasta nem seu conteudo.
    $script:recentFolders.RemoveAt($index)
    Save-Config
    Refresh-RecentFolderRows
}

if (Test-Path -LiteralPath $script:configFile -PathType Leaf) {
    try {
        $saved = Get-Content -LiteralPath $script:configFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$saved.idioma -in @('en', 'pt', 'es')) {
            $script:language = [string]$saved.idioma
        }
        if ($saved.pastaMonitorada -and (Test-Path -LiteralPath ([string]$saved.pastaMonitorada) -PathType Container)) {
            $script:watchFolder = [string]$saved.pastaMonitorada
        }
        foreach ($folder in @($saved.pastasRecentes)) {
            if ($folder -and (Test-Path -LiteralPath ([string]$folder) -PathType Container)) {
                $unique = $true
                foreach ($old in $script:recentFolders) {
                    if ([string]::Equals($old, [string]$folder, [System.StringComparison]::OrdinalIgnoreCase)) {
                        $unique = $false
                        break
                    }
                }
                if ($unique -and $script:recentFolders.Count -lt 12) {
                    $script:recentFolders.Add([string]$folder)
                }
            }
        }
    } catch { } # Config corrompida: inicia com preferencias padrao.
}

if (-not (Test-Path -LiteralPath $script:watchFolder -PathType Container)) {
    [void][System.IO.Directory]::CreateDirectory($script:watchFolder)
}

function Is-TemporaryFile([string]$fileName) {
    # Chrome: .crdownload; outros navegadores/gerenciadores: .download, .part etc.
    return ($fileName -match '(?i)\.(crdownload|download|part|partial|tmp|opdownload|aria2)$')
}

function Initialize-Monitoring {
    $script:tracked = @{}
    $script:seen = @{}
    # Nao pergunta por arquivos que ja estavam na pasta antes de iniciar.
    foreach ($f in @(Get-ChildItem -LiteralPath $script:watchFolder -File -ErrorAction SilentlyContinue)) {
        if (-not (Is-TemporaryFile $f.Name)) {
            $script:seen[$f.FullName] = $true
        }
    }
}

function Is-ReadyToMove([string]$path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    $stream = $null
    try {
        # Se outro processo ainda esta escrevendo, adia a pergunta.
        $stream = [System.IO.File]::Open(
            $path, [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Find-FreeName([string]$destinationFolder, [string]$originalFileName) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($originalFileName)
    $extension = [System.IO.Path]::GetExtension($originalFileName)
    $target = Join-Path $destinationFolder $originalFileName
    $count = 1
    while (Test-Path -LiteralPath $target) {
        $target = Join-Path $destinationFolder ("{0} ({1}){2}" -f $base, $count, $extension)
        $count++
    }
    return $target
}

function Move-DownloadedFile([string]$sourcePath, [string]$destinationFolder) {
    if (-not (Test-Path -LiteralPath $destinationFolder -PathType Container)) {
        throw (T 'destinationMissing')
    }
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw (T 'sourceMissing')
    }
    $sourceDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::GetDirectoryName($sourcePath)).TrimEnd('\')
    $destinationDirectory = [System.IO.Path]::GetFullPath($destinationFolder).TrimEnd('\')
    if ([string]::Equals($sourceDirectory, $destinationDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw (T 'sourceEqualsDest')
    }
    if (-not (Is-ReadyToMove $sourcePath)) {
        throw (T 'sourceInUse')
    }
    $target = Find-FreeName $destinationFolder ([System.IO.Path]::GetFileName($sourcePath))
    Move-Item -LiteralPath $sourcePath -Destination $target -ErrorAction Stop
    return $target
}

function New-UiLabel([string]$text, [int]$x, [int]$y, [int]$w, [int]$h) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $text
    $label.Location = [System.Drawing.Point]::new($x, $y)
    $label.Size = [System.Drawing.Size]::new($w, $h)
    $label.AutoEllipsis = $true
    return $label
}

function Update-MainStatus {
    if ($script:paused) {
        $script:statusLabel.Text = T 'pausedStatus'
        $script:pauseButton.Text = T 'resume'
        $script:trayPauseItem.Text = T 'resume'
    } else {
        $script:statusLabel.Text = (T 'activeStatus') -f $script:movedCount
        $script:pauseButton.Text = T 'pause'
        $script:trayPauseItem.Text = T 'pause'
    }
    $script:folderLabel.Text = $script:watchFolder
    $script:folderTip.SetToolTip($script:folderLabel, $script:watchFolder)
}

function Update-UiLanguage {
    $script:mainForm.Text = T 'appTitle'
    $script:mainTitle.Text = T 'appTitle'
    $script:folderTitle.Text = T 'watched'
    $script:languageLabel.Text = T 'languageLabel'
    $script:changeButton.Text = T 'changeFolder'
    $script:openButton.Text = T 'openFolder'
    $script:exitButton.Text = T 'exit'
    $script:helpLabel.Text = T 'help'
    $script:trayShowItem.Text = T 'showWindow'
    $script:trayExitItem.Text = T 'trayExit'
    $script:trayIcon.Text = T 'appTitle'
    Update-MainStatus
}

function Toggle-Pause {
    $script:paused = -not $script:paused
    Update-MainStatus
}

function Show-MainWindow {
    $script:mainForm.Show()
    $script:mainForm.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $script:mainForm.Activate()
}

function Exit-Organizer {
    $script:exitRequested = $true
    $script:timer.Stop()
    $script:trayIcon.Visible = $false
    $script:mainForm.Close()
}

# Uma unica rotina para o botao principal e os 12 botoes OK das pastas antigas.
# Ao concluir, salva o destino no historico e fecha a janela deste download.
function Confirm-FileDestination([string]$destinationFolder) {
    $dest = $destinationFolder.Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($dest)) {
        [void][System.Windows.Forms.MessageBox]::Show(
            (T 'missingDestination'),
            (T 'chooseFolderTitle'), 'OK', 'Information')
        return
    }

    try {
        # Garante historico consistente para caminhos relativos com barras finais.
        $dest = [System.IO.Path]::GetFullPath($dest)
        $movedTo = Move-DownloadedFile $script:promptSourcePath $dest
        Add-RecentFolder $dest
        $script:movedCount++
        Update-MainStatus
        $script:promptForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $script:promptForm.Close()
    } catch {
        [void][System.Windows.Forms.MessageBox]::Show(
            "$(T 'moveError')`n$($_.Exception.Message)",
            (T 'moveErrorTitle'), 'OK', 'Warning')
    }
}

function Ask-ForDestination([string]$sourcePath) {
    $script:promptSourcePath = $sourcePath
    $script:promptForm = New-Object System.Windows.Forms.Form
    $script:promptForm.Text = (T 'promptTitle') + '  |  developed by hmnd-team'
    $workArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    # Em telas pequenas a janela ganha rolagem, sem ocultar os 12 campos.
    $windowHeight = [Math]::Min(708, [Math]::Max(420, $workArea.Height - 24))
    $windowWidth = [Math]::Min(790, [Math]::Max(680, $workArea.Width - 24))
    $script:promptForm.Size = [System.Drawing.Size]::new($windowWidth, $windowHeight)
    $script:promptForm.AutoScroll = $true
    $script:promptForm.StartPosition = 'CenterScreen'
    $script:promptForm.FormBorderStyle = 'FixedDialog'
    $script:promptForm.MaximizeBox = $false
    $script:promptForm.TopMost = $true
    $script:promptForm.ShowInTaskbar = $true
    $script:promptForm.Font = [System.Drawing.Font]::new('Segoe UI', 9)

    $heading = New-UiLabel (T 'promptHeading') 18 14 735 24
    $heading.Font = [System.Drawing.Font]::new('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $script:promptForm.Controls.Add($heading)

    $nameLabel = New-UiLabel ([System.IO.Path]::GetFileName($sourcePath)) 18 44 735 44
    $nameLabel.Font = [System.Drawing.Font]::new('Segoe UI', 10)
    $script:promptForm.Controls.Add($nameLabel)

    $destinationLabel = New-UiLabel (T 'chooseNew') 18 95 735 22
    $script:promptForm.Controls.Add($destinationLabel)

    $script:promptDestination = New-Object System.Windows.Forms.TextBox
    $script:promptDestination.Location = [System.Drawing.Point]::new(18, 122)
    $script:promptDestination.Size = [System.Drawing.Size]::new(625, 26)
    $script:promptForm.Controls.Add($script:promptDestination)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = T 'browse'
    $browseButton.Location = [System.Drawing.Point]::new(650, 120)
    $browseButton.Size = [System.Drawing.Size]::new(114, 30)
    $script:promptForm.Controls.Add($browseButton)

    $moveButton = New-Object System.Windows.Forms.Button
    $moveButton.Text = T 'moveAbove'
    $moveButton.Location = [System.Drawing.Point]::new(18, 162)
    $moveButton.Size = [System.Drawing.Size]::new(211, 35)
    $moveButton.BackColor = [System.Drawing.Color]::FromArgb(221, 238, 255)
    $script:promptForm.Controls.Add($moveButton)

    $keepButton = New-Object System.Windows.Forms.Button
    $keepButton.Text = T 'keep'
    $keepButton.Location = [System.Drawing.Point]::new(240, 162)
    $keepButton.Size = [System.Drawing.Size]::new(196, 35)
    $script:promptForm.Controls.Add($keepButton)
    $script:promptForm.AcceptButton = $moveButton
    $script:promptForm.CancelButton = $keepButton

    $recentLabel = New-UiLabel (T 'recent') 18 214 735 25
    $recentLabel.Font = [System.Drawing.Font]::new('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
    $script:promptForm.Controls.Add($recentLabel)

    # Cada linha: [X] [numero] [caminho editavel] [OK]. O X remove apenas
    # o item dessa posicao do historico; OK move o download para o caminho.
    $script:recentTextBoxes = New-Object 'System.Collections.Generic.List[System.Windows.Forms.TextBox]'
    $script:recentDeleteButtons = New-Object 'System.Collections.Generic.List[System.Windows.Forms.Button]'
    $deleteToolTip = New-Object System.Windows.Forms.ToolTip
    for ($i = 0; $i -lt 12; $i++) {
        $y = 246 + ($i * 31)

        $deleteButton = New-Object System.Windows.Forms.Button
        $deleteButton.Text = 'X'
        $deleteButton.Location = [System.Drawing.Point]::new(18, ($y - 1))
        $deleteButton.Size = [System.Drawing.Size]::new(27, 28)
        $deleteButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $deleteButton.FlatAppearance.BorderSize = 1
        $deleteButton.ForeColor = [System.Drawing.Color]::Firebrick
        # Tag guarda o indice da lista, nao o texto editavel do campo.
        $deleteButton.Tag = [int]$i
        $deleteButton.Add_Click({
            param($sender, $eventArgs)
            Remove-RecentFolderAtIndex ([int]$sender.Tag)
        })
        $script:promptForm.Controls.Add($deleteButton)
        $script:recentDeleteButtons.Add($deleteButton)
        $deleteToolTip.SetToolTip($deleteButton, (T 'removeTip'))

        $numberLabel = New-UiLabel ('{0:00}' -f ($i + 1)) 50 ($y + 4) 27 23
        $script:promptForm.Controls.Add($numberLabel)

        $rowField = New-Object System.Windows.Forms.TextBox
        $rowField.Location = [System.Drawing.Point]::new(79, $y)
        $rowField.Size = [System.Drawing.Size]::new(602, 25)
        $script:promptForm.Controls.Add($rowField)
        $script:recentTextBoxes.Add($rowField)

        $rowButton = New-Object System.Windows.Forms.Button
        $rowButton.Text = 'OK'
        $rowButton.Location = [System.Drawing.Point]::new(688, ($y - 1))
        $rowButton.Size = [System.Drawing.Size]::new(76, 28)
        # Tag associa cada botao ao respectivo campo, sem capturar $i no evento.
        $rowButton.Tag = $rowField
        $rowButton.Add_Click({
            param($sender, $eventArgs)
            $row = $sender.Tag
            Confirm-FileDestination ([string]$row.Text)
        })
        $script:promptForm.Controls.Add($rowButton)
    }
    Refresh-RecentFolderRows

    $tip = New-UiLabel (T 'xHelp') 18 626 735 20
    $tip.ForeColor = [System.Drawing.Color]::DimGray
    $script:promptForm.Controls.Add($tip)

    $browseButton.Add_Click({
        $picker = New-Object System.Windows.Forms.FolderBrowserDialog
        $picker.Description = T 'destinationPicker'
        if (-not [string]::IsNullOrWhiteSpace($script:promptDestination.Text) -and
            (Test-Path -LiteralPath $script:promptDestination.Text -PathType Container)) {
            $picker.SelectedPath = $script:promptDestination.Text
        } else {
            $picker.SelectedPath = $script:watchFolder
        }
        if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:promptDestination.Text = $picker.SelectedPath
        }
        $picker.Dispose()
    })
    $moveButton.Add_Click({
        Confirm-FileDestination $script:promptDestination.Text
    })
    $keepButton.Add_Click({
        $script:promptForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $script:promptForm.Close()
    })

    try { [void]$script:promptForm.ShowDialog() }
    finally {
        $deleteToolTip.Dispose()
        $script:recentTextBoxes = $null
        $script:recentDeleteButtons = $null
        $script:promptForm.Dispose()
        $script:promptForm = $null
    }
}

# Janela de controle (pode ser minimizada para a area de notificacao).
$script:mainForm = New-Object System.Windows.Forms.Form
$script:mainForm.Text = T 'appTitle'
$script:mainForm.Size = [System.Drawing.Size]::new(790, 257)
$script:mainForm.StartPosition = 'CenterScreen'
$script:mainForm.FormBorderStyle = 'FixedDialog'
$script:mainForm.MaximizeBox = $false
$script:mainForm.Font = [System.Drawing.Font]::new('Segoe UI', 9)

$script:mainTitle = New-UiLabel (T 'appTitle') 18 17 475 31
$script:mainTitle.Font = [System.Drawing.Font]::new('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$script:mainForm.Controls.Add($script:mainTitle)

$script:languageLabel = New-UiLabel (T 'languageLabel') 520 19 85 25
$script:mainForm.Controls.Add($script:languageLabel)
$script:languageBox = New-Object System.Windows.Forms.ComboBox
$script:languageBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:languageBox.Location = [System.Drawing.Point]::new(607, 16)
$script:languageBox.Size = [System.Drawing.Size]::new(154, 29)
[void]$script:languageBox.Items.AddRange([object[]]@('English', 'Português', 'Español'))
$script:languageBox.SelectedIndex = switch ($script:language) { 'pt' { 1 } 'es' { 2 } default { 0 } }
$script:mainForm.Controls.Add($script:languageBox)

$script:folderTitle = New-UiLabel (T 'watched') 18 57 710 21
$script:mainForm.Controls.Add($script:folderTitle)
$script:folderLabel = New-UiLabel $script:watchFolder 18 78 745 25
$script:folderLabel.Font = [System.Drawing.Font]::new('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$script:mainForm.Controls.Add($script:folderLabel)
$script:folderTip = New-Object System.Windows.Forms.ToolTip

$script:changeButton = New-Object System.Windows.Forms.Button
$script:changeButton.Text = T 'changeFolder'
$script:changeButton.Location = [System.Drawing.Point]::new(18, 112)
$script:changeButton.Size = [System.Drawing.Size]::new(160, 33)
$script:mainForm.Controls.Add($script:changeButton)

$script:openButton = New-Object System.Windows.Forms.Button
$script:openButton.Text = T 'openFolder'
$script:openButton.Location = [System.Drawing.Point]::new(191, 112)
$script:openButton.Size = [System.Drawing.Size]::new(160, 33)
$script:mainForm.Controls.Add($script:openButton)

$script:pauseButton = New-Object System.Windows.Forms.Button
$script:pauseButton.Text = T 'pause'
$script:pauseButton.Location = [System.Drawing.Point]::new(364, 112)
$script:pauseButton.Size = [System.Drawing.Size]::new(160, 33)
$script:mainForm.Controls.Add($script:pauseButton)

$script:exitButton = New-Object System.Windows.Forms.Button
$script:exitButton.Text = T 'exit'
$script:exitButton.Location = [System.Drawing.Point]::new(537, 112)
$script:exitButton.Size = [System.Drawing.Size]::new(160, 33)
$script:mainForm.Controls.Add($script:exitButton)

$script:statusLabel = New-UiLabel '' 18 160 745 23
$script:mainForm.Controls.Add($script:statusLabel)
$script:helpLabel = New-UiLabel (T 'help') 18 188 745 22
$script:helpLabel.ForeColor = [System.Drawing.Color]::DimGray
$script:mainForm.Controls.Add($script:helpLabel)

$script:trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$script:trayShowItem = $script:trayMenu.Items.Add((T 'showWindow'))
$script:trayPauseItem = $script:trayMenu.Items.Add((T 'pause'))
$script:trayExitItem = $script:trayMenu.Items.Add((T 'trayExit'))
$script:trayIcon = New-Object System.Windows.Forms.NotifyIcon
$script:trayIcon.Icon = [System.Drawing.SystemIcons]::Application
$script:trayIcon.Text = T 'appTitle'
$script:trayIcon.ContextMenuStrip = $script:trayMenu
$script:trayIcon.Visible = $true

$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = $script:pollIntervalMs

$script:changeButton.Add_Click({
    $picker = New-Object System.Windows.Forms.FolderBrowserDialog
    $picker.Description = T 'watchPicker'
    $picker.SelectedPath = $script:watchFolder
    if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:watchFolder = $picker.SelectedPath
        Initialize-Monitoring
        Save-Config
        Update-MainStatus
    }
    $picker.Dispose()
})
$script:openButton.Add_Click({
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $script:watchFolder + '"')
})
$script:pauseButton.Add_Click({ Toggle-Pause })
$script:exitButton.Add_Click({ Exit-Organizer })
$script:trayShowItem.Add_Click({ Show-MainWindow })
$script:trayPauseItem.Add_Click({ Toggle-Pause })
$script:trayExitItem.Add_Click({ Exit-Organizer })
$script:trayIcon.Add_DoubleClick({ Show-MainWindow })

# Changing language updates the visible interface immediately and persists to config.json.
$script:languageBox.Add_SelectedIndexChanged({
    $chosen = switch ($script:languageBox.SelectedIndex) { 1 { 'pt' } 2 { 'es' } default { 'en' } }
    if ($script:language -ne $chosen) {
        $script:language = $chosen
        Update-UiLanguage
        Save-Config
    }
})

$script:mainForm.Add_Resize({
    if ($script:mainForm.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        $script:mainForm.Hide()
    }
})
$script:mainForm.Add_FormClosing({
    param($sender, $e)
    if (-not $script:exitRequested -and $e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $script:mainForm.Hide()
    }
})

$script:timer.Add_Tick({
    if ($script:paused -or $script:isPromptOpen) { return }
    if (-not (Test-Path -LiteralPath $script:watchFolder -PathType Container)) { return }
    $now = [System.DateTime]::UtcNow
    try {
        $files = @(Get-ChildItem -LiteralPath $script:watchFolder -File -ErrorAction SilentlyContinue |
            Sort-Object -Property CreationTimeUtc)
        $present = @{}
        foreach ($file in $files) { $present[$file.FullName] = $true }
        # Um nome de arquivo pode ser reutilizado depois que o original foi apagado ou movido.
        foreach ($oldPath in @($script:seen.Keys)) {
            if (-not $present.ContainsKey($oldPath)) { [void]$script:seen.Remove($oldPath) }
        }
        foreach ($file in $files) {
            $path = $file.FullName
            if ((Is-TemporaryFile $file.Name) -or $script:seen.ContainsKey($path)) { continue }
            if (-not $script:tracked.ContainsKey($path)) {
                $script:tracked[$path] = @{
                    size = [long]$file.Length
                    writeTicks = $file.LastWriteTimeUtc.Ticks
                    stableSince = $now
                }
                continue
            }
            $state = $script:tracked[$path]
            if ($state.size -ne $file.Length -or $state.writeTicks -ne $file.LastWriteTimeUtc.Ticks) {
                $state.size = [long]$file.Length
                $state.writeTicks = $file.LastWriteTimeUtc.Ticks
                $state.stableSince = $now
                continue
            }
            if (($now - $state.stableSince).TotalSeconds -lt $script:stableSeconds) { continue }
            if (($now - $file.LastWriteTimeUtc).TotalSeconds -lt 2) { continue }
            if ((Test-Path -LiteralPath ($path + '.crdownload')) -or
                (Test-Path -LiteralPath ($path + '.download'))) { continue }
            if (-not (Is-ReadyToMove $path)) { continue }

            # Marca antes da caixa de dialogo: evitar perguntas repetidas caso opte por manter.
            $script:seen[$path] = $true
            [void]$script:tracked.Remove($path)
            $script:isPromptOpen = $true
            $script:timer.Stop()
            try { Ask-ForDestination $path }
            finally {
                $script:isPromptOpen = $false
                if (-not $script:exitRequested) { $script:timer.Start() }
            }
            break
        }
        foreach ($trackedPath in @($script:tracked.Keys)) {
            if (-not (Test-Path -LiteralPath $trackedPath -PathType Leaf)) {
                [void]$script:tracked.Remove($trackedPath)
            }
        }
    } catch {
        # Um download pode desaparecer/ser renomeado entre duas verificacoes.
        # Nao interrompe o programa; proxima verificacao continua.
    }
})

Initialize-Monitoring
Update-UiLanguage
$script:timer.Start()
try {
    [System.Windows.Forms.Application]::Run($script:mainForm)
} finally {
    $script:timer.Stop()
    $script:trayIcon.Visible = $false
    $script:trayIcon.Dispose()
    $script:trayMenu.Dispose()
    $script:timer.Dispose()
    $script:mainForm.Dispose()
}
