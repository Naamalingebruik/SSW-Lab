# Study Guide AZ-104 — Azure Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-AZ104.md)

**Duration:** 8 weeks · **Lab preset:** Minimal (DC01 · W11-01) — Azure tasks run in the cloud
**MS Learn path:** [Azure Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104)
**Exam weight:**

| Domain | Weight |
|---|---|
| Manage Azure identities and governance | 20–25% |
| Implement and manage storage | 15–20% |
| Deploy and manage Azure compute resources | 20–25% |
| Implement and manage virtual networking | 15–20% |
| Monitor and maintain Azure resources | 10–15% |

> **Prerequisite:** Azure subscription via MSDN/Visual Studio Subscriptions (monthly credit)
> The SSW-Lab VMs serve as a *hybrid on-premises endpoint* for some labs (VPN, Azure Arc)
> **Tenant note:** the shared dev tenant helps with Entra and identity topics, but most of AZ-104 still requires real Azure resources. Follow the guide explicitly when it tells you to switch from local VM work to the tenant or Azure subscription.

## How to use this study guide

- Start each week by reading the learning objectives and deciding which tasks must happen in Azure itself versus which tasks are only supported by SSW-Lab.
- Work cost-consciously throughout the lab: note what you create and remove resources on the same day when they are no longer needed.
- Complete the knowledge check only after doing both the portal and CLI/PowerShell work; AZ-104 often tests whether you recognise multiple administration paths.
- If you work in a mixed Dutch/English team, keep key terms aligned in both languages, such as *resource group / resourcegroep* and *management group / beheerlaag*.

## Lab coverage and expectations

- **Strong SSW-Lab support:** hybrid identity fundamentals, Azure CLI from Windows clients, Azure File Sync integration, networking concepts, and selected administration and monitoring exercises.
- **Partial coverage:** many AZ-104 objectives live primarily in Azure; the local VMs mainly support Arc, VPN, File Sync, and hybrid identity scenarios.
- **Cloud-first areas:** compute, storage, VNets, load balancing, monitoring, backup, and governance should mainly be practised in the Azure portal and via CLI/PowerShell.
- Treat this as a complete study route, but not as a local-only lab: the real exam fit comes from consistently creating and cleaning up Azure resources yourself.

## How to use the knowledge checks

- Answer every question by first identifying the correct scope and management layer.
- Verify that you understand not only the portal path, but the underlying platform concept as well.
- Revisit questions on storage redundancy, networking, and RBAC versus Policy, because these are easy to mix up in scenario questions.
- Tie each answer back to operational impact: cost, availability, security, and management overhead.

---

## Week 1 — Azure identities and governance
> **Exam domain:** Manage Azure identities and governance · **Weight:** 20–25%

> **Real-world scenario:** A Sogeti consultant is onboarding a newly acquired subsidiary of a financial services client. The subsidiary has its own Active Directory, 200 employees, and needs scoped access to specific Azure workloads without gaining visibility into the parent company's subscriptions. You are asked to design the RBAC delegation model, create a management group hierarchy, and enforce a policy that restricts resource creation to approved regions only.

### Learning Objectives
- [ ] Create and manage Entra ID users and groups, including guest (B2B) accounts
- [ ] Assign and verify Azure RBAC roles at management group, subscription, resource group, and resource scope
- [ ] Build a management group hierarchy and understand policy inheritance across scopes
- [ ] Assign and evaluate Azure Policy definitions to enforce allowed locations
- [ ] Configure Cost Management budget alerts to control lab spending
- [ ] Run basic Azure CLI commands from LAB-W11-01 to list and inspect resources

### MS Learn modules
- [Manage Azure identities and governance](https://learn.microsoft.com/en-us/training/paths/az-104-manage-identities-governance/)
- [Configure Azure Active Directory](https://learn.microsoft.com/en-us/training/modules/configure-azure-active-directory/)
- [Configure user and group accounts](https://learn.microsoft.com/en-us/training/modules/configure-user-group-accounts/)
- [Configure subscriptions and governance](https://learn.microsoft.com/en-us/training/modules/configure-subscriptions/)

### Key Concepts
| Term | Description |
|------|-------------|
| Entra ID | Microsoft's cloud identity platform (formerly Azure Active Directory); manages users, groups, and app registrations |
| Azure RBAC | Role-Based Access Control for Azure resources — controls *what* you can do with resources |
| Entra ID roles | Directory-level roles (e.g. Global Admin, User Admin) — control *who* can manage the directory itself, not resources |
| Management group | Hierarchical container above subscriptions; RBAC assignments and policies assigned here cascade to all child subscriptions |
| Azure Policy | Rules engine that evaluates resources against defined conditions and applies effects (Deny, Audit, Append, Modify, DeployIfNotExists) |
| Resource Group | Logical container for related Azure resources sharing a lifecycle; also a primary RBAC scope |
| Cost Management | Azure-native tool for monitoring spend, setting budgets, and triggering alerts when thresholds are reached |
| Resource lock | CanNotDelete or ReadOnly protection on resources; overrides RBAC — even Owners cannot delete a locked resource |

### Lab exercises (SSW-Lab + Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Create a *Resource Group*: `rg-sswlab-dev` in West Europe |
| **Azure portal** | Create an additional Entra ID user: `az-admin@<tenant>.onmicrosoft.com` |
| **Azure portal** | Assign the *Contributor* role to `az-admin` on the resource group via IAM |
| **Azure portal** | Create a *Management group* structure: Root → SSW → Dev/Prod |
| **Azure portal** | Assign an *Azure Policy*: "Allowed locations = West Europe, North Europe" |
| **LAB-W11-01** | Use Azure CLI: `az group list --output table` |
| **Azure portal** | Set up a *Cost budget alert* at €50 for `rg-sswlab-dev` |

### Lab commands

```powershell
# Create a new Entra ID user
az ad user create --display-name "AZ Admin" --user-principal-name az-admin@<tenant>.onmicrosoft.com --password "P@ssw0rd123!"

# Assign Contributor role on a resource group
az role assignment create --assignee az-admin@<tenant>.onmicrosoft.com --role "Contributor" --scope /subscriptions/<sub-id>/resourceGroups/rg-sswlab-dev

# List all role assignments in a resource group
az role assignment list --resource-group rg-sswlab-dev --output table

# Assign a built-in Azure Policy (Allowed locations)
az policy assignment create --name "allowed-locations" --policy "e56962a6-4747-49cd-b67b-bf8b01975c4f" --params '{"listOfAllowedLocations":{"value":["westeurope","northeurope"]}}'

# Create a budget alert
az consumption budget create --budget-name "sswlab-budget" --amount 50 --time-grain Monthly --resource-group rg-sswlab-dev --notifications '[{"enabled":true,"operator":"GreaterThan","threshold":80,"contactEmails":["admin@example.com"]}]'
```

### Knowledge check
1. What is the difference between *Azure RBAC* and *Entra ID roles*?
2. How does *Policy* compare to *RBAC* — when do you use which?
3. What is the difference between *Management Group*, *Subscription*, *Resource Group* and *Resource*?
4. How does *Azure Cost Management* work and how do you configure budget alerts?

<details>
<summary>Answers</summary>

1. **Azure RBAC** controls access to Azure *resources* (VMs, storage, networking, etc.) and is enforced at the Azure Resource Manager layer. Examples: Owner, Contributor, Reader. **Entra ID roles** control who can manage the *directory itself* — creating users, assigning licenses, configuring Conditional Access. These are two separate permission systems: being a Subscription Owner does not make you a Global Admin, and vice versa.

2. **Azure Policy** defines *what configuration is allowed or required* for resources — it is governance-focused and can block non-compliant deployments (Deny effect) or just report them (Audit). **RBAC** defines *who can perform actions* on resources. Use Policy to enforce infrastructure standards (e.g. "only West Europe"), and use RBAC to control who has the permissions to create or modify those resources. Both are complementary and can be assigned at management group scope to cascade across subscriptions.

3. The Azure scope hierarchy from broadest to narrowest: **Management Group** → **Subscription** → **Resource Group** → **Resource**. Management groups are purely governance containers. Subscriptions are billing and isolation boundaries. Resource Groups are lifecycle and deployment units — resources in the same group are typically deployed, managed, and deleted together. Resources are the individual services (VMs, storage accounts, etc.).

4. **Azure Cost Management** collects and analyses spend across subscriptions. A **budget alert** is configured by setting a spend threshold (e.g. €50/month) and alert conditions (e.g. at 80% and 100%). When the threshold is reached, Azure sends an email to configured recipients. Budgets are proactive — they warn before overspend occurs, unlike the Cost Analysis view which is retrospective.

5. A company acquires a new business unit and wants to give its IT team the ability to create and manage VMs in a specific subscription, but not to change network configurations or assign roles to others. Which built-in RBAC role should you assign?
   - A) Owner
   - B) Contributor
   - C) Virtual Machine Contributor
   - D) User Access Administrator

   **Answer: C** — Virtual Machine Contributor grants rights to create and manage VMs but not to manage the virtual network or assign RBAC roles. Contributor (B) would also allow network changes. Owner (A) includes rights to assign roles. User Access Administrator (D) is specifically for managing role assignments.

6. Your organisation needs to ensure that no Azure resources can be created outside West Europe and North Europe across all subscriptions in the company's management group. What is the correct approach?
   - A) Assign a Contributor role to all subscription owners and instruct them not to create resources elsewhere
   - B) Create an Azure Policy with the "Allowed locations" definition and assign it at management group scope
   - C) Create an Azure Policy at each subscription individually
   - D) Configure a Resource Lock on each subscription

   **Answer: B** — Assigning the policy at management group scope ensures it cascades to all child subscriptions automatically. Option C would work but is not scalable. Option A relies on manual compliance. Option D — resource locks do not restrict location of new resources.

7. An administrator configures a ReadOnly resource lock on a resource group containing a storage account. A user with the Contributor role attempts to upload a blob. What happens?
   - A) The upload succeeds because the user has Contributor rights
   - B) The upload fails because the lock blocks all write operations including data plane writes
   - C) The upload succeeds because data plane operations bypass ARM locks
   - D) The upload fails but only for new containers, not existing ones

   **Answer: C** — Resource locks operate at the Azure Resource Manager (control plane) level and do not block data plane operations such as blob uploads, file reads, or queue operations. The Contributor role allows the data plane write; the lock does not prevent it.

</details>

---

## Week 2 — Implement and manage storage
> **Exam domain:** Implement and manage storage · **Weight:** 15–20%

> **Real-world scenario:** A growing data analytics team at a retail client generates around 500 GB of raw data monthly. Reports older than 90 days are rarely accessed, and data older than two years must be kept for compliance but is virtually never read. The storage costs are rising fast and your Sogeti engagement lead asks you to design a lifecycle management strategy and recommend the right redundancy tier given that the team operates from a single Dutch office but the data is business-critical.

### Learning Objectives
- [ ] Create and configure a General Purpose v2 storage account with LRS redundancy
- [ ] Understand and compare storage redundancy options: LRS, ZRS, GRS, RA-GRS, GZRS
- [ ] Generate and test a Shared Access Signature (SAS) token with scoped permissions
- [ ] Configure a lifecycle management policy to automatically tier blobs to Cool
- [ ] Create an Azure File Share and mount it via SMB from LAB-W11-01
- [ ] Install and configure Azure File Sync on LAB-DC01 with cloud tiering enabled

### MS Learn modules
- [Configure storage accounts](https://learn.microsoft.com/en-us/training/modules/configure-storage-accounts/)
- [Configure Azure Blob Storage](https://learn.microsoft.com/en-us/training/modules/configure-blob-storage/)
- [Configure Azure Files and Azure File Sync](https://learn.microsoft.com/en-us/training/modules/configure-azure-files-file-sync/)
- [Configure Azure Storage security](https://learn.microsoft.com/en-us/training/modules/configure-storage-security/)

### Key Concepts
| Term | Description |
|------|-------------|
| LRS | Locally Redundant Storage — 3 copies within a single datacenter; no protection against datacenter failure |
| ZRS | Zone-Redundant Storage — copies across 3 availability zones in the same region |
| GRS | Geo-Redundant Storage — LRS in primary region + 3 copies in a secondary region (read-only via RA-GRS) |
| GZRS | Geo-Zone-Redundant Storage — combines ZRS in primary with geo-replication to secondary |
| Access tiers | Hot (frequent access), Cool (monthly), Cold (quarterly, 90-day min), Archive (rare, hours to rehydrate) |
| SAS token | Shared Access Signature — a time-limited, permission-scoped URL token; cannot be revoked unless tied to a Stored Access Policy |
| Stored Access Policy | A reusable, revocable access policy attached to a container; revoking it invalidates all associated SAS tokens |
| Azure File Sync | Syncs an on-premises Windows file server folder with an Azure File Share; supports cloud tiering |
| Cloud tiering | Files not accessed recently are evicted from local storage but remain accessible as stubs — fetched on demand from Azure |
| Lifecycle management | Rules that automatically move or delete blobs based on age or last-access patterns |

### Lab exercises (SSW-Lab + Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Create a Storage Account: LRS, General Purpose v2, Hot tier |
| **Azure portal** | Create a Blob container → upload a test file |
| **Azure portal** | Generate a *Shared Access Signature (SAS)* with read permissions, valid for 1 hour |
| **LAB-W11-01** | Use Azure Storage Explorer or `azcopy` to upload to blob |
| **Azure portal** | Create an *Azure File Share* → map via SMB (`net use Z: \\...`) |
| **LAB-DC01** | Install Azure File Sync agent → register server → sync an LAB-DC01 folder |
| **Azure portal** | Configure a *Lifecycle management policy*: move to Cool tier after 30 days |

### Lab commands

```powershell
# Create a storage account
az storage account create --name sswlabstorage --resource-group rg-sswlab-dev --location westeurope --sku Standard_LRS --kind StorageV2

# Generate a SAS token for a container (read-only, 1 hour)
az storage container generate-sas --account-name sswlabstorage --name mycontainer --permissions r --expiry (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:mmZ") --output tsv

# Upload a file with azcopy
azcopy copy "C:\testfile.txt" "https://sswlabstorage.blob.core.windows.net/mycontainer/testfile.txt?<SAS-token>"

# List blobs in a container
az storage blob list --account-name sswlabstorage --container-name mycontainer --output table

# Create an Azure File Share and mount it
az storage share create --name myfileshare --account-name sswlabstorage --quota 5
net use Z: \\sswlabstorage.file.core.windows.net\myfileshare /u:AZURE\sswlabstorage <storage-key>
```

### Knowledge check
1. What are the storage access tiers and when do you use each?
2. What is the difference between a *SAS token* and an *access key*?
3. How does *Azure File Sync* work and what is *cloud tiering*?
4. What is the difference between *LRS*, *ZRS*, *GRS* and *GZRS*?

<details>
<summary>Answers</summary>

1. Azure Blob Storage has four access tiers: **Hot** — optimised for data accessed frequently (multiple times per month); highest storage cost, lowest transaction cost. **Cool** — for data accessed monthly; lower storage cost, higher transaction cost; minimum 30-day retention. **Cold** — for data accessed quarterly; minimum 90-day retention. **Archive** — for rarely accessed data (years); lowest storage cost but data is offline and requires rehydration (up to 15 hours) before it can be read. Lifecycle policies can automate movement between tiers.

2. An **access key** is a full-privilege credential that grants unrestricted access to the entire storage account — treat it like a root password. A **SAS token** is a delegated, scoped token that grants specific permissions (read, write, list, etc.) to a specific service, container, or blob, with an expiry time and optionally an IP restriction. SAS tokens are safer for sharing with external parties because they are limited in scope and time. However, a raw SAS token cannot be revoked once issued — to enable revocation, bind it to a Stored Access Policy.

3. **Azure File Sync** extends an Azure File Share to on-premises Windows Servers. You install the Azure File Sync agent on the server, register it with a Storage Sync Service, and configure a sync group linking a server endpoint (a local folder) to a cloud endpoint (the Azure file share). **Cloud tiering** is an optional feature that automatically evicts infrequently accessed files from local disk, replacing them with placeholder stub files. When a user opens a stub, it is transparently rehydrated from Azure Files. This allows the local volume to serve as a cache for the most-used files while the full dataset lives in the cloud.

4. **LRS** replicates data 3 times within a single datacenter — no resilience against datacenter failure. **ZRS** replicates across 3 availability zones in the same region — protects against zone-level failures but not against a full regional outage. **GRS** adds geo-replication: LRS in the primary region plus 3 copies in a paired secondary region. The secondary is not readable by default unless you enable **RA-GRS**. **GZRS** combines zone-level redundancy in the primary (ZRS) with geo-replication — the highest resilience tier. Use GRS or GZRS when you need protection against a complete regional failure.

5. A company shares monthly financial reports with an external auditor. The reports are stored in Azure Blob Storage. The auditor needs read access to a specific container for exactly 48 hours. Which approach provides the least privilege while meeting the requirement?
   - A) Share the storage account access key with the auditor
   - B) Create a SAS token scoped to the container with read permission and a 48-hour expiry
   - C) Assign the auditor the Storage Blob Data Reader role at the subscription level
   - D) Make the container public (anonymous access)

   **Answer: B** — A SAS token scoped to the container with read-only access and a 48-hour expiry grants exactly the required access. Option A shares full account access with no expiry. Option C grants access beyond the required scope. Option D removes all access control.

6. A lifecycle management policy is configured to move blobs to Cool tier after 30 days and delete them after 365 days. A blob was uploaded 28 days ago and has not been accessed since. What is its current state?
   - A) Already moved to Cool tier because it has been inactive for more than 7 days
   - B) Still in Hot tier because the 30-day threshold has not yet been reached
   - C) Moved to Archive tier because it is not accessed frequently
   - D) Deleted because inactive blobs are removed after 14 days by default

   **Answer: B** — Lifecycle management policies apply rules based on configured age thresholds. With a 30-day rule, the blob remains in Hot tier until day 30. No default automatic deletion or tiering occurs before a rule threshold is met.

7. A development team needs to store container images in a private Azure Container Registry and pull them from Azure Container Instances. They want to avoid storing credentials in their pipeline configuration. Which authentication method should you recommend?
   - A) Store the ACR admin username and password as pipeline secrets
   - B) Use a SAS token generated against the ACR storage account
   - C) Enable the Managed Identity on the ACI and assign the AcrPull role to the registry
   - D) Make the ACR registry public temporarily during the pull

   **Answer: C** — Managed Identity eliminates the need to store or rotate credentials. Assigning AcrPull to the managed identity grants the minimum required access. Option A stores credentials which must be rotated. Option B is not applicable to ACR authentication. Option D introduces a security risk.

</details>

---

## Week 3 — Deploy and manage Virtual Machines
> **Exam domain:** Deploy and manage Azure compute resources · **Weight:** 20–25%

> **Real-world scenario:** A logistics company is migrating its on-premises application tier to Azure. The application consists of two web servers and one application server that must remain available during scheduled platform maintenance windows. The client's SLA requires 99.95% uptime. You are the Azure administrator on the Sogeti project team and must design the VM deployment using Availability Sets, configure automated backups, and demonstrate a recovery procedure.

### Learning Objectives
- [ ] Deploy a Windows Server 2022 VM using the Azure portal and configure its size, disk, and network settings
- [ ] Attach and initialise a managed data disk inside a running Windows VM
- [ ] Create a VM snapshot and restore a new managed disk from it
- [ ] Configure an Availability Set and understand fault domain vs update domain distribution
- [ ] Explain the differences between Availability Sets, Availability Zones, and VM Scale Sets
- [ ] Enable Azure Backup for a VM and execute an on-demand backup job

### MS Learn modules
- [Configure virtual machines](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machines/)
- [Configure virtual machine availability](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-availability/)
- [Configure virtual machine extensions](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-extensions/)

### Key Concepts
| Term | Description |
|------|-------------|
| Availability Set | Groups VMs across Fault Domains (separate racks) and Update Domains (rolling reboot groups) within a single datacenter — protects against hardware failure, not datacenter failure |
| Availability Zone | Physically separate datacenters within a region; VMs in different zones are protected against datacenter-level failure |
| VM Scale Set (VMSS) | Auto-scaling group of identical VMs; scales out/in based on metrics (CPU, memory, custom); load-balanced automatically |
| Spot VM | Uses unused Azure capacity at a deeply discounted rate; can be evicted with 30 seconds' notice — suitable only for interruptible workloads |
| Managed disk | Azure-managed virtual disk; tiers: Premium SSD (production), Standard SSD (dev/test), Standard HDD (archive) |
| VM snapshot | Point-in-time read-only copy of a managed disk; used to create new disks or for rollback |
| Generalised image | VM image that has been sysprepped (Windows) or deprovision+generalised (Linux); all machine-specific state removed — suitable for deploying multiple identical VMs |
| Specialised image | Exact copy of a VM including machine identity and local accounts; used to restore a specific machine, not for bulk deployment |
| Azure Backup | Managed backup service using a Recovery Services Vault; supports VMs, Azure Files, SQL in VMs, and more |

### Lab exercises (Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Deploy a Windows Server 2022 VM (B2s SKU) in `rg-sswlab-dev` |
| **Azure portal** | Connect via RDP → install IIS via Server Manager |
| **Azure portal** | Add a *data disk* (32 GB, Standard SSD) → initialise in Windows |
| **Azure portal** | Take a *VM snapshot* → restore a new managed disk from the snapshot |
| **Azure portal** | Configure *Auto-shutdown* to control costs (22:00 UTC) |
| **Azure portal** | Deploy an *Availability Set* with 2 VMs → verify fault/update domain distribution |
| **Azure portal** | Enable *Azure Backup* for the VM → run an on-demand backup |

### Lab commands

```powershell
# Deploy a VM via Azure CLI
az vm create --resource-group rg-sswlab-dev --name sswlab-vm01 --image Win2022AzureEditionCore --size Standard_B2s --admin-username azureadmin --admin-password "P@ssw0rd123!" --location westeurope

# Attach a data disk to an existing VM
az vm disk attach --resource-group rg-sswlab-dev --vm-name sswlab-vm01 --name sswlab-datadisk01 --new --size-gb 32 --sku Standard_LRS

# Take a snapshot of the OS disk
$diskId = az vm show --resource-group rg-sswlab-dev --name sswlab-vm01 --query "storageProfile.osDisk.managedDisk.id" -o tsv
az snapshot create --resource-group rg-sswlab-dev --name sswlab-snapshot01 --source $diskId

# Enable Azure Backup for a VM
az backup protection enable-for-vm --resource-group rg-sswlab-dev --vault-name sswlab-rsv --vm sswlab-vm01 --policy-name DefaultPolicy

# Trigger an on-demand backup job
az backup protection backup-now --resource-group rg-sswlab-dev --vault-name sswlab-rsv --container-name sswlab-vm01 --item-name sswlab-vm01 --backup-management-type AzureIaasVM
```

### Knowledge check
1. What is the difference between *Availability Sets* and *Availability Zones*?
2. When do you use *Azure VM Scale Sets* versus standalone VMs?
3. How do *Azure Spot VMs* work and when are they appropriate?
4. What is the difference between *generalised* and *specialised* images?

<details>
<summary>Answers</summary>

1. An **Availability Set** distributes VMs across Fault Domains (separate physical racks with independent power and networking) and Update Domains (groups that are rebooted one at a time during planned maintenance). This protects against hardware failures and maintenance events *within a single datacenter* — but the entire set is still within one building and one availability zone. **Availability Zones** place VMs in physically separate datacenters (different buildings, power supplies, and cooling) within the same Azure region. This protects against an entire datacenter going offline. For maximum resilience, use Availability Zones; use Availability Sets when your region doesn't support zones or when you need managed-disk aligned grouping for older architectures.

2. **VM Scale Sets** are the right choice when your workload requires horizontal scaling — adding or removing identical VMs dynamically based on demand. VMSS is ideal for stateless workloads like web servers, API backends, or batch compute. All instances run the same image and configuration. **Standalone VMs** are appropriate for persistent, stateful workloads — domain controllers, database servers, individual application tiers — where each VM has a unique identity and configuration that must persist across restarts.

3. **Azure Spot VMs** allow you to purchase unused Azure compute capacity at up to 90% discount. The trade-off is eviction: Azure can reclaim Spot VMs with as little as 30 seconds' notice when capacity is needed elsewhere. This makes them appropriate only for workloads that can tolerate interruption, such as batch processing jobs, rendering pipelines, development/test environments, or stateless workers that can checkpoint and restart. They are never appropriate for production workloads that require continuous availability.

4. A **generalised image** has had all machine-specific information removed (via Sysprep on Windows or `waagent -deprovision+user` on Linux). The resulting image can be used to deploy many identical VMs, each of which will receive a new machine SID, hostname, and configuration on first boot. A **specialised image** is a direct copy of a running VM, preserving its exact state including machine SID, local accounts, and installed software state. Use a specialised image to restore or clone a specific machine; use a generalised image to provision a fleet of new VMs from a template.

5. A company runs a two-tier web application with a front-end tier (stateless IIS servers) and a database tier. They want to ensure the front-end servers remain available during Azure platform maintenance. The region supports availability zones. Which configuration provides the best resilience for the front-end tier?
   - A) Deploy all front-end VMs in an Availability Set with 3 fault domains
   - B) Deploy each front-end VM in a separate Availability Zone
   - C) Deploy front-end VMs as Azure Spot VMs in different regions
   - D) Deploy front-end VMs in the same Availability Zone to reduce latency

   **Answer: B** — Availability Zones protect against datacenter-level failure. Since the region supports zones, this is the better choice over Availability Sets (A), which only protect within one datacenter. Spot VMs (C) can be evicted without warning. Placing VMs in the same zone (D) offers no redundancy.

6. A development team wants to run overnight batch processing jobs at minimum cost. Jobs take 4–6 hours, checkpoint their progress every 30 minutes, and can restart from the last checkpoint if interrupted. Which VM type is most appropriate?
   - A) Standard D-series VMs for predictable performance
   - B) Azure Spot VMs because the workload can tolerate interruption and restart from checkpoints
   - C) Availability Set VMs to ensure the jobs always complete without interruption
   - D) Azure Reserved VM Instances for maximum cost savings on continuous workloads

   **Answer: B** — Spot VMs are ideal for interruptible batch workloads with checkpointing. The workload explicitly tolerates eviction. Standard VMs (A) and Reserved Instances (D) are more expensive than needed for an interruptible batch job. Availability Sets (C) protect against hardware failure during maintenance, not cost.

7. You are asked to restore a specific server VM to its exact state from 3 days ago, including all installed applications, local user accounts, and machine identity. What type of image or recovery point should you use?
   - A) A generalised image captured before the change, deployed as a new VM
   - B) A specialised image or VM restore point that preserves the machine identity and state
   - C) A Sysprep-prepared image from the Azure Compute Gallery
   - D) An ARM template export of the VM configuration

   **Answer: B** — A specialised image or an Azure Backup restore point preserves the exact machine state including SID, hostname, and accounts. A generalised image (A, C) strips machine-specific data and cannot restore a specific machine's identity. An ARM template (D) only describes the VM configuration, not its data or state.

</details>

---

## Week 4 — Containers and Azure App Service
> **Exam domain:** Deploy and manage Azure compute resources · **Weight:** 20–25%

> **Real-world scenario:** A software product team at a Sogeti client wants to modernise their release process. They currently deploy a monolithic .NET application to VMs manually, which causes 30-minute outages during each release. You are asked to migrate the application to Azure App Service, implement deployment slots for zero-downtime releases, and explore Azure Container Apps for a new microservices API that the team is building in parallel.

### Learning Objectives
- [ ] Deploy an Azure App Service web app using Azure CLI from Cloud Shell with the F1 free tier
- [ ] Configure and execute a deployment slot swap for zero-downtime deployment
- [ ] Deploy an Azure Container Instance using both the portal and `az container create`
- [ ] Create an Azure Container Registry and push a container image to it
- [ ] Deploy an Azure Container App from ACR and configure horizontal scaling rules
- [ ] Explain the differences between ACI, ACA, and AKS and select the appropriate service

### MS Learn modules
- [Configure Azure App Service](https://learn.microsoft.com/en-us/training/modules/configure-azure-app-services/)
- [Configure Azure Container Instances](https://learn.microsoft.com/en-us/training/modules/configure-azure-container-instances/)
- [Configure Azure Container Apps](https://learn.microsoft.com/en-us/training/modules/introduction-to-azure-container-apps/)

### Key Concepts
| Term | Description |
|------|-------------|
| App Service Plan | Defines the compute tier (size and instance count) that backs one or more App Service apps; plans range from Free (F1) to Premium |
| Deployment slot | A separate instance of an App Service app (e.g. staging) in the same plan; supports slot swap for zero-downtime releases and instant rollback |
| Azure Container Registry (ACR) | Private Docker-compatible container registry hosted in Azure; integrates with ACI and ACA for private image pulls |
| Azure Container Instances (ACI) | Serverless container execution — starts in seconds, billed per second; no cluster required; ideal for short-lived or single-container workloads |
| Azure Container Apps (ACA) | Fully managed container platform built on Kubernetes (KEDA + Envoy); supports microservices, event-driven scaling, Dapr, and ingress — no direct Kubernetes management required |
| Azure Kubernetes Service (AKS) | Fully managed Kubernetes cluster; maximum control and flexibility but requires Kubernetes expertise to operate |
| Autoscaling | App Service and ACA both support horizontal scale-out based on CPU, memory, or HTTP request metrics; App Service plans must be Standard or higher for autoscale |
| Consumption plan | Serverless billing model for Azure Functions; scales to zero when idle — differs from an App Service Plan which has always-on compute |

### Lab exercises (Azure portal + Cloud Shell)
| Environment | Task |
|---|---|
| **Azure Cloud Shell** | Deploy a simple web app: `az webapp create --sku F1 --name sswlab-app ...` |
| **Azure portal** | Configure a *deployment slot* (staging) → perform a *swap* to production |
| **Azure portal** | Deploy an Azure Container Instance with an nginx image |
| **Azure Cloud Shell** | `az container create --image nginx --dns-name-label sswlab-ci ...` |
| **Azure portal** | Create an *Azure Container Registry* → push a container image |
| **Azure portal** | Deploy a *Container App* from ACR → configure scaling rules |
| **Azure portal** | Configure an *App Service plan* → scale out to 2 instances |
| **Azure portal** | Review *App Service Diagnostics* → analyse availability graph |

### Lab commands

```bash
# Deploy an App Service web app (Free tier)
az webapp create --resource-group rg-sswlab-dev --plan sswlab-asp --name sswlab-app --runtime "DOTNET|8.0"

# Add a deployment slot
az webapp deployment slot create --name sswlab-app --resource-group rg-sswlab-dev --slot staging

# Swap staging to production
az webapp deployment slot swap --name sswlab-app --resource-group rg-sswlab-dev --slot staging --target-slot production

# Create a Container Registry and push an image
az acr create --resource-group rg-sswlab-dev --name sswlabacr --sku Basic
az acr login --name sswlabacr
docker tag myapp sswlabacr.azurecr.io/myapp:v1
docker push sswlabacr.azurecr.io/myapp:v1
```

### Knowledge check
1. What is the difference between *Azure Container Instances*, *Azure Container Apps* and *Azure Kubernetes Service*?
2. How do *deployment slots* work and why is a *slot swap* useful?
3. What is the difference between an *App Service plan* and a *Consumption plan* for Azure Functions?
4. How do you configure *autoscaling* based on CPU usage?

<details>
<summary>Answers</summary>

1. **ACI (Azure Container Instances)** is the simplest option — deploy a single container (or small group) without any cluster. It starts in seconds and is billed per second. Best for isolated, short-lived tasks, CI/CD jobs, or testing. No load balancing, no auto-scaling. **ACA (Azure Container Apps)** is a managed platform built on Kubernetes and KEDA. It supports microservices, event-driven scaling (including scale to zero), traffic splitting, Dapr integration, and built-in ingress. You never interact with Kubernetes directly. Best for production microservices and APIs. **AKS (Azure Kubernetes Service)** gives you a fully managed Kubernetes cluster where you have full control over the configuration, nodes, networking, and add-ons. Highest flexibility, highest operational complexity. Best when your team is experienced with Kubernetes or you have requirements that ACA cannot fulfill.

2. A **deployment slot** is a live, separately addressable instance of your App Service app. The typical workflow is: deploy new code to the **staging** slot → test it at its dedicated URL → perform a **slot swap**, which atomically exchanges staging and production by swapping the routing rules. The previous production version is now in the staging slot and can be instantly swapped back if a problem is discovered — providing zero-downtime deployment and a one-step rollback mechanism.

3. An **App Service plan** is a dedicated compute allocation (specific VM size and instance count) that runs continuously. You pay for the plan regardless of how much your apps use it. It supports always-on settings and is required for deployment slots, VNet integration, and custom autoscale. A **Consumption plan** for Azure Functions is serverless — it provisions resources on demand when a function is triggered and scales to zero when idle. You pay only for actual execution time. The trade-off is cold start latency and the absence of features that require persistent compute (no always-on, no VNet integration without Premium plan).

4. In App Service (Standard plan or higher): navigate to the app → **Scale out (App Service plan)** → enable autoscale → add a rule: if *CPU Percentage* (averaged over 10 minutes) is *greater than* 70%, increase instance count by 1. Add a corresponding scale-in rule at 30% CPU. Set minimum/maximum instance counts. The autoscale engine evaluates the rules every minute. In Azure Container Apps, configure a scaling rule from the portal or via YAML: set `minReplicas`, `maxReplicas`, and add a CPU utilisation trigger with a `utilizationPercentage` threshold.

5. A team deploys a new version of their web app to a staging deployment slot and performs smoke tests. They then execute a slot swap. Shortly after, a critical bug is discovered in the new version. What is the fastest way to restore the previous version?
   - A) Redeploy the previous version from source control to the production slot
   - B) Delete the production slot and recreate it from a backup
   - C) Swap the staging and production slots again — the previous version is still in the staging slot
   - D) Scale the App Service plan down and back up to force a redeploy

   **Answer: C** — After a slot swap, the previous production code is now in the staging slot. A second swap instantly restores it to production with zero downtime and no redeployment required.

6. A company has a stateless API that processes incoming webhook events. Traffic is minimal during business hours but spikes unpredictably at night when external partners batch-send events. They want to minimise cost while handling spikes automatically. Which hosting option is most appropriate?
   - A) App Service plan (Standard tier) with a fixed instance count of 5
   - B) Azure Container Apps with KEDA-based HTTP scaling configured with minReplicas set to 0
   - C) Azure Kubernetes Service with a node pool of 3 dedicated nodes
   - D) Azure Container Instances running a single container continuously

   **Answer: B** — ACA with scale-to-zero minimises cost during idle periods and scales out automatically during spikes using KEDA. A fixed instance count (A, C) wastes resources during low-traffic periods. A single ACI container (D) cannot scale and has no built-in autoscaling.

7. A company wants to run a nightly data export job that takes approximately 20 minutes, uses a custom Docker image stored in their private ACR, and requires no persistent state after completion. Which Azure service is best suited?
   - A) Azure App Service with a WebJob
   - B) Azure Container Instances pulling the image from ACR
   - C) Azure Kubernetes Service with a CronJob resource
   - D) Azure Container Apps with a scheduled trigger

   **Answer: B** — ACI is ideal for short-lived, single-container, stateless tasks with a custom image. It starts quickly, runs the job, and stops — you pay only for runtime. AKS (C) introduces unnecessary cluster management overhead. App Service WebJobs (A) require an always-on App Service plan. ACA scheduled triggers (D) are possible but add more infrastructure than needed for a simple 20-minute job.

</details>

---

## Week 5 — Virtual networks
> **Exam domain:** Implement and manage virtual networking · **Weight:** 15–20%

> **Real-world scenario:** A healthcare client is deploying a patient data processing application in Azure. Regulatory requirements state that no patient data may traverse the public internet, and the storage account and database endpoints must only be reachable from within the corporate Azure VNet. The client's on-premises network must also connect securely to the Azure environment. You are responsible for designing the network segmentation, configuring Private Endpoints, and setting up the VPN connection from the Sogeti-managed lab environment.

### Learning Objectives
- [ ] Create a VNet with multiple subnets and assign appropriate address spaces
- [ ] Create and configure NSG rules, and understand the difference between subnet-level and NIC-level application
- [ ] Configure VNet peering between two VNets and verify connectivity
- [ ] Create an Azure Private DNS Zone and enable automatic VM registration
- [ ] Configure a Point-to-Site VPN from LAB-W11-01 to an Azure VNet
- [ ] Deploy Azure Bastion and connect to a VM without a public IP or open RDP port
- [ ] Create a Private Endpoint for a Storage Account and validate DNS resolution

### MS Learn modules
- [Configure virtual networks](https://learn.microsoft.com/en-us/training/modules/configure-virtual-networks/)
- [Configure network security groups](https://learn.microsoft.com/en-us/training/modules/configure-network-security-groups/)
- [Configure Azure DNS](https://learn.microsoft.com/en-us/training/modules/configure-azure-dns/)
- [Configure virtual network peering](https://learn.microsoft.com/en-us/training/modules/configure-vnet-peering/)

### Key Concepts
| Term | Description |
|------|-------------|
| VNet | Virtual Network — an isolated layer-3 network in Azure; resources within a VNet communicate by default, resources in different VNets do not |
| NSG | Network Security Group — a stateful packet filter with inbound and outbound rules based on IP, port, and protocol; applied to a subnet or a NIC |
| Service tag | A named group of IP prefixes for an Azure service (e.g. `AzureLoadBalancer`, `Internet`, `Storage`) used in NSG rules to avoid hardcoding IP ranges |
| VNet peering | Direct, low-latency connection between two VNets over the Azure backbone; non-transitive by default |
| Private DNS Zone | DNS resolution scoped to linked VNets; names resolve to private IP addresses and are never exposed to the internet |
| Azure Bastion | Managed PaaS RDP/SSH gateway deployed into a dedicated `AzureBastionSubnet` (/26 or larger); provides secure browser-based access without exposing VM ports publicly |
| Service endpoint | Secures a subnet's outbound route to an Azure PaaS service via the Azure backbone — the PaaS service still has a public IP |
| Private endpoint | Places an Azure PaaS service (storage, SQL, etc.) behind a private IP in your VNet; traffic never traverses the public internet |
| Point-to-Site VPN | VPN connection from an individual device (e.g. LAB-W11-01) to an Azure VNet; uses certificate or Entra ID authentication |

### Lab exercises (Azure portal + SSW-Lab)
| Environment | Task |
|---|---|
| **Azure portal** | Create a VNet: `10.100.0.0/16` with subnets `frontend/10.100.1.0/24` and `backend/10.100.2.0/24` |
| **Azure portal** | Configure an *NSG*: allow HTTP/HTTPS inbound, deny everything else |
| **Azure portal** | Attach NSG to the frontend subnet → test from a VM in the backend subnet |
| **Azure portal** | Create a second VNet → configure *VNet peering* between both |
| **Azure portal** | Configure an *Azure Private DNS Zone* → auto-register VMs |
| **LAB-W11-01** | Configure a *Point-to-Site VPN* to the Azure VNet → test the connection |
| **Azure portal** | Deploy *Azure Bastion* → connect to a VM without public IP or RDP port |
| **Azure portal** | Configure a *Private Endpoint* for a Storage Account → verify DNS resolution |
| **Azure portal** | Review *Effective routes* on the NIC of a VM |

### Lab commands

```bash
# Create a VNet with two subnets
az network vnet create --resource-group rg-sswlab-dev --name sswlab-vnet --address-prefix 10.100.0.0/16 --subnet-name frontend --subnet-prefix 10.100.1.0/24
az network vnet subnet create --resource-group rg-sswlab-dev --vnet-name sswlab-vnet --name backend --address-prefix 10.100.2.0/24

# Create an NSG and attach to a subnet
az network nsg create --resource-group rg-sswlab-dev --name sswlab-nsg-frontend
az network nsg rule create --resource-group rg-sswlab-dev --nsg-name sswlab-nsg-frontend --name AllowHTTP --priority 100 --protocol Tcp --destination-port-range 80 443 --access Allow --direction Inbound
az network vnet subnet update --resource-group rg-sswlab-dev --vnet-name sswlab-vnet --name frontend --network-security-group sswlab-nsg-frontend

# Configure VNet peering (both directions)
az network vnet peering create --resource-group rg-sswlab-dev --name vnet1-to-vnet2 --vnet-name sswlab-vnet --remote-vnet sswlab-vnet2 --allow-vnet-access
az network vnet peering create --resource-group rg-sswlab-dev --name vnet2-to-vnet1 --vnet-name sswlab-vnet2 --remote-vnet sswlab-vnet --allow-vnet-access
```

### Knowledge check
1. What is the difference between an *NSG* applied at the subnet level and at the NIC level?
2. How does *VNet peering* work — is it transitive?
3. What is the difference between *Azure DNS* public zones and *Private DNS Zones*?
4. What is a *service endpoint* versus a *private endpoint*?

<details>
<summary>Answers</summary>

1. An **NSG at subnet level** filters all traffic entering or leaving the entire subnet — it acts as a boundary guard for every resource in that subnet. An **NSG at NIC level** filters traffic for a single network interface (one VM). When both are applied, traffic must pass through both NSGs — the effective rule is the most restrictive combination. Common pattern: use a subnet-level NSG to enforce broad policy (e.g. deny all inbound from the internet) and a NIC-level NSG for VM-specific overrides. Remember: NSG rules are evaluated by priority (lower number = higher priority), and the first matching rule wins.

2. **VNet peering** creates a direct, private connection between two VNets using the Azure backbone — no public internet, no gateways, very low latency. Traffic is not encrypted by default (it stays within the Microsoft network). Peering must be created in both directions (A→B and B→A). It is **not transitive**: if VNet A is peered with VNet B, and B is peered with C, A cannot communicate with C through B. To enable transitive routing, you need either a hub-and-spoke topology with an Azure Firewall or VPN Gateway as the hub, or you need to create direct peering between A and C.

3. **Azure DNS public zones** host DNS records for publicly resolvable domain names (e.g. contoso.com). Records are accessible from the internet. Azure acts as an authoritative DNS server for the zone, but you must delegate your domain's NS records to Azure DNS. **Private DNS zones** are resolvable only from VNets that have been linked to the zone. They are ideal for private endpoints (e.g. `storageaccount.privatelink.blob.core.windows.net` resolving to a private IP), internal service names, and hybrid scenarios where on-premises names should resolve to Azure private IPs.

4. A **service endpoint** extends a VNet subnet's identity to an Azure PaaS service (like Storage or SQL) over the Azure backbone, allowing you to restrict the PaaS service's firewall to only your subnet. The PaaS service still has and uses its *public* IP address — traffic leaves your subnet but stays on the Microsoft backbone, never touching the public internet. A **private endpoint** assigns a *private IP address* from your VNet directly to the PaaS service. The service becomes accessible only via that private IP; the public endpoint can be disabled entirely. DNS must be configured to resolve the service's hostname to the private IP. Private endpoints are the stronger isolation model and are the current best practice.

5. A company has three VNets: Hub, Spoke-A, and Spoke-B. Hub is peered with Spoke-A and Hub is peered with Spoke-B. A VM in Spoke-A needs to communicate with a VM in Spoke-B. What must be configured?
   - A) Nothing — traffic flows automatically through the Hub because both spokes are peered with it
   - B) Enable "Allow gateway transit" on the Hub peering and "Use remote gateway" on both Spoke peerings
   - C) Create a direct VNet peering between Spoke-A and Spoke-B, or deploy an Azure Firewall or VPN Gateway in the Hub to enable transitive routing
   - D) Configure an NSG on the Hub VNet to allow traffic between the two spoke address spaces

   **Answer: C** — VNet peering is not transitive. Spoke-A and Spoke-B cannot communicate via Hub without either a direct peering between them or a network appliance (Azure Firewall, VPN Gateway) in the Hub that routes traffic between spokes. Option B alone (gateway transit) enables on-premises-to-spoke routing, not spoke-to-spoke directly.

6. A security audit finding states that the company's Azure SQL database is accessible over the public internet and only protected by a firewall rule. The audit recommends that the database should not be reachable via any public IP. Which solution addresses this requirement?
   - A) Configure an NSG on the SQL server's subnet with a Deny rule for all inbound internet traffic
   - B) Enable a Service Endpoint for SQL on the application subnet
   - C) Create a Private Endpoint for the Azure SQL database in the application VNet and disable the public endpoint
   - D) Restrict the SQL firewall to the application server's public IP address

   **Answer: C** — A Private Endpoint assigns a private IP from the VNet to the SQL database, making it unreachable from the internet. Disabling the public endpoint fully eliminates internet-facing access. Service endpoints (B) still use a public IP. NSGs (A) cannot be applied to PaaS services directly. Restricting by public IP (D) still leaves the public endpoint open.

7. You deploy Azure Bastion in a VNet to provide secure RDP access to VMs. A VM in a peered VNet is not reachable via Bastion. What is the most likely cause?
   - A) Bastion requires a public IP on the target VM to establish the RDP session
   - B) Azure Bastion in one VNet cannot connect to VMs in a peered VNet unless "Allow gateway transit" is configured on the Bastion VNet peering
   - C) The AzureBastionSubnet is too small — it must be at least a /24
   - D) Bastion only supports VMs in the same VNet; cross-VNet access requires a VPN Gateway

   **Answer: B** — Azure Bastion supports connecting to VMs in peered VNets, but the peering must have "Allow gateway transit" enabled on the Bastion side and "Use remote gateways" on the peered VNet side. Without this, Bastion cannot reach VMs in peered VNets. The AzureBastionSubnet minimum size is /26, not /24.

</details>

---

## Week 6 — Load balancing and network routing
> **Exam domain:** Implement and manage virtual networking · **Weight:** 15–20%

> **Real-world scenario:** A Sogeti client runs a public-facing e-commerce platform with a web tier and an API tier, both hosted on Azure VMs behind a load balancer. During a recent peak sales event, one web server became unresponsive but continued receiving traffic, causing errors for customers. You are asked to implement proper health probing, configure path-based routing to separate web and API traffic, and use Azure Network Watcher to diagnose an intermittent connectivity issue reported by the operations team.

### Learning Objectives
- [ ] Deploy a Standard Load Balancer with a backend pool, health probe, and load balancing rule
- [ ] Verify Load Balancer failover by stopping one backend VM and observing traffic redistribution
- [ ] Create User Defined Routes (UDR) to redirect traffic via a network virtual appliance
- [ ] Deploy an Application Gateway with WAF and configure path-based routing rules
- [ ] Use Azure Network Watcher IP Flow Verify and Connection Troubleshoot to diagnose connectivity issues
- [ ] Explain the differences between Azure Load Balancer, Application Gateway, and Azure Front Door

### MS Learn modules
- [Configure Azure Load Balancer](https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/)
- [Configure Azure Application Gateway](https://learn.microsoft.com/en-us/training/modules/configure-azure-application-gateway/)
- [Configure network routing and endpoints](https://learn.microsoft.com/en-us/training/modules/configure-network-routing-endpoints/)
- [Configure Azure Firewall](https://learn.microsoft.com/en-us/training/modules/configure-azure-firewall/)

### Key Concepts
| Term | Description |
|------|-------------|
| Azure Load Balancer (L4) | Distributes TCP/UDP traffic based on IP and port; no content inspection; supports Standard (zone-redundant) and Basic SKU |
| Application Gateway (L7) | HTTP/HTTPS load balancer with URL path routing, SSL termination, session affinity, header rewriting, and integrated WAF |
| Azure Front Door | Global HTTP/HTTPS load balancer and CDN with routing across regions; used for geo-redundant multi-region apps |
| WAF (Web Application Firewall) | Protects against OWASP Top 10 threats; available on Application Gateway and Front Door |
| Health probe | Periodically tests backend VMs; if a probe fails, the Load Balancer stops sending traffic to that instance |
| UDR (User Defined Route) | A custom route table entry that overrides Azure's default system routes; commonly used to force traffic through a firewall/NVA |
| SNAT | Source Network Address Translation — a Load Balancer uses SNAT to replace the source IP of outbound traffic from backend VMs with the Load Balancer's frontend IP |
| NVA (Network Virtual Appliance) | A VM running firewall or routing software (e.g. Palo Alto, Fortinet); traffic is steered to it via UDR |
| Network Watcher | Suite of network diagnostic tools: IP Flow Verify, Connection Troubleshoot, NSG Flow Logs, Packet Capture, Next Hop |

### Lab exercises (Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Deploy a *Standard Load Balancer* for 2 web server VMs |
| **Azure portal** | Configure a health probe on port 80 → test failover (stop 1 VM) |
| **Azure portal** | Configure *User Defined Routes (UDR)*: route traffic via a Network Virtual Appliance |
| **Azure portal** | Deploy an *Application Gateway* with WAF → configure a path-based routing rule |
| **Azure portal** | Use *Azure Network Watcher → IP Flow Verify* to diagnose NSG blocking |
| **Azure portal** | Use *Connection Troubleshoot* to analyse connectivity issues |

### Lab commands

```bash
# Create a Standard Load Balancer with a public IP
az network lb create --resource-group rg-sswlab-dev --name sswlab-lb --sku Standard --frontend-ip-name frontendConfig --public-ip-address sswlab-lb-pip

# Add a health probe
az network lb probe create --resource-group rg-sswlab-dev --lb-name sswlab-lb --name httpProbe --protocol Http --port 80 --path /

# Add a load balancing rule
az network lb rule create --resource-group rg-sswlab-dev --lb-name sswlab-lb --name httpRule --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name frontendConfig --backend-pool-name backendPool --probe-name httpProbe

# Use Network Watcher IP Flow Verify
az network watcher test-ip-flow --resource-group rg-sswlab-dev --vm sswlab-vm01 --direction Inbound --protocol Tcp --local 10.100.1.4:80 --remote 203.0.113.10:12345
```

### Knowledge check
1. What is the difference between *Azure Load Balancer* (L4) and *Application Gateway* (L7)?
2. When do you use *Azure Front Door* versus Application Gateway?
3. How does *SNAT* work in a Load Balancer configuration?
4. What are *service tags* in NSG rules and what are they used for?

<details>
<summary>Answers</summary>

1. **Azure Load Balancer (Layer 4)** operates at the transport layer — it routes TCP and UDP flows based on source/destination IP address and port number. It has no visibility into HTTP headers, URLs, or cookies. It is fast, low-latency, and supports any TCP/UDP protocol. It cannot make routing decisions based on URL path or hostname. **Application Gateway (Layer 7)** operates at the application layer — it understands HTTP and HTTPS. It can route traffic based on URL path (e.g. `/api/*` to one backend, `/static/*` to another), hostname, or query string. It also provides SSL termination (offloading certificate management), cookie-based session affinity, header rewriting, and an integrated WAF. Use Load Balancer for non-HTTP workloads or when you need raw throughput; use Application Gateway when you need content-based routing or web application protection.

2. **Azure Front Door** is a global, anycast-based HTTP/HTTPS load balancer that operates across Azure regions. Use it when you have backends in multiple Azure regions and want automatic failover, latency-based routing (directing users to the nearest healthy region), built-in CDN caching, and global WAF. **Application Gateway** is a regional service — it distributes traffic across backends within a single region. Use Application Gateway for intra-region load balancing with path-based routing and WAF. A common pattern combines both: Front Door for global traffic management with regional Application Gateways providing local WAF and routing in each region.

3. When VMs in a Load Balancer backend pool initiate outbound internet connections, they do not have public IP addresses. **SNAT (Source NAT)** allows these VMs to reach the internet by translating their private source IP to the Load Balancer's public frontend IP. From the internet's perspective, all outbound traffic from the backend pool originates from the Load Balancer's IP. Each active connection consumes an ephemeral port on the frontend IP. If you exhaust the available SNAT ports (SNAT exhaustion), new outbound connections fail — this is a common production issue with large backend pools.

4. **Service tags** are Microsoft-managed named groups of IP address prefixes associated with a specific Azure service. Examples: `Internet` (all public IP space), `AzureLoadBalancer` (Azure health probe source IPs), `Storage.WestEurope` (Azure Storage IPs in West Europe), `VirtualNetwork` (all addresses in the VNet and peered VNets). Using service tags in NSG rules lets you allow or deny traffic to/from Azure services without maintaining static IP lists — Microsoft updates the prefixes behind the tags automatically. This is the recommended approach for writing NSG rules that interact with Azure services.

5. A company deploys a web application with two backend pools: one for the web front-end (`/`) and one for the REST API (`/api/*`). They also need SSL termination and WAF protection. Which Azure service should they use?
   - A) Azure Standard Load Balancer with two backend pools
   - B) Azure Application Gateway with WAF and path-based routing rules
   - C) Azure Front Door with two origin groups
   - D) An NSG with separate rules for port 80 and port 443

   **Answer: B** — Application Gateway supports path-based routing, WAF, and SSL termination in a single regional service. Load Balancer (A) cannot inspect URL paths. Front Door (C) is global and suitable for multi-region, but adds unnecessary complexity for a single-region app. NSGs (D) have no HTTP-layer awareness.

6. Backend VMs in a Load Balancer pool begin failing to make outbound HTTPS calls to an external payment API. The VMs have no public IPs. Network Watcher shows the outbound connections are being attempted but timing out. What is the most likely cause?
   - A) The NSG on the backend subnet is blocking inbound traffic on port 443
   - B) SNAT port exhaustion — the Load Balancer frontend IP has run out of ephemeral ports for outbound connections
   - C) The health probe is failing, so the Load Balancer is blocking all traffic
   - D) The VMs cannot reach the internet without a public IP assigned directly to the NIC

   **Answer: B** — SNAT exhaustion is a common production issue when many VMs share a single frontend IP and make high volumes of outbound connections. Each TCP connection consumes an ephemeral SNAT port. The fix is to add a NAT Gateway or additional frontend IPs. NSG rules (A) would block specific ports for all traffic, not cause timeouts. Health probe failure (C) affects inbound distribution, not outbound. VMs without public IPs can still reach the internet via SNAT (D).

7. A company is planning to expand their application to users in Southeast Asia while keeping their primary infrastructure in West Europe. They want users to be routed automatically to the nearest healthy region. Which service provides this capability?
   - A) Azure Application Gateway deployed in both regions
   - B) Azure Load Balancer with a global SKU
   - C) Azure Traffic Manager with performance-based routing
   - D) Azure Front Door with latency-based routing across regional backends

   **Answer: D** — Azure Front Door provides global anycast routing with latency-based routing, health probes across regions, and CDN caching — designed exactly for this multi-region scenario. Traffic Manager (C) also supports geo/performance routing at DNS level but lacks CDN and WAF capabilities. Application Gateway (A) is regional only. Load Balancer Global SKU (B) handles cross-region TCP/UDP load balancing but not HTTP-layer features.

</details>

---

## Week 7 — Monitoring and Azure Monitor
> **Exam domain:** Monitor and maintain Azure resources · **Weight:** 10–15%

> **Real-world scenario:** A Sogeti client running a production ERP system on Azure VMs reports intermittent performance degradation on Monday mornings. The operations team has no centralised logging and relies on ad-hoc RDP sessions to check Event Viewer. You are asked to implement Azure Monitor with Log Analytics, configure automated CPU alerts, and set up Azure Backup with a proven restore procedure — all before the client's next quarterly review.

### Learning Objectives
- [ ] Create a Log Analytics Workspace and connect Azure VMs to it
- [ ] Enable VM Insights and interpret the Performance and Map tabs
- [ ] Write KQL queries to filter, aggregate, and project log data
- [ ] Create an alert rule with a metric trigger and configure an action group for email notification
- [ ] Install the Azure Monitor Agent (AMA) on LAB-DC01 and verify data ingestion
- [ ] Configure a Recovery Services Vault, back up DC01 files, and perform a test file restore
- [ ] Configure Azure Site Recovery for a VM and execute a test failover to a secondary region

### MS Learn modules
- [Configure Azure Monitor](https://learn.microsoft.com/en-us/training/modules/configure-azure-monitor/)
- [Configure Log Analytics](https://learn.microsoft.com/en-us/training/modules/configure-log-analytics/)
- [Configure Azure alerts and action groups](https://learn.microsoft.com/en-us/training/modules/configure-azure-alerts/)
- [Configure Azure Backup and recovery](https://learn.microsoft.com/en-us/training/modules/configure-azure-backup/)

### Key Concepts
| Term | Description |
|------|-------------|
| Azure Monitor Metrics | Numerical time-series data (CPU %, disk I/O, network bytes) collected every minute; retained 93 days; best for real-time dashboards and metric-based alerts |
| Azure Monitor Logs | Text-structured data stored in a Log Analytics workspace; queried with KQL; retained 30 days by default (configurable up to 2 years) |
| KQL | Kusto Query Language — used to query Log Analytics data; key operators: `where`, `project`, `summarize`, `order by`, `join`, `render` |
| Azure Monitor Agent (AMA) | Current unified agent for collecting logs and metrics from VMs (replaces MMA/OMS agent); deployed via Data Collection Rules |
| Action group | A reusable collection of notification and action targets (email, SMS, webhook, Azure Function, ITSM) triggered by alert rules |
| Alert rule | Monitors a metric or log query result; fires when a condition is breached; triggers an action group |
| Recovery Services Vault | Container for Azure Backup and Azure Site Recovery configurations and recovery points |
| Azure Backup | Protection against data loss — stores recovery points; supports VMs, Azure Files, SQL Server in VMs, blobs |
| Azure Site Recovery (ASR) | Disaster recovery — continuously replicates VM disk changes to a secondary region; enables failover if the primary region fails |
| Diagnostic settings | Per-resource configuration that routes platform logs and metrics to a Log Analytics workspace, storage account, or Event Hub |

### Lab exercises (Azure portal + SSW-Lab)
| Environment | Task |
|---|---|
| **Azure portal** | Create a *Log Analytics Workspace* → connect the Azure VMs |
| **Azure portal** | Enable *VM Insights* → review the Performance and Map tabs |
| **Azure portal** | Write a KQL query: CPU > 80% in the past 24 hours |
| **Azure portal** | Create an *Alert rule*: CPU > 85% → email notification to admin |
| **LAB-DC01** | Install the *Azure Monitor Agent (AMA)* → verify in Log Analytics |
| **Azure portal** | Configure a *Recovery Services Vault* → back up DC01 files |
| **Azure portal** | Run a *test restore* → recover a file to an alternate location |
| **Azure portal** | Configure *Azure Site Recovery* for a VM → perform a test failover to a secondary region |

### Lab commands

```powershell
# Query CPU usage above 80% for a VM in the last 24 hours (KQL in Log Analytics)
Perf
| where TimeGenerated > ago(24h)
| where CounterName == "% Processor Time"
| where CounterValue > 80
| project TimeGenerated, Computer, CounterValue
| order by TimeGenerated desc

# Create a Log Analytics workspace via CLI
az monitor log-analytics workspace create --resource-group rg-sswlab-dev --workspace-name sswlab-law --location westeurope

# Create an action group for email alerts
az monitor action-group create --resource-group rg-sswlab-dev --name sswlab-ag --short-name ssw-ag --email-receiver name=AdminEmail email=admin@example.com

# Create a CPU metric alert rule
az monitor metrics alert create --resource-group rg-sswlab-dev --name "HighCPU-Alert" --scopes /subscriptions/<sub-id>/resourceGroups/rg-sswlab-dev/providers/Microsoft.Compute/virtualMachines/sswlab-vm01 --condition "avg Percentage CPU > 85" --window-size 5m --evaluation-frequency 1m --action sswlab-ag
```

### Knowledge check
1. What is the difference between *Azure Monitor Metrics* and *Azure Monitor Logs*?
2. How does *Azure Alerts* work — what are *action groups*?
3. Write a KQL query: all failed sign-ins from the past week.
4. What is the difference between *Azure Backup* and *Azure Site Recovery*?

<details>
<summary>Answers</summary>

1. **Azure Monitor Metrics** are numerical values collected at regular intervals (typically every minute) — examples: CPU percentage, available memory bytes, disk read operations per second. They are stored in a time-series database optimised for fast graphing and threshold-based alerting. Metrics are retained for 93 days and are ideal for real-time monitoring. **Azure Monitor Logs** collect structured or unstructured text-based events from resources, agents, and diagnostic settings into a Log Analytics workspace. Examples: Windows Event Logs, Azure Activity Logs, application trace logs, custom security events. Logs are queried with KQL and retained for 30 days by default. Use Metrics for dashboards and numeric threshold alerts; use Logs for forensics, complex correlation queries, and case-study scenarios.

2. An **alert rule** in Azure Monitor defines a condition to monitor — either a metric threshold (e.g. CPU > 85% for 5 minutes) or a log query result (e.g. count of failed logins > 10 in 1 hour). When the condition is breached, the alert fires and calls an **action group**. An action group is a separately defined, reusable resource that specifies *what to do* when an alert fires: send an email, send an SMS, call a webhook, trigger an Azure Function, or integrate with an ITSM tool like ServiceNow. Decoupling alert rules from action groups means one action group can be shared by many rules, and you can update notification targets without modifying individual rules.

3. The `SigninLogs` table in Log Analytics (populated via Entra ID diagnostic settings) contains sign-in events. A query for failed sign-ins from the past 7 days:
   ```kql
   SigninLogs
   | where TimeGenerated > ago(7d)
   | where ResultType != "0"
   | project TimeGenerated, UserPrincipalName, IPAddress, Location, ResultDescription, AppDisplayName
   | order by TimeGenerated desc
   ```
   `ResultType == "0"` indicates success; any non-zero value is a failure. You can also use `| summarize count() by UserPrincipalName` to identify accounts with the most failures.

4. **Azure Backup** is a data protection service — its purpose is to recover from data loss caused by accidental deletion, file corruption, or ransomware. It creates and retains recovery points (snapshots and vault-backed copies) from which you can restore individual files, entire VMs, or databases. The VM keeps running normally during backup. **Azure Site Recovery (ASR)** is a disaster recovery service — its purpose is to keep workloads available during a regional outage. ASR continuously replicates VM disk changes to a secondary Azure region. If the primary region fails, you initiate a failover and VMs come online in the secondary region. After the primary is restored, you perform a failback. Use Backup for operational recovery (day-to-day mistakes); use ASR for regional disaster recovery (DR planning and business continuity).

5. A company wants to receive an email notification whenever any resource in their Azure subscription is deleted. Which Azure Monitor feature and log source should they configure?
   - A) A metric alert rule on the subscription's CPU usage
   - B) A log alert rule based on the Azure Activity Log querying for "Delete" operations
   - C) An NSG flow log alert for all outbound traffic
   - D) A VM Insights alert for disk I/O

   **Answer: B** — The Azure Activity Log records all control-plane operations including resource deletions. A log alert rule querying the `AzureActivity` table for `OperationName contains "delete"` and `ActivityStatus == "Succeeded"` will trigger the action group. Metric alerts (A) and NSG flow logs (C) are not relevant to resource deletion events. VM Insights (D) monitors performance data.

6. An operations team receives too many noisy alerts from a CPU metric alert configured with a 1-minute evaluation window and a 5-minute window size. The alerts fire during brief spikes that resolve themselves. What configuration change reduces false positives without missing genuine sustained high CPU?
   - A) Lower the CPU threshold from 85% to 70%
   - B) Increase the evaluation frequency from 1 minute to 15 minutes
   - C) Increase the window size to 15 or 30 minutes so the alert only fires when CPU is elevated over a sustained period
   - D) Disable the alert rule during business hours

   **Answer: C** — Increasing the aggregation window size (e.g. to 15 minutes) means the alert only fires if CPU remains above the threshold for the full window, filtering out transient spikes. Lowering the threshold (A) would make alerts more frequent. Increasing evaluation frequency (B) without changing the window does not reduce noise. Disabling during business hours (D) removes visibility entirely.

7. A company has a Recovery Services Vault with daily VM backups retained for 30 days. A developer accidentally deletes critical application data from a VM's data disk at 14:00 today. The last backup completed at 03:00 today. What data can be recovered and what will be lost?
   - A) All data up to 14:00 today can be recovered because Azure Backup captures changes continuously
   - B) Data from the 03:00 backup can be restored; approximately 11 hours of changes made between 03:00 and 14:00 will be lost
   - C) No data can be recovered because the disk was not deleted, only the data on it
   - D) The entire VM must be restored; individual file recovery is not possible with Azure Backup

   **Answer: B** — Azure Backup takes point-in-time snapshots on a schedule (in this case daily at 03:00). Recovery is possible up to the last recovery point. Data written between the last backup and the deletion event cannot be recovered from backup. Individual file recovery (Item Level Recovery) is supported by Azure Backup, contradicting option D.

</details>

---

## Week 8 — Exam preparation

### Activities
- Review weak domains based on the [official exam study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104)
- Complete the **Microsoft Learn practice assessment** for AZ-104: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Practice resource creation via **Azure CLI** and **PowerShell (Az module)** — the exam includes CLI questions
- Revisit VNet architecture and NSG scenarios (most frequently examined)
- Clean up all Azure resources to avoid charges: `az group delete -n rg-sswlab-dev`
- Schedule your exam via Pearson VUE

### Exam focus areas
- Networking: NSG rules, UDR, VNet peering, Private Endpoints, Azure Bastion — heavily weighted
- VM availability: know the exact difference between Availability Set / Zone / VMSS
- Storage: redundancy options (LRS/ZRS/GRS), tier management, blob versioning, soft delete
- Compute: ARM templates *and* Bicep files — both are in scope
- RBAC: scope levels (management group → subscription → resource group → resource)
- Backup & recovery: difference between Azure Backup and Azure Site Recovery (failover)
- KQL: basic queries (where, summarize, project) appear in case-study questions

---

## Exam Coverage Gaps and Must-Do Labs

This section maps the SSW-Lab Minimal preset (DC01 + W11-01 as hybrid endpoints; all Azure work in the cloud) against the full AZ-104 exam domain coverage. It identifies topics that are underrepresented in the 8-week programme and prescribes the additional labs most likely to close scoring gaps.

### Topics not fully covered by the weekly labs

| Gap area | Why it matters | Suggested action |
|---|---|---|
| ARM templates and Bicep | Exam includes hands-on deployment scenarios with both formats | Complete Labs 4.7–4.8 from the M365-Lab reference guide; export a resource group as ARM JSON, modify a parameter, redeploy; author a minimal Bicep file and deploy via `az deployment group create` |
| VM Scale Sets with autoscale | Heavily tested in compute domain (20–25%); VMSS scaling scenarios appear in case studies | Deploy a VMSS with 2 instances; configure CPU-based scale-out (>80%) and scale-in (<20%) rules; verify instance count changes |
| Storage: soft delete, versioning, object replication | Exam asks detailed questions about blob data protection options | Enable soft delete (7-day retention) and blob versioning on a storage account; delete and restore a blob; configure object replication between two accounts |
| Storage firewall and private endpoint combined | Common exam scenario: restrict storage access to a specific VNet | Configure storage firewall to deny public access; add a subnet service endpoint; then replace with a private endpoint and verify DNS resolves to private IP |
| Azure Disk Encryption | Part of compute domain; appears in security-oriented questions | Enable ADE on a VM using an Azure Key Vault; verify encryption status with `Get-AzVmDiskEncryptionStatus` |
| Backup vault (DataProtection API) | Exam distinguishes Recovery Services vault from Backup vault | Create a Backup vault; configure a blob backup policy; understand which workloads require which vault type |
| NSG flow logs and Traffic Analytics | Network Watcher tools are in-scope for the monitoring domain | Enable NSG flow logs on a subnet NSG; send to a storage account and Log Analytics; query `NTANetAnalytics` in KQL |
| ExpressRoute vs VPN Gateway decision | Appears in architecture scenario questions | Study conceptually (ExpressRoute cannot be lab-tested due to cost); focus on: when private connectivity is required, latency vs cost trade-offs, SKU capabilities |

### Must-do labs before scheduling the exam

1. **ARM + Bicep deployment**: Export `rg-sswlab-dev` as an ARM template → edit a parameter value → redeploy in Incremental mode. Then write a minimal Bicep file to create a storage account and deploy it from Azure CLI or Cloud Shell.
2. **VM Scale Set with autoscale**: Create a VMSS (Windows Server 2022, 2 initial instances) in `rg-sswlab-dev` → configure a CPU-based autoscale profile (min 1 / max 5) → generate CPU load and observe scale-out → verify in Metrics.
3. **Storage data protection scenario**: On one storage account, enable soft delete (7 days), blob versioning, and a lifecycle policy (Cool after 30 days, Archive after 90 days) → delete a blob and restore it → inspect version history.
4. **Storage access restriction**: Configure the storage account firewall to Deny public access → add a VNet subnet rule → validate access is blocked from an unlisted source → replace with a private endpoint and confirm DNS resolution returns a private IP.
5. **Azure Site Recovery test failover**: In the Recovery Services Vault, enable replication for one Azure VM to North Europe → wait for Protected status → run a Test Failover → document the failover RTO → clean up the test environment and verify Failback capability.

### Exit criteria before booking the exam

1. You can demonstrate all five AZ-104 exam domains hands-on via the Azure portal, Azure CLI, and PowerShell — without consulting documentation.
2. You can diagnose a network connectivity failure end-to-end using Network Watcher (IP Flow Verify, Effective routes, NSG Flow Logs).
3. You score 80%+ consistently on the [Microsoft Learn practice assessment](https://learn.microsoft.com/en-us/credentials/certifications/exams/az-104/practice/assessment?assessment-type=practice&assessmentId=21).
4. You have completed at least two full review passes over identity/governance, networking, and backup/recovery — the three domains most frequently cited as exam weak points.
