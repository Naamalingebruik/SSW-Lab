# Study Guide SC-300 — Identity and Access Administrator

> **Language:** English | [Nederlands](studieprogramma-SC300.md)

**Duration:** 7 weeks · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)
**MS Learn path:** [Identity and Access Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-300)
**Exam weight:**

| Domain | Weight |
|---|---|
| Implement and manage user identities | 20–25% |
| Implement authentication and access management | 25–30% |
| Plan and implement workload identities | 20–25% |
| Plan and automate identity governance | 20–25% |

> **Updated:** Skills measured as of November 7, 2025. Domains renamed and reweighted. "Implement access management for Azure resources by using Azure roles" was **removed** from the exam. **Global Secure Access** added as a new section under authentication and access management.

> **Prerequisite:** Microsoft 365 E5 developer tenant + Azure subscription (MSDN)
> SC-300 involves more Azure portal work than MD-102/MS-102

> **New as of November 2025:** *Implement Global Secure Access* was added to the exam. Current SSW-Lab scripts do not yet cover this area end-to-end, so use the matching [MS Learn module](https://learn.microsoft.com/en-us/training/modules/deploy-configure-microsoft-entra-global-secure-access/) as a required companion.

## How to use this study guide

- Read the exam domain and learning objectives first each week; SC-300 is heavily about choosing between similar identity options with different trade-offs.
- Then perform the lab exercises in Entra, Azure, and on the on-premises VMs where relevant so you can observe hybrid behaviour rather than only reading about it.
- Complete the knowledge check only after the theory and lab work, and pay close attention to why the rejected options are wrong.
- If you work with bilingual colleagues, keep Microsoft terminology active in both languages, such as *guest user / gastgebruiker* and *workload identity / workload-identiteit*.

## Lab coverage and expectations

- **Strong SSW-Lab coverage:** hybrid identity, Entra Connect, PHS/PTA, SSPR, Conditional Access, PIM, app registrations, service principals, and identity governance fundamentals.
- **Partial coverage:** lifecycle workflows, access reviews at scale, workload identities in more complex application chains, and some risk detections depend on tenant licensing and suitable test signals.
- **Study separately as well:** Global Secure Access, some of the newest Entra portal experiences, and scenarios that require a second tenant or production-like partner trust.
- Use the lab steps to build understanding, but always test yourself on the design decision too: when should you choose a specific identity model, policy, or governance approach?

## How to use the knowledge checks

- Answer first which design or control you would choose, and only then how you would implement it technically.
- For every answer, state which risk is reduced or which governance problem is being solved.
- Revisit missed questions with a terminology focus: many SC-300 choices sound similar, but their prerequisites are different.
- Spend extra attention on guest access, Conditional Access, workload identities, and governance because they generate many scenario-style exam questions.

---

## Week 1 — Entra ID fundamentals and hybrid identity
> **Exam domain:** Implement and manage user identities · **Weight:** 20–25%

> **Real-world scenario:** A mid-sized manufacturing company has 800 on-premises Active Directory users and is migrating to Microsoft 365. The IT consultant must decide which hybrid authentication method to deploy so that users can sign in to Microsoft 365 services with their existing AD credentials — without storing password hashes in the cloud, as required by the company's security policy. At the same time, SSPR must be configured so employees can reset their own passwords from the login screen without calling the helpdesk.

### Learning Objectives
- [ ] Configure and manage an Entra ID tenant, including tenant properties and user settings
- [ ] Create, configure, and manage user and group objects in Entra ID
- [ ] Implement and verify Azure AD Connect Sync with Password Hash Synchronization (PHS)
- [ ] Configure Seamless SSO and understand the underlying Kerberos mechanism
- [ ] Distinguish between Entra Connect Sync and Entra Cloud Sync and select the appropriate option
- [ ] Manage the user lifecycle including soft delete, restore, and hard delete behaviour

### MS Learn modules
- [Implement initial configuration of Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/implement-initial-configuration-azure-active-directory/)
- [Create, configure, and manage identities](https://learn.microsoft.com/en-us/training/modules/create-configure-manage-identities/)
- [Implement and manage hybrid identity](https://learn.microsoft.com/en-us/training/modules/implement-manage-hybrid-identity/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **LAB-DC01** | Verify AD structure: `Get-ADForest`, `Get-ADDomain`, `Get-ADUser -Filter *` |
| **LAB-DC01** | Install Azure AD Connect Sync → configure *Password Hash Sync* |
| **LAB-DC01** | Verify sync: `Start-ADSyncSyncCycle -PolicyType Delta` |
| **LAB-MGMT01** | Open **Entra admin center** (entra.microsoft.com) → verify sync status |
| **LAB-MGMT01** | Configure *Custom Security Attributes* for user classification |
| **LAB-MGMT01** | Review *Audit logs* in Entra ID → filter on user creation events |

### Lab commands

```powershell
# Trigger a delta sync cycle from the AD Connect server
Start-ADSyncSyncCycle -PolicyType Delta

# View sync connector status
Get-ADSyncConnector | Select-Object Name, ConnectorTypeName, LastSyncTime

# Restore a soft-deleted user via Microsoft Graph PowerShell
Restore-MgDirectoryDeletedItem -DirectoryObjectId "<object-id>"

# Force a full sync cycle (use sparingly)
Start-ADSyncSyncCycle -PolicyType Initial
```

### Key Concepts
| Term | Description |
|------|-------------|
| Entra Connect Sync | On-premises sync agent that replicates AD objects to Entra ID; supports complex filtering, attribute writeback, and device writeback |
| Entra Cloud Sync | Lightweight, cloud-managed provisioning agent — ideal for simple multi-forest scenarios; fewer features than full Connect Sync |
| Password Hash Sync (PHS) | Synchronized hashed password hashes to Entra ID; authentication occurs in the cloud — remains functional even if on-prem AD is unreachable |
| Pass-through Authentication (PTA) | Authentication is validated by an on-premises agent; no password hashes stored in the cloud — requires the PTA agent to be online |
| Seamless SSO | Domain-joined Windows devices authenticate to Entra ID apps automatically via Kerberos, using the `AZUREADSSOACC` computer account in AD |
| Soft delete | User account is deactivated and retained for 30 days; restorable via Entra portal or PowerShell |
| Hard delete | Permanent removal of a user object after the 30-day soft-delete window; cannot be undone |
| Staging mode | Entra Connect calculates sync operations but does not apply changes — used for testing or standby failover configurations |

### Knowledge check
1. What are the three authentication methods in hybrid identity and when do you use each?
2. How does *Seamless SSO* work and which Kerberos component is involved?
3. What is the difference between *soft delete* and *hard delete* of an Entra ID user?
4. How do you configure *password writeback* and why is it needed for SSPR?

<details>
<summary>Answers</summary>

1. **Password Hash Sync (PHS):** password hashes are synced to Entra ID; authentication happens in the cloud. Use when you want the most resilient option — sign-in works even if on-prem AD is temporarily unavailable. Microsoft recommends PHS as the default. **Pass-through Authentication (PTA):** authentication is forwarded to an on-premises agent; no hashes stored in the cloud. Use when organisational policy prohibits storing any credentials in the cloud. Requires the PTA agent to remain online. **Active Directory Federation Services (AD FS):** full federation with on-premises STS. Use only when specific claims, smart-card authentication, or complex federation requirements make PHS/PTA unsuitable. Not recommended for new deployments.

2. Seamless SSO uses a dedicated computer account named `AZUREADSSOACC` created in the on-premises AD. When a domain-joined Windows device accesses an Entra ID application, it requests a Kerberos service ticket for `AZUREADSSOACC` from the domain controller. The ticket is forwarded to Entra ID, which validates it and issues an access token — all without prompting the user for credentials.

3. **Soft delete:** the account is disabled and moved to a recycle bin state in Entra ID. The user cannot sign in, but the object and its attributes (group memberships, licences) are retained for 30 days. It can be restored with `Restore-MgDirectoryDeletedItem` or via the portal. **Hard delete:** permanent removal of the object from the directory — occurs automatically after the 30-day soft-delete period or can be triggered manually. A hard-deleted user cannot be restored; a new account must be created.

4. Password writeback is enabled in the Entra Connect Sync wizard under **Optional features → Password writeback**. It is required for SSPR because when a cloud user resets their password via the SSPR portal, the new password must be written back to the on-premises Active Directory to keep both directories in sync. Without writeback, the on-premises password remains unchanged, causing authentication failures for on-premises services and applications.

**Scenario-based questions:**

5. A company uses Pass-through Authentication (PTA) for its 1,200 users. During a planned maintenance window, the on-premises PTA agent servers are taken offline for 4 hours. What happens to users who attempt to sign in to Microsoft 365 during this window?
   - A) Users can still sign in because Entra ID caches credentials for 24 hours
   - B) Users cannot sign in because PTA requires the agent to be online to validate credentials
   - C) Users are automatically redirected to SSPR to reset their password
   - D) Users can sign in using their last known password hash stored in Entra ID

   **Answer: B.** PTA authenticates every request in real time by forwarding it to an on-premises agent. If all PTA agents are offline, authentication fails entirely. This is a key distinction from PHS, where authentication continues from the cloud even if on-prem AD is unreachable.

6. An employee left the company 15 days ago and their account was deleted in Entra ID. The HR department now reports the employee is returning and wants the account fully restored, including all group memberships and licence assignments. Which action should the Identity Administrator take?
   - A) Create a new account manually and re-add group memberships
   - B) Restore the soft-deleted user via the Entra portal or `Restore-MgDirectoryDeletedItem`
   - C) Use the Entra Connect Sync to re-synchronise the account from on-premises AD
   - D) Contact Microsoft Support to restore the hard-deleted account

   **Answer: B.** The account was deleted 15 days ago and is still within the 30-day soft-delete retention window. Restoring a soft-deleted user recovers all attributes, group memberships, and licence assignments. Option C would work for synced accounts only if the on-premises AD object also still exists, but the Entra portal restore is the direct and correct path.

7. A company wants to deploy Entra Cloud Sync instead of Entra Connect Sync. Which scenario would make Entra Cloud Sync the better choice?
   - A) The company requires attribute writeback for devices to on-premises AD
   - B) The company has three separate AD forests and needs a simple sync configuration with no writeback requirements
   - C) The company needs to sync Exchange hybrid attributes including mailbox settings
   - D) The company uses AD FS and wants to migrate to PTA

   **Answer: B.** Entra Cloud Sync is designed for simple multi-forest scenarios where its lighter footprint and cloud-managed updates are advantages. It does not support device writeback, Exchange hybrid attributes, or PTA — those scenarios require full Entra Connect Sync.

</details>

---

## Week 2 — External identities and Entra B2B
> **Exam domain:** Implement and manage user identities · **Weight:** 20–25%

> **Real-world scenario:** A Sogeti consultant is helping a financial services firm onboard three strategic partners who need access to a shared SharePoint site and a Teams workspace for project collaboration. The security team requires that partner users authenticate using their own corporate credentials, not a shared account, and that MFA claims from a trusted partner tenant are honoured to avoid double authentication challenges. Additionally, the CISO wants any user account flagged as high-risk by Identity Protection to be immediately blocked until remediated, without requiring manual admin intervention.

### Learning Objectives
- [ ] Invite and manage B2B guest users and understand the redemption flow
- [ ] Configure cross-tenant access settings (inbound and outbound trust policies)
- [ ] Understand the difference between B2B collaboration and B2B direct connect
- [ ] Enable and configure Entra ID Protection risk policies
- [ ] Differentiate between user risk and sign-in risk, and apply appropriate remediation
- [ ] Simulate risky sign-ins in a lab environment to validate policy enforcement

### MS Learn modules
- [Implement and manage external identities](https://learn.microsoft.com/en-us/training/modules/implement-manage-external-identities/)
- [Implement and manage Microsoft Entra ID Protection](https://learn.microsoft.com/en-us/training/modules/implement-manage-azure-ad-identity-protection/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **LAB-MGMT01** | Invite an external B2B user (use a personal or second tenant account) |
| **LAB-MGMT01** | Configure *Cross-tenant access settings*: block inbound access for specific tenants |
| **LAB-MGMT01** | Enable *Entra ID Protection* → review the *Risk detections* dashboard |
| **LAB-MGMT01** | Configure *User risk policy*: high risk → force password change |
| **LAB-MGMT01** | Configure *Sign-in risk policy*: medium risk → require MFA |
| **LAB-W11-01** | Simulate a risky sign-in: sign in as TestUser01 from an anonymous browser session |

### Lab commands

```powershell
# Invite a B2B guest user via Microsoft Graph PowerShell
New-MgInvitation -InvitedUserEmailAddress "partner@contoso.com" `
    -InviteRedirectUrl "https://myapps.microsoft.com" `
    -SendInvitationMessage:$true

# List all guest users in the tenant
Get-MgUser -Filter "userType eq 'Guest'" | Select-Object DisplayName, Mail, UserPrincipalName

# Dismiss a user risk (mark as false positive)
Invoke-MgDismissRiskyUser -UserIds "<user-object-id>"

# Confirm user compromise (triggers further protective actions)
Invoke-MgConfirmRiskyUserCompromised -UserIds "<user-object-id>"
```

### Key Concepts
| Term | Description |
|------|-------------|
| B2B Collaboration | External users are invited as guest accounts in your tenant; objects appear in your directory with `#EXT#` in the UPN |
| B2B Direct Connect | A mutual trust relationship between two tenants that allows access to specific resources (e.g., Teams shared channels) without creating guest objects in either directory |
| Cross-tenant synchronisation | Automatically provisions user objects from one Entra tenant into another as internal (non-guest) users, based on a synchronisation configuration |
| Redemption flow | The process by which an invited guest accepts the invitation, verifies their identity, and is granted access to the inviting tenant's resources |
| One-time passcode (OTP) | A fallback authentication method for guest users who have no Azure AD, Microsoft, or Google account — a temporary code is sent by email |
| Sign-in risk | The probability that a specific authentication attempt was not made by the legitimate user (e.g., sign-in from anonymous IP, atypical travel) |
| User risk | The cumulative probability that a user account has been compromised (e.g., leaked credentials detected on the dark web) |
| Dismiss risk | An admin action that marks a detected risk as a false positive and clears the risk state without taking further action |

### Knowledge check
1. What is the difference between *B2B direct connect* and *B2B collaboration*?
2. How does *Identity Protection* work — what signals does it use for risk scores?
3. What is a *risky user* versus a *risky sign-in*? How do you remediate each?
4. What does a *Conditional Access policy based on user risk* do?

<details>
<summary>Answers</summary>

1. **B2B Collaboration:** the external user receives a guest account in your tenant (an object is created in your directory). This supports the widest range of resource access scenarios. **B2B Direct Connect:** a mutual trust relationship between two Entra tenants that enables access to specific shared resources (currently Teams Connect shared channels) without creating guest objects in either tenant. No directory object is created; access is controlled via cross-tenant access policies.

2. Identity Protection continuously evaluates authentication signals against Microsoft's global threat intelligence. Risk signals include: anonymous IP address, atypical travel (impossible travel between two distant locations), unfamiliar sign-in properties, malware-linked IP, leaked credentials detected on the dark web, and password spray patterns. These signals feed machine learning models that assign a risk level (Low, Medium, High) to each sign-in and to user accounts over time.

3. A **risky user** is an account that Identity Protection has flagged as potentially compromised based on accumulated signals over time — for example, leaked credentials. Remediation: force a password change (which clears the user risk upon successful completion), or an admin can manually dismiss the risk if it is a false positive. A **risky sign-in** is a specific authentication attempt flagged as suspicious — for example, a sign-in from an anonymous IP. Remediation: require MFA for that session (satisfactory MFA can clear the sign-in risk), or an admin can confirm compromise or dismiss the risk.

4. A Conditional Access policy based on user risk evaluates the accumulated risk level of the user account at the time of sign-in. If the user risk meets or exceeds the configured threshold (e.g., High), the policy enforces a grant control — most commonly "Require password change" combined with MFA. A successful self-service password change clears the user risk state, allowing normal access to resume without further admin intervention.

**Scenario-based questions:**

5. A company uses B2B collaboration to grant partner consultants access to a SharePoint site. The security team notices that partner users are being prompted for MFA twice — once when signing in to their own tenant and again when accessing the company's resources. Which configuration eliminates the duplicate MFA prompt while maintaining security?
   - A) Disable MFA requirements for all guest users in the Conditional Access policy
   - B) Configure inbound cross-tenant access settings to trust MFA claims from the partner tenant
   - C) Enable B2B Direct Connect instead of B2B collaboration for the partner tenant
   - D) Assign the guest users a Temporary Access Pass for each session

   **Answer: B.** Inbound cross-tenant access settings allow you to trust MFA completions performed in the partner's tenant. When the partner user has already completed MFA against their own Entra ID, that MFA claim is honoured, preventing a second challenge. Options A and D reduce security; option C changes the access model entirely.

6. A user's account shows a High user risk in Identity Protection due to leaked credentials found on the dark web. The company has a Conditional Access policy that blocks High risk users. The user calls the helpdesk saying they cannot sign in. Which remediation step allows the user to regain access without admin manually resetting their risk?
   - A) Ask the user to wait 24 hours for the risk to automatically expire
   - B) The admin dismisses the risk in the Identity Protection portal
   - C) Temporarily exclude the user from all Conditional Access policies
   - D) The user performs a self-service password reset via SSPR, which clears the user risk upon completion

   **Answer: D.** When a Conditional Access policy uses "Require password change" as the grant control for high user risk, the user is guided through SSPR with strong MFA verification. A successfully completed secure password change automatically clears the user risk state. Option B (dismiss) is also valid if it is a false positive, but it does not require a password change and leaves credentials potentially compromised.

7. A company wants to allow users from Tenant A to access Teams shared channels in Tenant B without creating guest objects in Tenant B's directory. Which capability should the administrator configure?
   - A) B2B collaboration with automatic invitation redemption
   - B) Cross-tenant synchronisation from Tenant A to Tenant B
   - C) B2B Direct Connect with a mutual trust configuration between the two tenants
   - D) Entra Application Proxy with a connector in Tenant B

   **Answer: C.** B2B Direct Connect is specifically designed for Teams shared channels and creates no guest objects in either directory. It requires a mutual trust configuration (both tenants must configure inbound and outbound cross-tenant access settings). Cross-tenant synchronisation (B) would provision internal users, not enable shared channel access. B2B collaboration (A) creates guest objects.

</details>

---

## Week 3 — Authentication methods and MFA
> **Exam domain:** Implement authentication and access management · **Weight:** 25–30%

> **Real-world scenario:** A government agency client is requiring Sogeti to implement phishing-resistant MFA for all 2,500 employees as part of a Zero Trust compliance mandate. The helpdesk currently handles 40–50 password reset calls per week. The IAM consultant must design an authentication strategy that replaces SMS-based MFA with FIDO2 security keys for privileged users, deploys Microsoft Authenticator with passkeys for regular staff, and introduces a Temporary Access Pass process for new-joiner onboarding and lost-device recovery — all managed from a single policy location rather than the legacy per-user MFA portal.

### Learning Objectives
- [ ] Configure and manage authentication methods in the tenant-wide Authentication methods policy
- [ ] Understand and explain phishing-resistant MFA methods and their distinctions
- [ ] Enable and test passwordless authentication with FIDO2 and Microsoft Authenticator
- [ ] Configure Windows Hello for Business in a hybrid environment
- [ ] Issue and use a Temporary Access Pass (TAP) for onboarding and recovery scenarios
- [ ] Migrate from legacy per-user MFA settings to Conditional Access-managed MFA

### MS Learn modules
- [Plan and implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-multi-factor-authentication/)
- [Implement passwordless authentication](https://learn.microsoft.com/en-us/training/modules/implement-authentication-by-using-microsoft-entra-id/)
- [Manage user authentication](https://learn.microsoft.com/en-us/training/modules/manage-user-authentication/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **LAB-MGMT01** | Open **Entra → Security → Authentication methods** → enable FIDO2 and Authenticator |
| **LAB-W11-01** | Register *Microsoft Authenticator* as MFA method for TestUser01 |
| **LAB-W11-01** | Register *Windows Hello for Business* on W11-01 |
| **LAB-MGMT01** | Configure *Authentication strength* in Conditional Access: Phishing-resistant MFA |
| **LAB-MGMT01** | Review the *Authentication methods activity* report → analyse method usage |
| **LAB-MGMT01** | Disable *legacy per-user MFA* → migrate to Conditional Access-based MFA |

### Lab commands

```powershell
# Create a Temporary Access Pass for a user
New-MgUserAuthenticationTemporaryAccessPassMethod -UserId "<user-id>" `
    -LifetimeInMinutes 60 -IsUsableOnce:$true

# List registered authentication methods for a user
Get-MgUserAuthenticationMethod -UserId "<user-id>"

# Remove a specific authentication method (e.g., a lost FIDO2 key)
Remove-MgUserAuthenticationFido2Method -UserId "<user-id>" `
    -Fido2AuthenticationMethodId "<method-id>"

# Report on authentication method registrations across the tenant
Get-MgReportAuthenticationMethodUserRegistrationDetail |
    Select-Object UserPrincipalName, IsMfaRegistered, IsPasswordlessCapable
```

### Key Concepts
| Term | Description |
|------|-------------|
| FIDO2 security key | A hardware token (e.g., YubiKey) that performs cryptographic authentication — phishing-resistant because the key is bound to the specific origin domain |
| Microsoft Authenticator (passwordless) | Push notification or number-matching sign-in via the Authenticator app; phishing-resistant via number matching — no password is entered |
| Passkey | A FIDO2-based credential stored in the Microsoft Authenticator app or a compatible platform authenticator; combines the convenience of the app with hardware-level security |
| Temporary Access Pass (TAP) | A time-limited, one-time or multi-use passcode used for initial onboarding, MFA method re-registration, or account recovery when other methods are unavailable |
| Authentication strength | A Conditional Access grant control that requires users to authenticate with a specific set of methods (e.g., Phishing-resistant MFA); can be built-in or custom |
| Certificate-based authentication (CBA) | Uses an X.509 certificate stored on a smart card or device as the primary authentication factor; phishing-resistant |
| Entra Password Protection | Blocks weak and commonly used passwords via a global banned list plus a custom tenant-specific banned list; can be deployed on-premises via a DC agent |
| Combined security info registration | A unified registration experience where users set up both MFA methods and SSPR recovery methods in a single workflow |

### Knowledge check
1. What is *phishing-resistant MFA* and which methods qualify?
2. How does *Windows Hello for Business* work in a hybrid environment?
3. What is the difference between the *Authentication methods policy* and *legacy MFA settings*?
4. When do you use a *Temporary Access Pass (TAP)*?

<details>
<summary>Answers</summary>

1. Phishing-resistant MFA refers to authentication methods that cryptographically bind the authentication response to the specific origin (website or application), making it impossible for an attacker to intercept and replay credentials on a spoofed site. Qualifying methods are: **FIDO2 security keys** (hardware-bound), **Windows Hello for Business** (device-bound, backed by TPM), **Microsoft Authenticator with number matching** (the user must match a displayed number, preventing blind approval attacks), and **certificate-based authentication (CBA)** with smart cards.

2. In a hybrid environment, Windows Hello for Business (WHfB) provisions a key pair on the device's TPM during device registration (which requires Hybrid Azure AD Join or Entra Join). At sign-in, Windows uses the private key to sign a challenge from Entra ID. For on-premises resources, WHfB obtains a Kerberos ticket from the domain controller using **Entra Kerberos** (a partial credentials trust model), allowing SSO to on-premises apps without a password. This requires the Key Trust or Cloud Kerberos Trust deployment model.

3. The **Authentication methods policy** (Entra → Security → Authentication methods → Policies) is the modern, unified policy that controls which authentication methods (FIDO2, Authenticator, TAP, SMS, etc.) are available per group. It is the recommended approach. **Legacy per-user MFA settings** is the older Azure AD Multi-Factor Authentication portal where MFA was enabled or disabled per individual user. Microsoft is retiring the legacy portal; organisations should migrate to Conditional Access policies (using Authentication strength) and the Authentication methods policy.

4. A TAP is used in three main scenarios: **(1) Initial onboarding** — a new employee uses the TAP to sign in for the first time and register their preferred MFA methods. **(2) MFA method recovery** — a user has lost access to all their registered MFA methods (lost phone, broken FIDO2 key); the TAP provides a one-time way to sign in and re-register new methods. **(3) Bootstrapping a passwordless account** — when setting up a fully passwordless identity, a TAP is used as the temporary credential before permanent passwordless methods are registered.

**Scenario-based questions:**

5. A company's security team wants to ensure that users signing in to a highly sensitive finance application must use only phishing-resistant MFA. Regular MFA (SMS or standard Authenticator push) must not satisfy the requirement. Which Conditional Access configuration achieves this?
   - A) Create a CA policy targeting the finance app with grant control "Require multi-factor authentication"
   - B) Create a CA policy targeting the finance app with a custom Authentication strength that includes only FIDO2 and certificate-based authentication
   - C) Enable Entra ID Protection sign-in risk policy set to High for the finance app
   - D) Configure the finance app's Enterprise Application to require device compliance

   **Answer: B.** The built-in "MFA" grant control accepts any registered MFA method, including SMS. To restrict to phishing-resistant methods only, you must create a custom Authentication strength that explicitly includes only FIDO2, WHfB, CBA, or passkeys, and use that as the grant control in the CA policy.

6. A new employee joins a company that uses passwordless authentication. The employee has not yet registered any authentication methods. The IT admin must allow the employee to sign in on their first day and register a FIDO2 key. Which credential should the admin create for the employee?
   - A) A Temporary Access Pass (TAP) with `isUsableOnce: false` so the employee can sign in multiple times during the registration process
   - B) A standard temporary password that expires after 24 hours
   - C) An SSPR-generated email verification code
   - D) A guest account in a separate onboarding tenant

   **Answer: A.** A multi-use TAP is the correct onboarding credential for passwordless accounts. It allows the employee to sign in, navigate to `aka.ms/mysecurityinfo`, and register their FIDO2 key. A TAP with `isUsableOnce: false` and a suitable lifetime window (e.g., 4 hours) supports the registration workflow without being consumed on the first use.

7. An organisation is migrating from legacy per-user MFA to Conditional Access-managed MFA. During testing, some users report they are still being prompted for MFA even though the new CA policy is in report-only mode. What is most likely causing the additional MFA prompts?
   - A) The CA policy in report-only mode is still enforcing MFA in addition to logging
   - B) The users still have per-user MFA enabled in the legacy MFA portal, which operates independently of Conditional Access
   - C) The combined security info registration portal is triggering MFA registration prompts
   - D) The users have not yet registered a method in the Authentication methods policy

   **Answer: B.** Legacy per-user MFA runs independently of Conditional Access and continues to enforce MFA regardless of CA policy state. To fully migrate, both the new CA policy must be enabled AND per-user MFA must be disabled in the legacy MFA portal for those users. Report-only mode (A) logs but does not enforce.

</details>

---

## Week 4 — Conditional Access and Global Secure Access
> **Exam domain:** Implement authentication and access management · **Weight:** 25–30%

> **Real-world scenario:** A Sogeti team is engaged by a law firm with 350 users, strict data residency requirements, and a large remote workforce. The firm wants to ensure that no unmanaged or non-compliant device can access SharePoint and Teams, that access from outside the EU triggers step-up authentication, and that a senior partner approval is required every time an admin disables a Conditional Access policy. Additionally, the firm is evaluating replacing its legacy VPN with a zero-trust per-application access model so that remote staff can only reach the applications they need, not the full internal network.

### Learning Objectives
- [ ] Design and implement Conditional Access policies using the signals-decisions-enforcement model
- [ ] Use the What If tool to validate CA policy behaviour before enabling
- [ ] Configure Named Locations, Authentication contexts, and Protected actions
- [ ] Understand Continuous Access Evaluation (CAE) and its advantages over standard token lifetimes
- [ ] Explain the three Global Secure Access traffic profiles and their use cases
- [ ] Differentiate between Global Secure Access Private Access and a traditional VPN

### MS Learn modules
- [Plan, implement, and administer Conditional Access](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-conditional-access/)
- [Implement Conditional Access for cloud app access](https://learn.microsoft.com/en-us/training/modules/implement-conditional-access-cloud-app-protection/)
- [Implement Global Secure Access](https://learn.microsoft.com/en-us/training/modules/implement-global-secure-access/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **LAB-MGMT01** | Create CA policy: block access to all apps from non-compliant devices |
| **LAB-MGMT01** | Create CA policy: MFA required for admin roles on every sign-in |
| **LAB-MGMT01** | Use the *What If* tool in CA to simulate access decisions |
| **LAB-W11-01** | Test CA policy as TestUser01 → verify which controls are enforced |
| **LAB-W11-02** | Test with a non-enrolled device → verify block |
| **LAB-MGMT01** | Enable *Sign-in frequency* for sensitive applications (re-auth every 4 hours) |
| **LAB-MGMT01** | Review the **CA insights and reporting** workbook in Entra ID |
| **LAB-MGMT01** | In the Entra admin center, explore **Global Secure Access**: review Private Access and Internet Access settings |
| **LAB-MGMT01** | Enable *Internet Access for Microsoft 365* in Global Secure Access → review traffic logs |

### Lab commands

```powershell
# List all Conditional Access policies and their state
Get-MgIdentityConditionalAccessPolicy |
    Select-Object DisplayName, State, CreatedDateTime

# Retrieve sign-in logs filtered to CA policy failures (requires Log Analytics or MS Graph)
# Via Microsoft Graph PowerShell:
Get-MgAuditLogSignIn -Filter "conditionalAccessStatus eq 'failure'" -Top 20 |
    Select-Object UserPrincipalName, AppDisplayName, ConditionalAccessStatus

# Get all named locations
Get-MgIdentityConditionalAccessNamedLocation | Select-Object DisplayName, Id

# Enable or update a CA policy state (enabled/disabled/enabledForReportingButNotEnforced)
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId "<policy-id>" `
    -State "enabledForReportingButNotEnforced"
```

### Key Concepts
| Term | Description |
|------|-------------|
| CA Signals | The inputs evaluated by the policy engine: user/group/role, target application, network location, device platform and compliance state, client app type, sign-in risk, and user risk |
| Grant control | CA decision that either blocks access or grants it subject to conditions (MFA, compliant device, authentication strength, terms of use) |
| Session control | CA decision that allows access but restricts the session (sign-in frequency, persistent browser session, app-enforced restrictions, continuous access evaluation) |
| Named location | An IP range or country/region list marked as trusted or untrusted, used as a CA signal for location-based policies |
| Continuous Access Evaluation (CAE) | Tokens are revoked in near-real-time when a risk event occurs (e.g., admin revokes session, password change, location change), closing the gap left by standard token lifetimes (60–90 min) |
| Authentication context | A tag assigned to a CA policy and consumed by an application to trigger step-up authentication when a specific high-risk action is performed within the app |
| Protected actions | High-privilege Entra ID operations (e.g., disabling a CA policy, assigning a privileged role) that always require additional CA verification via an assigned authentication context |
| Global Secure Access (GSA) | Microsoft's Security Service Edge (SSE) solution, integrating Zero Trust Network Access (ZTNA) and a Secure Web Gateway into the Entra ID control plane |
| Private Access | The GSA ZTNA component — provides identity-aware, per-application access to on-premises and private resources without requiring a traditional VPN tunnel |
| Internet Access | The GSA Secure Web Gateway component — filters and secures internet-bound traffic from devices running the GSA client |
| Universal Conditional Access | CA policy enforcement at the network level via the GSA infrastructure, extending policy control beyond the authentication moment to the ongoing network session |

### Knowledge check
1. What is the difference between *Block* and *Grant with MFA* in Conditional Access?
2. How do *Named Locations* work and when do you use *compliant network*?
3. What are *Authentication contexts* and when do you use them?
4. How do you prevent *lock-out* during CA migration in production?
5. What is *Global Secure Access* and what are the three traffic profiles (Private, Internet, M365)?
6. What is the difference between *Private Access* and a traditional VPN?

<details>
<summary>Answers</summary>

1. **Block:** access is denied unconditionally when the policy conditions are met — the user cannot satisfy any requirement to gain entry. Used when access from a particular condition (e.g., high-risk user, specific geography) must never be permitted. **Grant with MFA:** access is permitted, but the user must satisfy the MFA requirement before the session is established. The user retains the ability to authenticate — they are not permanently denied, they are challenged. Choosing between the two depends on whether a path to compliant access exists: if the user can satisfy a condition, use Grant; if no condition is acceptable, use Block.

2. Named Locations define IP ranges or country/region sets that represent trusted or untrusted networks. They are used as CA conditions under **Locations**. *Compliant network* is a specific location condition tied to the Global Secure Access network — it allows you to require that access originates from a device running the GSA client, so traffic is routed through and validated by the GSA infrastructure. Use compliant network when you want to enforce that all access to sensitive resources occurs through the managed GSA tunnel rather than from arbitrary internet IP addresses.

3. Authentication contexts are labels (e.g., `C1`, `C2`) that you create in Entra ID and assign to a CA policy. Applications that support step-up authentication (such as SharePoint, or custom apps using the MSAL library) can request a specific authentication context when a user attempts a sensitive action within the app (e.g., viewing a confidential document or approving a financial transaction). Entra ID evaluates the CA policy bound to that context and may prompt the user for additional MFA or a stronger authentication method — without requiring a full re-sign-in.

4. Always begin CA migration in **Report-only mode**: the policy evaluates and logs decisions but does not enforce them. Review Sign-in logs and the CA Insights workbook to identify users who would be blocked before enabling enforcement. Maintain at least one **break-glass account** that is excluded from all CA policies and is not subject to PIM — this ensures emergency admin access if all policies are misconfigured. Test policies on a pilot group before rolling out to all users. Use the **What If** tool to simulate access decisions for specific user/app/location combinations.

5. Global Secure Access is Microsoft's Security Service Edge solution, integrating identity-aware network access control into the Entra ID platform. The three traffic profiles are: **(1) Microsoft 365 Access profile** — optimises and secures traffic to Microsoft 365 services (Exchange Online, SharePoint, Teams) via a dedicated GSA tunnel; includes Universal CA enforcement for M365. **(2) Private Access profile** — Zero Trust Network Access to on-premises and private cloud applications; replaces VPN for application-level access; policies are enforced per app. **(3) Internet Access profile** — routes general internet traffic through the GSA Secure Web Gateway, applying web content filtering and threat protection policies.

6. **Traditional VPN:** once connected, the user typically has broad network-level access to all resources on that network segment. There is no identity-aware, per-application policy enforcement during the session; the VPN connection is the only control boundary. **GSA Private Access (ZTNA):** access is granted per individual application or application group, not to the whole network. Every access request is evaluated against Conditional Access policies bound to the specific application — identity, device compliance, and risk signals are checked continuously via Universal CA. A compromised device or revoked session immediately terminates access. There is no lateral movement risk because the user never has network-level visibility beyond the explicitly permitted application endpoints.

**Scenario-based questions:**

7. A company enables a new Conditional Access policy in enforcement mode that requires device compliance for all cloud apps. The next morning, the IT administrator cannot sign in to the Entra portal from their personal laptop to fix the policy. What should the administrator have configured in advance to recover from this situation?
   - A) A Named Location for the admin's home IP address, excluded from the policy
   - B) A break-glass account that is excluded from all Conditional Access policies
   - C) The What If tool to pre-test the policy before enabling it
   - D) A Conditional Access policy in report-only mode running in parallel

   **Answer: B.** A break-glass (emergency access) account excluded from all CA policies is the standard safeguard for CA lock-out scenarios. Options A and C are good practices but do not solve the recovery problem once the policy is already locked. Option D would not help because the report-only policy does not interfere with enforcement.

8. A CA policy uses Continuous Access Evaluation (CAE). An admin revokes all active sessions for a user account at 14:00 because the account is suspected to be compromised. The user has an active access token that was issued at 13:30. What happens to the user's session?
   - A) The user's session continues until the access token expires at approximately 15:00–15:30
   - B) The user's session is terminated within seconds because CAE enables near-real-time token revocation
   - C) The user's session is terminated only after the user signs in again
   - D) The user receives an MFA prompt within the next hour to re-authenticate

   **Answer: B.** CAE enables near-real-time revocation of tokens by pushing a revocation event to the application. Applications that support CAE (including Microsoft 365 apps) receive the event and immediately invalidate the session, rather than waiting for the standard 60–90 minute token lifetime to expire.

9. A Global Secure Access administrator wants to ensure that users accessing a sensitive on-premises HR application must be connecting via the GSA client — not from arbitrary internet locations. Which CA condition should be configured?
   - A) Named Location restricted to the company's office IP ranges
   - B) Device compliance required
   - C) Compliant network location (Global Secure Access)
   - D) Sign-in risk below Medium

   **Answer: C.** The "Compliant network" location condition in CA verifies that the traffic originated via the Global Secure Access client and passed through the GSA infrastructure. Office IP ranges (A) would only cover on-site access and not remote employees using GSA. Device compliance (B) verifies device state but not network path.

</details>

---

## Week 5 — Application access and app registrations
> **Exam domain:** Plan and implement workload identities · **Weight:** 20–25%

> **Real-world scenario:** A Sogeti DevOps team is building an internal automation platform for a banking client. The platform uses an Azure Function to read emails from a shared mailbox via Microsoft Graph, write results to SharePoint, and call an internal REST API. The security team requires that the Azure Function never uses a stored password or client secret — only a managed identity — and that the internal API uses app-only permissions with explicit admin consent. A separate concern is that 12 third-party SaaS apps in the tenant have been granted overly broad API permissions by individual developers, and those need to be reviewed and tightened.

### Learning Objectives
- [ ] Distinguish between an App registration and an Enterprise application, and explain when each is used
- [ ] Configure API permissions (delegated and application) and understand the impact of admin consent
- [ ] Implement OAuth 2.0 and OpenID Connect flows for application authentication
- [ ] Create and manage client secrets and certificates for app authentication
- [ ] Configure Entra Application Proxy for secure access to on-premises web applications
- [ ] Understand managed identities (system-assigned vs. user-assigned) and when to use each

### MS Learn modules
- [Manage and implement application access in Azure AD](https://learn.microsoft.com/en-us/training/modules/manage-implement-application-access/)
- [Implement app registrations](https://learn.microsoft.com/en-us/training/modules/implement-app-registrations/)
- [Integrate single sign-on in Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/authenticate-external-apps/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **LAB-MGMT01** | Register a test app in **Entra → App registrations** |
| **LAB-MGMT01** | Add *API permissions*: `User.Read` and `Mail.Read` → grant admin consent |
| **LAB-MGMT01** | Create a *client secret* → note the value |
| **LAB-MGMT01** | Configure SSO for a gallery app (e.g. GitHub) via *Enterprise applications* |
| **LAB-MGMT01** | Configure *App proxy* for an on-premises app (use MGMT01 as test server) |
| **LAB-MGMT01** | Assign the app to a group → verify access in the *My Apps* portal |

### Lab commands

```powershell
# List all app registrations in the tenant
Get-MgApplication | Select-Object DisplayName, AppId, CreatedDateTime

# List API permissions for a specific app registration
Get-MgApplicationRequiredResourceAccess -ApplicationId "<app-object-id>"

# Create a new client secret for an app registration
Add-MgApplicationPassword -ApplicationId "<app-object-id>" `
    -PasswordCredential @{ DisplayName = "LabSecret"; EndDateTime = "2026-01-01" }

# List all enterprise applications (service principals) with app permissions
Get-MgServicePrincipal -Filter "servicePrincipalType eq 'Application'" |
    Select-Object DisplayName, AppId, AppRoles
```

### Key Concepts
| Term | Description |
|------|-------------|
| App registration | The developer-facing configuration object in Entra ID that defines the application's identity, OAuth/OIDC settings, redirect URIs, and API permissions |
| Enterprise application | The service principal instance of an application in your tenant — this is where you configure user/group assignments, SSO settings, and user provisioning (SCIM) |
| Delegated permission | The application acts on behalf of a signed-in user — the effective permissions are the intersection of the app's requested permissions and the user's own permissions |
| Application permission | The application acts as itself (as a background service or daemon) without a signed-in user — always requires admin consent; the app receives the full permissions granted |
| Managed identity | An Azure-native identity for Azure resources that is automatically managed by the platform — no credentials to store, rotate, or protect; eliminates secrets in code |
| System-assigned managed identity | Lifecycle is tied to the Azure resource — automatically deleted when the resource is deleted; one-to-one relationship |
| User-assigned managed identity | An independent identity object that can be assigned to multiple resources; lifecycle is managed separately from any individual resource |
| Entra Application Proxy | Publishes on-premises web applications securely via Entra ID using an outbound-only connector — no inbound firewall ports required |
| SCIM provisioning | Automated user and group provisioning to SaaS applications using the System for Cross-domain Identity Management open standard |

### Knowledge check
1. What is the difference between an *App registration* and an *Enterprise application*?
2. How does the OAuth 2.0 *authorization code flow* work in summary?
3. What is a *managed identity* and when do you use system-assigned versus user-assigned?
4. What does *application proxy* do and which ports does it require?

<details>
<summary>Answers</summary>

1. An **App registration** is the technical identity configuration created by the application developer. It defines the application's client ID, authentication settings, redirect URIs, and the Microsoft Graph API permissions the application requests. It is a global object in the Microsoft identity platform. An **Enterprise application** (also called a service principal) is the local instance of the app in a specific Entra tenant. It is created automatically when a user consents to an app or when an admin adds it to the tenant. This is where administrators control which users and groups can access the app, configure SSO, and set up automated provisioning. The distinction is: App registration = "what the app is"; Enterprise application = "how the app is deployed in this tenant."

2. The OAuth 2.0 authorisation code flow proceeds as follows: **(1)** The user visits the application and is redirected to the Entra ID authorisation endpoint with a `response_type=code` request. **(2)** The user authenticates and, if required, consents to the requested permissions. **(3)** Entra ID returns an authorisation code to the application's registered redirect URI. **(4)** The application's back-end exchanges the code for an access token and (optionally) a refresh token by calling the token endpoint with the client ID and client secret. **(5)** The access token is used to call the protected API (e.g., Microsoft Graph). The key security property is that the access token is never exposed to the browser — it is exchanged server-side.

3. A managed identity is an identity in Entra ID that is automatically provisioned and maintained by the Azure platform for use by Azure resources (VMs, App Services, Functions, etc.). There are no credentials to manage — Azure issues tokens on demand via the Instance Metadata Service endpoint. **System-assigned:** enabled directly on a single Azure resource; deleted automatically when the resource is deleted; ideal for resources that have a unique identity and should not share credentials. **User-assigned:** created as a standalone Entra ID object and assigned to one or more resources; survives deletion of individual resources; ideal when multiple resources need to share the same identity (e.g., a fleet of VMs all needing the same Key Vault access).

4. Entra Application Proxy enables secure remote access to on-premises web applications without opening inbound firewall ports or using a traditional VPN. A lightweight **connector agent** is installed on an on-premises Windows Server. The connector establishes a persistent outbound HTTPS connection (port 443) to the Application Proxy service in Azure. Remote users authenticate against Entra ID (with Conditional Access applied) and are proxied through this channel to the internal application. Required ports: **outbound TCP 443 and TCP 80** from the connector server to the internet — no inbound ports need to be opened on the corporate firewall.

**Scenario-based questions:**

5. A developer registers an Azure Function app in Entra ID to read all users' calendars via Microsoft Graph (`Calendars.Read`). The function runs as a background service with no signed-in user. Which permission type is required and what additional step must be completed before the app can call the API?
   - A) Delegated permission; the function must sign in as a service account and the user must consent
   - B) Application permission; an admin must grant admin consent for the `Calendars.Read` application permission
   - C) Delegated permission; admin consent is automatically granted for background services
   - D) Application permission; the function can call the API immediately after the app registration is created

   **Answer: B.** Background services without a signed-in user require Application permissions. Application permissions always require explicit admin consent — they are never auto-granted. Without admin consent, the token request will fail with an insufficient_scope error.

6. A company deploys 10 identical Azure VMs that all need to read secrets from the same Azure Key Vault. The security team wants a single identity that can be managed independently of any individual VM, so that if a VM is rebuilt, its access to Key Vault is not interrupted. Which managed identity type should be used?
   - A) System-assigned managed identity on each VM
   - B) User-assigned managed identity shared across all 10 VMs
   - C) A service principal with a client secret shared across all 10 VMs
   - D) A system-assigned managed identity on the Key Vault resource

   **Answer: B.** A user-assigned managed identity has an independent lifecycle and can be assigned to multiple resources simultaneously. All 10 VMs share the same identity and Key Vault access policy assignment. System-assigned (A) would require a separate Key Vault access policy entry per VM, and would be deleted if a VM is deleted, breaking access. Option C involves secrets that must be stored and rotated, which managed identities eliminate.

7. An organisation wants to publish an on-premises intranet portal to remote workers without opening any inbound firewall ports. Remote users must authenticate with their Entra ID credentials, and Conditional Access must be applied before they can reach the portal. Which solution should the administrator configure?
   - A) Site-to-site VPN between Azure and the on-premises network
   - B) Entra Application Proxy with a connector installed on an on-premises server
   - C) Global Secure Access Private Access with a ZTNA connector
   - D) Azure AD B2C for external authentication to the intranet portal

   **Answer: B.** Entra Application Proxy is specifically designed to publish on-premises web applications via an outbound-only connector, with Entra ID authentication (including CA) enforced at the perimeter. No inbound firewall ports are required. Option C (GSA Private Access) is an alternative for ZTNA, but Application Proxy is the canonical answer for this specific on-premises web app publishing scenario in the SC-300 exam context.

</details>

---

## Week 6 — Identity governance: Entitlement and Access Reviews
> **Exam domain:** Plan and automate identity governance · **Weight:** 20–25%

> **Real-world scenario:** A Sogeti consultant is designing an identity governance framework for a healthcare organisation with 3,000 employees and strict regulatory requirements (NEN 7510, ISO 27001). Doctors, nurses, and administrative staff require different access packages that expire automatically when a project ends. The compliance team has mandated quarterly access reviews for all privileged roles, and the HR system must automatically trigger account deactivation and access revocation within 24 hours of an employee's recorded departure date. PIM must be enabled for all Global Administrator roles, with a two-person approval workflow and MFA on every activation.

### Learning Objectives
- [ ] Create and manage entitlement management catalogs and access packages with approval workflows
- [ ] Configure access package lifecycle settings including expiration, renewal, and separation of duties
- [ ] Create and manage access reviews for groups, applications, and privileged roles
- [ ] Enable and configure Privileged Identity Management (PIM) for Entra ID roles
- [ ] Activate a PIM-eligible role Just-in-Time and review the audit trail
- [ ] Explain lifecycle workflows in Entra ID Governance and their use cases

### MS Learn modules
- [Plan and implement entitlement management](https://learn.microsoft.com/en-us/training/modules/plan-implement-entitlement-management/)
- [Plan, implement, and manage access reviews](https://learn.microsoft.com/en-us/training/modules/plan-implement-manage-access-review/)
- [Implement Privileged Identity Management](https://learn.microsoft.com/en-us/training/modules/implement-privileged-identity-management/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **LAB-MGMT01** | Create an *Access package* via **Entra → Identity Governance → Entitlement management** |
| **LAB-MGMT01** | Configure *policy*: users can self-request access, manager must approve |
| **LAB-W11-01** | Request the Access package as TestUser01 via the *My Access* portal (`myaccess.microsoft.com`) |
| **LAB-MGMT01** | Approve the request → verify the assignment |
| **LAB-MGMT01** | Create an *Access review* for a group → assign a reviewer |
| **LAB-MGMT01** | Enable **Privileged Identity Management (PIM)** for the *Global Administrator* role |
| **LAB-MGMT01** | Activate the GA role *Just-in-time* via PIM → verify audit trail |

### Lab commands

```powershell
# List all PIM eligible role assignments
Get-MgRoleManagementDirectoryRoleEligibilitySchedule |
    Select-Object PrincipalId, RoleDefinitionId, Status

# Retrieve PIM activation history (audit)
Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest |
    Select-Object PrincipalId, Action, Status, CreatedDateTime, Justification

# List all access packages in a catalog
Get-MgEntitlementManagementAccessPackage |
    Select-Object DisplayName, Id, CreatedDateTime

# Get pending access package assignment requests
Get-MgEntitlementManagementAssignmentRequest -Filter "state eq 'pendingApproval'" |
    Select-Object Id, RequestType, State
```

### Key Concepts
| Term | Description |
|------|-------------|
| Entitlement management | The Entra ID Governance framework for managing access lifecycle via catalogs, access packages, and automated approval and expiry workflows |
| Catalog | A container in entitlement management that groups related resources (Entra groups, applications, SharePoint sites) for a specific organisational unit or project |
| Access package | A bundle of resources (from a catalog) that users can request together through a single structured workflow, with defined approval, duration, and review requirements |
| Separation of duties | A configuration in entitlement management that prevents a user from holding two incompatible access packages simultaneously — enforces least privilege |
| PIM — Eligible assignment | The user has been granted the right to activate the role but must explicitly activate it, providing a justification and (if configured) completing MFA and approval |
| PIM — Active assignment | The role is permanently active for the user; no activation step is required — used sparingly for break-glass or service accounts |
| PIM — Just-in-time access | The practice of activating a privileged role only for the duration needed for a task, reducing the persistent attack surface of standing privileges |
| Lifecycle workflow | An automated Entra ID Governance workflow triggered by HR events (joiner, mover, leaver) that executes tasks such as generating TAPs, adding users to groups, or disabling accounts |
| Access review | A periodic, structured review in which designated reviewers confirm whether users should retain access to groups, applications, or privileged roles |

### Knowledge check
1. What is the difference between *entitlement management* and *access reviews*?
2. How does PIM *Just-in-Time access* work and why is it better than permanent role assignment?
3. What are *lifecycle workflows* in Identity Governance?
4. How do you configure *separation of duties* via incompatible access packages?

<details>
<summary>Answers</summary>

1. **Entitlement management** governs how users *request and are granted* access to resources. It provides a structured request-and-approval workflow, automated expiry and renewal, and a self-service portal (My Access). It manages the full access lifecycle from initial request to expiration. **Access reviews** address a different question: *should users who already have access retain it?* An access review is a periodic, formal review where designated reviewers (managers, resource owners, or the users themselves) confirm whether each user's access is still appropriate. The two features complement each other: entitlement management controls the granting process; access reviews enforce ongoing access hygiene.

2. PIM Just-in-Time access works by assigning users an **Eligible** role rather than an Active (permanent) role. An eligible user appears in Entra ID as not having the role until they explicitly activate it through PIM, providing a business justification, duration (up to the configured maximum), and completing any required approval and MFA steps. After the activation window expires, the role is automatically removed. **Advantages over permanent assignment:** (1) reduces the persistent attack surface — a compromised account without an active high-privilege role cannot immediately abuse admin capabilities; (2) every activation is logged with justification and approver, creating a full audit trail; (3) activation alerts can notify the security team; (4) the window for credential misuse is limited to the activation duration.

3. Lifecycle workflows are automated Entra ID Governance workflows that trigger based on user attribute changes typically driven by HR system integration (via SCIM or API). They address three HR events: **Joiner** (new employee starting — can auto-generate a TAP, send a welcome email, add the user to onboarding groups), **Mover** (employee changing role or department — can update group memberships, revoke old access packages), and **Leaver** (employee leaving — can disable the account, remove group memberships, revoke access packages, or trigger an access review). Lifecycle workflows replace manual IT processes with policy-driven automation, ensuring consistent execution and audit trails.

4. In entitlement management, navigate to an access package and open the **Policies** tab. Under the policy settings, find **Requestor information** or the separation of duties configuration and specify **Incompatible access packages** — the access packages that a user must not hold simultaneously with this one. When a user requests the access package, entitlement management checks whether they already hold any of the incompatible packages. If so, the request is automatically denied. This enforces four-eyes principles and regulatory compliance requirements (e.g., preventing the same person from both initiating and approving financial transactions).

**Scenario-based questions:**

5. A company's compliance team requires that the Global Administrator role is never permanently assigned to any user. All admins must activate the role for a maximum of 4 hours at a time, provide a business justification, and have their request approved by the Security team. Which PIM configuration implements this?
   - A) Assign all admins an Active assignment with a 4-hour session timeout in Conditional Access
   - B) Assign all admins an Eligible assignment with maximum activation duration of 4 hours, require approval, and configure the Security team as approvers
   - C) Assign all admins an Active assignment with an expiration date 90 days from now
   - D) Create an Access Package for the Global Administrator role with a 4-hour expiration

   **Answer: B.** PIM Eligible assignment is the correct approach. The activation settings on the role allow you to configure maximum duration, require justification, and require approval with designated approvers. Active assignments (A, C) do not require activation and cannot enforce per-session duration limits. Access packages (D) manage resource access, not directly privileged Entra ID roles.

6. A quarterly access review is configured for the "Finance Approvers" security group with auto-apply results enabled. A reviewer fails to respond to a review item within the review period. What happens to that user's access when the review closes?
   - A) The user's access is retained because a reviewer must explicitly remove access for it to take effect
   - B) The user's access is removed automatically because auto-apply is enabled and the default behaviour for non-response is to remove access
   - C) The review item is escalated to the reviewer's manager for a secondary decision
   - D) The access review is extended for an additional 7 days to allow the reviewer to respond

   **Answer: B.** When a reviewer does not respond and auto-apply results is enabled, the system applies the configured "If reviewers don't respond" setting. The recommended and most common default is to remove access for unreviewed users, ensuring that stale access is cleaned up even without explicit reviewer action. The exact behaviour depends on the review configuration, but B reflects the designed compliance posture.

7. An organisation wants to automate the deactivation of user accounts within 24 hours of an employee's last working day, as recorded in the HR system (via the `employeeLeaveDateTime` attribute in Entra ID). Which feature should the Identity Administrator configure?
   - A) An access review triggered manually by the HR department each time an employee leaves
   - B) A Conditional Access policy that blocks sign-in after the leave date
   - C) A Lifecycle workflow with a Leaver trigger based on the `employeeLeaveDateTime` attribute, configured to disable the account and remove group memberships
   - D) An Entra Connect Sync rule that deletes the AD account when the HR attribute is set

   **Answer: C.** Lifecycle workflows are purpose-built for joiner/mover/leaver automation. A Leaver workflow triggered by `employeeLeaveDateTime` (with a pre-configured offset, e.g., "on the day of") can disable the account, remove licences and group memberships, and revoke access packages — all automatically and with a full audit trail. Manual reviews (A) cannot guarantee the 24-hour SLA. CA policies (B) block sign-in but do not perform cleanup tasks.

</details>

---

## Week 7 — Exam preparation

### Activities
- Review weak domains based on the [official exam study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-300)
- Complete the **Microsoft Learn practice assessment** for SC-300: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Revisit PIM configuration, CA What-If scenarios and entitlement management
- Create an overview of all Identity Protection risk types and remediation steps
- Schedule your exam via Pearson VUE

### Exam focus areas
- **Domain weights changed:** user identities 20–25%, workload identities 20–25%, governance 20–25%
- **Global Secure Access** is a new exam section — know Private Access, Internet Access and M365 profiles
- Azure RBAC for resources ("Implement access management for Azure resources") was **removed** from SC-300 scope
- Conditional Access: *What If* scenarios, authentication strength, continuous access evaluation and protected actions
- PIM: know the difference between eligible, active and permanent assignments
- Identity governance: entitlement management vs. access reviews vs. lifecycle workflows
- B2B: cross-tenant access settings, cross-tenant synchronisation and external collaboration settings
- App registrations: delegated vs. application API permissions; managed identities (system vs. user-assigned)
- Identity monitoring: KQL queries in Log Analytics, Identity Secure Score

---

## Exam Coverage Gaps and Must-Do Labs

The SSW-Lab 7-week programme covers all four SC-300 exam domains. The following topics receive lighter treatment in the lab exercises but carry significant exam weight based on the November 2025 study guide. Prioritise these before scheduling the exam.

### Coverage gaps to address

| Gap | Why it matters | Recommended action |
|-----|---------------|-------------------|
| **Global Secure Access — client deployment** | GSA is a new exam section (Nov 2025). The lab exercises cover portal exploration and traffic profile configuration, but do not include client installation and end-to-end testing. | Complete the [MS Learn GSA module](https://learn.microsoft.com/en-us/training/modules/deploy-configure-microsoft-entra-global-secure-access/). In a personal Azure/M365 tenant, install the GSA Windows client, enable the M365 profile, and review traffic logs. |
| **Cross-tenant synchronisation** | The exam tests cross-tenant sync as a distinct capability from B2B invitations. The lab exercises cover B2B collaboration and cross-tenant access settings but not automated cross-tenant provisioning. | Configure cross-tenant synchronisation between two test tenants (use a developer tenant as the target). Verify that a source user appears as an internal user (not a guest) in the target tenant. |
| **Identity monitoring: KQL and Log Analytics** | Monitoring and diagnostics are examined in Domain 4. Writing basic KQL queries against `SigninLogs` and `AuditLogs` is a practical exam skill. | Connect Entra ID diagnostic settings to a Log Analytics workspace. Practice the following queries: high-risk sign-ins, failed MFA attempts, CA policy failures, PIM activations, and role assignment changes. |
| **Lifecycle workflows (joiner/mover/leaver)** | Lifecycle workflows are explicitly listed in the Nov 2025 governance domain. They are not covered in the lab exercises. | In the Entra portal, create a joiner workflow that generates a TAP and sends a welcome email. Trigger it manually against a test user. |
| **Workload identity risk (Defender for Cloud Apps)** | Workload identity risk management and Defender for Cloud Apps integration appear in Domain 3. | Review the Defender for Cloud Apps app governance section. Understand how OAuth app policies detect risky workload identities and how to revoke app consent. |
| **Entra Password Protection on-premises** | On-premises Password Protection deployment (DC agent) is a hybrid identity topic that may appear in authentication questions. | Review the DC agent installation concept and understand that it intercepts password change requests via the Netlogon service, checking against the global and custom banned lists. |

### Must-do labs for exam readiness

1. **Global Secure Access end-to-end:** enable the M365 traffic forwarding profile, install the GSA client on a test device, authenticate, and verify that session traffic appears in GSA traffic logs. Understand what Universal Conditional Access means in this context.
2. **Cross-tenant synchronisation:** configure synchronisation from one Entra tenant to another. Validate that the provisioned user appears as a member user (not a guest), and test what happens when the source user is deactivated.
3. **App registration with both permission types:** create an app registration with `User.Read` (delegated) and `Mail.ReadBasic.All` (application) permissions. Grant admin consent. Explain the difference in effective permissions and why application permissions always require admin consent.
4. **KQL identity queries:** write and run at least three queries in Log Analytics — one against `SigninLogs` (e.g., high-risk sign-ins last 7 days), one against `AuditLogs` (e.g., role assignments), and one for CA policy failures. Be able to interpret the output.
5. **PIM full cycle:** assign a user an eligible Global Administrator role with approval required and MFA on activation. Activate the role as that user, complete the approval flow, verify the audit trail, and confirm the role expires automatically.

### Exit criteria before booking the exam

1. You can map every SC-300 exam domain to a concrete lab exercise or practical scenario from your own environment.
2. You have tested CA, Identity Protection, workload identity, Global Secure Access, and governance capabilities in a live tenant — not just read about them.
3. You can analyse a sign-in risk incident using Log Analytics KQL rather than relying solely on portal clicks.
4. You understand why Azure RBAC for resources is out of scope and can articulate what remains in scope for workload identities.
5. You have completed the [MS Learn practice assessment](https://learn.microsoft.com/en-us/credentials/certifications/exams/sc-300/practice/assessment?assessment-type=practice&assessmentId=60) and scored consistently above 80%.
