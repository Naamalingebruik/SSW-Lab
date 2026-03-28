# Studieprogramma AZ-104 — Azure Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-az104.md)

**Duur:** 8 weken · **Lab preset:** Minimal (DC01 · W11-01) — Azure-taken draaien in de cloud
**MS Learn pad:** [Azure Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104)
**Examengewicht:**

| Domein | Gewicht |
|---|---|
| Azure identiteiten en governance beheren | 20–25% |
| Storage implementeren en beheren | 15–20% |
| Azure compute resources deployen en beheren | 20–25% |
| Virtuele netwerken implementeren en beheren | 15–20% |
| Azure resources monitoren en onderhouden | 10–15% |

> **Voorwaarde:** Azure subscription via MSDN/Visual Studio Subscriptions (maandelijks tegoed)
> De SSW-Lab VMs dienen als *hybride on-premises endpoint* voor sommige labs (VPN, Azure Arc)
> **Tenantnotitie:** de gedeelde dev-tenant helpt voor Entra- en identity-onderdelen, maar het grootste deel van AZ-104 vraagt echte Azure-resources. Volg dus expliciet de momenten waarop je van lokale VM naar tenant of Azure-subscription schakelt.

## Zo gebruik je dit studieprogramma

- Lees per week eerst de leerdoelen en bepaal welke taken je echt in Azure moet uitvoeren en welke alleen ondersteunend in SSW-Lab plaatsvinden.
- Houd tijdens het lab een kostenbewuste werkwijze aan: noteer wat je aanmaakt en ruim resources dezelfde dag weer op als ze niet meer nodig zijn.
- Maak de kennischeck pas nadat je zowel portal- als CLI/PowerShell-stappen hebt gedaan; AZ-104 toetst vaak of je meerdere beheerpaden herkent.
- Werk je in een gemengd Nederlands/Engelstalig team, houd termen bewust parallel bij, zoals *resourcegroep / resource group* en *beheerlaag / management group*.

## Labdekking en verwachtingen

- **Sterke dekking in SSW-Lab:** hybride identiteitsbasis, Azure CLI vanaf Windows-clients, Azure File Sync-koppeling, netwerkconcepten en enkele beheer- en monitoringoefeningen.
- **Gedeeltelijke dekking:** veel AZ-104-onderdelen spelen primair in Azure zelf; de lokale VMs ondersteunen vooral scenario's rond Arc, VPN, File Sync en hybride identiteit.
- **Cloud-first onderdelen:** compute, storage, VNets, load balancing, monitoring, backup en governance moet je vooral in de Azure-portal en via CLI/PowerShell oefenen.
- Zie dit document daarom als complete studieroute, maar niet als "lokaal-only" lab: de echte examenfit ontstaat pas als je consequent ook de Azure-resources zelf bouwt en opruimt.

## Werkwijze voor kennischecks

- Beantwoord elke vraag vanuit scope en beheerlaag: op welk niveau wijs je iets toe of dwing je iets af?
- Controleer of je niet alleen het portalpad kent, maar ook het concept erachter begrijpt.
- Herhaal vooral vragen over storage-redundantie, networking en RBAC/Policy, omdat die in scenario's snel door elkaar lopen.
- Koppel je antwoord steeds terug aan operationele impact: kosten, beschikbaarheid, beveiliging en beheerlast.

---

## Week 1 — Azure identiteiten en governance
> **Examendomein:** Azure-identiteiten en governance beheren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een Sogeti-consultant begeleidt de onboarding van een recent overgenomen dochterbedrijf van een financiële klant. De dochter heeft een eigen Active Directory, 200 medewerkers en moet toegang krijgen tot specifieke Azure-workloads zonder zicht te krijgen op de subscriptions van het moederbedrijf. Je ontwerpt het RBAC-delegatiemodel, bouwt een management group-hiërarchie en dwingt via Azure Policy af dat resources alleen in goedgekeurde regio's mogen worden uitgerold.

### Leerdoelen
- [ ] Entra ID-gebruikers en -groepen aanmaken en beheren via Azure portal en Azure CLI
- [ ] Azure RBAC-rollen toewijzen op resource group- en subscription-niveau en het verschil begrijpen met Entra ID-directoryrollen
- [ ] Een Management Group-hiërarchie opbouwen (Root → tussenliggend niveau → Dev/Prod)
- [ ] Een Azure Policy toewijzen die resourcelocaties beperkt tot toegestane regio's
- [ ] Cost Management gebruiken: budgetten instellen en alertmeldingen configureren
- [ ] Het scopemodel begrijpen: Management Group → Subscription → Resource Group → Resource

### MS Learn modules
- [Manage Azure identities and governance](https://learn.microsoft.com/en-us/training/paths/az-104-manage-identities-governance/)
- [Configure Azure Active Directory](https://learn.microsoft.com/en-us/training/modules/configure-azure-active-directory/)
- [Configure user and group accounts](https://learn.microsoft.com/en-us/training/modules/configure-user-group-accounts/)
- [Configure subscriptions and governance](https://learn.microsoft.com/en-us/training/modules/configure-subscriptions/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Entra ID (Azure AD) | Microsofts cloud-identiteitsservice voor Azure en Microsoft 365; beheert gebruikers, groepen en applicaties |
| Azure RBAC | Role-Based Access Control voor Azure-resources; rollen worden toegewezen op een scope (MG, subscription, RG, resource) |
| Entra ID-rollen | Directoryrollen die beheer van Entra ID zelf regelen (bijv. Global Admin, User Admin) — los van Azure RBAC |
| Management Group | Hiërarchische container boven subscriptions; policies en RBAC-toewijzingen gelden voor alle onderliggende subscriptions |
| Subscription | Factuur- en isolatie-eenheid voor Azure-resources; RBAC en policies gelden per subscription |
| Resource Group | Logische container voor Azure-resources; lifecycle-eenheid (samen aanmaken, samen verwijderen) |
| Azure Policy | Regels die resourceconfiguraties valideren en afdwingen; effecten zijn Audit, Deny, Append, Modify, DeployIfNotExists |
| Resource Lock | CanNotDelete of ReadOnly — beschermt kritieke resources; overschrijft RBAC, ook Owners worden geblokkeerd |
| Cost Management | Azure-tool voor het bewaken van uitgaven, instellen van budgetten en configureren van kostenalerts |
| Service Principal | App-identiteit in Entra ID voor geautomatiseerde toegang; minder veilig dan een Managed Identity omdat er een secret bij hoort |

### Lab oefeningen (SSW-Lab + Azure portal)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Maak een *Resource Group* aan: `rg-sswlab-dev` in West Europe |
| **Azure portal** | Maak een extra Entra ID-gebruiker aan: `az-admin@<tenant>.onmicrosoft.com` |
| **Azure portal** | Ken de rol *Contributor* toe aan `az-admin` op de resource group via IAM |
| **Azure portal** | Maak een *Management group* structuur aan: Root → SSW → Dev/Prod |
| **Azure portal** | Wijs een *Azure Policy* toe: "Allowed locations = West Europe, North Europe" |
| **LAB-W11-01** | Gebruik Azure CLI: `az group list --output table` |
| **Azure portal** | Maak een *Cost budget alert* in op €50 voor `rg-sswlab-dev` |

### Labcommando's

```powershell
# Maak een nieuwe Entra ID-gebruiker aan
az ad user create --display-name "AZ Admin" --user-principal-name az-admin@<tenant>.onmicrosoft.com --password "P@ssw0rd123!"

# Wijs de rol Contributor toe op een resource group
az role assignment create --assignee az-admin@<tenant>.onmicrosoft.com --role "Contributor" --scope /subscriptions/<sub-id>/resourceGroups/rg-sswlab-dev

# Toon alle roltoewijzingen in een resource group
az role assignment list --resource-group rg-sswlab-dev --output table

# Wijs een ingebouwde Azure Policy toe (Allowed locations)
az policy assignment create --name "allowed-locations" --policy "e56962a6-4747-49cd-b67b-bf8b01975c4f" --params '{"listOfAllowedLocations":{"value":["westeurope","northeurope"]}}'

# Maak een budgetwaarschuwing aan
az consumption budget create --budget-name "sswlab-budget" --amount 50 --time-grain Monthly --resource-group rg-sswlab-dev --notifications '[{"enabled":true,"operator":"GreaterThan","threshold":80,"contactEmails":["admin@example.com"]}]'
```

### Kennischeck
1. Wat is het verschil tussen *Azure RBAC* en *Entra ID rollen*?
2. Hoe werkt *Policy* versus *RBAC* — wanneer gebruik je welke?
3. Wat is het verschil tussen *Management Group*, *Subscription*, *Resource Group* en *Resource*?
4. Hoe werkt *Azure Cost Management* en hoe stel je budgetmeldingen in?

<details>
<summary>Antwoorden</summary>

1. Azure RBAC-rollen beheren toegang tot Azure-resources (VMs, storage, netwerken). Ze worden toegewezen op een scope: Management Group, Subscription, Resource Group of individuele resource. Voorbeelden: Owner, Contributor, Reader. Entra ID-rollen beheren de Entra ID-directory zelf: gebruikers aanmaken, Conditional Access-policies beheren, MFA afdwingen. Voorbeelden: Global Administrator, User Administrator. De lagen zijn onafhankelijk — een Subscription Owner is niet automatisch een Global Admin in Entra ID.

2. Azure Policy: dwingt af *welke configuraties* resources mogen hebben, ongeacht wie ze aanmaakt. Voorbeeld: "resources mogen alleen in West Europe worden aangemaakt". Werkt op basis van resource-eigenschappen. Azure RBAC: regelt *wie* iets mag doen met resources. Voorbeeld: "deze gebruiker mag VMs starten maar niet verwijderen". Gebruik Policy voor compliancevereisten en governance; gebruik RBAC voor toegangsbeheer per gebruiker of team.

3. Management Group: hiërarchische container boven subscriptions; policies en RBAC worden geërfd door alle onderliggende subscriptions. Subscription: factuur- en isolatie-eenheid; alle Azure-resources leven in een subscription. Resource Group: logische container voor een groep samenhangende resources die je als eenheid beheert (bijv. alle resources van een applicatie). Resource: het individuele Azure-object (VM, storage account, VNet). Overerving gaat van boven naar beneden: policies op MG-niveau gelden voor alle subscriptions, resource groups en resources eronder.

4. Azure Cost Management (via portal.azure.com/#view/Microsoft_Azure_CostManagement) toont actuele en historische kosten per resource, resource group of subscription. Een budgetalert stel je in via Cost Management → Budgets → Add: kies een bedrag (bijv. €50/maand), stel alertdrempels in (bijv. 80% en 100%), voeg een actiegroep toe met een e-mailadres. Azure stuurt automatisch een melding als het verbruik de drempel bereikt. Budgets zijn proactief — ze blokkeren geen uitgaven, maar waarschuwen tijdig.

</details>

---

**Scenario-vragen:**

5. Een bedrijf neemt een nieuwe bedrijfseenheid over en wil het IT-team de mogelijkheid geven om VMs aan te maken en te beheren in een specifieke subscription, maar zonder netwerkconfiguraties te wijzigen of rollen toe te wijzen aan anderen. Welke ingebouwde Azure RBAC-rol moet je toewijzen?
   - A) Owner
   - B) Contributor
   - C) Virtual Machine Contributor
   - D) User Access Administrator

<details>
<summary>Antwoord</summary>

**C) Virtual Machine Contributor.** Deze rol geeft rechten om VMs aan te maken en te beheren, maar niet om het virtuele netwerk te beheren of RBAC-rollen toe te wijzen. Contributor (B) zou ook netwerkwijzigingen toestaan. Owner (A) omvat het recht om rollen toe te wijzen. User Access Administrator (D) is specifiek bedoeld voor het beheer van roltoewijzingen.

</details>

6. Jouw organisatie moet ervoor zorgen dat er in geen enkele subscription binnen de management group Azure-resources worden aangemaakt buiten West Europe en North Europe. Wat is de juiste aanpak?
   - A) Wijs de Contributor-rol toe aan alle subscription-owners en instrueer hen geen resources elders aan te maken
   - B) Maak een Azure Policy met de definitie "Allowed locations" en wijs deze toe op management group-niveau
   - C) Maak een Azure Policy per subscription afzonderlijk aan
   - D) Configureer een Resource Lock op elke subscription

<details>
<summary>Antwoord</summary>

**B) Maak een Azure Policy met de definitie "Allowed locations" en wijs deze toe op management group-niveau.** Door de policy op management group-niveau toe te wijzen, geldt deze automatisch voor alle onderliggende subscriptions. Optie C werkt wel, maar is niet schaalbaar. Optie A is afhankelijk van handmatige naleving. Optie D — resource locks beperken de locatie van nieuwe resources niet.

</details>

7. Een beheerder configureert een ReadOnly resource lock op een resource group met daarin een storage account. Een gebruiker met de Contributor-rol probeert een blob te uploaden. Wat gebeurt er?
   - A) Het uploaden slaagt omdat de gebruiker Contributor-rechten heeft
   - B) Het uploaden mislukt omdat de lock alle schrijfbewerkingen blokkeert, inclusief schrijfacties op het datavlak
   - C) Het uploaden slaagt omdat datavlakbewerkingen buiten ARM locks vallen
   - D) Het uploaden mislukt, maar alleen voor nieuwe containers, niet voor bestaande

<details>
<summary>Antwoord</summary>

**C) Het uploaden slaagt omdat datavlakbewerkingen buiten ARM locks vallen.** Resource locks werken op het Azure Resource Manager-niveau (het beheervlak) en blokkeren geen datavlakbewerkingen zoals het uploaden van blobs, het lezen van bestanden of wachtrij-bewerkingen. De Contributor-rol staat de schrijfactie op het datavlak toe; de lock verhindert dit niet.

</details>

---

## Week 2 — Storage implementeren en beheren
> **Examendomein:** Storage implementeren en beheren · **Gewicht:** 15–20%

> **Praktijkscenario:** Een data-analyseteam bij een retailklant genereert maandelijks ongeveer 500 GB aan ruwe data. Rapporten ouder dan 90 dagen worden zelden geraadpleegd en data ouder dan twee jaar moet om compliance-redenen bewaard blijven maar wordt vrijwel nooit gelezen. De opslagkosten lopen snel op en je moet een lifecycle-strategie ontwerpen en de juiste redundantieoptie adviseren voor een businesskritische workload vanuit een Nederlands kantoor.

### Leerdoelen
- [ ] Een Storage Account aanmaken met de juiste redundantieoptie (LRS/ZRS/GRS/GZRS) voor het scenario
- [ ] Blob containers aanmaken, bestanden uploaden en access tiers (Hot/Cool/Cold/Archive) correct toepassen
- [ ] Een Shared Access Signature (SAS) genereren met beperkte rechten en geldigheidsduur
- [ ] Een Azure File Share aanmaken en koppelen als netwerkschijf via SMB op LAB-W11-01
- [ ] Azure File Sync installeren op LAB-DC01, een server registreren en cloud tiering begrijpen
- [ ] Een Lifecycle Management Policy configureren die blobs automatisch verplaatst of verwijdert

### MS Learn modules
- [Configure storage accounts](https://learn.microsoft.com/en-us/training/modules/configure-storage-accounts/)
- [Configure Azure Blob Storage](https://learn.microsoft.com/en-us/training/modules/configure-blob-storage/)
- [Configure Azure Files and Azure File Sync](https://learn.microsoft.com/en-us/training/modules/configure-azure-files-file-sync/)
- [Configure Azure Storage security](https://learn.microsoft.com/en-us/training/modules/configure-storage-security/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Storage Account | Container op accountniveau voor alle Azure-opslag (blob, files, queue, table); General Purpose v2 is de standaard keuze |
| LRS | Locally Redundant Storage: 3 synchrone kopieën binnen één datacenter; geen bescherming bij datacenteruitval |
| ZRS | Zone-Redundant Storage: 3 synchrone kopieën verspreid over 3 availability zones in dezelfde regio |
| GRS | Geo-Redundant Storage: LRS in primaire regio + asynchroon 3 kopieën in secundaire regio honderden km's weg |
| GZRS | Geo-Zone-Redundant Storage: combineert ZRS in primaire regio met GRS-replicatie naar secundaire regio; maximale bescherming |
| Access tier (blob) | Hot: frequente toegang; Cool: maandelijkse toegang; Cold: kwartaalsgewijze toegang; Archive: langdurige opslag, rehydratie duurt uren |
| SAS token | Shared Access Signature: tijdelijk delegated toegangstoken met specifieke rechten, geldigheidsduur en optionele IP-beperking |
| Stored Access Policy | Herroepbaar SAS-beleid gekoppeld aan een container; hiermee kun je actieve SAS-tokens ongeldig maken |
| Azure File Sync | Synct een on-premises Windows File Server met een Azure File Share; ondersteunt cloud tiering |
| Cloud tiering | Zelden gebruikte bestanden worden alleen als verwijzing lokaal bewaard en op verzoek vanuit de cloud geladen |
| Lifecycle Management | Automatisch verplaatsen of verwijderen van blobs op basis van leeftijd of laatste toegangsdatum |

### Lab oefeningen (SSW-Lab + Azure portal)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Maak een Storage Account aan: LRS, General Purpose v2, Hot tier |
| **Azure portal** | Maak een Blob container aan → upload een testbestand |
| **Azure portal** | Genereer een *Shared Access Signature (SAS)* met leesrechten, 1 uur geldig |
| **LAB-W11-01** | Gebruik Azure Storage Explorer of `azcopy` om naar blob te uploaden |
| **Azure portal** | Maak een *Azure File Share* aan → verbind via SMB (`net use Z: \\...`) |
| **LAB-DC01** | Installeer Azure File Sync agent → registreer server → sync LAB-DC01-map |
| **Azure portal** | Configureer *Lifecycle management policy*: verplaats naar Cool na 30 dagen |

### Labcommando's

```powershell
# Maak een storage account aan
az storage account create --name sswlabstorage --resource-group rg-sswlab-dev --location westeurope --sku Standard_LRS --kind StorageV2

# Genereer een SAS-token voor een container (alleen-lezen, 1 uur)
az storage container generate-sas --account-name sswlabstorage --name mycontainer --permissions r --expiry (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:mmZ") --output tsv

# Zet een bestand over met azcopy
azcopy copy "C:\testfile.txt" "https://sswlabstorage.blob.core.windows.net/mycontainer/testfile.txt?<SAS-token>"

# Toon blobs in een container
az storage blob list --account-name sswlabstorage --container-name mycontainer --output table

# Maak een Azure File Share aan en koppel deze
az storage share create --name myfileshare --account-name sswlabstorage --quota 5
net use Z: \\sswlabstorage.file.core.windows.net\myfileshare /u:AZURE\sswlabstorage <storage-key>
```

### Kennischeck
1. Wat zijn de storage tiers en wanneer gebruik je welke?
2. Wat is het verschil tussen een *SAS token* en een *access key*?
3. Hoe werkt *Azure File Sync* en wat is *cloud tiering*?
4. Wat is het verschil tussen *LRS*, *ZRS*, *GRS* en *GZRS*?

<details>
<summary>Antwoorden</summary>

1. Hot: voor blobs die dagelijks of wekelijks worden gebruikt; laagste transactiekosten, hoogste opslagkosten per GB. Cool: voor data die maandelijks wordt benaderd; lagere opslagkosten maar hogere transactiekosten; minimale bewaarduur 30 dagen. Cold: voor data die kwartaalsgewijs wordt benaderd; nog lagere opslagkosten; minimale bewaarduur 90 dagen. Archive: voor langdurige archivering; laagste opslagkosten maar rehydratie naar Hot/Cool duurt uren (Standard Rehydrate) of minuten (High Priority, duurder). Kies op basis van toegangspatroon: hoe minder frequent, hoe goedkoper de opslag maar duurder de toegang.

2. Access key: geeft volledige toegang tot het volledige storage account (alle containers, files, queues, tables) en heeft geen vervaldatum. Moet geheim worden gehouden en regelmatig worden geroteerd. SAS-token: tijdelijk delegated token met beperkte scope (bijv. alleen lezen van één container), een instelbare vervaldatum, en optioneel IP-beperking. Veiliger dan een access key omdat de rechten minimaal zijn en het token automatisch verloopt. Aanbevolen voor externe partijen of tijdelijke toegang.

3. Azure File Sync koppelt een on-premises Windows File Server aan een Azure File Share. Bestanden worden bidirectioneel gesynchroniseerd. Cloud tiering: als de lokale schijf vol dreigt te raken, worden zelden gebruikte bestanden vervangen door een verwijzingsstub op de lokale server — het bestand zelf staat alleen in Azure Files. Bij toegang wordt het bestand transparant vanuit de cloud geladen. Voordeel: lokale schijfruimte wordt geoptimaliseerd terwijl alle bestanden bereikbaar blijven.

4. LRS: 3 kopieën in één datacenter; bescherming tegen server- of schijfuitval, niet bij datacenteruitval. ZRS: 3 kopieën in 3 aparte availability zones binnen dezelfde regio; beschermt bij uitval van één datacenter. GRS: LRS in primaire regio plus asynchroon repliceren naar een secundaire regio (honderden km's weg); beschermt bij volledige regio-uitval, maar de secundaire regio is standaard alleen leesbaar via Microsoft-initiated failover (RA-GRS maakt de secundaire altijd leesbaar). GZRS: combineert ZRS in de primaire regio met GRS naar de secundaire regio; maximale bescherming zowel bij zone- als bij regio-uitval.

</details>

---

**Scenario-vragen:**

5. Een bedrijf deelt maandelijkse financiële rapporten met een externe auditor. De rapporten staan in Azure Blob Storage. De auditor heeft gedurende precies 48 uur leestoegang nodig tot een specifieke container. Welke aanpak biedt de minste rechten terwijl aan de vereiste wordt voldaan?
   - A) Deel de storage account access key met de auditor
   - B) Maak een SAS-token aan dat is beperkt tot de container met leesrechten en een vervaltijd van 48 uur
   - C) Ken de auditor de rol Storage Blob Data Reader toe op subscription-niveau
   - D) Maak de container publiek toegankelijk (anonieme toegang)

<details>
<summary>Antwoord</summary>

**B) Maak een SAS-token aan dat is beperkt tot de container met leesrechten en een vervaltijd van 48 uur.** Een SAS-token beperkt tot de container met alleen-lezentoegang en een vervaltijd van 48 uur biedt precies de vereiste toegang. Optie A deelt volledige accounttoegang zonder vervaldatum. Optie C verleent toegang buiten de vereiste scope. Optie D verwijdert alle toegangscontrole.

</details>

6. Een lifecycle management policy is geconfigureerd om blobs na 30 dagen naar de Cool-tier te verplaatsen en na 365 dagen te verwijderen. Een blob is 28 dagen geleden geüpload en is sindsdien niet meer geopend. Wat is de huidige staat van de blob?
   - A) Al verplaatst naar Cool-tier omdat de blob meer dan 7 dagen inactief is
   - B) Nog steeds in Hot-tier omdat de drempel van 30 dagen nog niet is bereikt
   - C) Verplaatst naar Archive-tier omdat de blob niet frequent wordt geopend
   - D) Verwijderd omdat inactieve blobs standaard na 14 dagen worden verwijderd

<details>
<summary>Antwoord</summary>

**B) Nog steeds in Hot-tier omdat de drempel van 30 dagen nog niet is bereikt.** Lifecycle management policies passen regels toe op basis van geconfigureerde leeftijdsdrempels. Met een regel van 30 dagen blijft de blob in de Hot-tier tot dag 30. Er vindt geen standaard automatische verwijdering of tiering plaats voordat een regeldrempel is bereikt.

</details>

7. Een ontwikkelteam wil container images opslaan in een privé Azure Container Registry en deze ophalen vanuit Azure Container Instances. Ze willen geen inloggegevens opslaan in hun pipeline-configuratie. Welke authenticatiemethode raad je aan?
   - A) Sla de ACR-beheerdersnaam en het wachtwoord op als pipeline-secrets
   - B) Gebruik een SAS-token dat is gegenereerd op basis van het ACR-storage account
   - C) Schakel de Managed Identity in op de ACI en ken de AcrPull-rol toe aan de registry
   - D) Maak de ACR-registry tijdelijk publiek toegankelijk tijdens het ophalen

<details>
<summary>Antwoord</summary>

**C) Schakel de Managed Identity in op de ACI en ken de AcrPull-rol toe aan de registry.** Managed Identity elimineert de noodzaak om inloggegevens op te slaan of te roteren. Door AcrPull toe te wijzen aan de managed identity wordt minimale toegang verleend. Optie A slaat inloggegevens op die periodiek geroteerd moeten worden. Optie B is niet van toepassing op ACR-authenticatie. Optie D introduceert een beveiligingsrisico.

</details>

---

## Week 3 — Virtual Machines deployen en beheren
> **Examendomein:** Azure compute-resources deployen en beheren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een logistiek bedrijf migreert zijn on-premises applicatielaag naar Azure. De oplossing bestaat uit twee webservers en een applicatieserver die beschikbaar moeten blijven tijdens gepland platformonderhoud. De SLA vereist 99,95% uptime. Jij ontwerpt de VM-opzet met Availability Sets, richt back-ups in en demonstreert een herstelprocedure die tijdens een klantreview standhoudt.

### Leerdoelen
- [ ] Een Windows Server VM deployen via Azure portal (juiste SKU, regio, schijftype kiezen)
- [ ] Een data disk toevoegen aan een bestaande VM en initialiseren in Windows
- [ ] Een VM snapshot maken en een nieuw managed disk herstellen vanuit die snapshot
- [ ] Availability Sets configureren en de spreiding over Fault Domains en Update Domains begrijpen
- [ ] Azure Backup inschakelen voor een VM en een on-demand backup uitvoeren
- [ ] Het verschil kennen tussen Availability Sets, Availability Zones en VM Scale Sets voor het examen

### MS Learn modules
- [Configure virtual machines](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machines/)
- [Configure virtual machine availability](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-availability/)
- [Configure virtual machine extensions](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-extensions/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| VM-grootte (SKU) | Combinatie van vCPU, RAM en tijdelijke opslag; bijv. Standard_B2s (2 vCPU, 4 GB RAM) voor dev/test |
| Managed disk | Azure-beheerde virtuele schijf; typen: Premium SSD (productie), Standard SSD (dev/test), Standard HDD (archief) |
| Availability Set | Spreidt VMs over Fault Domains (aparte racks) en Update Domains (rolling updates); beschermt binnen één datacenter |
| Fault Domain | Groep van servers die dezelfde stroomtoevoer en netwerkaansluiting delen; uitval van één rack treft slechts één FD |
| Update Domain | Groep van VMs die tegelijk worden herstart bij platform-onderhoud; max. 20 UD's in een Availability Set |
| Availability Zone | Beschermt bij uitval van een volledig datacenter; VMs in aparte fysieke datacenters binnen dezelfde regio |
| VM Scale Set (VMSS) | Automatisch schaalbare groep van identieke VMs op basis van regels (bijv. CPU > 80% → voeg VM toe) |
| Azure Spot VM | Ongebruikte Azure-capaciteit tegen gereduceerde prijs; kan op elk moment worden teruggenomen; geschikt voor batch-workloads |
| Generalized image | VM-image waaruit alle machine-specifieke data is verwijderd (Sysprep/waagent); kan worden hergebruikt voor nieuwe VMs |
| Specialized image | Exacte kopie van een bestaande VM inclusief SID en gebruikersinstellingen; alleen voor herstel of klonen |
| VM-extensie | Agent of script dat na VM-deployment wordt uitgevoerd; bijv. Custom Script Extension voor IIS-installatie |

### Lab oefeningen (Azure portal)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Deployeer een Windows Server 2022 VM (B2s SKU) in `rg-sswlab-dev` |
| **Azure portal** | Verbind via RDP → installeer IIS via Server Manager |
| **Azure portal** | Voeg een *data disk* toe (32 GB, Standard SSD) → initialiseer in Windows |
| **Azure portal** | Maak een *VM snapshot* → herstel een nieuw managed disk van de snapshot |
| **Azure portal** | Configureer *Auto-shutdown* om kosten te besparen (22:00 UTC) |
| **Azure portal** | Deployeer een *Availability Set* met 2 VMs → verifieer fault/update domain spreiding |
| **Azure portal** | Activeer *Azure Backup* voor de VM → voer een on-demand backup uit |

### Labcommando's

```powershell
# Rol een VM uit via Azure CLI
az vm create --resource-group rg-sswlab-dev --name sswlab-vm01 --image Win2022AzureEditionCore --size Standard_B2s --admin-username azureadmin --admin-password "P@ssw0rd123!" --location westeurope

# Koppel een datadisk aan een bestaande VM
az vm disk attach --resource-group rg-sswlab-dev --vm-name sswlab-vm01 --name sswlab-datadisk01 --new --size-gb 32 --sku Standard_LRS

# Maak een snapshot van de OS-disk
$diskId = az vm show --resource-group rg-sswlab-dev --name sswlab-vm01 --query "storageProfile.osDisk.managedDisk.id" -o tsv
az snapshot create --resource-group rg-sswlab-dev --name sswlab-snapshot01 --source $diskId

# Schakel Azure Backup in voor een VM
az backup protection enable-for-vm --resource-group rg-sswlab-dev --vault-name sswlab-rsv --vm sswlab-vm01 --policy-name DefaultPolicy

# Start een on-demand back-uptaak
az backup protection backup-now --resource-group rg-sswlab-dev --vault-name sswlab-rsv --container-name sswlab-vm01 --item-name sswlab-vm01 --backup-management-type AzureIaasVM
```

### Kennischeck
1. Wat is het verschil tussen *Availability Sets* en *Availability Zones*?
2. Wanneer gebruik je *Azure VM Scale Sets* versus losse VMs?
3. Hoe werkt *Azure Spot VMs* en wanneer zijn ze geschikt?
4. Wat is het verschil tussen *generalized* en *specialized* images?

<details>
<summary>Antwoorden</summary>

1. Availability Sets beschermen binnen één datacenter door VMs te spreiden over Fault Domains (aparte racks, aparte stroomtoevoer) en Update Domains (rolling platform-updates). Als één rack uitvalt, draait de andere VM nog. Availability Zones beschermen bij uitval van een volledig datacenter: elke zone is een apart fysiek gebouw met eigen stroom, koeling en netwerk. Voor maximale bescherming gebruik je Availability Zones; Availability Sets zijn een alternatief als zones niet beschikbaar zijn in een regio.

2. VM Scale Sets zijn geschikt wanneer je een groep identieke VMs nodig hebt die automatisch schaalt op basis van load (CPU, geheugen, HTTP-requests). Typische use cases: webservers, API-gateways, batchverwerking. Losse VMs zijn beter voor situaties waarbij elke VM uniek is (andere configuratie, andere rol) of handmatig beheer gewenst is. VMSS biedt ook rolling upgrades voor zero-downtime deployments.

3. Azure Spot VMs maken gebruik van ongebruikte Azure-datacapaciteit en zijn daardoor 60–90% goedkoper dan reguliere VMs. Het nadeel: Azure kan de VM op elk moment terugnemen (eviction) met slechts 30 seconden waarschuwing als die capaciteit nodig is. Geschikt voor: batchverwerking, CI/CD-pipelines, renderingstaken, dataverwerkingstaken — alles waarbij onderbreking acceptabel is en de workload herstart kan worden.

4. Generalized image: de VM is voorbereid met Sysprep (Windows) of waagent (Linux) om alle machine-specifieke instellingen (computernaam, SID, gebruikersaccounts) te verwijderen. Het image kan worden gebruikt als basis voor nieuwe VMs. Specialized image: een exacte punt-in-tijd kopie van een bestaande VM inclusief alle instellingen, SID en gebruikersdata. Gebruik specialized voor herstelscenario's of het klonen van een bestaande VM met identieke configuratie; gebruik generalized als je een golden master image wilt hergebruiken.

</details>

---

**Scenario-vragen:**

5. Een bedrijf runt een webapplicatie met twee lagen: een stateless front-end (IIS-servers) en een databaselaag. Ze willen ervoor zorgen dat de front-end servers beschikbaar blijven tijdens Azure-platformonderhoud. De regio ondersteunt availability zones. Welke configuratie biedt de beste veerkracht voor de front-end laag?
   - A) Alle front-end VMs deployen in een Availability Set met 3 fault domains
   - B) Elke front-end VM deployen in een aparte Availability Zone
   - C) Front-end VMs deployen als Azure Spot VMs in verschillende regio's
   - D) Front-end VMs deployen in dezelfde Availability Zone om latentie te verlagen

<details>
<summary>Antwoord</summary>

**B) Elke front-end VM deployen in een aparte Availability Zone.** Availability Zones beschermen tegen uitval op datacenter-niveau. Omdat de regio zones ondersteunt, is dit de betere keuze ten opzichte van Availability Sets (A), die alleen binnen één datacenter beschermen. Spot VMs (C) kunnen zonder waarschuwing worden teruggenomen. VMs in dezelfde zone plaatsen (D) biedt geen redundantie.

</details>

6. Een ontwikkelteam wil 's nachts batchverwerkingstaken uitvoeren tegen minimale kosten. De taken duren 4–6 uur, slaan elke 30 minuten de voortgang op als checkpoint, en kunnen worden hervat vanaf het laatste checkpoint als ze worden onderbroken. Welk VM-type is het meest geschikt?
   - A) Standard D-series VMs voor voorspelbare prestaties
   - B) Azure Spot VMs omdat de workload onderbreking kan verdragen en kan worden hervat vanaf checkpoints
   - C) Availability Set VMs om te garanderen dat taken altijd zonder onderbreking worden voltooid
   - D) Azure Reserved VM Instances voor maximale kostenbesparingen bij continue workloads

<details>
<summary>Antwoord</summary>

**B) Azure Spot VMs omdat de workload onderbreking kan verdragen en kan worden hervat vanaf checkpoints.** Spot VMs zijn ideaal voor onderbreekbare batchtaken met checkpointing. De workload verdraagt expliciet eviction. Standard VMs (A) en Reserved Instances (D) zijn duurder dan nodig voor een onderbreekbare batchtaak. Availability Sets (C) beschermen tegen hardwarestoringen tijdens onderhoud, niet tegen kosten.

</details>

7. Je wordt gevraagd een specifieke server-VM te herstellen naar de exacte staat van 3 dagen geleden, inclusief alle geïnstalleerde applicaties, lokale gebruikersaccounts en machine-identiteit. Welk type image of herstelpunt moet je gebruiken?
   - A) Een generalized image vastgelegd vóór de wijziging, gedeployed als nieuwe VM
   - B) Een specialized image of VM-herstelpunt dat de machine-identiteit en -staat bewaart
   - C) Een Sysprep-voorbereid image uit de Azure Compute Gallery
   - D) Een ARM-template-export van de VM-configuratie

<details>
<summary>Antwoord</summary>

**B) Een specialized image of VM-herstelpunt dat de machine-identiteit en -staat bewaart.** Een specialized image of een Azure Backup-herstelpunt bewaart de exacte machinestatus, inclusief SID, hostnaam en accounts. Een generalized image (A, C) verwijdert machine-specifieke data en kan de identiteit van een specifieke machine niet herstellen. Een ARM-template (D) beschrijft alleen de VM-configuratie, niet de data of toestand.

</details>

---

## Week 4 — Containers en Azure App Service
> **Examendomein:** Azure compute-resources deployen en beheren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een softwareteam bij een Sogeti-klant wil de release-aanpak moderniseren. Hun monolithische .NET-app wordt nog handmatig naar VMs gedeployed, wat bij elke release tot ongeveer 30 minuten downtime leidt. Je migreert de webapp naar Azure App Service, richt deployment slots in voor vrijwel zero-downtime releases en verkent Azure Container Apps voor een nieuwe microservices-API die parallel wordt ontwikkeld.

### Leerdoelen
- [ ] Een Azure App Service web-app deployen via Azure CLI en deployment slots configureren
- [ ] Een slot swap uitvoeren voor zero-downtime deployment van staging naar productie
- [ ] Een Azure Container Instance deployen vanuit een publiek container image
- [ ] Een Azure Container Registry aanmaken en een container image pushen
- [ ] Autoscaling configureren voor een App Service Plan op basis van CPU-gebruik
- [ ] Het verschil kennen tussen ACI, ACA en AKS voor scenariovragen in het examen

### MS Learn modules
- [Configure Azure App Service](https://learn.microsoft.com/en-us/training/modules/configure-azure-app-services/)
- [Configure Azure Container Instances](https://learn.microsoft.com/en-us/training/modules/configure-azure-container-instances/)
- [Configure Azure Container Apps](https://learn.microsoft.com/en-us/training/modules/introduction-to-azure-container-apps/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| App Service Plan | Compute-laag voor web-apps: bepaalt de grootte (CPU/RAM), het aantal instanties en de beschikbare features (slots, autoscaling) |
| Deployment slot | Aparte instantie van een web-app binnen hetzelfde App Service Plan; gebruikt voor staging en zero-downtime deployments |
| Slot swap | Wisselt de productie- en staging-slot atomair; bij een probleem kun je direct terugswappen |
| Azure Container Registry (ACR) | Privé Docker-containerregistry in Azure; integreert met ACI, ACA en AKS |
| Azure Container Instances (ACI) | Serverloze containers zonder VM-beheer; snel opstarten, betalen per seconde; geschikt voor korte of eenmalige taken |
| Azure Container Apps (ACA) | Beheerd containerplatform op Kubernetes; ondersteunt auto-scaling (inclusief scale-to-zero), Dapr en ingress |
| Azure Kubernetes Service (AKS) | Volledig beheerde Kubernetes-omgeving; meeste controle maar ook meeste beheercomplexiteit |
| Autoscaling | Automatisch het aantal instanties aanpassen op basis van een metriek (CPU, HTTP-requests); vereist Standard-tier of hoger |
| Consumption plan | Serverloze tariefvorm voor Azure Functions; betalen per uitvoering; schaalt automatisch naar nul |

### Lab oefeningen (Azure portal + CloudShell)
| Omgeving | Taak |
|---|---|
| **Azure CloudShell** | Deployeer een simpele webapp: `az webapp create --sku F1 --name sswlab-app ...` |
| **Azure portal** | Configureer *deployment slot* (staging) → doe een *swap* naar productie |
| **Azure portal** | Deployeer een Azure Container Instance met een nginx-image |
| **Azure CloudShell** | `az container create --image nginx --dns-name-label sswlab-ci ...` |
| **Azure portal** | Maak een *Azure Container Registry* aan → push een container-image |
| **Azure portal** | Deployeer een *Container App* vanuit ACR → configureer scaling-regels |
| **Azure portal** | Configureer een *App Service plan* → schaal uit naar 2 instanties |
| **Azure portal** | Bekijk *App Service Diagnostics* → analyseer beschikbaarheids-grafiek |

### Labcommando's

```bash
# Rol een App Service-webapp uit (Free tier)
az webapp create --resource-group rg-sswlab-dev --plan sswlab-asp --name sswlab-app --runtime "DOTNET|8.0"

# Voeg een deployment slot toe
az webapp deployment slot create --name sswlab-app --resource-group rg-sswlab-dev --slot staging

# Wissel staging om naar productie
az webapp deployment slot swap --name sswlab-app --resource-group rg-sswlab-dev --slot staging --target-slot production

# Maak een Container Registry aan en push een image
az acr create --resource-group rg-sswlab-dev --name sswlabacr --sku Basic
az acr login --name sswlabacr
docker tag myapp sswlabacr.azurecr.io/myapp:v1
docker push sswlabacr.azurecr.io/myapp:v1
```

### Kennischeck
1. Wat is het verschil tussen *Azure Container Instances*, *Azure Container Apps* en *Azure Kubernetes Service*?
2. Hoe werken *deployment slots* en waarom is *slot swap* nuttig?
3. Wat is het verschil tussen een *App Service plan* en *Consumption plan* voor Azure Functions?
4. Hoe configureer je *autoscaling* gebaseerd op CPU-gebruik?

<details>
<summary>Antwoorden</summary>

1. Azure Container Instances (ACI): de eenvoudigste optie voor het uitvoeren van containers zonder enige clusterinfrastructuur. Geen orchestratie, geen auto-scaling. Betalen per seconde. Ideaal voor korte, eenmalige of batch-taken. Azure Container Apps (ACA): beheerd platform gebouwd op Kubernetes (KEDA + Envoy) dat auto-scaling, ingress en service-to-service communicatie biedt. Ondersteunt scale-to-zero. Geschikt voor microservices en event-driven workloads zonder dat je Kubernetes zelf hoeft te beheren. Azure Kubernetes Service (AKS): volledig beheerde Kubernetes; je hebt volledige controle over de cluster-configuratie, networking en workloads. Hogere beheerscomplexiteit; geschikt voor grote, complexe containeromgevingen.

2. Een deployment slot is een aparte instantie van je web-app die dezelfde App Service Plan gebruikt. De typische workflow: deploy nieuwe versie naar het staging-slot, test grondig, voer dan een swap uit. Bij een swap worden de routing-configuraties atomair gewisseld zodat staging productie wordt en vice versa — zonder downtime voor gebruikers. Als er een probleem is met de nieuwe versie, swap je terug naar de vorige productieversie in seconden.

3. App Service Plan: de compute-laag is altijd actief en je betaalt per uur voor de ingerichte capaciteit (ongeacht of er requests zijn). Voordeel: voorspelbare kosten, geen cold starts, geschikt voor altijd-aan applicaties. Consumption plan (voor Azure Functions): serverless; de functie-instantie wordt alleen gestart bij een binnenkomende trigger. Betalen per uitvoering en per geheugengebruik. Schaalt automatisch naar nul als er geen verkeer is. Voordeel: zeer goedkoop bij laag of onregelmatig verkeer; nadeel: cold start-latentie.

4. Via Azure portal → App Service Plan → Scale out (App Service plan) → kies "Custom autoscale". Voeg een schaalregel toe: conditie "CPU Percentage greater than 70 for 10 minutes" → verhoog het aantal instanties met 1. Voeg een schaalregel in omgekeerde richting toe: "CPU Percentage less than 30 for 10 minutes" → verlaag met 1. Stel een minimum (bijv. 1) en maximum (bijv. 5) aantal instanties in. Autoscaling is alleen beschikbaar in het Standard-abonnement of hoger, niet in Free of Shared.

</details>

---

**Scenario-vragen:**

5. Een team deployt een nieuwe versie van hun webapp naar een staging deployment slot en voert smoke tests uit. Vervolgens voeren ze een slot swap uit. Kort daarna wordt een kritieke bug ontdekt in de nieuwe versie. Wat is de snelste manier om de vorige versie te herstellen?
   - A) De vorige versie opnieuw deployen vanuit bronbeheer naar het productieslot
   - B) Het productieslot verwijderen en opnieuw aanmaken vanuit een back-up
   - C) De staging- en productieslots opnieuw swappen — de vorige versie staat nog in het staging-slot
   - D) Het App Service Plan omlaag schalen en opnieuw omhoog schalen om een herdeployment te forceren

<details>
<summary>Antwoord</summary>

**C) De staging- en productieslots opnieuw swappen — de vorige versie staat nog in het staging-slot.** Na een slot swap staat de vorige productiecode in het staging-slot. Een tweede swap herstelt deze onmiddellijk naar productie zonder downtime en zonder herdeployment.

</details>

6. Een bedrijf heeft een stateless API die inkomende webhook-events verwerkt. Het verkeer is minimaal tijdens kantooruren maar piekt onvoorspelbaar 's nachts wanneer externe partners batches van events versturen. Ze willen de kosten minimaliseren terwijl pieken automatisch worden opgevangen. Welke hostingoptie is het meest geschikt?
   - A) App Service Plan (Standard tier) met een vast aantal van 5 instanties
   - B) Azure Container Apps met KEDA-gebaseerde HTTP-schaling geconfigureerd met minReplicas ingesteld op 0
   - C) Azure Kubernetes Service met een node pool van 3 dedicated nodes
   - D) Azure Container Instances met één continu draaiende container

<details>
<summary>Antwoord</summary>

**B) Azure Container Apps met KEDA-gebaseerde HTTP-schaling geconfigureerd met minReplicas ingesteld op 0.** ACA met scale-to-zero minimaliseert kosten tijdens inactieve periodes en schaalt automatisch uit tijdens pieken via KEDA. Een vast aantal instanties (A, C) verspilt resources bij laag verkeer. Een enkele ACI-container (D) kan niet schalen en heeft geen ingebouwde autoscaling.

</details>

7. Een bedrijf wil elke nacht een data-exporttaak uitvoeren die ongeveer 20 minuten duurt, een eigen Docker-image gebruikt opgeslagen in hun privé ACR, en na voltooiing geen permanente staat vereist. Welke Azure-service is het meest geschikt?
   - A) Azure App Service met een WebJob
   - B) Azure Container Instances dat het image ophaalt vanuit ACR
   - C) Azure Kubernetes Service met een CronJob-resource
   - D) Azure Container Apps met een geplande trigger

<details>
<summary>Antwoord</summary>

**B) Azure Container Instances dat het image ophaalt vanuit ACR.** ACI is ideaal voor korte, enkelvoudige, stateless taken met een eigen image. Het start snel, voert de taak uit en stopt — je betaalt alleen voor de uitvoeringstijd. AKS (C) introduceert onnodige clusterbeheeroverhead. App Service WebJobs (A) vereisen een altijd-aan App Service Plan. ACA geplande triggers (D) zijn mogelijk maar voegen meer infrastructuur toe dan nodig is voor een eenvoudige taak van 20 minuten.

</details>

---

## Week 5 — Virtuele netwerken
> **Examendomein:** Virtuele netwerken implementeren en beheren · **Gewicht:** 15–20%

> **Praktijkscenario:** Een zorginstelling wil een Azure-hosted applicatie voor patiëntgegevens uitrollen. Door regelgeving mag patiëntdata nooit via het publieke internet lopen en moeten storage- en database-endpoints alleen vanuit het interne Azure-VNet bereikbaar zijn. Tegelijk moet het on-premises netwerk veilig kunnen koppelen aan Azure. Jij ontwerpt segmentatie, Private Endpoints en de VPN-verbinding vanuit de SSW-Lab-omgeving.

### Leerdoelen
- [ ] Een VNet aanmaken met meerdere subnetten en correcte CIDR-bereiken definiëren
- [ ] Een NSG aanmaken, inbound- en outbound-regels configureren en koppelen aan een subnet
- [ ] VNet peering configureren tussen twee VNets (inclusief beide richtingen) en de niet-transitieve aard begrijpen
- [ ] Een Azure Private DNS Zone aanmaken en koppelen aan een VNet voor automatische VM-registratie
- [ ] Azure Bastion deployen voor beveiligde RDP/SSH-toegang zonder publiek IP op de VM
- [ ] Een Private Endpoint aanmaken voor een Storage Account en DNS-resolutie verifiëren

### MS Learn modules
- [Configure virtual networks](https://learn.microsoft.com/en-us/training/modules/configure-virtual-networks/)
- [Configure network security groups](https://learn.microsoft.com/en-us/training/modules/configure-network-security-groups/)
- [Configure Azure DNS](https://learn.microsoft.com/en-us/training/modules/configure-azure-dns/)
- [Configure virtual network peering](https://learn.microsoft.com/en-us/training/modules/configure-vnet-peering/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| VNet | Virtueel netwerk: geïsoleerde netwerkomgeving in Azure; resources in hetzelfde VNet kunnen standaard met elkaar communiceren |
| Subnet | Adresruimte-segment binnen een VNet; NSGs en route tables worden aan subnetten gekoppeld |
| NSG | Network Security Group: stateless firewall met Allow/Deny-regels op basis van IP, poort en protocol; lagere prioriteitswaarde = hogere prioriteit |
| ASG | Application Security Group: logische groepering van VM-NIC's als bron of doel in NSG-regels; vereenvoudigt regelsets |
| VNet peering | Directe laag-3-verbinding tussen twee VNets via het Azure-backbone; niet transitief (A↔B en B↔C betekent niet A↔C) |
| Azure Bastion | Beheerde RDP/SSH-gateway via HTTPS (poort 443); geen publiek IP of open RDP-poort op de VM nodig |
| Private DNS Zone | DNS-zone alleen bereikbaar vanuit gekoppelde VNets; gebruikt voor privé-resolutie van internal servicenamen en private endpoints |
| Service endpoint | Beveiligde route van een subnet naar een Azure-PaaS-service; verkeer gaat via het Azure-backbone maar de service behoudt een publiek endpoint |
| Private endpoint | Geeft een Azure-PaaS-service een privé IP-adres in jouw VNet; verkeer verlaat het privénetwerk nooit; sterker dan een service endpoint |
| Effective routes | Overzicht van de actieve routeringstabel op een NIC, inclusief door Azure beheerde systeemroutes en eventuele UDRs |

### Lab oefeningen (Azure portal + SSW-Lab)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Maak een VNet aan: `10.100.0.0/16` met subnets `frontend/10.100.1.0/24` en `backend/10.100.2.0/24` |
| **Azure portal** | Configureer een *NSG*: sta HTTP/HTTPS in, blokkeer al het overige inbound |
| **Azure portal** | Koppel NSG aan het frontend-subnet → test met VM in backend |
| **Azure portal** | Maak een tweede VNet aan → configureer *VNet peering* tussen beide |
| **Azure portal** | Configureer een *Azure Private DNS Zone* → registreer VMs automatisch |
| **LAB-W11-01** | Configureer een *Point-to-Site VPN* naar het Azure VNet → test verbinding |
| **Azure portal** | Deployeer *Azure Bastion* → verbind met een VM zonder publiek IP of RDP-poort |
| **Azure portal** | Configureer een *Private Endpoint* voor een Storage Account → verifieer DNS-resolutie |
| **Azure portal** | Bekijk *Effective routes* op de NIC van een VM |

### Labcommando's

```bash
# Maak een VNet aan met twee subnetten
az network vnet create --resource-group rg-sswlab-dev --name sswlab-vnet --address-prefix 10.100.0.0/16 --subnet-name frontend --subnet-prefix 10.100.1.0/24
az network vnet subnet create --resource-group rg-sswlab-dev --vnet-name sswlab-vnet --name backend --address-prefix 10.100.2.0/24

# Maak een NSG aan en koppel deze aan een subnet
az network nsg create --resource-group rg-sswlab-dev --name sswlab-nsg-frontend
az network nsg rule create --resource-group rg-sswlab-dev --nsg-name sswlab-nsg-frontend --name AllowHTTP --priority 100 --protocol Tcp --destination-port-range 80 443 --access Allow --direction Inbound
az network vnet subnet update --resource-group rg-sswlab-dev --vnet-name sswlab-vnet --name frontend --network-security-group sswlab-nsg-frontend

# Configureer VNet-peering in beide richtingen
az network vnet peering create --resource-group rg-sswlab-dev --name vnet1-to-vnet2 --vnet-name sswlab-vnet --remote-vnet sswlab-vnet2 --allow-vnet-access
az network vnet peering create --resource-group rg-sswlab-dev --name vnet2-to-vnet1 --vnet-name sswlab-vnet2 --remote-vnet sswlab-vnet --allow-vnet-access
```

### Kennischeck
1. Wat is het verschil tussen een *NSG* op subnet-niveau en op NIC-niveau?
2. Hoe werkt *VNet peering* — is het transitief?
3. Wat is het verschil tussen *Azure DNS* public zones en *Private DNS Zones*?
4. Wat is *service endpoint* versus *private endpoint*?

<details>
<summary>Antwoorden</summary>

1. NSG op subnet-niveau: geldt voor al het verkeer dat het subnet ingaat of verlaat, ongeacht welke VM. Eén NSG beschermt meerdere VMs tegelijk. NSG op NIC-niveau: geldt alleen voor die specifieke VM/NIC. Als beide zijn ingesteld, wordt het verkeer door beide NSGs gefilterd: het inkomende verkeer passeert eerst de subnet-NSG dan de NIC-NSG; uitgaand verkeer omgekeerd. De meest restrictieve regel wint. In de praktijk is koppelen aan het subnet de meest gebruikte en overzichtelijkste aanpak.

2. VNet peering maakt een directe laag-3-verbinding via het Azure-backbone tussen twee VNets. Verkeer verloopt privé en met lage latentie zonder gateway. Belangrijk: peering is NIET transitief. Als VNet A is gepeerd met B, en VNet B is gepeerd met C, kunnen A en C niet automatisch communiceren via B. Oplossingen voor transitive routing: een Azure Firewall of VPN Gateway als hub in een hub-spoke topologie, of een directe peering aanmaken tussen A en C.

3. Azure DNS public zones: beheert DNS-records voor een publiek geregistreerd domein (bijv. contoso.com). Records zijn bereikbaar vanuit het internet. Private DNS zones: DNS-resolutie alleen beschikbaar vanuit VNets die aan de zone zijn gekoppeld. Niet bereikbaar van buiten. Gebruik voor: interne servicenamen (bijv. app.internal), automatische registratie van VM-namen, en DNS-integratie voor private endpoints (bijv. privatelink.blob.core.windows.net).

4. Service endpoint: beveiligde, directe route van een VNet-subnet naar een Azure-PaaS-service (bijv. Storage, SQL). Het verkeer gaat via het geoptimaliseerde Azure-backbone in plaats van over internet, maar het doel-IP-adres van de service blijft een publiek adres. Je kunt de storage-firewall instellen om alleen dat subnet toe te laten. Private endpoint: geeft de PaaS-service een privé IP-adres rechtstreeks in jouw VNet. DNS lost de servicenaam op naar dat privé IP. Verkeer verlaat het VNet nooit. Private endpoint is de sterkere optie: ook al is de storage-firewall verkeerd geconfigureerd, het publieke endpoint is los te stellen. Aanbevolen voor productieomgevingen en compliance-gevoelige data.

</details>

---

**Scenario-vragen:**

5. Een bedrijf heeft drie VNets: Hub, Spoke-A en Spoke-B. Hub is gepeerd met Spoke-A en Hub is gepeerd met Spoke-B. Een VM in Spoke-A moet communiceren met een VM in Spoke-B. Wat moet er worden geconfigureerd?
   - A) Niets — verkeer stroomt automatisch via de Hub omdat beide spokes daarmee zijn gepeerd
   - B) "Allow gateway transit" inschakelen op de Hub-peering en "Use remote gateway" op beide Spoke-peerings
   - C) Een directe VNet-peering aanmaken tussen Spoke-A en Spoke-B, of een Azure Firewall of VPN Gateway in de Hub deployen voor transitieve routing
   - D) Een NSG configureren op het Hub VNet om verkeer tussen de twee spoke-adresruimten toe te staan

<details>
<summary>Antwoord</summary>

**C) Een directe VNet-peering aanmaken tussen Spoke-A en Spoke-B, of een Azure Firewall of VPN Gateway in de Hub deployen voor transitieve routing.** VNet peering is niet transitief. Spoke-A en Spoke-B kunnen niet via Hub communiceren zonder een directe peering tussen hen, of een netwerkapparaat (Azure Firewall, VPN Gateway) in de Hub dat verkeer tussen spokes routeert. Optie B alleen (gateway transit) maakt on-premises-naar-spoke-routing mogelijk, niet spoke-naar-spoke direct.

</details>

6. Een beveiligingsaudit constateert dat de Azure SQL-database van het bedrijf bereikbaar is via het publieke internet en alleen wordt beschermd door een firewallregel. De audit adviseert dat de database niet bereikbaar mag zijn via een publiek IP. Welke oplossing pakt dit op de juiste manier aan?
   - A) Een NSG configureren op het subnet van de SQL-server met een Deny-regel voor al het inkomende internetverkeer
   - B) Een Service Endpoint voor SQL inschakelen op het applicatiesubnet
   - C) Een Private Endpoint aanmaken voor de Azure SQL-database in het applicatie-VNet en het publieke endpoint uitschakelen
   - D) De SQL-firewall beperken tot het publieke IP-adres van de applicatieserver

<details>
<summary>Antwoord</summary>

**C) Een Private Endpoint aanmaken voor de Azure SQL-database in het applicatie-VNet en het publieke endpoint uitschakelen.** Een Private Endpoint kent een privé IP uit het VNet toe aan de SQL-database, waardoor deze niet bereikbaar is via internet. Het uitschakelen van het publieke endpoint elimineert volledig de internettoegang. Service endpoints (B) gebruiken nog steeds een publiek IP. NSGs (A) kunnen niet direct worden toegepast op PaaS-services. Beperken op publiek IP (D) laat het publieke endpoint open.

</details>

7. Je deployt Azure Bastion in een VNet voor beveiligde RDP-toegang tot VMs. Een VM in een gepeerd VNet is niet bereikbaar via Bastion. Wat is de meest waarschijnlijke oorzaak?
   - A) Bastion vereist een publiek IP op de doel-VM om de RDP-sessie tot stand te brengen
   - B) Azure Bastion in één VNet kan geen verbinding maken met VMs in een gepeerd VNet tenzij "Allow gateway transit" is geconfigureerd op de Bastion VNet-peering
   - C) Het AzureBastionSubnet is te klein — het moet minimaal een /24 zijn
   - D) Bastion ondersteunt alleen VMs in hetzelfde VNet; cross-VNet-toegang vereist een VPN Gateway

<details>
<summary>Antwoord</summary>

**B) Azure Bastion in één VNet kan geen verbinding maken met VMs in een gepeerd VNet tenzij "Allow gateway transit" is geconfigureerd op de Bastion VNet-peering.** Azure Bastion ondersteunt verbindingen met VMs in gepeerde VNets, maar de peering moet "Allow gateway transit" hebben ingeschakeld aan de Bastion-zijde en "Use remote gateways" aan de zijde van het gepeerde VNet. Zonder deze instelling kan Bastion VMs in gepeerde VNets niet bereiken. De minimale grootte van het AzureBastionSubnet is /26, niet /24.

</details>

---

## Week 6 — Load balancing en netwerkrouting
> **Examendomein:** Virtuele netwerken implementeren en beheren · **Gewicht:** 15–20%

> **Praktijkscenario:** Een Sogeti-klant runt een publiek e-commerceplatform met een webtier en API-tier op Azure VMs achter een load balancer. Tijdens een piekcampagne bleef een webserver verkeer ontvangen terwijl die al onresponsief was, met fouten voor klanten tot gevolg. Je moet health probes correct inrichten, routing tussen web- en API-verkeer scheiden en Azure Network Watcher inzetten om intermitterende connectiviteitsproblemen te analyseren.

### Leerdoelen
- [ ] Een Standard Load Balancer deployen met een backend pool, health probe en load balancing rule
- [ ] Een failover-scenario testen door één VM te stoppen en de health probe-respons te observeren
- [ ] User Defined Routes (UDR) aanmaken om verkeer via een NVA (Network Virtual Appliance) te routeren
- [ ] Azure Network Watcher gebruiken: IP Flow Verify en Connection Troubleshoot uitvoeren
- [ ] Het verschil kennen tussen Load Balancer (L4) en Application Gateway (L7) voor het examen
- [ ] Service tags in NSG-regels toepassen om Azure-platformverkeer toe te staan

### MS Learn modules
- [Configure Azure Load Balancer](https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/)
- [Configure Azure Application Gateway](https://learn.microsoft.com/en-us/training/modules/configure-azure-application-gateway/)
- [Configure network routing and endpoints](https://learn.microsoft.com/en-us/training/modules/configure-network-routing-endpoints/)
- [Configure Azure Firewall](https://learn.microsoft.com/en-us/training/modules/configure-azure-firewall/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Azure Load Balancer | Laag-4 (TCP/UDP) load balancer; distribueert verkeer op basis van IP-adres en poort; geen inhoudsinspectie |
| Health probe | Controleert periodiek de gezondheid van backend-VM's; bij uitval wordt de VM uit de pool verwijderd |
| SNAT | Source Network Address Translation: de Load Balancer vertaalt het bron-IP van uitgaand verkeer naar het frontend-IP; vereist voor outbound internetverkeer zonder publiek IP op de VM |
| Application Gateway | Laag-7 (HTTP/HTTPS) load balancer met URL-based routing, SSL-terminatie, WAF en sessie-affiniteit |
| WAF | Web Application Firewall: beschermt tegen OWASP-aanvallen (SQL injection, XSS); beschikbaar op Application Gateway en Azure Front Door |
| UDR | User-Defined Route: overschrijft de standaard Azure-systeemrouting; gebruikt om verkeer via een firewall of NVA te sturen |
| NVA | Network Virtual Appliance: een VM die als router of firewall fungeert (bijv. Palo Alto, Cisco, of Azure Firewall zelf) |
| Azure Front Door | Globale L7 load balancer en CDN; geschikt voor multi-regio-applicaties met geo-routering en failover |
| Service tag | Vooraf gedefinieerde groep IP-adressen van Azure-services (bijv. AzureMonitor, Storage, Sql); vereenvoudigt NSG-regels |
| Network Watcher | Azure-tool voor netwerkdiagnostiek: IP Flow Verify, Next Hop, Connection Troubleshoot, NSG flow logs, pakketopname |

### Lab oefeningen (Azure portal)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Deployeer een *Standard Load Balancer* voor 2 webserver-VMs |
| **Azure portal** | Configureer health probe op poort 80 → test failover (stop 1 VM) |
| **Azure portal** | Configureer *User Defined Routes (UDR)*: routeer verkeer via een NVA |
| **Azure portal** | Deployeer een *Application Gateway* met WAF → configureer een path-based routing rule |
| **Azure portal** | Bekijk *Azure Network Watcher → IP Flow Verify* om NSG-blokkering te diagnosticeren |
| **Azure portal** | Gebruik *Connection Troubleshoot* om verbindingsproblemen te analyseren |

### Labcommando's

```bash
# Maak een Standard Load Balancer aan met een publiek IP-adres
az network lb create --resource-group rg-sswlab-dev --name sswlab-lb --sku Standard --frontend-ip-name frontendConfig --public-ip-address sswlab-lb-pip

# Voeg een health probe toe
az network lb probe create --resource-group rg-sswlab-dev --lb-name sswlab-lb --name httpProbe --protocol Http --port 80 --path /

# Voeg een load balancing-regel toe
az network lb rule create --resource-group rg-sswlab-dev --lb-name sswlab-lb --name httpRule --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name frontendConfig --backend-pool-name backendPool --probe-name httpProbe

# Gebruik Network Watcher IP Flow Verify
az network watcher test-ip-flow --resource-group rg-sswlab-dev --vm sswlab-vm01 --direction Inbound --protocol Tcp --local 10.100.1.4:80 --remote 203.0.113.10:12345
```

### Kennischeck
1. Wat is het verschil tussen *Azure Load Balancer* (L4) en *Application Gateway* (L7)?
2. Wanneer gebruik je *Azure Front Door* versus Application Gateway?
3. Hoe werkt *SNAT* in een Load Balancer-configuratie?
4. Wat zijn *service tags* in NSG-regels en waarvoor gebruik je ze?

<details>
<summary>Antwoorden</summary>

1. Azure Load Balancer (L4): distribueert TCP/UDP-verkeer op basis van IP-adres, poort en protocol. Geen inzicht in de HTTP-inhoud. Hoge performance, lage latentie. Geschikt voor: databases, niet-HTTP-applicaties, intern verkeer tussen tiers. Application Gateway (L7): inspecteert HTTP/HTTPS-inhoud. Biedt: URL-based routing (pad /api → backend A, /images → backend B), SSL-terminatie (TLS wordt op de gateway beëindigd), WAF (beschermt tegen OWASP Top 10), cookie-based sessie-affiniteit, HTTP-header herschrijving. Kies Application Gateway voor web-applicaties; Load Balancer voor generiek TCP/UDP of hoge doorvoer.

2. Application Gateway: regionaal — load balanceert binnen één Azure-regio. Geschikt voor webtoepassingen die in één regio draaien. Azure Front Door: globaal — distribueert verkeer over meerdere regio's op basis van latentie, prioriteit of geo-proximity. Biedt ook CDN, DDoS-beveiliging, globale WAF en anycast-routing. Kies Front Door voor multi-regio-applicaties of wanneer je een globaal CDN met failover nodig hebt.

3. SNAT (Source NAT): wanneer een VM zonder publiek IP via de Load Balancer uitgaand internetverkeer verstuurt, vertaalt de Load Balancer het privé bron-IP naar het frontend (publiek) IP van de Load Balancer. Dit stelt de VM in staat internetsites te bereiken. SNAT heeft een beperkt aantal poorten per publiek IP (64.000 per IP). Bij grootschalige outbound workloads kan SNAT-port exhaustion optreden; de oplossing is een NAT Gateway die meer SNAT-poorten biedt.

4. Service tags zijn vooraf gedefinieerde groepen van IP-bereiken die bij een Azure-service horen. Voorbeelden: AzureMonitor (IP's van Azure Monitor), Storage.WestEurope (IP's van Storage in West Europe), VirtualNetwork (het VNet-adresruimte), Internet (alle publieke IP's buiten Azure). Je gebruikt ze in NSG-regels als bron of doel zodat je geen individuele IP-adressen hoeft bij te houden die door Microsoft kunnen wijzigen. Voorbeeld: sta inbound toe van de service tag AzureLoadBalancer om health probes te laten werken.

</details>

---

**Scenario-vragen:**

5. Een bedrijf deployt een webapplicatie met twee backend pools: één voor de web-frontend (`/`) en één voor de REST API (`/api/*`). Ze hebben ook SSL-terminatie en WAF-bescherming nodig. Welke Azure-service moet worden gebruikt?
   - A) Azure Standard Load Balancer met twee backend pools
   - B) Azure Application Gateway met WAF en path-based routing rules
   - C) Azure Front Door met twee origin groups
   - D) Een NSG met aparte regels voor poort 80 en poort 443

<details>
<summary>Antwoord</summary>

**B) Azure Application Gateway met WAF en path-based routing rules.** Application Gateway ondersteunt path-based routing, WAF en SSL-terminatie in één regionale service. Load Balancer (A) kan geen URL-paden inspecteren. Front Door (C) is globaal en geschikt voor meerdere regio's, maar voegt onnodige complexiteit toe voor een single-region applicatie. NSGs (D) hebben geen HTTP-laagbewustheid.

</details>

6. Backend VMs in een Load Balancer-pool beginnen te falen bij het maken van uitgaande HTTPS-verbindingen naar een externe betalings-API. De VMs hebben geen publieke IP's. Network Watcher toont dat de uitgaande verbindingen worden geprobeerd maar een time-out krijgen. Wat is de meest waarschijnlijke oorzaak?
   - A) De NSG op het backend-subnet blokkeert inkomend verkeer op poort 443
   - B) SNAT port exhaustion — het frontend-IP van de Load Balancer heeft geen ephemere poorten meer beschikbaar voor uitgaande verbindingen
   - C) De health probe faalt, waardoor de Load Balancer al het verkeer blokkeert
   - D) De VMs kunnen internet niet bereiken zonder een publiek IP direct toegewezen aan de NIC

<details>
<summary>Antwoord</summary>

**B) SNAT port exhaustion — het frontend-IP van de Load Balancer heeft geen ephemere poorten meer beschikbaar voor uitgaande verbindingen.** SNAT exhaustion is een veelvoorkomend productieprobleem wanneer veel VMs een enkel frontend-IP delen en grote hoeveelheden uitgaande verbindingen maken. Elke TCP-verbinding verbruikt een ephemere SNAT-poort. De oplossing is een NAT Gateway toevoegen of extra frontend-IPs. NSG-regels (A) zouden specifieke poorten blokkeren voor al het verkeer, niet time-outs veroorzaken. Health probe-fout (C) beïnvloedt inkomende distributie, niet uitgaand verkeer. VMs zonder publieke IPs kunnen internet nog steeds bereiken via SNAT (D).

</details>

7. Een bedrijf plant hun applicatie uit te breiden naar gebruikers in Zuidoost-Azië terwijl de primaire infrastructuur in West Europe blijft. Ze willen dat gebruikers automatisch worden gerouteerd naar de dichtstbijzijnde gezonde regio. Welke service biedt deze mogelijkheid?
   - A) Azure Application Gateway gedeployed in beide regio's
   - B) Azure Load Balancer met een global SKU
   - C) Azure Traffic Manager met op-prestaties-gebaseerde routing
   - D) Azure Front Door met latentiegebaseerde routing naar regionale backends

<details>
<summary>Antwoord</summary>

**D) Azure Front Door met latentiegebaseerde routing naar regionale backends.** Azure Front Door biedt globale anycast-routing met latentiegebaseerde routing, health probes over regio's en CDN-caching — precies ontworpen voor dit multi-regio scenario. Traffic Manager (C) ondersteunt ook geo/prestatierouting op DNS-niveau maar mist CDN en WAF-mogelijkheden. Application Gateway (A) is alleen regionaal. Load Balancer Global SKU (B) verwerkt cross-regio TCP/UDP-taakverdeling maar heeft geen HTTP-laagfuncties.

</details>

---

## Week 7 — Monitoring en Azure Monitor
> **Examendomein:** Azure-resources monitoren en onderhouden · **Gewicht:** 10–15%

> **Praktijkscenario:** Een Sogeti-klant draait een productie-ERP op Azure VMs en meldt op maandagochtend terugkerende performanceproblemen. Het operations-team heeft geen centrale logging en werkt vooral via ad-hoc RDP-sessies en Event Viewer. Je moet Azure Monitor en Log Analytics implementeren, CPU-alerting automatiseren en Azure Backup met aantoonbare restore-procedure inrichten voor de volgende kwartaalreview.

### Leerdoelen
- [ ] Een Log Analytics Workspace aanmaken en Azure VMs verbinden via de Azure Monitor Agent
- [ ] KQL-queries schrijven voor veelvoorkomende examenvragen (CPU, aanmeldingsfouten, activiteitslog)
- [ ] Een alert rule aanmaken op basis van een metric en een action group met e-mailnotificatie configureren
- [ ] Azure Backup configureren voor een Recovery Services Vault en een test-restore uitvoeren
- [ ] Azure Site Recovery inrichten voor een VM en een test-failover naar een secundaire regio uitvoeren
- [ ] Het verschil kennen tussen Azure Backup en Azure Site Recovery voor het examen

### MS Learn modules
- [Configure Azure Monitor](https://learn.microsoft.com/en-us/training/modules/configure-azure-monitor/)
- [Configure Log Analytics](https://learn.microsoft.com/en-us/training/modules/configure-log-analytics/)
- [Configure Azure alerts and action groups](https://learn.microsoft.com/en-us/training/modules/configure-azure-alerts/)
- [Configure Azure Backup and recovery](https://learn.microsoft.com/en-us/training/modules/configure-azure-backup/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Azure Monitor | Overkoepelend platform voor metrics, logs, alerts, dashboards en workbooks |
| Metrics | Numerieke tijdreeksdata (CPU %, netwerk-bytes, schijf-IOPS); bewaard 93 dagen; ideaal voor trends en alerts |
| Log Analytics | Log-aggregatieservice en KQL-querytool; bewaart logs standaard 30 dagen (configureerbaar tot 2 jaar) |
| Azure Monitor Agent (AMA) | Nieuwe diagnostische agent die MMA/OMS vervangt; installeert via Data Collection Rules |
| KQL | Kusto Query Language: de querytaal voor Log Analytics; basisoperators zijn where, project, summarize, order by |
| Action Group | Definitie van meldingsacties bij een alert (e-mail, SMS, webhook, ITSM, Azure Function); herbruikbaar over meerdere alertregels |
| Alert rule | Trigger gebaseerd op een metric-drempel, een KQL-query-resultaat of een activiteitslogbericht |
| Recovery Services Vault | Container voor Azure Backup (VMs, SQL, Azure Files) en Azure Site Recovery |
| Azure Backup | Beheerde back-upservice die herstelpunten aanmaakt; beschermt tegen dataverlies, ransomware en onbedoelde verwijdering |
| Azure Site Recovery (ASR) | Disaster recovery: repliceert VMs naar een secundaire regio; bij een regio-uitval voer je een failover uit |
| NSG flow logs | Registreert welk verkeer door NSG-regels gaat; opgeslagen in een storage account; te analyseren met Traffic Analytics |

### Lab oefeningen (Azure portal + SSW-Lab)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Maak een *Log Analytics Workspace* aan → verbind de Azure VMs |
| **Azure portal** | Schakel *VM Insights* in → bekijk Performance en Map tabblad |
| **Azure portal** | Schrijf een KQL-query: CPU > 80% in de afgelopen 24 uur |
| **Azure portal** | Maak een *Alert rule* aan: CPU > 85% → email naar beheerder |
| **LAB-DC01** | Installeer de *Azure Monitor Agent (AMA)* → verifieer in Log Analytics |
| **Azure portal** | Configureer een *Recovery Services Vault* → backup DC01-bestanden |
| **Azure portal** | Voer een *test restore* uit → herstel een bestand naar alternatieve locatie |
| **Azure portal** | Configureer *Azure Site Recovery* voor een VM → voer een test-failover uit naar een secundaire regio |

### Labcommando's

```powershell
# Query CPU-gebruik boven 80% voor een VM in de afgelopen 24 uur (KQL in Log Analytics)
Perf
| where TimeGenerated > ago(24h)
| where CounterName == "% Processor Time"
| where CounterValue > 80
| project TimeGenerated, Computer, CounterValue
| order by TimeGenerated desc

# Maak een Log Analytics-workspace aan via CLI
az monitor log-analytics workspace create --resource-group rg-sswlab-dev --workspace-name sswlab-law --location westeurope

# Maak een action group aan voor e-mailwaarschuwingen
az monitor action-group create --resource-group rg-sswlab-dev --name sswlab-ag --short-name ssw-ag --email-receiver name=AdminEmail email=admin@example.com

# Maak een CPU-metrische waarschuwingsregel aan
az monitor metrics alert create --resource-group rg-sswlab-dev --name "HighCPU-Alert" --scopes /subscriptions/<sub-id>/resourceGroups/rg-sswlab-dev/providers/Microsoft.Compute/virtualMachines/sswlab-vm01 --condition "avg Percentage CPU > 85" --window-size 5m --evaluation-frequency 1m --action sswlab-ag
```

### Kennischeck
1. Wat is het verschil tussen *Azure Monitor Metrics* en *Azure Monitor Logs*?
2. Hoe werkt *Azure Alerts* — wat zijn *action groups*?
3. Schrijf een KQL-query: alle failed sign-ins uit de afgelopen week.
4. Wat is het verschil tussen *Azure Backup* en *Azure Site Recovery*?

<details>
<summary>Antwoorden</summary>

1. Azure Monitor Metrics: numerieke tijdreeksdata verzameld elke minuut van Azure-resources (CPU %, netwerk-bytes, IOPS). Bewaard 93 dagen. Geoptimaliseerd voor dashboards en drempelgebaseerde alerts. Lage latentie. Azure Monitor Logs: tekst-gebaseerde, gestructureerde logdata opgeslagen in een Log Analytics-workspace. Afkomstig van diagnostische instellingen, agents (Windows Event Log, Syslog) en Azure Activity Logs. Analyseerbaar via KQL. Bewaard standaard 30 dagen. Gebruik Metrics voor real-time monitoring en snelle alerts; gebruik Logs voor root-cause analysis, beveiligingsonderzoek en complexe correlaties.

2. Azure Alerts bewaken continu een conditie (metric-drempel, KQL-query, activiteitslogbericht) en vuren af als die conditie waar is. Workflow: Alert rule evalueert de conditie → als actief, wordt een alert gegenereerd → de alert roept een Action Group aan. Action Group: een herbruikbare definitie van wie en hoe er gewaarschuwd wordt. Kan bevatten: e-mail, SMS, voice call, Azure Function aanroepen, webhook naar een ITSM-systeem (ServiceNow), Logic App triggeren. Meerdere alertregels kunnen naar dezelfde Action Group wijzen.

3. KQL-query voor failed sign-ins uit de afgelopen 7 dagen (vereist Microsoft Entra ID-logs in Log Analytics):
   ```
   SigninLogs
   | where TimeGenerated > ago(7d)
   | where ResultType != "0"
   | project TimeGenerated, UserPrincipalName, ResultType, ResultDescription, IPAddress, Location
   | order by TimeGenerated desc
   ```
   ResultType "0" betekent succes; alle andere waarden zijn fouten of blokkades. Alternatief via AuditLogs voor Entra-gerelateerde activiteiten.

4. Azure Backup: beschermt tegen dataverlies door periodieke herstelpunten (snapshots/back-ups) te maken. Herstel is op bestandsniveau, schijfniveau of VM-niveau. Gebruik bij: onbedoelde verwijdering, corruptie, ransomware. De VM blijft in dezelfde regio. Herstel duurt minuten tot uren afhankelijk van de omvang. Azure Site Recovery (ASR): disaster recovery service die een volledige VM continu repliceert naar een secundaire Azure-regio. Bij een regio-uitval voer je een failover uit: de VM wordt actief in de doelregio. Herstel van de bedrijfsvoering duurt minuten. Gebruik ASR voor bedrijfscontinuïteit bij regio-uitval; gebruik Azure Backup voor reguliere gegevensherstelscenario's.

</details>

---

**Scenario-vragen:**

5. Een bedrijf wil een e-mailmelding ontvangen wanneer er een resource wordt verwijderd uit hun Azure-subscription. Welke Azure Monitor-functie en logbron moeten ze configureren?
   - A) Een metric alert rule op het CPU-gebruik van de subscription
   - B) Een log alert rule gebaseerd op het Azure Activity Log met een query op "Delete"-bewerkingen
   - C) Een NSG flow log alert voor al het uitgaande verkeer
   - D) Een VM Insights-alert voor schijf-I/O

<details>
<summary>Antwoord</summary>

**B) Een log alert rule gebaseerd op het Azure Activity Log met een query op "Delete"-bewerkingen.** Het Azure Activity Log registreert alle beheervlakbewerkingen, inclusief het verwijderen van resources. Een log alert rule die de `AzureActivity`-tabel bevraagt op `OperationName contains "delete"` en `ActivityStatus == "Succeeded"` activeert de action group. Metric alerts (A) en NSG flow logs (C) zijn niet relevant voor het verwijderen van resources. VM Insights (D) bewaakt prestatiedata.

</details>

6. Een operationeel team ontvangt te veel ruisige meldingen van een CPU metric alert die is geconfigureerd met een evaluatievenster van 1 minuut en een venstergrootte van 5 minuten. De alerts worden geactiveerd tijdens korte pieken die zichzelf oplossen. Welke configuratiewijziging vermindert valse positieven zonder echte aanhoudende hoge CPU te missen?
   - A) De CPU-drempel verlagen van 85% naar 70%
   - B) De evaluatiefrequentie verhogen van 1 minuut naar 15 minuten
   - C) De venstergrootte verhogen naar 15 of 30 minuten zodat de alert alleen afgaat als de CPU gedurende een langere periode verhoogd blijft
   - D) De alertregel uitschakelen tijdens kantooruren

<details>
<summary>Antwoord</summary>

**C) De venstergrootte verhogen naar 15 of 30 minuten zodat de alert alleen afgaat als de CPU gedurende een langere periode verhoogd blijft.** Door de aggregatievenstergrootte te vergroten (bijv. naar 15 minuten), gaat de alert alleen af als de CPU gedurende het volledige venster boven de drempel blijft, waardoor kortstondige pieken worden uitgefilterd. De drempel verlagen (A) zou alerts vaker laten afgaan. De evaluatiefrequentie verhogen (B) zonder het venster te wijzigen vermindert de ruis niet. Uitschakelen tijdens kantooruren (D) verwijdert volledig het zicht.

</details>

7. Een bedrijf heeft een Recovery Services Vault met dagelijkse VM-back-ups die 30 dagen worden bewaard. Een ontwikkelaar verwijdert per ongeluk kritieke applicatiedata van de datadisk van een VM om 14:00 vandaag. De laatste back-up is om 03:00 vandaag voltooid. Welke data kan worden hersteld en wat gaat verloren?
   - A) Alle data tot 14:00 vandaag kan worden hersteld omdat Azure Backup wijzigingen continu vastlegt
   - B) Data van de back-up van 03:00 kan worden hersteld; ongeveer 11 uur aan wijzigingen aangebracht tussen 03:00 en 14:00 gaan verloren
   - C) Er kan geen data worden hersteld omdat de schijf niet is verwijderd, alleen de data erop
   - D) De volledige VM moet worden hersteld; individueel bestandsherstel is niet mogelijk met Azure Backup

<details>
<summary>Antwoord</summary>

**B) Data van de back-up van 03:00 kan worden hersteld; ongeveer 11 uur aan wijzigingen aangebracht tussen 03:00 en 14:00 gaan verloren.** Azure Backup maakt punt-in-tijd snapshots op een schema (in dit geval dagelijks om 03:00). Herstel is mogelijk tot het laatste herstelpunt. Data die is geschreven tussen de laatste back-up en het verwijderingsmoment kan niet worden hersteld vanuit back-up. Individueel bestandsherstel (Item Level Recovery) wordt ondersteund door Azure Backup, wat optie D weerlegt.

</details>

---

## Week 8 — Examenvoorbereiding

### Examendekking en verplichte labs

Doel: van goede basis naar volledige exam-dekking met cloudpraktijk.

### Nog expliciet af te dekken
1. ARM templates en Bicep hands-on, inclusief aanpassen en deployen.
2. VM Scale Sets en compute-schaalscenario's.
3. Storage security details, zoals firewalls, soft delete, versioning en replicatiekeuzes.
4. Backup-vault varianten en herstelrapportage.

### Verplichte labs voor slaagkans
1. Deploy 1 resource set met ARM en 1 met Bicep, en leg verschillen vast.
2. Maak een VM Scale Set met autoscale regels en voer een loadtest uit.
3. Configureer storage firewall plus private endpoint en valideer toegangsbeperkingen.
4. Configureer blob soft delete, versioning en lifecycle policy in 1 scenario.
5. Voer een Azure Site Recovery test failover uit en documenteer failback-stappen.

### Exit criteria voordat je examen plant
1. Je kunt alle vijf AZ-104 domeinen praktisch aantonen in portal, CLI en PowerShell.
2. Je beheerst networking-troubleshooting met Network Watcher in realistische cases.
3. Je hebt minimaal 2 volledige herhaalruns gedaan van identity, networking en recovery.

---

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenstudiegids](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104)
- Doe de **Microsoft Learn oefenassessment** AZ-104: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Oefen resource-aanmaak via **Azure CLI** en **PowerShell (Az module)** — examen bevat CLI-vragen
- Herhaal VNet-architectuur en NSG-scenario's (meest gestelde vragen)
- Verwijder alle Azure-resources om kosten te voorkomen: `az group delete -n rg-sswlab-dev`
- Plan je examen via Pearson VUE

### Aandachtspunten voor het examen
- Networking: NSG-regels, UDR, VNet peering, Private Endpoints, Azure Bastion — zwaar gewogen
- VM availability: ken het verschil Availability Set / Zone / VMSS exact
- Storage: redundantie-opties (LRS/ZRS/GRS), tier-beheer, blob versioning, soft delete
- Compute: ARM templates én Bicep files — beide zijn in scope
- RBAC: scope-levels (management group → subscription → resource group → resource)
- Backup & recovery: verschil tussen Azure Backup en Azure Site Recovery (failover)
- KQL: basisquery's (where, summarize, project) komen voor in casevragen

### Veelgemaakte fouten op het examen

| Valstrik | Onthoud |
|----------|---------|
| VNet peering is transitief | **Nee** — A→B en B→C betekent NIET dat A→C werkt |
| NSG-prioriteit: hogere waarde = hogere prioriteit | **Nee** — lagere getal = hogere prioriteit (100 wint van 4000) |
| Resource lock werkt alleen voor Owners | **Nee** — lock overschrijft RBAC; ook Owners worden geblokkeerd |
| SAS-tokens kunnen altijd worden herroepen | **Nee** — alleen als ze gekoppeld zijn aan een Stored Access Policy |
| GRS repliceert altijd leesbaar naar de secundaire regio | **Nee** — alleen met RA-GRS is de secundaire regio altijd leesbaar |
| Azure Policy = alleen "Deny" | **Nee** — ook Audit, Append, Modify, DeployIfNotExists |
| Availability Sets beschermen bij datacenteruitval | **Nee** — Availability Sets beschermen alleen binnen één datacenter |
| VMSS vereist handmatige schaalregels | **Nee** — VMSS kan automatisch schalen op basis van metrics |
