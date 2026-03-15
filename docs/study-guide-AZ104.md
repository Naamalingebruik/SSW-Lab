# Study Guide AZ-104 — Azure Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-AZ104.md)

**Duration:** 8 weeks · **Lab preset:** Minimal (DC01 · W11-01) — Azure tasks run in the cloud  
**MS Learn path:** [Azure Administrator](https://learn.microsoft.com/en-us/certifications/exams/az-104/)  
**Exam weight:**

| Domain | Weight |
|---|---|
| Manage Azure identities and governance | 15–20% |
| Implement and manage storage | 15–20% |
| Deploy and manage Azure compute resources | 20–25% |
| Implement and manage virtual networking | 25–30% |
| Monitor and maintain Azure resources | 10–15% |

> **Prerequisite:** Azure subscription via MSDN/Visual Studio Subscriptions (monthly credit)  
> The SSW-Lab VMs serve as a *hybrid on-premises endpoint* for some labs (VPN, Azure Arc)

---

## Week 1 — Azure identities and governance

### MS Learn modules
- [Manage Azure identities and governance](https://learn.microsoft.com/en-us/training/paths/az-104-manage-identities-governance/)
- [Configure Azure Active Directory](https://learn.microsoft.com/en-us/training/modules/configure-azure-active-directory/)
- [Configure user and group accounts](https://learn.microsoft.com/en-us/training/modules/configure-user-group-accounts/)
- [Configure subscriptions and governance](https://learn.microsoft.com/en-us/training/modules/configure-subscriptions/)

### Lab exercises (SSW-Lab + Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Create a *Resource Group*: `rg-sswlab-dev` in West Europe |
| **Azure portal** | Create an additional Entra ID user: `az-admin@<tenant>.onmicrosoft.com` |
| **Azure portal** | Assign the *Contributor* role to `az-admin` on the resource group via IAM |
| **Azure portal** | Create a *Management group* structure: Root → SSW → Dev/Prod |
| **Azure portal** | Assign an *Azure Policy*: "Allowed locations = West Europe, North Europe" |
| **SSW-W11-01** | Use Azure CLI: `az group list --output table` |
| **Azure portal** | Set up a *Cost budget alert* at €50 for `rg-sswlab-dev` |

### Knowledge check
1. What is the difference between *Azure RBAC* and *Entra ID roles*?
2. How does *Policy* compare to *RBAC* — when do you use which?
3. What is the difference between *Management Group*, *Subscription*, *Resource Group* and *Resource*?
4. How does *Azure Cost Management* work and how do you configure budget alerts?

---

## Week 2 — Implement and manage storage

### MS Learn modules
- [Configure storage accounts](https://learn.microsoft.com/en-us/training/modules/configure-storage-accounts/)
- [Configure Azure Blob Storage](https://learn.microsoft.com/en-us/training/modules/configure-blob-storage/)
- [Configure Azure Files and Azure File Sync](https://learn.microsoft.com/en-us/training/modules/configure-azure-files-file-sync/)
- [Configure Azure Storage security](https://learn.microsoft.com/en-us/training/modules/configure-storage-security/)

### Lab exercises (SSW-Lab + Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Create a Storage Account: LRS, General Purpose v2, Hot tier |
| **Azure portal** | Create a Blob container → upload a test file |
| **Azure portal** | Generate a *Shared Access Signature (SAS)* with read permissions, valid for 1 hour |
| **SSW-W11-01** | Use Azure Storage Explorer or `azcopy` to upload to blob |
| **Azure portal** | Create an *Azure File Share* → map via SMB (`net use Z: \\...`) |
| **SSW-DC01** | Install Azure File Sync agent → register server → sync an SSW-DC01 folder |
| **Azure portal** | Configure a *Lifecycle management policy*: move to Cool tier after 30 days |

### Knowledge check
1. What are the storage access tiers and when do you use each?
2. What is the difference between a *SAS token* and an *access key*?
3. How does *Azure File Sync* work and what is *cloud tiering*?
4. What is the difference between *LRS*, *ZRS*, *GRS* and *GZRS*?

---

## Week 3 — Deploy and manage Virtual Machines

### MS Learn modules
- [Configure virtual machines](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machines/)
- [Configure virtual machine availability](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-availability/)
- [Configure virtual machine extensions](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-extensions/)

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

### Knowledge check
1. What is the difference between *Availability Sets* and *Availability Zones*?
2. When do you use *Azure VM Scale Sets* versus standalone VMs?
3. How do *Azure Spot VMs* work and when are they appropriate?
4. What is the difference between *generalised* and *specialised* images?

---

## Week 4 — Containers and Azure App Service

### MS Learn modules
- [Configure Azure App Service](https://learn.microsoft.com/en-us/training/modules/configure-azure-app-services/)
- [Configure Azure Container Instances](https://learn.microsoft.com/en-us/training/modules/configure-azure-container-instances/)
- [Configure Azure Kubernetes Service basics](https://learn.microsoft.com/en-us/training/modules/intro-to-kubernetes/)

### Lab exercises (Azure portal + Cloud Shell)
| Environment | Task |
|---|---|
| **Azure Cloud Shell** | Deploy a simple web app: `az webapp create --sku F1 --name sswlab-app ...` |
| **Azure portal** | Configure a *deployment slot* (staging) → perform a *swap* to production |
| **Azure portal** | Deploy an Azure Container Instance with an nginx image |
| **Azure Cloud Shell** | `az container create --image nginx --dns-name-label sswlab-ci ...` |
| **Azure portal** | Configure an *App Service plan* → scale out to 2 instances |
| **Azure portal** | Review *App Service Diagnostics* → analyse availability graph |

### Knowledge check
1. What is the difference between *Azure Container Instances* and *Azure Kubernetes Service*?
2. How do *deployment slots* work and why is a *slot swap* useful?
3. What is the difference between an *App Service plan* and a *Consumption plan* for Azure Functions?
4. How do you configure *autoscaling* based on CPU usage?

---

## Week 5 — Virtual networks

### MS Learn modules
- [Configure virtual networks](https://learn.microsoft.com/en-us/training/modules/configure-virtual-networks/)
- [Configure network security groups](https://learn.microsoft.com/en-us/training/modules/configure-network-security-groups/)
- [Configure Azure DNS](https://learn.microsoft.com/en-us/training/modules/configure-azure-dns/)
- [Configure virtual network peering](https://learn.microsoft.com/en-us/training/modules/configure-vnet-peering/)

### Lab exercises (Azure portal + SSW-Lab)
| Environment | Task |
|---|---|
| **Azure portal** | Create a VNet: `10.100.0.0/16` with subnets `frontend/10.100.1.0/24` and `backend/10.100.2.0/24` |
| **Azure portal** | Configure an *NSG*: allow HTTP/HTTPS inbound, deny everything else |
| **Azure portal** | Attach NSG to the frontend subnet → test from a VM in the backend subnet |
| **Azure portal** | Create a second VNet → configure *VNet peering* between both |
| **Azure portal** | Configure an *Azure Private DNS Zone* → auto-register VMs |
| **SSW-W11-01** | Configure a *Point-to-Site VPN* to the Azure VNet → test the connection |
| **Azure portal** | Review *Effective routes* on the NIC of a VM |

### Knowledge check
1. What is the difference between an *NSG* applied at the subnet level and at the NIC level?
2. How does *VNet peering* work — is it transitive?
3. What is the difference between *Azure DNS* public zones and *Private DNS Zones*?
4. What is a *service endpoint* versus a *private endpoint*?

---

## Week 6 — Load balancing and network routing

### MS Learn modules
- [Configure Azure Load Balancer](https://learn.microsoft.com/en-us/training/modules/configure-azure-load-balancer/)
- [Configure Azure Application Gateway](https://learn.microsoft.com/en-us/training/modules/configure-azure-application-gateway/)
- [Configure network routing and endpoints](https://learn.microsoft.com/en-us/training/modules/configure-network-routing-endpoints/)
- [Configure Azure Firewall](https://learn.microsoft.com/en-us/training/modules/configure-azure-firewall/)

### Lab exercises (Azure portal)
| Environment | Task |
|---|---|
| **Azure portal** | Deploy a *Standard Load Balancer* for 2 web server VMs |
| **Azure portal** | Configure a health probe on port 80 → test failover (stop 1 VM) |
| **Azure portal** | Configure *User Defined Routes (UDR)*: route traffic via a Network Virtual Appliance |
| **Azure portal** | Deploy an *Application Gateway* with WAF → configure a path-based routing rule |
| **Azure portal** | Use *Azure Network Watcher → IP Flow Verify* to diagnose NSG blocking |
| **Azure portal** | Use *Connection Troubleshoot* to analyse connectivity issues |

### Knowledge check
1. What is the difference between *Azure Load Balancer* (L4) and *Application Gateway* (L7)?
2. When do you use *Azure Front Door* versus Application Gateway?
3. How does *SNAT* work in a Load Balancer configuration?
4. What are *service tags* in NSG rules and what are they used for?

---

## Week 7 — Monitoring and Azure Monitor

### MS Learn modules
- [Configure Azure Monitor](https://learn.microsoft.com/en-us/training/modules/configure-azure-monitor/)
- [Configure Log Analytics](https://learn.microsoft.com/en-us/training/modules/configure-log-analytics/)
- [Configure Azure alerts and action groups](https://learn.microsoft.com/en-us/training/modules/configure-azure-alerts/)
- [Configure Azure Backup and recovery](https://learn.microsoft.com/en-us/training/modules/configure-azure-backup/)

### Lab exercises (Azure portal + SSW-Lab)
| Environment | Task |
|---|---|
| **Azure portal** | Create a *Log Analytics Workspace* → connect the Azure VMs |
| **Azure portal** | Enable *VM Insights* → review the Performance and Map tabs |
| **Azure portal** | Write a KQL query: CPU > 80% in the past 24 hours |
| **Azure portal** | Create an *Alert rule*: CPU > 85% → email notification to admin |
| **SSW-DC01** | Install the *Azure Monitor Agent (AMA)* → verify in Log Analytics |
| **Azure portal** | Configure a *Recovery Services Vault* → back up DC01 files |
| **Azure portal** | Run a *test restore* → recover a file to an alternate location |

### Knowledge check
1. What is the difference between *Azure Monitor Metrics* and *Azure Monitor Logs*?
2. How does *Azure Alerts* work — what are *action groups*?
3. Write a KQL query: all failed sign-ins from the past week.
4. What is the difference between *Azure Backup* and *Azure Site Recovery*?

---

## Week 8 — Exam preparation

### Activities
- Review weak domains based on the [official exam profile](https://learn.microsoft.com/en-us/certifications/exams/az-104/)
- Complete the **Microsoft Learn practice assessment** for AZ-104: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Practice resource creation via **Azure CLI** and **PowerShell (Az module)** — the exam includes CLI questions
- Revisit VNet architecture and NSG scenarios (most frequently examined)
- Clean up all Azure resources to avoid charges: `az group delete -n rg-sswlab-dev`
- Schedule your exam via Pearson VUE

### Exam focus areas
- Networking: NSG rules, UDR, VNet peering, Private Endpoints — heavily weighted
- VM availability: know the exact difference between Availability Set / Zone / VMSS
- Storage: redundancy options (LRS/ZRS/GRS) and tier management
- RBAC: scope levels (management group → subscription → resource group → resource)
- KQL: basic queries (where, summarize, project) appear in case-study questions
