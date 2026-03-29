function New-SSWUnattendIso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceIso,

        [Parameter(Mandatory)]
        [string]$OutputIso,

        [Parameter(Mandatory)]
        [string]$UnattendXml,

        [scriptblock]$Log
    )

    $tmpWork = Join-Path $env:TEMP "SSW-ISO-Work-$(Get-Random)"
    try {
        if ($Log) { & $Log "Unblock-File op $SourceIso..." }
        Unblock-File -Path $SourceIso -ErrorAction SilentlyContinue
        if ($Log) { & $Log 'ISO koppelen...' }
        $mount = Mount-DiskImage -ImagePath $SourceIso -PassThru -ErrorAction Stop
        $driveLetter = ($mount | Get-Volume).DriveLetter
        if (-not $driveLetter) {
            throw 'Geen driveletter toegewezen.'
        }

        $srcDrive = "${driveLetter}:\"
        if ($Log) { & $Log 'Inhoud kopieren...' }
        New-Item -ItemType Directory -Path $tmpWork -Force | Out-Null
        robocopy $srcDrive $tmpWork /E /NP /NFL /NDL /NJH /NJS | Out-Null
        if ($Log) { & $Log 'unattend.xml injecteren...' }
        $UnattendXml | Set-Content -Path (Join-Path $tmpWork 'autounattend.xml') -Encoding UTF8 -Force
        if ($Log) { & $Log 'ISO bouwen met oscdimg...' }
        $oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (-not (Test-Path $oscdimg)) {
            throw "oscdimg.exe niet gevonden. Installeer Windows ADK (Deployment Tools)."
        }

        $bootData = '2#p0,e,b"{0}\boot\etfsboot.com"#pEF,e,b"{0}\efi\microsoft\boot\efisys.bin"' -f $tmpWork
        & $oscdimg -m -o -u2 -udfver102 "-bootdata:$bootData" $tmpWork $OutputIso 2>&1 | Out-Null
        if (-not (Test-Path $OutputIso)) {
            throw 'oscdimg heeft geen ISO aangemaakt.'
        }

        if ($Log) { & $Log "ISO aangemaakt: $OutputIso" }
    } finally {
        Dismount-DiskImage -ImagePath $SourceIso -ErrorAction SilentlyContinue
        if (Test-Path $tmpWork) {
            Remove-Item $tmpWork -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-SSWW11UnattendXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [securestring]$AdminPassword
    )

    $adminPasswordPlainText = ConvertFrom-SSWSecureString -SecureString $AdminPassword
    $adminPassXml = ConvertTo-SSWXmlSafeValue -Value $adminPasswordPlainText
    $domainAdminXml = ConvertTo-SSWXmlSafeValue -Value $Config.DomainAdmin

    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>nl-NL</UILanguage></SetupUILanguage>
      <InputLocale>nl-NL</InputLocale>
      <UILanguage>nl-NL</UILanguage>
      <SystemLocale>nl-NL</SystemLocale>
      <UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallFrom>
            <MetaData wcm:action="add">
              <Key>/IMAGE/NAME</Key>
              <Value>Windows 11 Enterprise</Value>
            </MetaData>
            <MetaData wcm:action="add">
              <Key>/IMAGE/EDITIONID</Key>
              <Value>Enterprise</Value>
            </MetaData>
          </InstallFrom>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>Never</WillShowUI>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>SSW Lab</FullName>
        <Organization>Sogeti SSW</Organization>
        <ProductKey>
          <Key>NPPR9-FWDCX-D2C8J-H872K-2YT43</Key>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName>
      <RegisteredOrganization>Sogeti SSW</RegisteredOrganization>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <InputLocale>nl-NL</InputLocale>
      <UILanguage>nl-NL</UILanguage>
      <UILanguageFallback>en-US</UILanguageFallback>
      <SystemLocale>nl-NL</SystemLocale>
      <UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>3</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$adminPassXml</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password><Value>$adminPassXml</Value><PlainText>true</PlainText></Password>
            <DisplayName>$domainAdminXml</DisplayName>
            <Group>Administrators</Group>
            <Name>$domainAdminXml</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@
}

function New-SSWServer2025UnattendXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [securestring]$AdminPassword
    )

    $adminPasswordPlainText = ConvertFrom-SSWSecureString -SecureString $AdminPassword
    $adminPassXml = ConvertTo-SSWXmlSafeValue -Value $adminPasswordPlainText
    $domainAdminXml = ConvertTo-SSWXmlSafeValue -Value $Config.DomainAdmin

    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>nl-NL</InputLocale><UILanguage>en-US</UILanguage>
      <SystemLocale>nl-NL</SystemLocale><UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>OnError</WillShowUI>
          <InstallToAvailablePartition>false</InstallToAvailablePartition>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>SSW Lab</FullName>
        <Organization>Sogeti SSW</Organization>
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <NetworkLocation>Work</NetworkLocation>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$adminPassXml</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password><Value>$adminPassXml</Value><PlainText>true</PlainText></Password>
            <DisplayName>$domainAdminXml</DisplayName>
            <Group>Administrators</Group>
            <Name>$domainAdminXml</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@
}
