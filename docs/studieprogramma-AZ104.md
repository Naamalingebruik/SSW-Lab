# Studieprogramma AZ-104 — Azure Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-AZ104.md)

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
> **Examendomein:** Manage Azure identities and governance · **Gewicht:** 20–25%

### Leerdoelen
- [ ] Entra ID-gebruikers en -groepen aanmaken en beheren via Azure portal en Azure CLI
- [ ] Azure RBAC-rollen toewijzen op resource group- en subscription-niveau en het verschil begrijpen met Entra ID-directoryrrollen
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
| Begriff | Uitleg |
|---------|--------|
| Entra ID (Azure AD) | Microsofts cloud-identiteitsservice voor Azure en Microsoft 365; beheert gebruikers, groepen en applicaties |
| Azure RBAC | Role-Based Access Control voor Azure-resources; rollen worden toegewezen op een scope (MG, subscription, RG, resource) |
| Entra ID-rollen | Directoryrrollen die beheer van Entra ID zelf regelen (bijv. Global Admin, User Admin) — los van Azure RBAC |
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
| **SSW-W11-01** | Gebruik Azure CLI: `az group list --output table` |
| **Azure portal** | Maak een *Cost budget alert* in op €50 voor `rg-sswlab-dev` |

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

## Week 2 — Storage implementeren en beheren
> **Examendomein:** Implement and manage storage · **Gewicht:** 15–20%

### Leerdoelen
- [ ] Een Storage Account aanmaken met de juiste redundantieoptie (LRS/ZRS/GRS/GZRS) voor het scenario
- [ ] Blob containers aanmaken, bestanden uploaden en access tiers (Hot/Cool/Cold/Archive) correct toepassen
- [ ] Een Shared Access Signature (SAS) genereren met beperkte rechten en geldigheidsduur
- [ ] Een Azure File Share aanmaken en koppelen als netwerkschijf via SMB op SSW-W11-01
- [ ] Azure File Sync installeren op SSW-DC01, een server registreren en cloud tiering begrijpen
- [ ] Een Lifecycle Management Policy configureren die blobs automatisch verplaatst of verwijdert

### MS Learn modules
- [Configure storage accounts](https://learn.microsoft.com/en-us/training/modules/configure-storage-accounts/)
- [Configure Azure Blob Storage](https://learn.microsoft.com/en-us/training/modules/configure-blob-storage/)
- [Configure Azure Files and Azure File Sync](https://learn.microsoft.com/en-us/training/modules/configure-azure-files-file-sync/)
- [Configure Azure Storage security](https://learn.microsoft.com/en-us/training/modules/configure-storage-security/)

### Kernbegrippen
| Begriff | Uitleg |
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
| **SSW-W11-01** | Gebruik Azure Storage Explorer of `azcopy` om naar blob te uploaden |
| **Azure portal** | Maak een *Azure File Share* aan → verbind via SMB (`net use Z: \\...`) |
| **SSW-DC01** | Installeer Azure File Sync agent → registreer server → sync SSW-DC01-map |
| **Azure portal** | Configureer *Lifecycle management policy*: verplaats naar Cool na 30 dagen |

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

4. LRS: 3 kopieën in één datacenter; bescherming tegen server- of schijfuitval, niet bij datacenteruitval. ZRS: 3 kopieën in 3 aparte availability zones binnen dezelfde regio; beschermt bij uitval van één datacenter. GRS: LRS in primaire regio plus asynchroon repliceren naar een secundaire regio (honderden km's weg); beschermt bij volledige regio-uitval, maar de secundaire regio is standaard alleen leesbaar via Microsoft-initiated failover (RA-GRS maakt de secundaire altijd leesbaar). GZRS: combineert ZRS in de primaire regio met GRS naar de secundaire regio; maximale bescherming zowel bij zoneals bij regio-uitval.

</details>

---

## Week 3 — Virtual Machines deployen en beheren
> **Examendomein:** Deploy and manage Azure compute resources · **Gewicht:** 20–25%

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
| Begriff | Uitleg |
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

## Week 4 — Containers en Azure App Service
> **Examendomein:** Deploy and manage Azure compute resources · **Gewicht:** 20–25%

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
| Begriff | Uitleg |
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

## Week 5 — Virtuele netwerken
> **Examendomein:** Implement and manage virtual networking · **Gewicht:** 15–20%

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
| Begriff | Uitleg |
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
| **SSW-W11-01** | Configureer een *Point-to-Site VPN* naar het Azure VNet → test verbinding |
| **Azure portal** | Deployeer *Azure Bastion* → verbind met een VM zonder publiek IP of RDP-poort |
| **Azure portal** | Configureer een *Private Endpoint* voor een Storage Account → verifieer DNS-resolutie |
| **Azure portal** | Bekijk *Effective routes* op de NIC van een VM |

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

## Week 6 — Load balancing en netwerkrouting
> **Examendomein:** Implement and manage virtual networking · **Gewicht:** 15–20%

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
| Begriff | Uitleg |
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

## Week 7 — Monitoring en Azure Monitor
> **Examendomein:** Monitor and maintain Azure resources · **Gewicht:** 10–15%

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
| Begriff | Uitleg |
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
| **SSW-DC01** | Installeer de *Azure Monitor Agent (AMA)* → verifieer in Log Analytics |
| **Azure portal** | Configureer een *Recovery Services Vault* → backup DC01-bestanden |
| **Azure portal** | Voer een *test restore* uit → herstel een bestand naar alternatieve locatie |
| **Azure portal** | Configureer *Azure Site Recovery* voor een VM → voer een test-failover uit naar een secundaire regio |

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

## Week 8 — Examenvoorbereiding

### Exam Coverage Gaps en Must-Do Labs

Doel: van goede basis naar volledige exam-dekking met cloudpraktijk.

### Nog expliciet af te dekken
1. ARM templates en Bicep hands-on, inclusief aanpassen en deployen.
2. VM Scale Sets en compute-schaalscenario's.
3. Storage security details, zoals firewalls, soft delete, versioning en replicatiekeuzes.
4. Backup-vault varianten en herstelrapportage.

### Must-do labs voor slaagkans
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
