# AI Assistant using Amazon Bedrock

**🚀 Universal AI Assistant - Ask Anything, Get Intelligent Responses!**

> ⚡ **NEW:** Now handles ANY topic with 5 response types (General, Blog, Explain, Summarize, Code)  
> ✅ **100% Backward Compatible** - All blog generation features still work!

---

## 🆕 What's New - Universal AI Assistant

This application has been upgraded from a **Blog Generator** to a **Universal AI Assistant** that can:

- ✅ Answer **ANY question** on **ANY topic**
- ✅ Provide 5 different response types
- ✅ Handle programming, science, history, math, business, creative topics
- ✅ Still generate blog posts (backward compatible)

### Response Types Available:
1. **General Response** - Direct answers to any question
2. **Blog Post** - Structured blog content with introduction, body, conclusion
3. **Detailed Explanation** - In-depth educational explanations
4. **Summary** - Concise summaries of topics
5. **Code/Programming Help** - Technical assistance with code examples

📖 **See [BEFORE_vs_AFTER.md](BEFORE_vs_AFTER.md)** for detailed comparison  
📚 **See [QUICK_START_EXAMPLES.md](QUICK_START_EXAMPLES.md)** for usage examples  
📋 **See [AI_ASSISTANT_UPGRADE.md](AI_ASSISTANT_UPGRADE.md)** for technical details

---

# Original: Blog Generator using Amazon Bedrock

An AI-powered blog generation application that uses Amazon Bedrock's Claude 3 Haiku model to generate blog posts with multiple output formats and flexible deployment options.

## ✨ Features

- **🤖 AI-Powered Content Generation**: Uses Claude 3 Haiku via Amazon Bedrock to generate high-quality blog posts
- **📊 Customizable Word Count**: Generate blogs from 50 to 2000 words
- **📄 Multiple Output Formats**: 
  - Plain Text
  - HTML with proper tags
  - Markdown formatting
- **💾 Flexible Storage Options**: 
  - Save to Amazon S3
  - Save locally
  - Both options simultaneously
- **🌐 Multiple Interfaces**:
  - Web UI (Flask-based)
  - REST API
  - AWS Lambda function
  - Command-line test script
- **🚀 Easy Deployment**: Automated Lambda deployment script included

## 🎯 How It Works

1. **Input**: Provide a blog topic, word count, and desired format
2. **Generation**: Claude 3 Haiku generates the blog post according to specifications
3. **Storage**: Save to S3, local file system, or both
4. **Response**: Receive the generated content with metadata

## Prerequisites

- AWS Account with access to:
  - Amazon Bedrock (Claude 3 Haiku model enabled)
  - Amazon S3 (bucket created)
  - AWS Lambda (if deploying as Lambda function)
- Python 3.9+
- AWS credentials configured

## 📦 Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## ⚙️ Configuration

Update the following in `app.py` and `deploy_lambda.py`:

- **S3 Bucket Name**: Change `blog-generator-storage-rishi-2026` to your bucket name
- **Region**: Update the region if needed (default: `us-east-1`)
- **Model**: Currently uses `anthropic.claude-3-haiku-20240307-v1:0`

## 🚀 Usage

### Option 1: Web Interface (Recommended for Testing)

Launch the Flask web application:

```bash
python web_app.py
```

Then open your browser to `http://localhost:5000`

**Features:**
- Interactive form for topic, word count, and format selection
- Real-time blog generation
- Download or save options (local/S3)
- Beautiful, responsive UI

### Option 2: Command-Line Test Script

Run the interactive test script:

```bash
python test_local.py
```

This will prompt you for:
- Blog topic
- Word count (50-2000)
- Output format (text/html/markdown)
- Save options (S3/local/both)

### Option 3: AWS Lambda Function

Deploy using the automated script:

```bash
python deploy_lambda.py
```

This script will:
- Create deployment package with dependencies
- Create/update IAM role with proper permissions
- Deploy/update Lambda function
- Run a test invocation

**Manual Lambda Invocation:**

```json
{
  "body": "{\"blog_topic\": \"Artificial Intelligence\", \"word_count\": 300, \"output_format\": \"markdown\"}"
}
```

**Lambda Response:**

```json
{
  "statusCode": 200,
  "body": "{\"message\": \"Blog generation completed successfully\", \"topic\": \"Artificial Intelligence\", \"word_count\": 300, \"format\": \"markdown\", \"s3_location\": \"s3://bucket/blog-output/20260227_143052.md\"}"
}
```

### Option 4: REST API

Use the Flask API endpoints programmatically:

**Generate Blog:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"blog_topic": "Cloud Computing", "word_count": 250, "output_format": "html"}'
```

**Save Blog:**
```bash
curl -X POST http://localhost:5000/api/save \
  -H "Content-Type: application/json" \
  -d '{"blog": "content here", "metadata": {...}, "save_local": true, "save_s3": false}'
```

### Option 5: Python Code Integration

Import and use directly in your Python code:

```python
from app import blog_generate_using_bedrock, save_blog_details_s3

# Generate blog
blog = blog_generate_using_bedrock(
    blogtopic="Machine Learning",
    word_count=400,
    output_format="markdown"
)

# Save to S3
save_blog_details_s3(
    s3_key="blog-output/ml_blog.md",
    s3_bucket="your-bucket-name",
    generate_blog=blog,
    content_type="text/markdown"
)
```

## Required AWS Permissions

The Lambda function (or local execution role) needs:

1. **Bedrock**: `bedrock:InvokeModel`
2. **S3**: `s3:PutObject` on your target bucket

## 📁 Project Structure

```
.
├── app.py              # Core blog generation logic (Lambda compatible)
├── web_app.py          # Flask web interface and REST API
├── test_local.py       # Interactive command-line test script
├── deploy_lambda.py    # Automated Lambda deployment script
├── requirements.txt    # Python dependencies
├── .gitignore          # Git ignore rules
└── README.md           # This file
```

## 📚 Dependencies

- `boto3>=1.34.0` - AWS SDK for Python
- `botocore>=1.34.0` - Low-level AWS service access
- `flask>=3.0.0` - Web framework (for web_app.py)

## 📤 Output Formats

Generated blogs are saved with format-specific extensions:

| Format | Extension | Content Type | Description |
|--------|-----------|--------------|-------------|
| Text | `.txt` | `text/plain` | Plain text format |
| HTML | `.html` | `text/html` | HTML with proper tags |
| Markdown | `.md` | `text/markdown` | Markdown formatting |

**Naming Convention:** `YYYYMMDD_HHMMSS.{ext}`
- Example: `20260227_143052.md`

## 🛡️ Error Handling

The application includes comprehensive error handling for:
- Bedrock API failures (with 3 retry attempts)
- S3 upload failures
- Missing or invalid input parameters
- Network timeouts (300 seconds configured)
- Invalid word count ranges (auto-corrected to 50-2000)
- Invalid output formats (defaults to 'text')

## 💡 Tips

- **Cost Optimization**: Claude 3 Haiku is the most cost-effective option for blog generation
- **Word Count**: Actual output may vary slightly from requested word count
- **HTML Output**: Includes semantic tags like `<h1>`, `<h2>`, `<p>` for better structure
- **Markdown Output**: Great for content management systems and documentation
- **S3 Storage**: Blogs are stored in the `blog-output/` prefix for easy organization

## 🚦 Quick Start Example

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start the web interface
python web_app.py

# 3. Open browser to http://localhost:5000

# 4. Enter topic, select options, and generate!
```

## 🔧 Troubleshooting

**Bedrock Access Denied:**
- Ensure Claude 3 Haiku model is enabled in your AWS account region
- Check IAM permissions for `bedrock:InvokeModel`

**S3 Upload Fails:**
- Verify bucket name is correct
- Check IAM permissions for `s3:PutObject`
- Ensure bucket exists in the specified region

**Lambda Deployment Issues:**
- Ensure AWS credentials are configured (`aws configure`)
- Check that you have permissions to create IAM roles and Lambda functions
- Verify boto3/botocore versions are compatible

## 📝 License

This project is open source and available for educational purposes.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Add new AI models
- Implement additional output formats
- Enhance the web UI
- Improve error handling
- Add unit tests

## 📧 Support

For issues or questions:
- Check the troubleshooting section
- Review AWS Bedrock documentation
- Verify your AWS credentials and permissions

---

**Built with ❤️ using Amazon Bedrock, Claude 3 Haiku, and Python**
