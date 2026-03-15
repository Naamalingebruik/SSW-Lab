# Studieprogramma AZ-104 — Azure Administrator

**Duur:** 8 weken · **Lab preset:** Minimal (DC01 · W11-01) — Azure-taken draaien in de cloud  
**MS Learn pad:** [Azure Administrator](https://learn.microsoft.com/en-us/certifications/exams/az-104/)  
**Examengewicht:**

| Domein | Gewicht |
|---|---|
| Azure identiteiten en governance beheren | 15–20% |
| Storage implementeren en beheren | 15–20% |
| Azure compute resources deployen en beheren | 20–25% |
| Virtuele netwerken implementeren en beheren | 25–30% |
| Azure resources monitoren en onderhouden | 10–15% |

> **Voorwaarde:** Azure subscription via MSDN/Visual Studio Subscriptions (maandelijks tegoed)  
> De SSW-Lab VMs dienen als *hybride on-premises endpoint* voor sommige labs (VPN, Azure Arc)

---

## Week 1 — Azure identiteiten en governance

### MS Learn modules
- [Manage Azure identities and governance](https://learn.microsoft.com/en-us/training/paths/az-104-manage-identities-governance/)
- [Configure Azure Active Directory](https://learn.microsoft.com/en-us/training/modules/configure-azure-active-directory/)
- [Configure user and group accounts](https://learn.microsoft.com/en-us/training/modules/configure-user-group-accounts/)
- [Configure subscriptions and governance](https://learn.microsoft.com/en-us/training/modules/configure-subscriptions/)

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

---

## Week 2 — Storage implementeren en beheren

### MS Learn modules
- [Configure storage accounts](https://learn.microsoft.com/en-us/training/modules/configure-storage-accounts/)
- [Configure Azure Blob Storage](https://learn.microsoft.com/en-us/training/modules/configure-blob-storage/)
- [Configure Azure Files and Azure File Sync](https://learn.microsoft.com/en-us/training/modules/configure-azure-files-file-sync/)
- [Configure Azure Storage security](https://learn.microsoft.com/en-us/training/modules/configure-storage-security/)

### Lab oefeningen (SSW-Lab + Azure portal)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Maak een Storage Account aan: LRS, General Purpose v2, Hot tier |
| **Azure portal** | Maak een Blob container aan → upload een testbestand |
| **Azure portal** | Genereer een *Shared Access Signature (SAS)* met leesrechten, 1 uur geldig |
| **SSW-W11-01** | Gebruik Azure Storage Explorer of `azcopy` om naar blob te uploaden |
| **Azure portal** | Maak een *Azure File Share* aan → verbind via SMB (`net use Z: \\...`) |
| **SSW-DCO1** | Installeer Azure File Sync agent → registreer server → sync SSW-DC01-map |
| **Azure portal** | Configureer *Lifecycle management policy*: verplaats naar Cool na 30 dagen |

### Kennischeck
1. Wat zijn de storage tiers en wanneer gebruik je welke?
2. Wat is het verschil tussen een *SAS token* en een *access key*?
3. Hoe werkt *Azure File Sync* en wat is *cloud tiering*?
4. Wat is het verschil tussen *LRS*, *ZRS*, *GRS* en *GZRS*?

---

## Week 3 — Virtual Machines deployen en beheren

### MS Learn modules
- [Configure virtual machines](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machines/)
- [Configure virtual machine availability](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-availability/)
- [Configure virtual machine extensions](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-extensions/)

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

---

## Week 4 — Containers en Azure App Service

### MS Learn modules
- [Configure Azure App Service](https://learn.microsoft.com/en-us/training/modules/configure-azure-app-services/)
- [Configure Azure Container Instances](https://learn.microsoft.com/en-us/training/modules/configure-azure-container-instances/)
- [Configure Azure Kubernetes Service basics](https://learn.microsoft.com/en-us/training/modules/intro-to-kubernetes/)

### Lab oefeningen (Azure portal + CloudShell)
| Omgeving | Taak |
|---|---|
| **Azure CloudShell** | Deployeer een simpele webapp: `az webapp create --sku F1 --name sswlab-app ...` |
| **Azure portal** | Configureer *deployment slot* (staging) → doe een *swap* naar productie |
| **Azure portal** | Deployeer een Azure Container Instance met een nginx-image |
| **Azure CloudShell** | `az container create --image nginx --dns-name-label sswlab-ci ...` |
| **Azure portal** | Configureer een *App Service plan* → schaal uit naar 2 instanties |
| **Azure portal** | Bekijk *App Service Diagnostics* → analyseer beschikbaarheids-grafiek |

### Kennischeck
1. Wat is het verschil tussen *Azure Container Instances* en *Azure Kubernetes Service*?
2. Hoe werken *deployment slots* en waarom is *slot swap* nuttig?
3. Wat is het verschil tussen een *App Service plan* en *Consumption plan* voor Azure Functions?
4. Hoe configureer je *autoscaling* gebaseerd op CPU-gebruik?

---

## Week 5 — Virtuele netwerken

### MS Learn modules
- [Configure virtual networks](https://learn.microsoft.com/en-us/training/modules/configure-virtual-networks/)
- [Configure network security groups](https://learn.microsoft.com/en-us/training/modules/configure-network-security-groups/)
- [Configure Azure DNS](https://learn.microsoft.com/en-us/training/modules/configure-azure-dns/)
- [Configure virtual network peering](https://learn.microsoft.com/en-us/training/modules/configure-vnet-peering/)

### Lab oefeningen (Azure portal + SSW-Lab)
| Omgeving | Taak |
|---|---|
| **Azure portal** | Maak een VNet aan: `10.100.0.0/16` met subnets `frontend/10.100.1.0/24` en `backend/10.100.2.0/24` |
| **Azure portal** | Configureer een *NSG*: sta HTTP/HTTPS in, blokkeer al het overige inbound |
| **Azure portal** | Koppel NSG aan het frontend-subnet → test met VM in backend |
| **Azure portal** | Maak een tweede VNet aan → configureer *VNet peering* tussen beide |
| **Azure portal** | Configureer een *Azure Private DNS Zone* → registreer VMs automatisch |
| **SSW-W11-01** | Configureer een *Point-to-Site VPN* naar het Azure VNet → test verbinding |
| **Azure portal** | Bekijk *Effective routes* op de NIC van een VM |

### Kennischeck
1. Wat is het verschil tussen een *NSG* op subnet-niveau en op NIC-niveau?
2. Hoe werkt *VNet peering* — is het transitief?
3. Wat is het verschil tussen *Azure DNS* public zones en *Private DNS Zones*?
4. Wat is *service endpoint* versus *private endpoint*?

---

## Week 6 — Load balancing en netwerkrouting

### MS Learn modules
- [Configure Azure Load Balancer](https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/)
- [Configure Azure Application Gateway](https://learn.microsoft.com/en-us/training/modules/configure-azure-application-gateway/)
- [Configure network routing and endpoints](https://learn.microsoft.com/en-us/training/modules/configure-network-routing-endpoints/)
- [Configure Azure Firewall](https://learn.microsoft.com/en-us/training/modules/configure-azure-firewall/)

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

---

## Week 7 — Monitoring en Azure Monitor

### MS Learn modules
- [Configure Azure Monitor](https://learn.microsoft.com/en-us/training/modules/configure-azure-monitor/)
- [Configure Log Analytics](https://learn.microsoft.com/en-us/training/modules/configure-log-analytics/)
- [Configure Azure alerts and action groups](https://learn.microsoft.com/en-us/training/modules/configure-azure-alerts/)
- [Configure Azure Backup and recovery](https://learn.microsoft.com/en-us/training/modules/configure-azure-backup/)

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

### Kennischeck
1. Wat is het verschil tussen *Azure Monitor Metrics* en *Azure Monitor Logs*?
2. Hoe werkt *Azure Alerts* — wat zijn *action groups*?
3. Schrijf een KQL-query: alle failed sign-ins uit de afgelopen week.
4. Wat is het verschil tussen *Azure Backup* en *Azure Site Recovery*?

---

## Week 8 — Examenvoorbereiding

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenprofiel](https://learn.microsoft.com/en-us/certifications/exams/az-104/)
- Doe de **Microsoft Learn oefenassessment** AZ-104: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Oefen resource-aanmaak via **Azure CLI** en **PowerShell (Az module)** — examen bevat CLI-vragen
- Herhaal VNet-architectuur en NSG-scenario's (meest gestelde vragen)
- Verwijder alle Azure-resources om kosten te voorkomen: `az group delete -n rg-sswlab-dev`
- Plan je examen via Pearson VUE

### Aandachtspunten voor het examen
- Networking: NSG-regels, UDR, VNet peering, Private Endpoints — zwaar gewogen
- VM availability: ken het verschil Availability Set / Zone / VMSS exact
- Storage: redundantie-opties (LRS/ZRS/GRS) en tier-beheer
- RBAC: scope-levels (management group → subscription → resource group → resource)
- KQL: basisquery's (where, summarize, project) komen voor in casevragen
