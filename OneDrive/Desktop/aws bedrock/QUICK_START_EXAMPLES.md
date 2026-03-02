# Quick Start Examples

## 🚀 Ready-to-Use Examples for Your AI Assistant

### 1. Web Interface (Easiest)

Start the server:
```bash
python web_app.py
```

Open browser to: `http://localhost:5000`

**Try these questions:**
- "What is machine learning?"
- "How do I create a function in Python?"
- "Explain the solar system"
- "Benefits of exercise"
- "Write a blog about sustainable living"

---

### 2. Python Code Examples

#### General Question
```python
from app import ai_generate_response

response = ai_generate_response(
    user_input="What is quantum computing?",
    response_type="general",
    max_tokens=1024,
    output_format="text"
)
print(response)
```

#### Get Programming Help
```python
from app import ai_generate_response

response = ai_generate_response(
    user_input="How do I connect to a MySQL database in Python?",
    response_type="code",
    max_tokens=1024,
    output_format="text"
)
print(response)
```

#### Detailed Explanation
```python
from app import ai_generate_response

response = ai_generate_response(
    user_input="Blockchain technology",
    response_type="explain",
    max_tokens=2048,
    output_format="markdown"
)
print(response)
```

#### Quick Summary
```python
from app import ai_generate_response

response = ai_generate_response(
    user_input="The history of the internet",
    response_type="summarize",
    max_tokens=512,
    output_format="text"
)
print(response)
```

#### Blog Post (Original Feature)
```python
from app import blog_generate_using_bedrock

blog = blog_generate_using_bedrock(
    blogtopic="The Future of Electric Vehicles",
    word_count=500,
    output_format="html"
)
print(blog)
```

---

### 3. REST API Examples

#### Using curl

**General Question:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "What is artificial intelligence?",
    "response_type": "general",
    "output_format": "text"
  }'
```

**Code Help:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "How to sort a dictionary by value in Python?",
    "response_type": "code",
    "output_format": "text"
  }'
```

**Explanation:**
```bash
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "Photosynthesis",
    "response_type": "explain",
    "output_format": "markdown"
  }'
```

#### Using Python requests
```python
import requests

# General question
response = requests.post(
    'http://localhost:5000/api/generate',
    json={
        'user_input': 'What is the Theory of Relativity?',
        'response_type': 'general',
        'output_format': 'text'
    }
)
print(response.json()['response'])

# Programming help
response = requests.post(
    'http://localhost:5000/api/generate',
    json={
        'user_input': 'How to handle exceptions in Python?',
        'response_type': 'code',
        'output_format': 'text'
    }
)
print(response.json()['response'])
```

---

### 4. AWS Lambda Examples

#### Event Format (New)
```json
{
  "body": "{\"user_input\": \"What are the benefits of cloud computing?\", \"response_type\": \"general\", \"output_format\": \"text\"}"
}
```

#### Event Format (Legacy - Still Works)
```json
{
  "body": "{\"blog_topic\": \"Climate Change\", \"word_count\": 300, \"output_format\": \"text\"}"
}
```

#### Test Lambda Locally
```python
from app import lambda_handler

# New format
event = {
    'body': '{"user_input": "Explain Docker containers", "response_type": "explain", "output_format": "text"}'
}
result = lambda_handler(event, None)
print(result['body'])

# Legacy format (backward compatible)
event = {
    'body': '{"blog_topic": "Cybersecurity", "word_count": 250, "output_format": "text"}'
}
result = lambda_handler(event, None)
print(result['body'])
```

---

### 5. Real-World Use Cases

#### Customer Support Chatbot
```python
def customer_support_bot(question):
    """Answer customer questions about any topic"""
    return ai_generate_response(
        user_input=question,
        response_type="general",
        max_tokens=512,
        output_format="text"
    )

# Examples
print(customer_support_bot("How do I reset my password?"))
print(customer_support_bot("What are your business hours?"))
```

#### Educational Assistant
```python
def study_helper(topic):
    """Help students learn any subject"""
    return ai_generate_response(
        user_input=topic,
        response_type="explain",
        max_tokens=2048,
        output_format="markdown"
    )

# Examples
print(study_helper("The water cycle"))
print(study_helper("Newton's laws of motion"))
```

#### Programming Tutor
```python
def code_tutor(question):
    """Help programmers with coding questions"""
    return ai_generate_response(
        user_input=question,
        response_type="code",
        max_tokens=1024,
        output_format="text"
    )

# Examples
print(code_tutor("How to use list comprehensions in Python?"))
print(code_tutor("What is the difference between == and === in JavaScript?"))
```

#### Content Creator
```python
def content_creator(topic, content_type="blog"):
    """Create different types of content"""
    if content_type == "blog":
        return blog_generate_using_bedrock(topic, word_count=400, output_format="html")
    elif content_type == "summary":
        return ai_generate_response(topic, response_type="summarize", max_tokens=256, output_format="text")
    else:
        return ai_generate_response(topic, response_type="explain", max_tokens=1024, output_format="markdown")

# Examples
print(content_creator("Digital Marketing", "blog"))
print(content_creator("SEO best practices", "summary"))
```

---

### 6. Different Output Formats

#### Plain Text
```python
response = ai_generate_response(
    user_input="What is Python?",
    response_type="general",
    output_format="text"
)
# Output: Plain text, easy to read
```

#### HTML
```python
response = ai_generate_response(
    user_input="Web Development Basics",
    response_type="explain",
    output_format="html"
)
# Output: <h1>Web Development Basics</h1><p>...</p>
```

#### Markdown
```python
response = ai_generate_response(
    user_input="Data Structures in Programming",
    response_type="explain",
    output_format="markdown"
)
# Output: # Data Structures\n## Arrays\n**Bold** text...
```

---

### 7. Topic Ideas to Try

**Science:**
- "Explain how vaccines work"
- "What is CRISPR gene editing?"
- "The Big Bang Theory"

**Technology:**
- "What is cloud computing?"
- "Explain microservices architecture"
- "How does blockchain work?"

**Programming:**
- "Difference between SQL and NoSQL databases"
- "What are design patterns?"
- "How to optimize Python code?"

**History:**
- "The Renaissance period"
- "Causes of the American Revolution"
- "Ancient Egyptian civilization"

**Business:**
- "What is agile methodology?"
- "Explain supply chain management"
- "Digital transformation strategies"

**Creative:**
- "Tips for better photography"
- "How to write compelling stories"
- "Color theory in design"

**Math:**
- "Explain calculus concepts"
- "What is probability?"
- "Linear algebra applications"

**Health:**
- "Benefits of regular exercise"
- "Importance of sleep"
- "Nutrition fundamentals"

---

### 8. Pro Tips

**For Better Responses:**
1. Be specific in your questions
2. Choose the right response type
3. Use markdown format for technical content
4. Adjust max_tokens for longer/shorter responses

**Response Type Guide:**
- `general` - Quick answers, Q&A
- `explain` - Educational, detailed
- `code` - Programming questions
- `summarize` - Brief overviews
- `blog` - Well-structured articles

**Token Guidelines:**
- Short answers: 512 tokens
- Medium responses: 1024 tokens
- Detailed explanations: 2048 tokens
- Blog posts: word_count × 2

---

## 🎉 You're Ready!

Your AI Assistant can now handle literally **ANY topic**. Just ask!

```python
# The sky's the limit!
response = ai_generate_response(
    user_input="Your question here",
    response_type="general",
    max_tokens=1024,
    output_format="text"
)
```

**Start exploring and have fun! 🚀**
