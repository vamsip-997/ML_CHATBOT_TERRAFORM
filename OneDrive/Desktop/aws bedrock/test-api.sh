#!/bin/bash
###############################################################################
# AI Assistant - API Testing Script
# Comprehensive tests for all response types
###############################################################################

# Get API endpoint from deployment info
if [ -f "deployment-info.txt" ]; then
    API_ENDPOINT=$(grep "API Endpoint:" deployment-info.txt | cut -d' ' -f3)
else
    echo "Error: deployment-info.txt not found. Please deploy first."
    exit 1
fi

echo "=========================================================================="
echo "  AI Assistant API Test Suite"
echo "=========================================================================="
echo ""
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Test 1: General Question
echo "Test 1: General Question"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "What is Python programming?",
    "response_type": "general"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 2: Code Help
echo "Test 2: Code Help"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "How to reverse a string in Python?",
    "response_type": "code"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 3: Explanation
echo "Test 3: Detailed Explanation"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "Machine Learning",
    "response_type": "explain"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 4: Summary
echo "Test 4: Summary"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "Benefits of cloud computing",
    "response_type": "summarize"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 5: Blog Post (Backward Compatible)
echo "Test 5: Blog Post (Backward Compatible)"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "blog_topic": "Artificial Intelligence",
    "word_count": 200,
    "output_format": "text"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 6: HTML Output
echo "Test 6: HTML Output Format"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "Web Development",
    "response_type": "explain",
    "output_format": "html"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 7: Markdown Output
echo "Test 7: Markdown Output Format"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "Data Structures",
    "response_type": "explain",
    "output_format": "markdown"
  }' | python3 -m json.tool
echo ""
sleep 2

# Test 8: Error Handling - Empty Input
echo "Test 8: Error Handling - Empty Input"
echo "------------------------"
curl -s -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "user_input": "",
    "response_type": "general"
  }' | python3 -m json.tool
echo ""

echo "=========================================================================="
echo "  Test Suite Complete"
echo "=========================================================================="
