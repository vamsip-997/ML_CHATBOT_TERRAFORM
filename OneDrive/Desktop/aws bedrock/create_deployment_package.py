#!/usr/bin/env python3
"""
Create Lambda deployment package
"""
import zipfile
import os
import shutil

def create_package():
    # Clean up with retry logic
    if os.path.exists('lambda_deployment.zip'):
        for i in range(3):
            try:
                os.remove('lambda_deployment.zip')
                print("Removed old package")
                break
            except PermissionError:
                if i < 2:
                    print(f"Warning: File is locked, retrying in 2 seconds... (attempt {i+1}/3)")
                    import time
                    time.sleep(2)
                else:
                    print("ERROR: Could not remove old package after 3 attempts.")
                    print("Please close any programs using lambda_deployment.zip and try again.")
                    return False
    
    print("Creating deployment package...")
    
    # Create zip file
    with zipfile.ZipFile('lambda_deployment.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:
        # Add files from lambda_package directory
        for root, dirs, files in os.walk('lambda_package'):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, 'lambda_package')
                print(f"Adding: {arcname}")
                zipf.write(file_path, arcname)
    
    # Get size
    size_mb = os.path.getsize('lambda_deployment.zip') / (1024 * 1024)
    print(f"\n✅ Package created: {size_mb:.2f} MB")
    
    # Verify lambda_function.py is in the zip
    with zipfile.ZipFile('lambda_deployment.zip', 'r') as zipf:
        if 'lambda_function.py' in zipf.namelist():
            print("✅ lambda_function.py is in the package")
        else:
            print("❌ lambda_function.py NOT found!")
            print("Files in zip:", zipf.namelist()[:20])
            return False
    
    return True

if __name__ == '__main__':
    if os.path.exists('lambda_package'):
        success = create_package()
        exit(0 if success else 1)
    else:
        print("❌ lambda_package directory not found")
        exit(1)
