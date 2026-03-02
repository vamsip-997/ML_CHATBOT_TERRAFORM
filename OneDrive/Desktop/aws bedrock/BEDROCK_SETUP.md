# 🔧 Amazon Bedrock Setup Guide

## ⚠️ Important: Use Case Form Required

You're seeing this error because AWS requires you to submit a use case form before using Anthropic Claude models in Bedrock.

```
Error: Model use case details have not been submitted for this account.
Fill out the Anthropic use case details form before using the model.
```

---

## 🚀 Quick Fix - Enable Claude Models

### Step 1: Access Model Access Page

**Direct Link:** https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

Or manually:
1. Go to AWS Console: https://console.aws.amazon.com/bedrock/
2. Click on **"Model access"** in the left sidebar
3. Make sure you're in **us-east-1** region (top-right corner)

---

### Step 2: Request Access to Claude Models

1. Click **"Modify model access"** button (orange button on top-right)

2. Scroll down to find **Anthropic** section

3. Check the box for:
   - ✅ **Claude 3 Haiku** (recommended - most cost-effective)
   - ✅ **Claude 3 Sonnet** (optional - more capable)
   - ✅ **Claude 3.5 Sonnet** (optional - most advanced)

4. Click **"Next"** button

---

### Step 3: Fill Out Use Case Form

AWS will ask you about your use case:

1. **Use case details:**
   - Select: **"Other"** or **"Content Generation"**
   - Description: "AI-powered blog content generation application"

2. **End user notice:**
   - Check: ✅ "I confirm that end users will be notified that they are interacting with AI"

3. Click **"Submit"**

---

### Step 4: Wait for Approval

- ⏱️ **Approval time:** Usually 5-15 minutes (can be instant)
- 📧 **Email notification:** You'll receive an email when approved
- 🔄 **Check status:** Refresh the Model Access page

**Status indicators:**
- 🟡 **In progress** - Request submitted, waiting for approval
- 🟢 **Access granted** - Ready to use!
- 🔴 **Access denied** - Contact AWS Support

---

## ✅ Verify Access

Once approved, verify access:

```bash
# List available models
aws bedrock list-foundation-models --region us-east-1 | grep -i claude

# Or check specific model
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-3-haiku-20240307-v1:0 \
  --region us-east-1
```

---

## 🎯 Alternative Models (If Claude Not Available)

If you can't get Claude access immediately, you can modify the code to use other models:

### Option 1: Amazon Titan

**Model ID:** `amazon.titan-text-express-v1`

**Update in `app.py`:**
```python
# Change line 26
modelId="amazon.titan-text-express-v1"

# Update body format (line 12-21)
body = {
    "inputText": prompt,
    "textGenerationConfig": {
        "maxTokenCount": max(512, word_count * 2),
        "temperature": 0.7,
        "topP": 0.9
    }
}

# Update response parsing (line 31)
blog_details = response_data['results'][0]['outputText']
```

### Option 2: AI21 Jurassic-2

**Model ID:** `ai21.j2-ultra-v1`

**Update in `app.py`:**
```python
# Change line 26
modelId="ai21.j2-ultra-v1"

# Update body format
body = {
    "prompt": prompt,
    "maxTokens": max(512, word_count * 2),
    "temperature": 0.7
}

# Update response parsing
blog_details = response_data['completions'][0]['data']['text']
```

---

## 📋 Current Model Configuration

Your application is configured to use:
- **Model:** Claude 3 Haiku
- **Model ID:** `anthropic.claude-3-haiku-20240307-v1:0`
- **Region:** us-east-1
- **Provider:** Anthropic

**To change models, edit:**
- `app.py` (line 26)
- Update the request body format
- Update the response parsing logic

---

## 🔗 Useful Links

### Bedrock Console
- **Model Access:** https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
- **Playgrounds:** https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/text-playground
- **Pricing:** https://aws.amazon.com/bedrock/pricing/

### Documentation
- **Bedrock User Guide:** https://docs.aws.amazon.com/bedrock/latest/userguide/
- **Model Access Guide:** https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html
- **Claude Models:** https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-anthropic-claude-messages.html

### Support
- **AWS Support:** https://console.aws.amazon.com/support/home
- **Bedrock FAQ:** https://aws.amazon.com/bedrock/faqs/

---

## 🧪 Test After Setup

Once model access is granted, test with:

```bash
# Option 1: Automated demo
python demo_cli_test.py

# Option 2: Interactive CLI
python test_local.py

# Option 3: Web interface
python web_app.py
# Then open http://localhost:5000
```

---

## 💰 Pricing Information

### Claude 3 Haiku (Recommended)
- **Input:** $0.25 per 1M tokens
- **Output:** $1.25 per 1M tokens
- **Estimated cost for 200-word blog:** ~$0.001 (less than 1 cent)

### Comparison
| Model | Input Price | Output Price | Speed | Quality |
|-------|-------------|--------------|-------|---------|
| Claude 3 Haiku | $0.25/1M | $1.25/1M | Fast | Good |
| Claude 3 Sonnet | $3.00/1M | $15.00/1M | Medium | Better |
| Claude 3.5 Sonnet | $3.00/1M | $15.00/1M | Medium | Best |
| Amazon Titan | $0.20/1M | $0.60/1M | Fast | Basic |

---

## 🆘 Still Having Issues?

### Common Problems

**1. Region Mismatch**
- Ensure you're in **us-east-1** region
- Check AWS Console top-right corner
- Update code if using different region

**2. Insufficient Permissions**
- Your IAM user needs: `bedrock:InvokeModel` permission
- Check IAM policies in console

**3. Form Not Appearing**
- Clear browser cache
- Try different browser
- Use incognito/private mode

**4. Request Denied**
- Contact AWS Support
- May need business verification
- Try different AWS account

---

## 📞 Contact AWS Support

If approval takes longer than expected:

1. Go to: https://console.aws.amazon.com/support/home
2. Click **"Create case"**
3. Select **"Account and billing support"**
4. Describe: "Requesting access to Amazon Bedrock - Claude 3 Haiku model"

---

**Once you have access, your blog generator will work perfectly! 🎉**
