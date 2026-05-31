# ⚙️ GrandPrixPassport — Tech Stack & Setup Guide

## Stack Overview

| Layer | Technology | Why |
|---|---|---|
| Frontend | Next.js 14 + TypeScript + Tailwind CSS | SSR for SEO, fast load |
| Mobile | React Native + Expo | Share code with web |
| Backend | AWS Lambda + API Gateway | Serverless, zero idle cost |
| Database | DynamoDB + Aurora Serverless | Scale to zero |
| Cache | ElastiCache Redis | Fast ticket price lookups |
| Search | OpenSearch | Fast circuit + hotel search |
| Auth | AWS Cognito + Social OAuth | Google/Apple sign-in built in |
| AI Engine | Claude API (Sonnet) | Trip planning, support, content |
| Email | AWS SES + Mailchimp | Transactional + marketing |
| Storage | S3 + CloudFront CDN | Photos, static assets |
| IaC | Terraform | Existing expertise |
| CI/CD | GitHub Actions + CodePipeline | Automated deploy |
| Monitoring | CloudWatch + X-Ray | Full observability |
| Payments | Stripe | Subscriptions + PCI |
| Analytics | PostHog + QuickSight | Product + business |
| Notifications | SNS + Firebase FCM | Price alerts + push |

---

## AI Development Tools

| Tool | Use | Cost | Privacy |
|---|---|---|---|
| Cursor | Primary code editor with AI | $20/mo | Enable Privacy Mode |
| Claude API | Backend AI features | Pay per use | API = no training |
| v0.dev | UI component generation | Free tier | Review terms |
| GitHub Copilot | Code suggestions | $10/mo | Private repos only |
| Perplexity | Research and fact-checking | $20/mo | Don't share secrets |

---

## Development Environment Setup

### Prerequisites
```bash
# Node.js 20+
node --version

# AWS CLI configured
aws configure

# Terraform installed
terraform --version

# Git configured
git config --global user.name "Sandeep Pulim"
git config --global user.email "your@email.com"
```

### AWS CLI Profile Setup
```bash
# Configure AWS SSO for Control Tower
aws configure sso
# Profile name: grandprixpassport-dev
# Profile name: grandprixpassport-prod

# Use specific profile
export AWS_PROFILE=grandprixpassport-dev
```

### Environment Variables
```bash
# Never commit these — stored in AWS Secrets Manager
# For local dev, use .env.local (in .gitignore)

CLAUDE_API_KEY=xxx
OPENF1_API_KEY=xxx
STUBHUB_CLIENT_ID=xxx
STUBHUB_CLIENT_SECRET=xxx
GOOGLE_MAPS_API_KEY=xxx
STRIPE_SECRET_KEY=xxx
```

---

## Frontend Setup (Next.js)

```bash
cd frontend
npx create-next-app@latest . --typescript --tailwind --app
npm install @anthropic-ai/sdk aws-amplify @tanstack/react-query
npm run dev
# → http://localhost:3000
```

### Key Dependencies
```json
{
  "dependencies": {
    "next": "14.x",
    "@anthropic-ai/sdk": "latest",
    "@tanstack/react-query": "^5.0",
    "aws-amplify": "^6.0",
    "tailwindcss": "^3.4",
    "typescript": "^5.0",
    "recharts": "^2.0",
    "mapbox-gl": "^3.0",
    "zustand": "^4.0"
  }
}
```

---

## Backend Setup (Lambda)

```bash
cd backend
npm init -y
npm install @aws-sdk/client-dynamodb @anthropic-ai/sdk axios
npm install --save-dev typescript @types/node aws-lambda esbuild
```

### Lambda Function Template
```typescript
// src/functions/tickets/handler.ts
import { APIGatewayProxyHandler } from 'aws-lambda';

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    // Function logic here
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ success: true })
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};
```

---

## Terraform Setup

```bash
cd infrastructure/terraform
terraform init
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform plan -var-file="environments/dev.tfvars"
```

---

## CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
      - name: Deploy infrastructure
        run: cd infrastructure/terraform && terraform apply -auto-approve
      - name: Deploy backend
        run: cd backend && npm run deploy
      - name: Deploy frontend
        run: cd frontend && npm run build && npm run deploy
```

---

## Security Checklist

- [ ] Enable MFA on root AWS account
- [ ] Enable MFA on all IAM users
- [ ] Enable CloudTrail in all regions
- [ ] Set up AWS Config rules
- [ ] Enable GuardDuty
- [ ] Enable Security Hub
- [ ] Configure budget alerts
- [ ] Enable S3 bucket versioning
- [ ] Enable RDS automated backups
- [ ] Set up WAF rules for API Gateway

---

*Last updated: May 2026*
