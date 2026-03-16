# Study Guide MS-102 — Microsoft 365 Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-MS102.md)

**Duration:** 8 weeks · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)  
**MS Learn path:** [Microsoft 365 Administrator](https://learn.microsoft.com/en-us/certifications/exams/ms-102/)  
**Exam weight:**

| Domain | Weight |
|---|---|
| Deploy and manage a Microsoft 365 tenant | 25–30% |
| Implement and manage Microsoft Entra identity and access | 25–30% |
| Manage security and threats by using Microsoft Defender XDR | 30–35% |
| Manage compliance by using Microsoft Purview | 10–15% |

> **Updated:** Skills measured as of November 10, 2025. Defender domain renamed to **Microsoft Defender XDR** (30–35%). Compliance domain renamed to **Microsoft Purview** (10–15%).

> **Prerequisite:** Microsoft 365 E5 developer tenant (via MSDN/M365 developer program)  
> Sign up at: [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program)

---

## Week 1 — Setting up the Microsoft 365 tenant

### MS Learn modules
- [Explore your Microsoft 365 cloud environment](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-cloud-environment/)
- [Configure your Microsoft 365 experience](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-experience/)
- [Manage Microsoft 365 tenants](https://learn.microsoft.com/en-us/training/modules/manage-your-microsoft-365-tenant/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Open the **Microsoft 365 admin center** (admin.microsoft.com) in Edge |
| **SSW-MGMT01** | Configure tenant settings: name, region, time zone |
| **SSW-MGMT01** | Add a custom domain (or verify `ssw.lab` equivalent in tenant) |
| **SSW-DC01** | Install Azure AD Connect → synchronise `ssw.lab` AD users to Entra ID |
| **SSW-MGMT01** | Verify synchronised users in **Entra admin center → Users** |
| **SSW-MGMT01** | Assign Microsoft 365 E5 licenses to synchronised users |
| **SSW-MGMT01** | Enable and configure **Microsoft 365 Backup**: set a backup policy for Exchange and OneDrive |

### Knowledge check
1. What is the difference between a *managed domain* and a *federated domain* in Microsoft 365?
2. How does *password hash synchronisation* work versus *pass-through authentication*?
3. Which DNS records are required for a custom domain in Microsoft 365?
4. What is the *Microsoft 365 compliance center* and what is it used for?
5. What is *Microsoft 365 Backup* and how does it differ from retention policies?

---

## Week 2 — User and group management

### MS Learn modules
- [Manage users and groups in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-users-and-groups-in-microsoft-365/)
- [Manage admin roles in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-admin-roles/)
- [Manage password policies](https://learn.microsoft.com/en-us/training/modules/manage-password-policies/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-DC01** | Create OU structure: `OU=SSW, OU=Users, DC=ssw, DC=lab` |
| **SSW-DC01** | Bulk-create test accounts via CSV + `Import-Csv | New-ADUser` |
| **SSW-MGMT01** | Assign roles in M365: create a *Helpdesk Administrator* |
| **SSW-MGMT01** | Create a dynamic group in Entra ID (attribute-based: `department -eq "IT"`) |
| **SSW-MGMT01** | Enable *Self-Service Password Reset* (SSPR) for the IT department |
| **SSW-W11-01** | Test SSPR as TestUser01 via `aka.ms/sspr` |
| **SSW-MGMT01** | Configure **Privileged Identity Management (PIM)**: make the Global Administrator role *eligible* for labadmin |
| **SSW-MGMT01** | Activate the GA role Just-in-Time via PIM → verify the audit trail under **Entra → PIM → Audit history** |

### Knowledge check
1. What is the principle of *least privilege* when assigning admin roles?
2. What is the difference between a security group and a Microsoft 365 group?
3. How does *bulk user creation* work via the Microsoft 365 admin center?
4. When do you use *dynamic groups* versus *assigned groups*?
5. What is *PIM* and why is *Just-in-Time* access preferred over permanent role assignment?

---

## Week 3 — Entra ID and hybrid identity

### MS Learn modules
- [Manage identity synchronisation with Azure AD Connect and Entra Cloud Sync](https://learn.microsoft.com/en-us/training/modules/manage-azure-active-directory-connect/)
- [Implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/implement-multifactor-authentication/)
- [Manage external identities](https://learn.microsoft.com/en-us/training/modules/manage-external-identities/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-DC01** | Check sync status: `Get-ADSyncScheduler` → verify cycle |
| **SSW-MGMT01** | Configure MFA via **Entra admin center → Security → Multifactor authentication** |
| **SSW-W11-01** | Register MFA method as TestUser01 (Authenticator app) |
| **SSW-MGMT01** | Review *Sign-in logs* in Entra ID → filter on MFA events |
| **SSW-MGMT01** | Invite an external user (B2B guest) via Entra ID |
| **SSW-MGMT01** | Configure *Cross-tenant access settings* for external organisations |
| **SSW-MGMT01** | Review **Entra Connect Health** → verify sync agent status and error report |
| **SSW-MGMT01** | Enable **Entra Password Protection** → configure banned password list |

### Knowledge check
1. What is the difference between per-user MFA and *Security Defaults*?
2. How does *Seamless Single Sign-On* (SSO) work with Azure AD Connect?
3. What is Azure AD B2B and when do you use B2B versus B2C?
4. How do you troubleshoot a sync error in Azure AD Connect?
5. What is the difference between *Microsoft Entra Connect Sync* and *Entra Cloud Sync*?
6. What does *Entra Password Protection* do and how does the on-premises agent work?

---

## Week 4 — Exchange Online management

### MS Learn modules
- [Manage Exchange Online recipients and permissions](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-recipients/)
- [Manage Exchange Online mail flow](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-mail-flow/)
- [Manage Exchange Online protection](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-protection/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Create shared mailboxes via the Exchange Admin Center (EAC) |
| **SSW-MGMT01** | Configure a *Distribution list* and a *Microsoft 365 Group* |
| **SSW-MGMT01** | Set up a *mail flow rule*: append disclaimer to outbound mail |
| **SSW-MGMT01** | Configure *Anti-spam* and *Anti-phishing* policies in Defender for Office 365 |
| **SSW-W11-01** | Run a *message trace* via EAC → analyse delivery status |
| **SSW-MGMT01** | Configure *DKIM* and review DMARC settings for the tenant domain |

### Knowledge check
1. What is the difference between a *shared mailbox* and a *room mailbox*?
2. How does *message trace* work and when do you use it?
3. What do *Safe Attachments* and *Safe Links* do in Defender for Office 365?
4. What is the difference between *anti-spam* and *anti-phishing* policies?

---

## Week 5 — SharePoint Online and Microsoft Teams

### MS Learn modules
- [Manage SharePoint Online](https://learn.microsoft.com/en-us/training/modules/manage-sharepoint-online/)
- [Manage Microsoft Teams](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-teams/)
- [Manage Teams collaboration settings](https://learn.microsoft.com/en-us/training/modules/manage-teams-collaboration-settings/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Create a SharePoint site collection (Team site) and assign permissions |
| **SSW-MGMT01** | Configure *external sharing* settings in the SharePoint admin center |
| **SSW-W11-01** | Upload documents to SharePoint → test sharing with TestUser02 |
| **SSW-MGMT01** | Create a Teams team via the Teams admin center → add members |
| **SSW-MGMT01** | Configure *Meetings policies* in Teams: restrict recording for guests |
| **SSW-MGMT01** | Review **Teams usage reports** in the M365 admin center |

### Knowledge check
1. What is the difference between a *Group site*, *Communication site* and *Hub site* in SharePoint?
2. How do you manage external access in Teams at the channel level versus the team level?
3. What are *sensitivity labels* and how do you apply them to Teams and SharePoint?
4. How do you use PowerShell (PnP / Teams module) for bulk management?

---

## Week 6 — Microsoft Defender XDR and threat management

### MS Learn modules
- [Explore the Microsoft Defender XDR portal](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-defender/)
- [Manage Microsoft Defender for Office 365](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-defender-office-365/)
- [Manage Microsoft Secure Score and Exposure Management](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-secure-score/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Open the **Microsoft Defender XDR portal** (security.microsoft.com) |
| **SSW-W11-01** | Onboard W11-01 to Defender for Endpoint via Intune policy |
| **SSW-W11-01** | Simulate suspicious activity: download the EICAR test file → check alert |
| **SSW-MGMT01** | Analyse the incident in the Defender portal → review the *Attack story* graph |
| **SSW-MGMT01** | Review the **Exposure Management** dashboard → check the Microsoft Secure Score |
| **SSW-MGMT01** | Run *Attack Simulation Training* → phishing simulation to TestUser01 |
| **SSW-MGMT01** | Analyse *Secure Score* → select an improvement action and implement it |

### Knowledge check
1. What is the difference between Defender for Office 365 Plan 1 and Plan 2?
2. How does *Automated Investigation and Response* (AIR) work in Defender?
3. What does *Threat Explorer* show and when do you use it?
4. How do you effectively improve your Microsoft Secure Score?
5. What is *Exposure Management* and how does it relate to Secure Score?

---

## Week 7 — Microsoft Purview Compliance

### MS Learn modules
- [Implement Microsoft Purview Information Protection](https://learn.microsoft.com/en-us/training/modules/implement-information-protection/)
- [Implement data loss prevention](https://learn.microsoft.com/en-us/training/modules/implement-data-loss-prevention/)
- [Manage Microsoft Purview eDiscovery](https://learn.microsoft.com/en-us/training/modules/manage-ediscovery/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Open the **Microsoft Purview portal** (compliance.microsoft.com) |
| **SSW-MGMT01** | Create a *sensitivity label*: "Confidential - Internal" with encryption |
| **SSW-W11-01** | Apply the label to a Word document → verify encryption |
| **SSW-MGMT01** | Create a *DLP policy*: block sending of Social Security Numbers via email |
| **SSW-W11-01** | Test the DLP policy: send email with a fictitious SSN → verify block |
| **SSW-MGMT01** | Run a *Core eDiscovery* search on the TestUser01 mailbox |

### Knowledge check
1. What is the difference between *sensitivity labels* and *retention labels*?
2. How does *DLP endpoint protection* work on managed devices?
3. What is *Communication Compliance* and when is it required?
4. What is the difference between *Core eDiscovery* and *eDiscovery Premium*?

---

## Week 8 — Exam preparation

### Activities
- Review weak domains based on the [official exam profile](https://learn.microsoft.com/en-us/certifications/exams/ms-102/)
- Complete the **Microsoft Learn practice assessment** for MS-102: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Revisit Azure AD Connect sync, Defender incidents and Purview labels
- Practice PowerShell: MgGraph module (`Connect-MgGraph`), Exchange Online module
- Schedule your exam via Pearson VUE

### Exam focus areas
- Hybrid identity: know both **Connect Sync** and **Entra Cloud Sync** — differences and migration scenarios
- **Defender XDR (30–35%):** unified portal, AIR, Exposure Management, Attack Simulation, Secure Score improvements
- DLP: differences between policies for Exchange, SharePoint and Endpoint
- **Purview (10–15%):** retention vs. sensitivity labels — know core scenarios
- PIM: eligible vs. active vs. permanent role assignments in MS-102 scope
- Entra Password Protection and Connect Health are now explicit exam objectives
