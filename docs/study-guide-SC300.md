# Study Guide SC-300 — Identity and Access Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-SC300.md)

**Duration:** 7 weeks · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)  
**MS Learn path:** [Identity and Access Administrator](https://learn.microsoft.com/en-us/certifications/exams/sc-300/)  
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

---

## Week 1 — Entra ID fundamentals and hybrid identity

### MS Learn modules
- [Implement initial configuration of Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/implement-initial-configuration-azure-active-directory/)
- [Create, configure, and manage identities](https://learn.microsoft.com/en-us/training/modules/create-configure-manage-identities/)
- [Implement and manage hybrid identity](https://learn.microsoft.com/en-us/training/modules/implement-manage-hybrid-identity/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-DC01** | Verify AD structure: `Get-ADForest`, `Get-ADDomain`, `Get-ADUser -Filter *` |
| **SSW-DC01** | Install Azure AD Connect Sync → configure *Password Hash Sync* |
| **SSW-DC01** | Verify sync: `Start-ADSyncSyncCycle -PolicyType Delta` |
| **SSW-MGMT01** | Open **Entra admin center** (entra.microsoft.com) → verify sync status |
| **SSW-MGMT01** | Configure *Custom Security Attributes* for user classification |
| **SSW-MGMT01** | Review *Audit logs* in Entra ID → filter on user creation events |

### Knowledge check
1. What are the three authentication methods in hybrid identity and when do you use each?
2. How does *Seamless SSO* work and which Kerberos component is involved?
3. What is the difference between *soft delete* and *hard delete* of an Entra ID user?
4. How do you configure *password writeback* and why is it needed for SSPR?

---

## Week 2 — External identities and Entra B2B

### MS Learn modules
- [Implement and manage external identities](https://learn.microsoft.com/en-us/training/modules/implement-manage-external-identities/)
- [Implement and manage Microsoft Entra ID Protection](https://learn.microsoft.com/en-us/training/modules/implement-manage-azure-ad-identity-protection/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Invite an external B2B user (use a personal or second tenant account) |
| **SSW-MGMT01** | Configure *Cross-tenant access settings*: block inbound access for specific tenants |
| **SSW-MGMT01** | Enable *Entra ID Protection* → review the *Risk detections* dashboard |
| **SSW-MGMT01** | Configure *User risk policy*: high risk → force password change |
| **SSW-MGMT01** | Configure *Sign-in risk policy*: medium risk → require MFA |
| **SSW-W11-01** | Simulate a risky sign-in: sign in as TestUser01 from an anonymous browser session |

### Knowledge check
1. What is the difference between *B2B direct connect* and *B2B collaboration*?
2. How does *Identity Protection* work — what signals does it use for risk scores?
3. What is a *risky user* versus a *risky sign-in*? How do you remediate each?
4. What does a *Conditional Access policy based on user risk* do?

---

## Week 3 — Authentication methods and MFA

### MS Learn modules
- [Plan and implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-multi-factor-authentication/)
- [Implement passwordless authentication](https://learn.microsoft.com/en-us/training/modules/implement-authentication-by-using-microsoft-entra-id/)
- [Manage user authentication](https://learn.microsoft.com/en-us/training/modules/manage-user-authentication/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Open **Entra → Security → Authentication methods** → enable FIDO2 and Authenticator |
| **SSW-W11-01** | Register *Microsoft Authenticator* as MFA method for TestUser01 |
| **SSW-W11-01** | Register *Windows Hello for Business* on W11-01 |
| **SSW-MGMT01** | Configure *Authentication strength* in Conditional Access: Phishing-resistant MFA |
| **SSW-MGMT01** | Review the *Authentication methods activity* report → analyse method usage |
| **SSW-MGMT01** | Disable *legacy per-user MFA* → migrate to Conditional Access-based MFA |

### Knowledge check
1. What is *phishing-resistant MFA* and which methods qualify?
2. How does *Windows Hello for Business* work in a hybrid environment?
3. What is the difference between the *Authentication methods policy* and *legacy MFA settings*?
4. When do you use a *Temporary Access Pass (TAP)*?

---

## Week 4 — Conditional Access and Global Secure Access

### MS Learn modules
- [Plan, implement, and administer Conditional Access](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-conditional-access/)
- [Implement Conditional Access for cloud app access](https://learn.microsoft.com/en-us/training/modules/implement-conditional-access-cloud-app-protection/)
- [Implement Global Secure Access](https://learn.microsoft.com/en-us/training/modules/implement-global-secure-access/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Create CA policy: block access to all apps from non-compliant devices |
| **SSW-MGMT01** | Create CA policy: MFA required for admin roles on every sign-in |
| **SSW-MGMT01** | Use the *What If* tool in CA to simulate access decisions |
| **SSW-W11-01** | Test CA policy as TestUser01 → verify which controls are enforced |
| **SSW-W11-02** | Test with a non-enrolled device → verify block |
| **SSW-MGMT01** | Enable *Sign-in frequency* for sensitive applications (re-auth every 4 hours) |
| **SSW-MGMT01** | Review the **CA insights and reporting** workbook in Entra ID |
| **SSW-MGMT01** | In the Entra admin center, explore **Global Secure Access**: review Private Access and Internet Access settings |
| **SSW-MGMT01** | Enable *Internet Access for Microsoft 365* in Global Secure Access → review traffic logs |

### Knowledge check
1. What is the difference between *Block* and *Grant with MFA* in Conditional Access?
2. How do *Named Locations* work and when do you use *compliant network*?
3. What are *Authentication contexts* and when do you use them?
4. How do you prevent *lock-out* during CA migration in production?
5. What is *Global Secure Access* and what are the three traffic profiles (Private, Internet, M365)?
6. What is the difference between *Private Access* and a traditional VPN?

---

## Week 5 — Application access and app registrations

### MS Learn modules
- [Manage and implement application access in Azure AD](https://learn.microsoft.com/en-us/training/modules/manage-implement-application-access/)
- [Implement app registrations](https://learn.microsoft.com/en-us/training/modules/implement-app-registrations/)
- [Integrate single sign-on in Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/authenticate-external-apps/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Register a test app in **Entra → App registrations** |
| **SSW-MGMT01** | Add *API permissions*: `User.Read` and `Mail.Read` → grant admin consent |
| **SSW-MGMT01** | Create a *client secret* → note the value |
| **SSW-MGMT01** | Configure SSO for a gallery app (e.g. GitHub) via *Enterprise applications* |
| **SSW-MGMT01** | Configure *App proxy* for an on-premises app (use MGMT01 as test server) |
| **SSW-MGMT01** | Assign the app to a group → verify access in the *My Apps* portal |

### Knowledge check
1. What is the difference between an *App registration* and an *Enterprise application*?
2. How does the OAuth 2.0 *authorization code flow* work in summary?
3. What is a *managed identity* and when do you use system-assigned versus user-assigned?
4. What does *application proxy* do and which ports does it require?

---

## Week 6 — Identity governance: Entitlement and Access Reviews

### MS Learn modules
- [Plan and implement entitlement management](https://learn.microsoft.com/en-us/training/modules/plan-implement-entitlement-management/)
- [Plan, implement, and manage access reviews](https://learn.microsoft.com/en-us/training/modules/plan-implement-manage-access-review/)
- [Implement Privileged Identity Management](https://learn.microsoft.com/en-us/training/modules/implement-privileged-identity-management/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Create an *Access package* via **Entra → Identity Governance → Entitlement management** |
| **SSW-MGMT01** | Configure *policy*: users can self-request access, manager must approve |
| **SSW-W11-01** | Request the Access package as TestUser01 via the *My Access* portal (`myaccess.microsoft.com`) |
| **SSW-MGMT01** | Approve the request → verify the assignment |
| **SSW-MGMT01** | Create an *Access review* for a group → assign a reviewer |
| **SSW-MGMT01** | Enable **Privileged Identity Management (PIM)** for the *Global Administrator* role |
| **SSW-MGMT01** | Activate the GA role *Just-in-time* via PIM → verify audit trail |

### Knowledge check
1. What is the difference between *entitlement management* and *access reviews*?
2. How does PIM *Just-in-Time access* work and why is it better than permanent role assignment?
3. What are *lifecycle workflows* in Identity Governance?
4. How do you configure *separation of duties* via incompatible access packages?

---

## Week 7 — Exam preparation

### Activities
- Review weak domains based on the [official exam profile](https://learn.microsoft.com/en-us/certifications/exams/sc-300/)
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
