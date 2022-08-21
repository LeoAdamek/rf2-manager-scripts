function Download-Rf2-Mod {
    param ( $ModId, $InstallDir )
    # Download the mod
    G:\Steam\steamcmd.exe +force_install_dir $InstallDir\Workshop +login anonymous +workshop_download_item 365960 $ModId +quit

    # Find any RFCMP files
    $cmpFiles = Get-ChildItem -File -Path $InstallDir\Workshop\steamapps\workshop\content\365960\$ModId -Filter '*.rfcmp'

    # Move them to packages
    Write-Output "Found ${cmpFiles.Length} RFCMP files..."
    Write-Output "Copying rfcmp files to packages dir"
    Move-Item -Path $cmpFiles.FullName -Destination $InstallDir\Packages

    Write-Output "Deleting mod download"

    if (Test-Path $InstallDir\Workshop\steamapps\workshop\content\365960\$ModID) {
        Remove-Item -Path $InstallDir\Workshop\steamapps\workshop\content\365960\$ModID -Recurse -Force
    }
    
    if (Test-Path $InstallDir\Workshop\steamapps\workshop\downloads\365960\$ModID) {
        Remove-Item -Path $InstallDir\Workshop\steamapps\workshop\downloads\365960\$ModID -Recurse -Force
    }
    
}

function Add-Mod-DBEntry {
    param ( [string]$ModId, [string]$Path, [string]$Name, [bool]$DLC )

    Import-Module -ErrorAction Stop PowerHTML

    if (-not(Test-Path -Path $Path -PathType Leaf)) {
        Initialize-Mod-DB -Path $Path
    }

    $doc = [XML](Get-Content -Path $Path)
    $mods = (Select-Xml -XPath '/mods' -Xml $doc).Node

    $mod = $doc.CreateElement('mod')

    if ($dlc) {
        $mod.SetAttribute('dlc', "yes")
    }

    $id = $doc.CreateElement('id')
    $id.AppendChild( $doc.CreateTextNode($ModId) )
    $mod.AppendChild( $id )
    
    $url = "https://steamcommunity.com/sharedfiles/filedetails/?id=$ModId"

    $urlNode = $doc.CreateElement('url')
    $urlNode.AppendChild($doc.CreateTextNode($url))
    $mod.AppendChild($urlNode)

    $n = $doc.CreateElement('name')
    if ( $Name ) {
        $n.AppendChild($doc.CreateTextNode($Name))
    } else {
        $modHTML = ConvertFrom-Html (Invoke-WebRequest -Uri $url -UseBasicParsing)
        
        $title = $modHTML.SelectNodes('//div') | Where-Object {
            $_.GetAttributeValue('class', 'none') -eq 'workshopItemTitle'
        }[0]
        $n.AppendChild($doc.CreateTextNode($title.InnerText))
    }

    $mod.AppendChild($n)

    $timestamp = $doc.CreateElement('added')
    $timestamp.AppendChild($doc.CreateTextNode( (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') ))
    $mod.AppendChild($timestamp)

    $mods.AppendChild($mod)

    $doc.Save($Path)
}

function Initialize-Mod-DB {
    param ( $Path )


    $doc = [System.Xml.XmlDocument]::new()
    $doc.AppendChild($doc.CreateElement('mods'))
    
    $doc.Save($Path)
}

# Ensure HTML parser is installed
if (-not (Get-Module -ErrorAction Ignore -ListAvailable PowerHTML)) {
    Write-Verbose "Installing PowerHTML"
    Install-Module PowerHTML -ErrorAction Stop
}

function Install-RF2-Mod {
    [CmdletBinding(DefaultParameterSetName='ModId')]

    param (
        [Parameter(Mandatory=$true, HelpMessage="Workshop Mod ID")]
        [string]$ModId,

        [Parameter(Mandatory=$true, HelpMessage="RF2 Install Path")]
        [string]$InstallPath,

        [Parameter(Mandatory=$false, HelpMessage="Override Mod Name")]
        [string]$Name,

        [Parameter(Mandatory=$false, HelpMessage="Flag Mod as DLC")]
        [bool]$DLC
    )

    PROCESS {
        Download-Rf2-Mod -ModId $ModId -InstallDir $InstallPath
        Add-Mod-DBEntry -ModId  $ModId -Path $InstallPath\mods.xml -Name $name -DLC $DLC
    }
}
