# Amplify GenAI Deployment Setup Guide

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** installed (v1.0+)
4. **Route53 Hosted Zone** for your domain
5. **SSL Certificate** in AWS Certificate Manager (ACM) for your domain

## Quick Start

### Step 1: Configure Your Deployment

1. Copy the template file:
   \`\`\`bash
   cp terraform.tfvars.template terraform.tfvars
   \`\`\`

2. Edit \`terraform.tfvars\` and replace the following placeholders:

   **Required Values:**
   - \`domain_name\`: Your application domain (e.g., \`app.example.com\`)
   - \`app_route53_zone_id\`: Your Route53 hosted zone ID
   - \`cognito_domain\`: Your Cognito domain (e.g., \`auth.example.com\`)
   - \`cognito_route53_zone_id\`: Same as app_route53_zone_id
   - \`ecs_alarm_email\`: Your email for notifications

   **Optional Values:**
   - Network CIDRs (if you want different ranges)
   - Resource names (if you want custom naming)
   - Scaling parameters (adjust based on your needs)

### Step 2: Find Your Route53 Hosted Zone ID

\`\`\`bash
aws route53 list-hosted-zones --query "HostedZones[?Name=='example.com.'].Id" --output text
\`\`\`

Replace \`example.com\` with your domain.

### Step 3: Verify Your SSL Certificate

\`\`\`bash
aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='*.example.com'].CertificateArn" --output text
\`\`\`

### Step 4: Initialize and Deploy

1. Initialize Terraform:
   \`\`\`bash
   terraform init
   \`\`\`

2. Review the deployment plan:
   \`\`\`bash
   terraform plan
   \`\`\`

3. Deploy the infrastructure:
   \`\`\`bash
   terraform apply
   \`\`\`

### Step 5: Export Outputs

After deployment, export the Terraform outputs:

\`\`\`bash
terraform output -json > terraform-outputs.json
\`\`\`

These outputs will be used by the backend configuration generator.

## Configuration Details

### Network Configuration

- **VPC CIDR**: Default is \`10.0.0.0/16\`
- **Public Subnets**: For ALB and NAT Gateways
- **Private Subnets**: For ECS tasks

### Domain Configuration

- **Application Domain**: Where your app will be accessible
- **Cognito Domain**: For authentication endpoints
- Both domains must be in the same Route53 hosted zone

### ECS Configuration

- **CPU**: 1024 (1 vCPU) - adjust based on load
- **Memory**: 4096 MB (4 GB) - adjust based on load
- **Auto-scaling**: Configured for 1-5 tasks based on CPU

## Security Notes

1. **Never commit \`terraform.tfvars\`** to version control
2. The template file (\`terraform.tfvars.template\`) is safe to commit
3. Secrets will be stored in AWS Secrets Manager
4. API keys should be added after deployment

## Troubleshooting

### Common Issues

1. **Route53 Zone Not Found**
   - Verify the zone ID is correct
   - Ensure the zone exists in your AWS account

2. **Certificate Validation Failed**
   - Ensure you have a wildcard certificate for your domain
   - Certificate must be in the same region (us-east-1)

3. **VPC CIDR Conflicts**
   - Choose a CIDR range that doesn't conflict with existing VPCs
   - Ensure subnet CIDRs are within the VPC CIDR range

## Next Steps

After infrastructure deployment:

1. Deploy the backend services (Lambda functions)
2. Update environment variables with backend endpoints
3. Deploy the frontend application
4. Configure API keys in Secrets Manager

## Support

For issues or questions:
- Check the Terraform output for error messages
- Review AWS CloudWatch logs
- Verify all prerequisites are met
