# Study Guide MS-102 — Microsoft 365 Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-MS102.md)

**Duration:** 8 weeks · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)
**MS Learn path:** [Microsoft 365 Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/ms-102)
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
> **Exam domain:** Deploy and manage a Microsoft 365 tenant · **Weight:** 25–30%

### Learning Objectives
- [ ] Navigate the Microsoft 365 admin center and identify its key management areas
- [ ] Configure tenant settings including organisation name, region, and time zone
- [ ] Add and verify a custom domain by creating the required DNS records
- [ ] Install and configure Azure AD Connect to synchronise on-premises AD users to Entra ID
- [ ] Assign Microsoft 365 E5 licenses to synchronised users
- [ ] Enable Microsoft 365 Backup and define backup policies for Exchange and OneDrive

### MS Learn modules
- [Explore your Microsoft 365 cloud environment](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-cloud-environment/)
- [Configure your Microsoft 365 experience](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-experience/)
- [Manage Microsoft 365 tenants](https://learn.microsoft.com/en-us/training/modules/manage-your-microsoft-365-tenant/)

### Key Concepts
| Term | Description |
|------|-------------|
| Microsoft 365 admin center | Central management portal for Microsoft 365 services, users, licenses, and billing (admin.microsoft.com) |
| Managed domain | A domain where authentication is handled entirely in Entra ID (cloud-only or password hash sync) |
| Federated domain | A domain where authentication is redirected to an on-premises identity provider (e.g., ADFS) |
| Azure AD Connect | Tool that synchronises on-premises Active Directory objects to Microsoft Entra ID |
| Password Hash Synchronisation (PHS) | Sync method that copies a hash of the user's password hash to Entra ID, allowing cloud-based authentication |
| Pass-Through Authentication (PTA) | Sync method that validates passwords against on-premises AD in real time without storing any hash in the cloud |
| Microsoft 365 Backup | Native backup service for Exchange, OneDrive, and SharePoint that enables point-in-time restore, distinct from retention policies |
| DNS records for custom domain | Includes a TXT verification record, MX record for mail delivery, CNAME records for Autodiscover and other services |

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

<details>
<summary>Answers</summary>

1. A **managed domain** means authentication is processed entirely in Entra ID (cloud). This includes password hash synchronisation and pass-through authentication. A **federated domain** redirects authentication to an on-premises identity provider such as ADFS. With federation, Entra ID trusts tokens issued by the federated IdP. Managed domains are simpler to operate and are the recommended approach for most organisations.

2. **Password Hash Synchronisation (PHS):** Azure AD Connect computes a hash of the on-premises password hash and syncs it to Entra ID. Authentication happens in the cloud — no dependency on on-premises infrastructure at sign-in time. This is the most resilient option. **Pass-Through Authentication (PTA):** Authentication requests are forwarded to lightweight agents running on-premises, which validate the password directly against Active Directory. No password hash is stored in the cloud. Requires on-premises agent availability for sign-in to succeed.

3. Required DNS records for a custom domain in Microsoft 365:
   - **TXT record** — domain ownership verification (also used for SPF)
   - **MX record** — routes incoming email to Exchange Online
   - **CNAME records** — Autodiscover (for Outlook), plus optional records for Teams SIP/federation, MDM enrolment, etc.
   - **SPF TXT record** — specifies authorised mail senders (overlaps with TXT above in practice)

4. The **Microsoft 365 compliance center** (now integrated into Microsoft Purview at purview.microsoft.com) is the central portal for data governance and regulatory compliance. It is used for: creating and managing sensitivity labels and DLP policies, configuring retention policies and records management, running eDiscovery searches, monitoring audit logs, and using Compliance Manager to track regulatory improvement actions.

5. **Microsoft 365 Backup** provides a dedicated point-in-time restore capability for Exchange mailboxes, OneDrive accounts, and SharePoint sites. It enables restore to a specific point in time (e.g., before a ransomware event), independently of retention policies. **Retention policies** are compliance tools: they preserve data for a defined period to meet legal or regulatory requirements and do not offer on-demand restore to a prior state.

</details>

---

## Week 2 — User and group management
> **Exam domain:** Deploy and manage a Microsoft 365 tenant · **Weight:** 25–30%

### Learning Objectives
- [ ] Apply the principle of least privilege when assigning Microsoft 365 admin roles
- [ ] Create and manage users in bulk using CSV import and PowerShell
- [ ] Configure dynamic groups in Entra ID using attribute-based membership rules
- [ ] Enable and test Self-Service Password Reset (SSPR) for a defined group
- [ ] Configure Privileged Identity Management (PIM) to make admin roles eligible rather than permanently active
- [ ] Activate a role Just-in-Time via PIM and verify the audit trail

### MS Learn modules
- [Manage users and groups in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-users-and-groups-in-microsoft-365/)
- [Manage admin roles in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-admin-roles/)
- [Manage password policies](https://learn.microsoft.com/en-us/training/modules/manage-password-policies/)

### Key Concepts
| Term | Description |
|------|-------------|
| Least privilege | Security principle: assign only the minimum permissions required for a task — no more, no less |
| Security group | Entra ID group used to grant access to resources; does not provide Microsoft 365 services or email |
| Microsoft 365 group | Shared workspace with mailbox, calendar, SharePoint site, and Teams channel; backed by Entra ID |
| Dynamic group | Group whose membership is automatically maintained by Entra ID based on user attribute rules (e.g., department, jobTitle) |
| Assigned group | Group with manually managed membership; suitable when membership is static or exception-based |
| Self-Service Password Reset (SSPR) | Allows users to reset their own password without contacting helpdesk, using registered authentication methods |
| Privileged Identity Management (PIM) | Entra ID feature that provides Just-in-Time privileged access, requiring activation before a role becomes active |
| Just-in-Time (JIT) access | Pattern in which elevated rights are granted only for a limited time window upon explicit request and approval |

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

<details>
<summary>Answers</summary>

1. **Least privilege** means assigning only the permissions that are strictly necessary for a user to perform their role. In Microsoft 365 admin role terms: a user managing only Exchange should receive the Exchange Administrator role, not Global Administrator. This limits the blast radius if an account is compromised. Combined with PIM, even eligible admins only have active privileges during a defined window.

2. A **security group** is used solely to control access to resources (SharePoint sites, Teams channels, applications, licenses). It has no mailbox and no collaboration workspace. A **Microsoft 365 group** is a connected workspace: it includes a shared mailbox and calendar, a SharePoint team site, a Teams team (if created from Teams), and a Planner. Microsoft 365 groups are used for collaboration; security groups are used for access control.

3. Bulk user creation in the Microsoft 365 admin center: navigate to **Users → Active users → Add multiple users** and upload a CSV file with the required columns (UserPrincipalName, DisplayName, Password, etc.). Alternatively, use PowerShell with the `Import-Csv` cmdlet piped to `New-MgUser` (Microsoft Graph) or `New-ADUser` (on-premises AD, then synced via Entra Connect).

4. Use **dynamic groups** when membership should automatically reflect current directory attributes — for example, all users with `department = "Sales"` or all devices with `operatingSystem = "Windows"`. Dynamic groups eliminate manual maintenance but have a processing delay. Use **assigned groups** when membership is small, static, or requires manual oversight (e.g., a break-glass account group, a pilot group).

5. **PIM (Privileged Identity Management)** is an Entra ID P2 feature that controls how and when privileged roles are used. With PIM, a user is *eligible* for a role but is not actively assigned to it. To use the role, they must explicitly activate it (provide justification, optionally get approval), and the activation expires after a configured time window (e.g., 1–8 hours). **Just-in-Time** access is preferred because permanently active admin roles are a persistent attack surface — any token theft or session hijack gives immediate global admin access. JIT minimises the window of exposure and creates a full audit trail.

</details>

---

## Week 3 — Entra ID and hybrid identity
> **Exam domain:** Implement and manage Microsoft Entra identity and access · **Weight:** 25–30%

### Learning Objectives
- [ ] Compare Microsoft Entra Connect Sync and Entra Cloud Sync and select the appropriate solution
- [ ] Configure and verify Multi-Factor Authentication (MFA) using Entra ID security settings
- [ ] Distinguish between per-user MFA, Security Defaults, and Conditional Access-based MFA
- [ ] Invite and manage external B2B guest users and configure cross-tenant access settings
- [ ] Use Entra Connect Health to monitor synchronisation status and investigate errors
- [ ] Configure Entra Password Protection with a custom banned password list

### MS Learn modules
- [Manage identity synchronisation with Azure AD Connect and Entra Cloud Sync](https://learn.microsoft.com/en-us/training/modules/manage-azure-active-directory-connect/)
- [Implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/implement-multifactor-authentication/)
- [Manage external identities](https://learn.microsoft.com/en-us/training/modules/manage-external-identities/)

### Key Concepts
| Term | Description |
|------|-------------|
| Entra Connect Sync | Full-featured on-premises synchronisation engine; supports complex topologies, custom attribute mapping, and filtering rules |
| Entra Cloud Sync | Lightweight cloud-provisioning agent requiring minimal on-premises footprint; ideal for disconnected forests or simple scenarios |
| Security Defaults | Preconfigured baseline security settings enabled by default on new tenants; requires MFA for all users and blocks legacy authentication |
| Per-user MFA | Legacy method of enabling MFA individually per account; bypasses Conditional Access and is not recommended for new deployments |
| Seamless SSO | Feature of Entra Connect that silently authenticates domain-joined devices using Kerberos, providing single sign-on to cloud apps without additional prompts |
| Azure AD B2B | External identity model allowing guest users from partner organisations to access resources in your tenant using their own credentials |
| Azure AD B2C | Consumer identity platform for building customer-facing applications with custom sign-up/sign-in flows; separate service from B2B |
| Entra Password Protection | Service that enforces a global and custom banned password list both in Entra ID and on-premises AD via a proxy agent |
| Entra Connect Health | Monitoring service that provides health alerts, performance data, and usage analytics for Entra Connect Sync agents |

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

<details>
<summary>Answers</summary>

1. **Per-user MFA** is a legacy, account-level toggle that forces MFA for a specific user regardless of context. It cannot be scoped by location, device state, or application, and it does not integrate well with Conditional Access. **Security Defaults** is a tenant-wide policy that enforces MFA for all users, blocks legacy authentication protocols, and requires MFA for admin role activations. Security Defaults is suitable for organisations without Entra ID P1/P2 licensing. For organisations with Conditional Access (P1+), Security Defaults should be disabled in favour of explicit CA policies.

2. **Seamless SSO** works by registering a computer account (`AZUREADSSOACC`) in Active Directory during Entra Connect setup. When a domain-joined device attempts to authenticate to Entra ID, it receives a Kerberos service ticket for this account from the on-premises domain controller. Entra ID decrypts the ticket using the shared secret, validates the identity, and issues a token — without the user being prompted. This provides transparent SSO to Azure-integrated applications from corporate-joined devices.

3. **Azure AD B2B** (Business-to-Business) allows external users from other organisations to be invited as guests into your tenant. They authenticate with their own organisational credentials (or Microsoft account) and access your resources under your policies. Use B2B for partner and supplier collaboration. **Azure AD B2C** (Business-to-Consumer) is a separate identity-as-a-service platform for customer-facing applications, supporting custom sign-up/sign-in flows, social identity providers (Google, Facebook), and consumer-scale identity management. B2C is not part of your Entra tenant — it is a standalone resource in Azure.

4. Troubleshooting sync errors in Entra Connect: (1) Open **Synchronisation Service Manager** on the connector server → check the Operations tab for export/import errors. (2) Use the **Entra Connect Health** portal (entra.microsoft.com → Monitoring → Entra Connect Health) for aggregated alerts and diagnostics. (3) Run `Start-ADSyncSyncCycle -PolicyType Delta` to trigger a manual delta sync. (4) Check for object-level errors such as duplicate `proxyAddresses` or `userPrincipalName` conflicts. (5) Use `Get-ADSyncCSObject` or the **Synchronisation Rules Editor** to trace specific object issues.

5. **Entra Connect Sync** is the full on-premises synchronisation engine, installed as a service on a Windows Server. It supports multi-forest topologies, granular attribute filtering, custom synchronisation rules, staging mode for disaster recovery, and writeback features (group writeback, device writeback). **Entra Cloud Sync** uses a lightweight agent (no full server installation) and is managed from the cloud. It is suitable for simpler single-forest scenarios, disconnected forests, or organisations migrating away from the on-premises agent. Cloud Sync does not yet support all Entra Connect features (e.g., device writeback, Exchange hybrid writeback).

6. **Entra Password Protection** prevents the use of weak passwords by enforcing a Microsoft-maintained global banned password list and optionally a custom organisational list. In Entra ID it applies at cloud password change/reset. For on-premises Active Directory, a **DC Agent** and a **Proxy Service** are deployed: the proxy forwards policy from Entra ID to the DC agents, and the DC agents enforce the banned password logic at the Windows password filter layer during every on-premises password change or reset.

</details>

---

## Week 4 — Exchange Online management
> **Exam domain:** Deploy and manage a Microsoft 365 tenant · **Weight:** 25–30%

### Learning Objectives
- [ ] Create and manage Exchange Online recipient types: shared mailboxes, room mailboxes, distribution lists, and Microsoft 365 groups
- [ ] Configure mail flow rules (transport rules) to enforce organisational messaging policies
- [ ] Configure anti-spam and anti-phishing policies in Microsoft Defender for Office 365
- [ ] Perform a message trace to investigate mail delivery issues
- [ ] Configure DKIM signing for a custom domain and understand its relationship with SPF and DMARC

### MS Learn modules
- [Manage Exchange Online recipients and permissions](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-recipients/)
- [Manage Exchange Online mail flow](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-mail-flow/)
- [Manage Exchange Online protection](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-protection/)

### Key Concepts
| Term | Description |
|------|-------------|
| Shared mailbox | A mailbox accessed by multiple users without a dedicated license (up to 50 GB); no dedicated sign-in credentials |
| Room mailbox | A resource mailbox representing a physical meeting room; accepts or declines meeting requests automatically |
| Distribution list | A mail-enabled group that delivers messages to all members; does not provide collaboration features |
| Mail flow rule (transport rule) | Server-side rule applied to messages in transit; can modify, redirect, reject, or add disclaimers to messages |
| DKIM | DomainKeys Identified Mail — adds a cryptographic signature to outbound messages, allowing receivers to verify the message was not tampered with |
| SPF | Sender Policy Framework — a DNS TXT record listing IP addresses authorised to send email for a domain |
| DMARC | Domain-based Message Authentication, Reporting and Conformance — policy governing what receivers do when SPF or DKIM checks fail (none / quarantine / reject) |
| Message trace | Exchange Online tool that tracks the path and delivery status of individual messages; available in EAC and via PowerShell |

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

<details>
<summary>Answers</summary>

1. A **shared mailbox** is designed for team use where multiple people need access to a common inbox (e.g., support@company.com). It has no password-based sign-in of its own and does not require a license for mailboxes under 50 GB. Users are granted Full Access and Send As/Send on Behalf permissions. A **room mailbox** represents a physical meeting space. It is a resource mailbox that can be targeted in meeting invitations, automatically processes booking requests based on configured policies (auto-accept, allow conflicts, booking windows), and appears in the room finder in Outlook.

2. **Message trace** tracks the delivery path of email messages through Exchange Online. For each message, it shows the sender, recipient, subject, time, delivery status (delivered, pending, failed), and the specific action taken at each hop. Use it when: a user reports a missing email, messages are being blocked or quarantined unexpectedly, or you need to verify that a mail flow rule or policy is triggering. Access via Exchange Admin Center → Mail flow → Message trace, or via `Get-MessageTrace` in Exchange Online PowerShell.

3. **Safe Attachments** scans email attachments in a detonation sandbox before delivering them to the recipient. If a file is found to be malicious, it is blocked or replaced (depending on the policy action). Dynamic Delivery mode allows the email body to arrive immediately while the attachment is still being scanned. **Safe Links** rewrites URLs in emails and Office documents at send time. When a user clicks a rewritten link, Safe Links performs a real-time reputation check and blocks access if the URL has been found to be malicious — even if it was clean at delivery time. Both features are part of Microsoft Defender for Office 365 Plan 1 and above.

4. **Anti-spam policies** focus on identifying and filtering unsolicited bulk email (spam) based on message characteristics, sender reputation, and heuristics. They classify messages as spam, high-confidence spam, phishing, bulk email, etc., and define what action to take (deliver to junk, quarantine, reject). **Anti-phishing policies** specifically target social engineering attacks: impersonation of trusted senders (user or domain impersonation), spoof intelligence (detecting forged From addresses), and mailbox intelligence (learning a user's communication patterns to detect anomalies). Anti-phishing also controls safety tips displayed to users and first-contact warnings.

</details>

---

## Week 5 — SharePoint Online and Microsoft Teams
> **Exam domain:** Deploy and manage a Microsoft 365 tenant · **Weight:** 25–30%

### Learning Objectives
- [ ] Create and configure SharePoint site collections and manage permissions at site, library, and item level
- [ ] Configure external sharing settings in SharePoint and understand the relationship with Entra B2B
- [ ] Create and manage Microsoft Teams teams via the Teams admin center
- [ ] Configure Teams meeting policies and restrict specific capabilities for guests
- [ ] Apply sensitivity labels to Teams and SharePoint sites to enforce data protection settings
- [ ] Use PowerShell (PnP module and Teams module) for bulk management tasks

### MS Learn modules
- [Manage SharePoint Online](https://learn.microsoft.com/en-us/training/modules/manage-sharepoint-online/)
- [Manage Microsoft Teams](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-teams/)
- [Manage Teams collaboration settings](https://learn.microsoft.com/en-us/training/modules/manage-teams-collaboration-settings/)

### Key Concepts
| Term | Description |
|------|-------------|
| Team site (Group site) | SharePoint site connected to a Microsoft 365 group; includes shared mailbox, calendar, and Teams channel |
| Communication site | Broadcast-style SharePoint site for publishing content to a wide audience; not connected to a Microsoft 365 group |
| Hub site | SharePoint site that aggregates navigation, search, and branding across multiple associated sites |
| External sharing levels | Configurable at tenant and site level: Anyone, New and existing guests, Existing guests only, or Only people in your organisation |
| Teams meeting policy | Admin-defined policy controlling what meeting features are available to users (recording, transcription, lobby, guest access) |
| Sensitivity label on sites | When a label with site and group protection is applied, it enforces privacy settings, external user access, and unmanaged device restrictions on the container |
| PnP PowerShell | Community-supported PowerShell module for SharePoint Online, providing cmdlets for bulk site, library, and permission management |
| Teams PowerShell module | Official Microsoft module for managing Teams settings, policies, and membership at scale |

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

<details>
<summary>Answers</summary>

1. A **Group site (Team site)** is automatically created when a Microsoft 365 group is created. It provides a collaborative workspace for team members, tightly coupled with the group's shared resources (mailbox, calendar, Teams). A **Communication site** is a standalone publishing site designed to broadcast information from a few authors to many readers; it has no connected group or shared mailbox. A **Hub site** is a SharePoint site designated as a parent hub to which other sites can associate. Hub association provides unified navigation, consistent branding, and cross-site search — it does not move content, it aggregates it.

2. External access in Teams operates at multiple levels. At the **tenant level**, the Teams admin center controls whether external Teams users (from other organisations) can find, call, and message your users. At the **team level**, the team owner controls whether guests (Entra B2B guests) can be added to the team. At the **channel level**, shared channels allow direct collaboration with external users without making them guests in the tenant — they retain their home tenant identity. Standard and private channels do not have separate external access settings beyond the team-level guest toggle.

3. **Sensitivity labels** are classification tags created in Microsoft Purview. When published to users, they can be applied to files and emails to enforce encryption, content marking, and access restrictions. When a label is scoped to **groups and sites**, applying it to a Teams team or SharePoint site enforces container-level settings: team privacy (public/private), whether external users can be added, and whether access from unmanaged devices is allowed. Labels are applied via the sensitivity label policy in the Purview portal, published to selected users or groups, and then usable in Office apps, SharePoint, and the Teams admin center.

4. **PnP PowerShell** (`Connect-PnPOnline`) provides cmdlets such as `New-PnPSite`, `Set-PnPTenantSite`, `Add-PnPGroupMember`, and `Set-PnPListPermission` for bulk SharePoint operations. The **Microsoft Teams PowerShell module** (`Connect-MicrosoftTeams`) provides cmdlets like `New-Team`, `Add-TeamUser`, `Set-TeamMeetingPolicy`, and `Get-CsTeamsCallingPolicy` for managing Teams at scale. Both are used in combination with `Import-Csv` or loops to apply consistent settings across multiple sites, teams, or users without manual portal work.

</details>

---

## Week 6 — Microsoft Defender XDR and threat management
> **Exam domain:** Manage security and threats by using Microsoft Defender XDR · **Weight:** 30–35%

### Learning Objectives
- [ ] Navigate the Microsoft Defender XDR unified portal and understand its component coverage
- [ ] Onboard a Windows 11 device to Microsoft Defender for Endpoint via Intune policy
- [ ] Investigate a security incident using the Attack story graph and take containment actions
- [ ] Understand how Automated Investigation and Response (AIR) processes alerts
- [ ] Use Threat Explorer to analyse email-based threats in the tenant
- [ ] Interpret the Microsoft Secure Score and implement a scored improvement action
- [ ] Explain the relationship between Exposure Management and Secure Score

### MS Learn modules
- [Explore the Microsoft Defender XDR portal](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-defender/)
- [Manage Microsoft Defender for Office 365](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-defender-office-365/)
- [Manage Microsoft Secure Score and Exposure Management](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-secure-score/)

### Key Concepts
| Term | Description |
|------|-------------|
| Microsoft Defender XDR | Extended Detection and Response platform unifying MDE, MDO, MDI, and MDCA signals into correlated incidents |
| Defender for Endpoint (MDE) | Endpoint security solution providing next-generation protection, EDR, Advanced Hunting, and vulnerability management |
| Defender for Office 365 Plan 1 | Adds Safe Attachments, Safe Links, and anti-phishing policies to Exchange Online Protection |
| Defender for Office 365 Plan 2 | Adds Threat Explorer, Attack Simulation Training, Automated Investigation and Response, and Advanced Hunting on top of Plan 1 |
| Automated Investigation and Response (AIR) | Automated workflow that investigates alerts, collects evidence, and proposes or executes remediation actions |
| Threat Explorer | Real-time interface for investigating email threats across the tenant; shows delivery actions, detection technology, and message details |
| Microsoft Secure Score | Aggregated security posture score based on enabled controls across identity, devices, apps, and data |
| Exposure Management | Broader attack surface management view that combines device vulnerability data, identity risk, and lateral movement paths |
| Attack Simulation Training | Managed phishing simulation service that measures user susceptibility and assigns targeted awareness training |

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

<details>
<summary>Answers</summary>

1. **Defender for Office 365 Plan 1** adds proactive protection on top of Exchange Online Protection: Safe Attachments (sandboxed attachment scanning), Safe Links (real-time URL rewriting and reputation checks), and advanced anti-phishing policies (impersonation protection, spoof intelligence, mailbox intelligence). **Plan 2** includes everything in Plan 1 and adds: Threat Explorer and real-time detections for investigating email threats, Attack Simulation Training for phishing simulations, post-breach capabilities including Automated Investigation and Response (AIR) for email, Advanced Hunting over email signals, and Campaign Views showing coordinated attack patterns.

2. **AIR** is triggered automatically when a high-confidence alert fires (e.g., a user clicked a malicious link, a suspicious process executed on a device). AIR runs a pre-defined investigation playbook: it collects related evidence (devices, users, emails, files), evaluates each entity, and produces a verdict (malicious, suspicious, clean). It then presents pending remediation actions (e.g., quarantine email, isolate device, disable user) for admin approval, or in some configurations executes them automatically. AIR reduces mean time to respond by performing triage that would otherwise require manual analyst work.

3. **Threat Explorer** (available in Defender for Office 365 Plan 2) provides real-time visibility into email threats detected in your tenant. It shows: all email messages and their detection verdicts, the delivery location (inbox, junk, quarantine, dropped), the detection technology that flagged the message (Safe Attachments, Safe Links, spoof intelligence, etc.), sender information, and associated URLs and attachments. Use it when investigating a phishing campaign, tracing whether a specific malicious email was delivered to other users, or manually remediating a set of emails.

4. Secure Score improvements are implemented by selecting specific improvement actions from the Secure Score portal (security.microsoft.com → Secure Score → Improvement actions). Each action lists the point value, implementation complexity, user impact, and step-by-step instructions. High-value, low-complexity actions first: enabling MFA for all users, blocking legacy authentication, enabling Safe Attachments and Safe Links policies. After implementing an action, the score updates within 24–48 hours as telemetry reflects the change. Some actions have third-party alternatives that can be marked to indicate the control is met outside of Microsoft.

5. **Exposure Management** is the attack surface management layer in the Defender XDR portal. It aggregates device vulnerability data (CVE exposure scores), identity risk factors (over-privileged accounts, lateral movement paths), and cloud surface indicators. While **Secure Score** measures which security controls and configurations are enabled (a posture metric), Exposure Management maps the actual attack paths and exposure that remain given the current environment. The two are complementary: Secure Score guides which settings to turn on; Exposure Management shows what an attacker could realistically reach given the current configuration.

</details>

---

## Week 7 — Microsoft Purview Compliance
> **Exam domain:** Manage compliance by using Microsoft Purview · **Weight:** 10–15%

### Learning Objectives
- [ ] Create and publish sensitivity labels with encryption and content marking
- [ ] Configure a DLP policy targeting sensitive information types across Exchange, SharePoint, and OneDrive
- [ ] Test and verify DLP policy enforcement in a controlled scenario
- [ ] Distinguish between sensitivity labels and retention labels and explain when to use each
- [ ] Run a Core eDiscovery search on a user mailbox and export the results
- [ ] Explain the role of Communication Compliance and the scenarios in which it is required

### MS Learn modules
- [Implement Microsoft Purview Information Protection](https://learn.microsoft.com/en-us/training/modules/implement-information-protection/)
- [Implement data loss prevention](https://learn.microsoft.com/en-us/training/modules/implement-data-loss-prevention/)
- [Manage Microsoft Purview eDiscovery](https://learn.microsoft.com/en-us/training/modules/manage-ediscovery/)

### Key Concepts
| Term | Description |
|------|-------------|
| Sensitivity label | A persistent classification tag applied to files, emails, or containers (sites/teams) that can enforce encryption, content marking, and access restrictions |
| Retention label | A label applied to a specific item (email, document, Teams message) that governs how long the item must be kept and what happens after the retention period |
| Retention policy | A location-scoped policy that automatically applies a retention or deletion rule to all content in a defined location (mailbox, site, Teams channel) |
| DLP policy | A Purview rule set that detects sensitive information types (SSNs, credit card numbers, etc.) in content and takes configured actions (block, warn, notify) |
| Sensitive Information Type (SIT) | A pattern definition (regular expression + keyword list) used by DLP policies and auto-labelling to identify specific categories of sensitive data |
| eDiscovery (Standard) | Provides search and hold capabilities across Exchange, SharePoint, and Teams for legal investigation purposes |
| eDiscovery (Premium) | Extends Standard with custodian management, review sets, AI-assisted analysis, near-duplicate detection, and email threading |
| Communication Compliance | Purview feature that scans Teams and email communications for policy violations (harassment, regulatory content, insider risk signals) |

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

<details>
<summary>Answers</summary>

1. **Sensitivity labels** describe the confidentiality of content and can actively protect it by applying encryption, content marking (headers, footers, watermarks), and restricting who can access or share the item. The label travels with the file. **Retention labels** govern the lifecycle of content: they define how long an item must be kept (to meet legal or regulatory requirements) and what happens when that period expires (delete, trigger a disposition review, or do nothing). A retention label does not protect content from reading or sharing — it only governs retention. A document can have both a sensitivity label and a retention label applied simultaneously.

2. **Endpoint DLP** extends Purview DLP policies to Windows 10/11 devices that are onboarded into Microsoft Defender for Endpoint. On managed endpoints, the DLP policy can detect sensitive content in files and enforce actions such as: blocking copying to removable USB drives, blocking upload to unauthorised cloud services or websites, blocking printing to non-corporate printers, blocking clipboard paste into unauthorised applications. These actions are enforced by the MDE sensor on the device, even when the device is off the corporate network. Endpoint DLP requires Microsoft 365 E5 or a Microsoft 365 E5 Compliance add-on.

3. **Communication Compliance** is a Purview feature that monitors Teams messages, Exchange email, and Teams channel posts for policy violations. It uses supervised review workflows where compliance officers (not IT admins) review flagged communications. Use cases include: monitoring for harassment or threatening language, detecting inadvertent sharing of financial information (regulatory compliance in financial services), identifying potential insider risk signals, and enforcing acceptable use policies. It is required in regulated industries where communications surveillance is mandated (e.g., FINRA, MiFID II for financial services) or where HR policies require documented oversight.

4. **eDiscovery (Standard)** provides the foundational legal hold and search capabilities: place a hold on specific mailboxes or sites to preserve content, run keyword and date-range searches across Exchange, SharePoint, OneDrive, and Teams, and export results. **eDiscovery (Premium)** adds a structured case management workflow: custodian management with legal hold notices, the ability to collect content into review sets for attorney review, AI-powered analytics (near-duplicate identification, email threading, themes), relevance scoring, and detailed chain-of-custody reporting. Premium is designed for complex litigation involving large volumes of data and multiple custodians.

</details>

---

## Week 8 — Exam preparation

### Activities
- Review weak domains based on the [official exam study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/ms-102)
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

---

## Exam Coverage Gaps and Must-Do Labs

This section addresses topics that are explicitly tested on the MS-102 exam but are underrepresented in the eight-week programme above. Complete these before scheduling the exam.

### Topics still requiring attention

1. **Service Health and operational monitoring** — The exam tests knowledge of how to monitor tenant health, configure service health notifications, and use the Network connectivity dashboard. The Message Center workflow (filtering, tagging, and exporting announcements) is also in scope.

2. **Group-based licensing** — Assigning licenses via group membership rather than per-user is an exam objective. You must understand how group-based licensing interacts with license conflicts, error states, and the processing delay after group membership changes.

3. **Microsoft Defender for Cloud Apps (MDCA)** — Cloud Discovery, app sanctioning/unsanctioning, activity policies, session policies, and the Conditional Access App Control (CAAC) proxy are all within Defender XDR domain scope (30–35%). These topics are absent from the weekly programme.

4. **Purview retention policies and retention labels (side-by-side)** — The exam distinguishes carefully between location-scoped retention policies and item-scoped retention labels. Records management concepts (record declaration, disposition review, file plan) are also in scope for Domain 4.

5. **Defender for Identity (MDI) fundamentals** — MDI sensor installation, alert types (Pass-the-Hash, Kerberoasting, lateral movement paths), and how MDI integrates with Defender XDR incidents are tested and not covered in the weekly labs.

6. **Conditional Access policy configuration** — CA is explicitly in Domain 2 (Entra identity and access). Named locations, device compliance conditions, authentication strengths, and sign-in frequency controls are common exam scenarios.

### Must-do labs before exam day

1. **Service Health notifications:** In the M365 admin center, configure email notifications for service incidents affecting Exchange Online and Teams. Document which advisory and incident categories are available and what triggers a notification.

2. **Group-based licensing:** Create a security group in Entra ID, assign an E5 license to the group, add TestUser01 as a member, and verify that the license is applied automatically. Then remove the user from the group and verify the license is revoked. Observe the processing delay.

3. **Defender for Cloud Apps — Cloud Discovery:** In the Defender XDR portal, navigate to Cloud apps → Cloud Discovery. Review the top discovered apps, sanction one app and unsanction another, and observe how unsanctioned app blocking works via Defender for Endpoint integration.

4. **Retention policy + retention label comparison:** Create one Exchange-scoped retention policy (retain for 5 years, then delete) and one retention label that declares items as records (retain for 7 years, disposition review required). Apply both in your lab tenant and compare the user experience and admin audit trail.

5. **Three complete Defender XDR incident flows:** For each incident, practice the full workflow: triage the alert queue, open the incident, review the Attack story, identify affected entities (user, device, email), execute a containment action (isolate device or disable user), and close the incident with a classification and determination. Use EICAR and Attack Simulation to generate real incidents in the lab.

6. **Conditional Access — named location and compliance policy:** Create a CA policy that requires compliant device status for access to SharePoint Online. Test from an enrolled (compliant) device and an unenrolled device to observe the different outcomes. Review the sign-in log entries to understand the CA evaluation detail.

### Exit criteria before scheduling the exam

1. You can demonstrate at least two concrete administrative actions for each of the four MS-102 exam domains without referring to notes.
2. You consistently score above the 700/1000 pass mark equivalent on the Microsoft Learn practice assessment.
3. You have completed at least one full incident response flow in the Defender XDR portal from alert through to resolved classification.
4. You can explain the difference between PHS, PTA, and Cloud Sync without prompting, including when to choose each.
5. You have no unresolved gaps in the Purview domain: you can confidently distinguish sensitivity labels, retention labels, retention policies, DLP policies, and eDiscovery (Standard vs. Premium).
