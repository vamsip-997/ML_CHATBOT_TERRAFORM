#!/usr/bin/env python3
"""
Local test script for the blog generator.
This allows you to test the blog generation without deploying to Lambda.
"""

import json
from app import blog_generate_using_bedrock, save_blog_details_s3
from datetime import datetime

def test_blog_generation():
    """Test the blog generation locally with custom options"""
    
    print("=" * 70)
    print("🚀 AI Blog Generator - Local Test")
    print("=" * 70)
    
    # Get topic from user
    blog_topic = input("\n📝 Enter blog topic: ").strip()
    
    if not blog_topic:
        print("❌ Error: Blog topic cannot be empty")
        return
    
    # Get word count
    word_count_input = input("📊 Enter word count (50-2000, default 200): ").strip()
    try:
        word_count = int(word_count_input) if word_count_input else 200
        word_count = max(50, min(word_count, 2000))
    except ValueError:
        print("⚠️  Invalid word count, using default (200)")
        word_count = 200
    
    # Get output format
    print("\n📄 Select output format:")
    print("  1. Plain Text (default)")
    print("  2. HTML")
    print("  3. Markdown")
    format_choice = input("Choose (1-3): ").strip()
    
    format_map = {'1': 'text', '2': 'html', '3': 'markdown', '': 'text'}
    output_format = format_map.get(format_choice, 'text')
    
    print(f"\n🤖 Generating {word_count}-word blog in {output_format.upper()} format...")
    print(f"📌 Topic: {blog_topic}")
    print("⏳ Please wait...\n")
    
    # Generate blog
    try:
        generated_blog = blog_generate_using_bedrock(
            blogtopic=blog_topic,
            word_count=word_count,
            output_format=output_format
        )
        
        if generated_blog:
            print("=" * 70)
            print("✅ Blog Generated Successfully!")
            print("=" * 70)
            print("\n" + generated_blog + "\n")
            print("=" * 70)
            
            # Ask if user wants to save
            print("\n💾 Save options:")
            print("  1. Save to S3")
            print("  2. Save locally")
            print("  3. Both")
            print("  4. Skip saving")
            save_choice = input("Choose (1-4): ").strip()
            
            current_time = datetime.now().strftime('%Y%m%d_%H%M%S')
            extensions = {'text': 'txt', 'html': 'html', 'markdown': 'md'}
            file_ext = extensions.get(output_format, 'txt')
            
            if save_choice in ['1', '3']:
                s3_key = f"blog-output/{current_time}.{file_ext}"
                s3_bucket = 'blog-generator-storage-rishi-2026'
                
                print(f"\n📤 Uploading to S3...")
                print(f"   Bucket: {s3_bucket}")
                print(f"   Key: {s3_key}")
                
                content_types = {
                    'text': 'text/plain',
                    'html': 'text/html',
                    'markdown': 'text/markdown'
                }
                content_type = content_types.get(output_format, 'text/plain')
                
                if save_blog_details_s3(s3_key, s3_bucket, generated_blog, content_type):
                    print("✅ Blog saved to S3 successfully!")
                else:
                    print("❌ Failed to save to S3")
            
            if save_choice in ['2', '3']:
                filename = f"blog_{current_time}.{file_ext}"
                
                print(f"\n💾 Saving locally to file...")
                
                with open(filename, 'w', encoding='utf-8') as f:
                    if output_format == 'text':
                        f.write(f"Topic: {blog_topic}\n")
                        f.write(f"Word Count: {word_count}\n")
                        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                        f.write("=" * 70 + "\n\n")
                    f.write(generated_blog)
                
                print(f"✅ Blog saved locally as: {filename}")
            
            if save_choice == '4':
                print("\n⏭️  Skipping save")
                
        else:
            print("❌ Error: No blog was generated")
            
    except Exception as e:
        print(f"❌ Error during blog generation: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_blog_generation()
