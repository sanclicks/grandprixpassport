# 🔐 GrandPrixPassport — Governance & Access Control

## Core Principle: Sandeep = Sole Human Operator

Every business function is handled by an AI agent.
Sandeep reviews outputs, approves decisions, and controls all access.

---

## AWS Access Hierarchy

```
Root Account (Sandeep only — MFA required)
    ↓
Management Account (Control Tower)
    ├── Audit Account (CloudTrail, Config)
    ├── Log Archive Account (Centralized logs)
    ├── Dev Account (Development environment)
    ├── Staging Account (QA/testing)
    └── Prod Account (Live users — restricted access)
```

### IAM Roles (Least Privilege)

| Role | Access | Used By |
|---|---|---|
| `gpp-admin` | Full access | Sandeep only |
| `gpp-dev` | Dev account only | Development work |
| `gpp-lambda-execution` | S3, DynamoDB, SES, Secrets | Lambda functions |
| `gpp-deploy` | CodePipeline, Lambda deploy | CI/CD pipeline |
| `gpp-readonly` | Read-only all services | Analytics and monitoring |

### Service Control Policies (SCPs)

Applied at Organization level:
- Block creation of resources outside us-east-1 and us-west-2
- Require MFA for all IAM operations
- Block disabling CloudTrail
- Require encryption on all S3 buckets
- Block public S3 buckets (except CloudFront origin)

---

## Credentials Management

### Stored in AWS Secrets Manager (NEVER in code):
```
/grandprixpassport/prod/claude/api-key
/grandprixpassport/prod/stripe/secret-key
/grandprixpassport/prod/stubhub/client-secret
/grandprixpassport/prod/vivid-seats/api-key
/grandprixpassport/prod/google-maps/api-key
/grandprixpassport/prod/openf1/api-key
/grandprixpassport/prod/sendgrid/api-key
```

### Sandeep's Personal Credentials:
- AWS root MFA: Hardware MFA key (never lose this)
- AWS SSO: Managed through IAM Identity Center
- Stripe: Personal account tied to LLC
- Affiliate accounts: Personal accounts tied to LLC
- GitHub: Personal account, repo is private

---

## AI Agent Oversight Rules

### Week 1–8 (Strict Review)
- ❌ No agent publishes anything without Sandeep review
- ❌ No agent spends any money without approval
- ❌ No agent modifies production infrastructure

### Week 9+ (Graduated Autonomy)
- ✅ Marketing Agent: Auto-post social media (pre-approved templates)
- ✅ Support Agent: Answer standard questions (within guardrails)
- ✅ Data Agent: Auto-run price checks and send alerts
- ❌ Still requires approval: Content publishing, code deploys, spending

### Always Requires Sandeep:
- Production deployments
- New affiliate/partner agreements
- Pricing changes
- Legal decisions
- Any spend over $100
- Database schema changes

---

## Financial Controls

| Account | Purpose | Access |
|---|---|---|
| Mercury Business Checking | Operating account | Sandeep + LLC |
| Stripe | Subscription payments | LLC only |
| AWS Billing | Infrastructure costs | Sandeep only |
| Affiliate payouts | Commission income | LLC bank account |

### Budget Alerts (AWS Budgets)
- $50/month — Email alert
- $100/month — Email + SMS alert
- $200/month — Email + SMS + automatic review

---

## Sandeep's Weekly Workflow (90 mins/week)

### Monday (30 mins)
- [ ] Review Analytics Agent weekly report
- [ ] Approve content queue for the week
- [ ] Check AWS cost dashboard

### Wednesday (20 mins)
- [ ] Review Product Manager Agent backlog
- [ ] Approve any pending decisions

### Friday (20 mins)
- [ ] Review Support Agent escalations
- [ ] Review Marketing Agent performance
- [ ] Approve any production deploys

### As Needed
- [ ] Review new affiliate applications
- [ ] Approve major product decisions
- [ ] Handle legal/compliance matters

---

## Incident Response

### If something breaks in production:
1. CloudWatch alarm triggers → Email to Sandeep
2. Sandeep reviews CloudWatch logs
3. If critical: Rollback via CodePipeline
4. DevOps Agent assists with diagnosis
5. Fix in dev → Test in staging → Deploy to prod

### Emergency contacts:
- AWS Support: via console (account level plan)
- Stripe Support: dashboard.stripe.com/support
- Domain Registrar: [registrar support URL]

---

## Privacy Protection

### What NOT to share with AI tools:
- Proprietary pricing algorithms
- Database schema details
- API integration specifics
- User data or analytics
- Revenue figures (until incorporated into pitch)

### Claude.ai Settings:
- Training opt-out: ✅ Disabled (Settings → Privacy → Help Improve Claude → OFF)
- Use Claude API (not claude.ai) for sensitive business logic

---

*Last updated: May 2026*
*Owner: Sandeep Pulim — GrandPrixPassport LLC*
