# AWS Production Deployment Checklist

## Pre-Deployment Checklist

### AWS Account Setup
- [ ] AWS Account created and verified
- [ ] IAM user created with admin access
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] AWS credentials tested (`aws sts get-caller-identity`)
- [ ] Billing alerts configured

### Amazon Bedrock Setup
- [ ] Bedrock service available in your region (us-east-1, us-west-2, etc.)
- [ ] Model access requested for Claude 3 Haiku
- [ ] Use case details submitted (if required)
- [ ] Model access approved (check in Bedrock console)
- [ ] Test Bedrock access: `aws bedrock list-foundation-models --region us-east-1`

### Development Environment
- [ ] Python 3.11+ installed
- [ ] pip package manager installed
- [ ] PowerShell 7+ (Windows) or Bash (Linux/Mac) available
- [ ] Git installed (optional, for version control)

### Project Files Ready
- [ ] `lambda_function.py` reviewed
- [ ] `cloudformation-template.yaml` reviewed
- [ ] `requirements_lambda.txt` present
- [ ] `deploy.ps1` or `deploy.sh` ready

---

## Deployment Checklist

### Step 1: Initial Setup
- [ ] Clone/download project files
- [ ] Review configuration in `cloudformation-template.yaml`
- [ ] Set environment variables (optional):
  - `AWS_REGION` (default: us-east-1)
  - `ENVIRONMENT` (default: production)

### Step 2: Run Deployment Script
- [ ] **Windows**: Run `.\deploy.ps1` in PowerShell
- [ ] **Linux/Mac**: Run `./deploy.sh` in terminal
- [ ] Wait for deployment to complete (5-10 minutes)
- [ ] Check for any errors in output

### Step 3: Verify Deployment
- [ ] CloudFormation stack created successfully
- [ ] Lambda function deployed and active
- [ ] API Gateway endpoint created
- [ ] S3 bucket created
- [ ] IAM roles created with correct permissions
- [ ] CloudWatch log group created

### Step 4: Save Deployment Information
- [ ] `deployment-info.txt` file created
- [ ] API endpoint URL saved
- [ ] S3 bucket name saved
- [ ] Lambda function ARN saved

---

## Post-Deployment Checklist

### Testing
- [ ] Run basic API test with curl
- [ ] Run comprehensive test suite (`test-api.ps1` or `test-api.sh`)
- [ ] Test all response types:
  - [ ] General questions
  - [ ] Code help
  - [ ] Explanations
  - [ ] Summaries
  - [ ] Blog posts (backward compatibility)
- [ ] Test different output formats (text, html, markdown)
- [ ] Test error handling (empty input, invalid parameters)
- [ ] Verify responses are being generated correctly
- [ ] Check S3 bucket for saved responses (if enabled)

### Monitoring Setup
- [ ] CloudWatch Dashboard created
- [ ] View Lambda metrics (invocations, errors, duration)
- [ ] View API Gateway metrics (requests, latency, errors)
- [ ] Configure CloudWatch Alarms
- [ ] Set up SNS topic for alerts (optional)
- [ ] Subscribe email to SNS topic (optional)
- [ ] Test alarm notifications

### Security Configuration
- [ ] Review IAM role permissions (least privilege)
- [ ] Verify S3 bucket is not publicly accessible
- [ ] Enable S3 bucket versioning
- [ ] Enable S3 server-side encryption (should be enabled by template)
- [ ] Review API Gateway CORS settings
- [ ] Consider adding API key requirement (optional)
- [ ] Consider adding WAF rules (optional)
- [ ] Enable CloudTrail logging (optional)

### Cost Optimization
- [ ] Review Lambda memory allocation (512 MB recommended)
- [ ] Review Lambda timeout (300s default)
- [ ] Set up S3 lifecycle policies (auto-delete old files)
- [ ] Configure API Gateway caching (optional)
- [ ] Set up usage plans and quotas (optional)
- [ ] Review and set AWS budget alerts

---

## Production Readiness Checklist

### Performance
- [ ] Load test with expected traffic volume
- [ ] Verify response times are acceptable
- [ ] Check concurrent execution limits
- [ ] Monitor cold start times
- [ ] Optimize Lambda memory if needed

### Reliability
- [ ] Test error handling and retries
- [ ] Verify CloudWatch logs are working
- [ ] Test throttling behavior
- [ ] Verify auto-scaling works correctly
- [ ] Test disaster recovery (backup/restore)

### Documentation
- [ ] Team trained on using the API
- [ ] API documentation created
- [ ] Monitoring procedures documented
- [ ] Troubleshooting guide reviewed
- [ ] Runbook created for common issues
- [ ] Contact information for support documented

### Compliance & Governance
- [ ] Data retention policies defined
- [ ] Privacy policy reviewed
- [ ] Terms of service defined (if public API)
- [ ] Compliance requirements met (GDPR, HIPAA, etc.)
- [ ] Tagging strategy implemented

---

## Ongoing Operations Checklist

### Daily
- [ ] Check CloudWatch Dashboard
- [ ] Review error logs
- [ ] Monitor cost alerts

### Weekly
- [ ] Review performance metrics
- [ ] Check for any throttling or errors
- [ ] Review S3 storage usage
- [ ] Clean up old S3 objects (if manual)

### Monthly
- [ ] Review and optimize costs
- [ ] Update dependencies if needed
- [ ] Review security configurations
- [ ] Check for AWS service updates
- [ ] Update documentation as needed

### Quarterly
- [ ] Conduct security review
- [ ] Review and update monitoring alerts
- [ ] Evaluate new Bedrock models
- [ ] Plan for capacity/scaling needs
- [ ] Disaster recovery drill

---

## Rollback Checklist (If Needed)

- [ ] Identify the issue
- [ ] Document the problem
- [ ] Determine if rollback is necessary
- [ ] Backup current CloudFormation stack
- [ ] Cancel stack update: `aws cloudformation cancel-update-stack`
- [ ] Or rollback to previous version
- [ ] Verify rollback completed successfully
- [ ] Test functionality after rollback
- [ ] Document lessons learned

---

## Decommission Checklist (If Needed)

- [ ] Export any important data from S3
- [ ] Notify users of shutdown
- [ ] Delete CloudFormation stack
- [ ] Verify all resources deleted
- [ ] Manually delete S3 bucket if needed
- [ ] Remove DNS records (if custom domain)
- [ ] Remove API keys/credentials
- [ ] Archive documentation
- [ ] Update asset inventory

---

## Quick Reference Commands

### Check Deployment Status
```bash
aws cloudformation describe-stacks --stack-name ai-assistant-stack --region us-east-1
```

### View Lambda Logs
```bash
aws logs tail /aws/lambda/ai-assistant-function --follow
```

### Test API
```bash
curl -X POST <API_ENDPOINT> \
  -H "Content-Type: application/json" \
  -d '{"user_input": "test", "response_type": "general"}'
```

### Check Costs
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost
```

---

## Support Contacts

- **AWS Support**: https://console.aws.amazon.com/support/
- **Bedrock Documentation**: https://docs.aws.amazon.com/bedrock/
- **Project Repository**: [Your repo link]
- **Team Lead**: [Name/Email]
- **On-Call Engineer**: [Contact info]

---

## Sign-Off

**Deployed by**: ___________________________  
**Date**: ___________________________  
**Environment**: ___________________________  
**Version**: ___________________________  

**Verified by**: ___________________________  
**Date**: ___________________________  

**Production Approval**: ___________________________  
**Date**: ___________________________  

---

## Notes

Use this space to document any deployment-specific details, customizations, or issues encountered:

```
[Your notes here]
```
