#!/usr/bin/env python3
"""
Simple web interface for the Blog Generator.
Provides a REST API and basic HTML interface.
"""

from flask import Flask, request, jsonify, render_template_string
from app import blog_generate_using_bedrock, save_blog_details_s3, ai_generate_response
from datetime import datetime
import os

app = Flask(__name__)

# HTML Template for the web interface
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Blog Generator</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 1.05em;
        }
        
        input[type="text"],
        input[type="number"],
        select {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1em;
            transition: border-color 0.3s;
        }
        
        input[type="text"]:focus,
        input[type="number"]:focus,
        select:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .button-group {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }
        
        button {
            flex: 1;
            padding: 15px 30px;
            border: none;
            border-radius: 8px;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: #f0f0f0;
            color: #333;
        }
        
        .btn-secondary:hover {
            background: #e0e0e0;
        }
        
        #result {
            margin-top: 30px;
            padding: 25px;
            background: #f8f9fa;
            border-radius: 10px;
            border-left: 4px solid #667eea;
            display: none;
        }
        
        #result.show {
            display: block;
            animation: slideIn 0.5s ease;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        #result h3 {
            color: #667eea;
            margin-bottom: 15px;
        }
        
        #blogContent {
            white-space: pre-wrap;
            line-height: 1.8;
            color: #333;
        }
        
        .loading {
            text-align: center;
            padding: 20px;
            display: none;
        }
        
        .loading.show {
            display: block;
        }
        
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .save-options {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 2px solid #e0e0e0;
        }
        
        .checkbox-group {
            display: flex;
            gap: 20px;
            margin-top: 10px;
        }
        
        .checkbox-label {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
        }
        
        input[type="checkbox"] {
            width: 20px;
            height: 20px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 AI Assistant</h1>
            <p>Powered by Amazon Bedrock & Claude 3 Haiku - Ask me anything!</p>
        </div>
        
        <div class="content">
            <form id="blogForm">
                <div class="form-group">
                    <label for="topic">💬 Your Question or Topic</label>
                    <input type="text" id="topic" name="topic" placeholder="Ask me anything or enter any topic..." required>
                </div>
                
                <div class="form-group">
                    <label for="responseType">🎯 Response Type</label>
                    <select id="responseType" name="responseType" onchange="toggleWordCount()">
                        <option value="general">General Response</option>
                        <option value="blog">Blog Post</option>
                        <option value="explain">Detailed Explanation</option>
                        <option value="summarize">Summary</option>
                        <option value="code">Code/Programming Help</option>
                    </select>
                </div>
                
                <div class="form-group" id="wordCountGroup" style="display: none;">
                    <label for="wordCount">📊 Word Count (50-2000)</label>
                    <input type="number" id="wordCount" name="wordCount" min="50" max="2000" value="200">
                </div>
                
                <div class="form-group">
                    <label for="format">📄 Output Format</label>
                    <select id="format" name="format">
                        <option value="text">Plain Text</option>
                        <option value="html">HTML</option>
                        <option value="markdown">Markdown</option>
                    </select>
                </div>
                
                <div class="button-group">
                    <button type="submit" class="btn-primary">✨ Get Response</button>
                    <button type="button" class="btn-secondary" onclick="clearForm()">🔄 Clear</button>
                </div>
            </form>
            
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p style="margin-top: 15px; color: #667eea; font-weight: 600;">Generating response...</p>
            </div>
            
            <div id="result">
                <h3>✅ AI Response</h3>
                <div id="blogContent"></div>
                
                <div class="save-options">
                    <label>💾 Save Options</label>
                    <div class="checkbox-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="saveLocal" checked>
                            <span>Save Locally</span>
                        </label>
                        <label class="checkbox-label">
                            <input type="checkbox" id="saveS3">
                            <span>Save to S3</span>
                        </label>
                    </div>
                    <button onclick="saveBlog()" class="btn-primary" style="margin-top: 15px; width: 100%;">
                        💾 Save Blog
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        let currentBlog = null;
        let currentMetadata = null;
        
        function toggleWordCount() {
            const responseType = document.getElementById('responseType').value;
            const wordCountGroup = document.getElementById('wordCountGroup');
            
            // Show word count only for blog posts
            if (responseType === 'blog') {
                wordCountGroup.style.display = 'block';
            } else {
                wordCountGroup.style.display = 'none';
            }
        }
        
        document.getElementById('blogForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const topic = document.getElementById('topic').value;
            const responseType = document.getElementById('responseType').value;
            const wordCount = parseInt(document.getElementById('wordCount').value) || 200;
            const format = document.getElementById('format').value;
            
            // Show loading
            document.getElementById('loading').classList.add('show');
            document.getElementById('result').classList.remove('show');
            
            try {
                const response = await fetch('/api/generate', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        user_input: topic,
                        response_type: responseType,
                        word_count: wordCount,
                        output_format: format
                    })
                });
                
                const data = await response.json();
                
                // Hide loading
                document.getElementById('loading').classList.remove('show');
                
                if (data.response) {
                    currentBlog = data.response;
                    currentMetadata = {
                        topic: topic,
                        response_type: responseType,
                        word_count: wordCount,
                        format: format
                    };
                    
                    document.getElementById('blogContent').textContent = data.response;
                    document.getElementById('result').classList.add('show');
                } else {
                    alert('Error generating response: ' + (data.error || 'Unknown error'));
                }
            } catch (error) {
                document.getElementById('loading').classList.remove('show');
                alert('Error: ' + error.message);
            }
        });
        
        async function saveBlog() {
            if (!currentBlog) return;
            
            const saveLocal = document.getElementById('saveLocal').checked;
            const saveS3 = document.getElementById('saveS3').checked;
            
            if (!saveLocal && !saveS3) {
                alert('Please select at least one save option');
                return;
            }
            
            try {
                const response = await fetch('/api/save', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        blog: currentBlog,
                        metadata: currentMetadata,
                        save_local: saveLocal,
                        save_s3: saveS3
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    let message = 'Blog saved successfully!\n\n';
                    if (data.local_file) message += `Local: ${data.local_file}\n`;
                    if (data.s3_location) message += `S3: ${data.s3_location}`;
                    alert(message);
                } else {
                    alert('Error saving blog: ' + (data.error || 'Unknown error'));
                }
            } catch (error) {
                alert('Error: ' + error.message);
            }
        }
        
        function clearForm() {
            document.getElementById('blogForm').reset();
            document.getElementById('result').classList.remove('show');
            currentBlog = null;
            currentMetadata = null;
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """Serve the web interface"""
    return render_template_string(HTML_TEMPLATE)

@app.route('/api/generate', methods=['POST'])
def generate_blog():
    """API endpoint to generate AI response for any topic"""
    try:
        data = request.json
        
        user_input = data.get('user_input')
        response_type = data.get('response_type', 'general')
        word_count = data.get('word_count', 200)
        output_format = data.get('output_format', 'text')
        
        if not user_input:
            return jsonify({'error': 'user_input is required'}), 400
        
        # Validate inputs
        word_count = max(50, min(word_count, 2000))
        if output_format not in ['text', 'html', 'markdown']:
            output_format = 'text'
        
        if response_type not in ['general', 'blog', 'explain', 'summarize', 'code']:
            response_type = 'general'
        
        # Calculate max tokens based on response type and word count
        if response_type == 'blog':
            max_tokens = max(512, word_count * 2)
        else:
            max_tokens = 2048  # Generous token limit for general responses
        
        # Generate AI response
        ai_response = ai_generate_response(
            user_input=user_input,
            response_type=response_type,
            max_tokens=max_tokens,
            output_format=output_format
        )
        
        if ai_response:
            return jsonify({
                'success': True,
                'response': ai_response,
                'metadata': {
                    'input': user_input,
                    'response_type': response_type,
                    'word_count': word_count,
                    'format': output_format
                }
            })
        else:
            return jsonify({'error': 'Failed to generate response'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/save', methods=['POST'])
def save_blog():
    """API endpoint to save a blog"""
    try:
        data = request.json
        
        blog = data.get('blog')
        metadata = data.get('metadata', {})
        save_local = data.get('save_local', False)
        save_s3 = data.get('save_s3', False)
        
        if not blog:
            return jsonify({'error': 'blog content is required'}), 400
        
        result = {'success': True}
        
        current_time = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_format = metadata.get('format', 'text')
        
        extensions = {'text': 'txt', 'html': 'html', 'markdown': 'md'}
        content_types = {
            'text': 'text/plain',
            'html': 'text/html',
            'markdown': 'text/markdown'
        }
        
        file_ext = extensions.get(output_format, 'txt')
        content_type = content_types.get(output_format, 'text/plain')
        
        # Save locally
        if save_local:
            filename = f"blog_{current_time}.{file_ext}"
            
            with open(filename, 'w', encoding='utf-8') as f:
                if output_format == 'text':
                    f.write(f"Topic: {metadata.get('topic', 'N/A')}\n")
                    f.write(f"Word Count: {metadata.get('word_count', 'N/A')}\n")
                    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                    f.write("=" * 70 + "\n\n")
                f.write(blog)
            
            result['local_file'] = filename
        
        # Save to S3
        if save_s3:
            s3_key = f"blog-output/{current_time}.{file_ext}"
            s3_bucket = 'blog-generator-storage-rishi-2026'
            
            if save_blog_details_s3(s3_key, s3_bucket, blog, content_type):
                result['s3_location'] = f"s3://{s3_bucket}/{s3_key}"
            else:
                result['s3_error'] = 'Failed to save to S3'
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("=" * 70)
    print("🚀 AI Assistant Web Interface")
    print("=" * 70)
    print("\n🌐 Starting server at http://localhost:5000")
    print("📝 Open your browser and navigate to the URL above")
    print("💬 Ask me anything - I can help with any topic!")
    print("\n⌨️  Press CTRL+C to stop the server\n")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
