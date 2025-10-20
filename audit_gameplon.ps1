<#
.SYNOPSIS
    Script d'audit automatique du parc informatique Gameplon
    
.DESCRIPTION
    Ce script collecte automatiquement les informations materielles, 
    logicielles et de securite d'un poste Windows.
    Export au format CSV pour consolidation dans Excel.
    
.AUTHOR
    Brief Gameplon - Formation AIS
    
.DATE
    20/10/2025
    
.VERSION
    1.0
#>

# ==============================================================================
# CONFIGURATION INITIALE
# ==============================================================================

# Continuer en cas d'erreur non critique
$ErrorActionPreference = "Continue"

# Recuperer la date du jour au format francais
$DateAudit = Get-Date -Format "dd/MM/yyyy HH:mm"

# Definir les chemins d'export
$CheminExport = "C:\Users\$env:USERNAME\Documents\Brief_Audit_Gameplon\Exports"

# Creer le dossier Exports s'il n'existe pas
if (-not (Test-Path $CheminExport)) {
    New-Item -Path $CheminExport -ItemType Directory -Force | Out-Null
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AUDIT GAMEPLON - Collecte en cours..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# SECTION 1 : INFORMATIONS SYSTEME DE BASE
# ==============================================================================

Write-Host "[1/7] Collecte des informations systeme..." -ForegroundColor Yellow

# Recuperer les informations systeme principales
$InfosSysteme = Get-ComputerInfo

# Nom du poste
$NomPoste = $env:COMPUTERNAME

# Nom de l'utilisateur connecte
$NomUtilisateur = $env:USERNAME

# Type et version de Windows
$TypeWindows = $InfosSysteme.WindowsProductName
$VersionWindows = $InfosSysteme.WindowsVersion
$BuildWindows = $InfosSysteme.OsBuildNumber

# Numero de serie materiel (UUID)
try {
    $NumeroSerie = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
} catch {
    $NumeroSerie = "N/A"
}

Write-Host "  [OK] Nom du poste : $NomPoste" -ForegroundColor Green
Write-Host "  [OK] Utilisateur : $NomUtilisateur" -ForegroundColor Green
Write-Host "  [OK] Windows : $TypeWindows" -ForegroundColor Green

# ==============================================================================
# SECTION 2 : PROCESSEUR ET MEMOIRE
# ==============================================================================

Write-Host "[2/7] Analyse du processeur et de la memoire..." -ForegroundColor Yellow

# Informations processeur
$Processeur = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
$NomProcesseur = $Processeur.Name.Trim()
$FrequenceGHz = [math]::Round($Processeur.MaxClockSpeed / 1000, 2)
$NombreCoeurs = $Processeur.NumberOfCores
$NombreThreads = $Processeur.NumberOfLogicalProcessors

# Informations memoire RAM
$MemoireTotale = Get-WmiObject -Class Win32_ComputerSystem
$RAMGo = [math]::Round($MemoireTotale.TotalPhysicalMemory / 1GB, 0)

# Type de RAM (DDR3, DDR4, DDR5)
try {
    $TypeRAM = (Get-WmiObject -Class Win32_PhysicalMemory | Select-Object -First 1).SMBIOSMemoryType
    $TypeRAMTexte = switch ($TypeRAM) {
        20 { "DDR" }
        21 { "DDR2" }
        24 { "DDR3" }
        26 { "DDR4" }
        34 { "DDR5" }
        default { "DDR4" }
    }
} catch {
    $TypeRAMTexte = "DDR4"
}

Write-Host "  [OK] Processeur : $NomProcesseur ($NombreCoeurs coeurs)" -ForegroundColor Green
Write-Host "  [OK] RAM : $RAMGo Go ($TypeRAMTexte)" -ForegroundColor Green

# ==============================================================================
# SECTION 3 : CARTE GRAPHIQUE
# ==============================================================================

Write-Host "[3/7] Analyse de la carte graphique..." -ForegroundColor Yellow

# Informations GPU
$CarteGraphique = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" -and $_.Name -notlike "*Remote*" } | Select-Object -First 1

if ($CarteGraphique) {
    $NomGPU = $CarteGraphique.Name
    
    # VRAM en Go
    if ($CarteGraphique.AdapterRAM -gt 0) {
        $VRAMGo = [math]::Round($CarteGraphique.AdapterRAM / 1GB, 0)
    } else {
        $VRAMGo = 1
    }
    
    $VersionPilote = $CarteGraphique.DriverVersion
    
    Write-Host "  [OK] GPU : $NomGPU ($VRAMGo Go)" -ForegroundColor Green
} else {
    $NomGPU = "Carte graphique integree"
    $VRAMGo = 0
    $VersionPilote = "N/A"
    Write-Host "  [OK] GPU : $NomGPU" -ForegroundColor Yellow
}

# ==============================================================================
# SECTION 4 : DISQUES
# ==============================================================================

Write-Host "[4/7] Analyse des disques..." -ForegroundColor Yellow

# Recuperer tous les disques physiques
$DisquesPhysiques = Get-PhysicalDisk
$NombreDisques = $DisquesPhysiques.Count

# Type de disque dominant (SSD ou HDD)
$TypesDisques = $DisquesPhysiques | Select-Object -ExpandProperty MediaType
if ($TypesDisques -contains "SSD") {
    $TypeDisque = "SSD"
} elseif ($TypesDisques -contains "NVMe") {
    $TypeDisque = "NVMe"
} else {
    $TypeDisque = "HDD"
}

# Capacite totale et espace libre du disque C:
$DisqueC = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$CapaciteTotaleGo = [math]::Round($DisqueC.Size / 1GB, 0)
$EspaceLibreGo = [math]::Round($DisqueC.FreeSpace / 1GB, 0)

Write-Host "  [OK] Disques : $NombreDisques detecte(s) - Type : $TypeDisque" -ForegroundColor Green
Write-Host "  [OK] Disque C: : $CapaciteTotaleGo Go (Libre : $EspaceLibreGo Go)" -ForegroundColor Green

# ==============================================================================
# SECTION 5 : RESEAU
# ==============================================================================

Write-Host "[5/7] Analyse du reseau..." -ForegroundColor Yellow

# Recuperer la carte reseau principale (celle qui a une IP)
$CarteReseau = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if ($CarteReseau) {
    $ChipsetReseau = $CarteReseau.InterfaceDescription
    $AdresseMAC = $CarteReseau.MacAddress
    
    # Recuperer l'adresse IP
    $ConfigIP = Get-NetIPAddress -InterfaceIndex $CarteReseau.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ConfigIP) {
        $AdresseIP = $ConfigIP.IPAddress
    } else {
        $AdresseIP = "Non assignee"
    }
    
    Write-Host "  [OK] Reseau : $ChipsetReseau" -ForegroundColor Green
    Write-Host "  [OK] IP : $AdresseIP | MAC : $AdresseMAC" -ForegroundColor Green
} else {
    $ChipsetReseau = "Non detecte"
    $AdresseMAC = "00:00:00:00:00:00"
    $AdresseIP = "N/A"
    Write-Host "  [WARN] Reseau : Aucune carte active" -ForegroundColor Yellow
}

# Wi-Fi et Bluetooth
$WiFiActif = if (Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*Wi-Fi*" -or $_.InterfaceDescription -like "*Wireless*" }) { "Oui" } else { "Non" }
$BluetoothActif = if (Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Bluetooth*" -and $_.Status -eq "OK" }) { "Oui" } else { "Non" }

# ==============================================================================
# SECTION 6 : SECURITE (TPM, SECURE BOOT, BITLOCKER)
# ==============================================================================

Write-Host "[6/7] Verification de la securite..." -ForegroundColor Yellow

# TPM (Trusted Platform Module)
try {
    $TPM = Get-Tpm -ErrorAction Stop
    $TPMActif = if ($TPM.TpmPresent -and $TPM.TpmEnabled) { "Oui" } else { "Non" }
} catch {
    $TPMActif = "Non"
}

# Secure Boot
try {
    $SecureBootActif = if (Confirm-SecureBootUEFI) { "Oui" } else { "Non" }
} catch {
    $SecureBootActif = "Non"
}

# BitLocker
$BitLockerActif = if ((Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue).ProtectionStatus -eq "On") { "Oui" } else { "Non" }

Write-Host "  [OK] TPM : $TPMActif | Secure Boot : $SecureBootActif | BitLocker : $BitLockerActif" -ForegroundColor Green

# ==============================================================================
# SECTION 7 : LOGICIELS ET SECURITE
# ==============================================================================

Write-Host "[7/7] Analyse des logiciels et securite..." -ForegroundColor Yellow

# Antivirus actif
try {
    $Antivirus = Get-MpComputerStatus -ErrorAction Stop
    $AntivirusActif = if ($Antivirus.AntivirusEnabled) { "Windows Defender actif" } else { "Desactive" }
} catch {
    $AntivirusActif = "Non detecte"
}

# Pare-feu
try {
    $PareFeu = Get-NetFirewallProfile -Profile Domain,Public,Private
    $PareFeuActif = if ($PareFeu | Where-Object { $_.Enabled -eq $true }) { "Oui" } else { "Non" }
} catch {
    $PareFeuActif = "Non"
}

# Derniere mise a jour Windows
try {
    $DerniereMiseAJour = (Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1).InstalledOn
    $DerniereMiseAJourTexte = $DerniereMiseAJour.ToString("dd/MM/yyyy")
} catch {
    $DerniereMiseAJourTexte = "Inconnue"
}

# UAC (User Account Control)
$UACActif = if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").EnableLUA -eq 1) { "Oui" } else { "Non" }

# Navigateurs installes
$Navigateurs = @()
if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") { $Navigateurs += "Chrome" }
if (Test-Path "C:\Program Files\Mozilla Firefox\firefox.exe") { $Navigateurs += "Firefox" }
if (Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe") { $Navigateurs += "Edge" }
$NavigateurTexte = if ($Navigateurs.Count -gt 0) { $Navigateurs -join ", " } else { "Edge (par defaut)" }

# Versions logiciels gaming
$VersionSteam = if (Test-Path "C:\Program Files (x86)\Steam\steam.exe") { "Installe" } else { "Non installe" }
$VersionOBS = if (Test-Path "C:\Program Files\obs-studio\bin\64bit\obs64.exe") { "Installe" } else { "Non installe" }

Write-Host "  [OK] Antivirus : $AntivirusActif" -ForegroundColor Green
Write-Host "  [OK] Pare-feu : $PareFeuActif | UAC : $UACActif" -ForegroundColor Green
Write-Host "  [OK] Derniere MaJ : $DerniereMiseAJourTexte" -ForegroundColor Green

# ==============================================================================
# CALCUL NIVEAU DE CONFORMITE
# ==============================================================================

$NoteConformite = 0

# Criteres de notation (sur 5)
if ($AntivirusActif -ne "Desactive") { $NoteConformite += 1 }
if ($PareFeuActif -eq "Oui") { $NoteConformite += 1 }
if ($TPMActif -eq "Oui") { $NoteConformite += 1 }
if ($BitLockerActif -eq "Oui") { $NoteConformite += 1 }
if ($UACActif -eq "Oui") { $NoteConformite += 1 }

# ==============================================================================
# EXPORT CSV - INVENTAIRE MATERIEL (Feuille 1)
# ==============================================================================

Write-Host ""
Write-Host "Generation du fichier CSV Materiel..." -ForegroundColor Cyan

$InventaireMateriel = [PSCustomObject]@{
    "Nom du poste" = $NomPoste
    "Nom d'utilisateur" = $NomUtilisateur
    "Date de l'audit" = $DateAudit
    "Type de Windows" = $TypeWindows
    "Version de Windows" = $VersionWindows
    "Build / Numero de version" = $BuildWindows
    "Numero de serie materiel" = $NumeroSerie
    "Processeur (marque / modele)" = $NomProcesseur
    "Frequence (GHz)" = $FrequenceGHz
    "Nombre de coeurs physiques" = $NombreCoeurs
    "Nombre de threads logiques" = $NombreThreads
    "Memoire vive (Go)" = $RAMGo
    "Type de RAM" = $TypeRAMTexte
    "Carte graphique principale" = $NomGPU
    "VRAM Carte Graphique" = $VRAMGo
    "Version du pilote Graphique" = $VersionPilote
    "Nombre de disques detectes" = $NombreDisques
    "Type de disque" = $TypeDisque
    "Capacite totale (Go)" = $CapaciteTotaleGo
    "Espace libre (Go)" = $EspaceLibreGo
    "Chipset reseau" = $ChipsetReseau
    "Adresse MAC" = $AdresseMAC
    "Adresse IP locale" = $AdresseIP
    "Connectivite Wi-Fi" = $WiFiActif
    "Bluetooth active" = $BluetoothActif
    "TPM active" = $TPMActif
    "Secure Boot" = $SecureBootActif
    "BitLocker actif" = $BitLockerActif
}

$FichierMateriel = "$CheminExport\$NomPoste`_Inventaire_Materiel.csv"
$InventaireMateriel | Export-Csv -Path $FichierMateriel -NoTypeInformation -Encoding UTF8 -Delimiter ";"

Write-Host "  [OK] Fichier cree : $FichierMateriel" -ForegroundColor Green

# ==============================================================================
# EXPORT CSV - INVENTAIRE LOGICIEL ET SECURITE (Feuille 2)
# ==============================================================================

Write-Host "Generation du fichier CSV Logiciel..." -ForegroundColor Cyan

$InventaireLogiciel = [PSCustomObject]@{
    "Nom du poste" = $NomPoste
    "Antivirus actif" = $AntivirusActif
    "Pare-feu active" = $PareFeuActif
    "Derniere mise a jour Windows" = $DerniereMiseAJourTexte
    "UAC actif" = $UACActif
    "Navigateur Web" = $NavigateurTexte
    "Version Nav Web" = "N/A"
    "Version Steam" = $VersionSteam
    "Version OBS Studio" = $VersionOBS
    "Taches planifiees anormales" = "A verifier manuellement"
    "Processus lourds identifies" = "A verifier manuellement"
    "Observations" = ""
    "Niveau de conformite (sur 5)" = $NoteConformite
}

$FichierLogiciel = "$CheminExport\$NomPoste`_Inventaire_Logiciel.csv"
$InventaireLogiciel | Export-Csv -Path $FichierLogiciel -NoTypeInformation -Encoding UTF8 -Delimiter ";"

Write-Host "  [OK] Fichier cree : $FichierLogiciel" -ForegroundColor Green

# ==============================================================================
# RESUME FINAL
# ==============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  AUDIT TERMINE AVEC SUCCES !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resume :" -ForegroundColor Cyan
Write-Host "  - Poste audite : $NomPoste" -ForegroundColor White
Write-Host "  - Note de conformite : $NoteConformite/5" -ForegroundColor White
Write-Host "  - Fichiers generes : 2 CSV" -ForegroundColor White
Write-Host ""
Write-Host "Emplacement des exports :" -ForegroundColor Cyan
Write-Host "  $CheminExport" -ForegroundColor White
Write-Host ""
Write-Host "Prochaine etape : Importer les CSV dans Excel" -ForegroundColor Yellow
Write-Host ""