# 🎮 Audit Gameplon - Script d'Audit Automatique

Script PowerShell pour l'audit automatique du parc informatique de l'équipe e-sport **Gameplon**.

## 📋 Description

Ce script collecte automatiquement les informations matérielles, logicielles et de sécurité d'un poste Windows et génère des exports CSV pour analyse.

**Développé dans le cadre de la formation AIS (Administrateur Infrastructure et Sécurité).**

## 🎯 Fonctionnalités

Le script collecte les informations suivantes :

### 🖥️ Matériel
- Processeur (modèle, fréquence, nombre de cœurs)
- Mémoire RAM (capacité, type DDR)
- Carte graphique (modèle, VRAM, version pilote)
- Disques (type SSD/HDD/NVMe, capacité, espace libre)
- Réseau (chipset, adresse MAC, IP locale)

### 🔐 Sécurité
- État TPM (Trusted Platform Module)
- Secure Boot (activé/désactivé)
- BitLocker (actif/inactif)
- Antivirus (état et type)
- Pare-feu Windows
- UAC (User Account Control)
- Dernière mise à jour Windows

### 💻 Logiciels
- Navigateurs installés
- Steam (installé/non installé)
- OBS Studio (installé/non installé)
- Note de conformité (sur 5)

## 📊 Exports générés

Le script génère **2 fichiers CSV** :
- `[NomPoste]_Inventaire_Materiel.csv` : Données matérielles
- `[NomPoste]_Inventaire_Logiciel.csv` : Données logicielles et sécurité

## 🚀 Utilisation

### Prérequis
- Windows 10/11 Pro
- PowerShell 5.1 ou supérieur
- Droits administrateur

### Exécution

1. **Télécharger le script** : `audit_gameplon.ps1`

2. **Ouvrir PowerShell en Administrateur**

3. **Autoriser l'exécution de scripts** (si nécessaire) :
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

4. **Naviguer vers le dossier du script** :
```powershell
cd C:\Chemin\Vers\Le\Script
```

5. **Exécuter le script** :
```powershell
.\audit_gameplon.ps1
```

Les fichiers CSV seront créés dans le dossier `Exports`.

## 📂 Structure des exports

### Inventaire Matériel (28 colonnes)
Nom du poste, utilisateur, date, Windows, processeur, RAM, GPU, disques, réseau, TPM, Secure Boot, BitLocker...

### Inventaire Logiciel (13 colonnes)
Nom du poste, antivirus, pare-feu, dernière mise à jour, UAC, navigateurs, Steam, OBS, note de conformité...

## 📈 Note de conformité

Le script calcule automatiquement une note de conformité sur 5 points basée sur :
- ✅ Antivirus actif (+1)
- ✅ Pare-feu actif (+1)
- ✅ TPM activé (+1)
- ✅ BitLocker actif (+1)
- ✅ UAC actif (+1)

## 🎓 Contexte du projet

**Brief : Audit initial et hygiène de base**

L'équipe e-sport Gameplon, basée à Lyon, utilise 16 PC portables gaming pour les entraînements et tournois. La maintenance du parc a été négligée, nécessitant un audit complet pour identifier les non-conformités et améliorer l'hygiène numérique.

## 👤 Auteur

Formation **AIS** (Administrateur Infrastructure et Sécurité)  
Brief 1.1.1 - Octobre 2025

## 📄 Licence

MIT License - Libre d'utilisation et de modification
