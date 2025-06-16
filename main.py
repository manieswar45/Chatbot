#!/usr/bin/env python3
"""
Main entry point for the AI Chatbot application.
This script initializes both backend and frontend services.
"""
import os
import sys
import argparse
import subprocess
import webbrowser
from pathlib import Path

def check_dependencies():
    """Check if required dependencies are installed."""
    try:
        import fastapi
        import uvicorn
        import motor.motor_asyncio
        import transformers
        import pydantic
        import jwt
        print("✅ All Python dependencies are installed.")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Run setup.sh to install all dependencies.")
        return False

def start_backend(port=8000):
    """Start the FastAPI backend server."""
    try:
        print(f"🚀 Starting backend server on port {port}...")
        # Use the app_fastapi.py file in the backend directory
        backend_path = Path("backend/app_fastapi.py")
        if not backend_path.exists():
            print(f"❌ Backend file not found: {backend_path}")
            return False
            
        # Run uvicorn server
        subprocess.Popen([
            sys.executable, 
            "-m", "uvicorn", 
            "backend.app_fastapi:app", 
            "--host", "0.0.0.0", 
            "--port", str(port), 
            "--reload"
        ])
        print(f"✅ Backend server started at http://localhost:{port}")
        return True
    except Exception as e:
        print(f"❌ Failed to start backend server: {e}")
        return False

def start_frontend(port=3000):
    """Start the React frontend development server."""
    try:
        print(f"🚀 Starting frontend server on port {port}...")
        frontend_dir = Path("frontend")
        if not frontend_dir.exists():
            print(f"❌ Frontend directory not found: {frontend_dir}")
            return False
            
        # Check if npm is installed
        try:
            subprocess.run(["npm", "--version"], check=True, stdout=subprocess.PIPE)
        except (subprocess.SubprocessError, FileNotFoundError):
            print("❌ npm is not installed. Please install Node.js and npm.")
            return False
            
        # Start the React development server
        os.chdir(frontend_dir)
        subprocess.Popen(["npm", "start"])
        print(f"✅ Frontend server started at http://localhost:{port}")
        return True
    except Exception as e:
        print(f"❌ Failed to start frontend server: {e}")
        return False

def open_browser(backend_port=8000, frontend_port=3000):
    """Open web browser with application URLs."""
    # Wait a moment for servers to start
    import time
    time.sleep(3)
    
    # Open frontend in browser
    frontend_url = f"http://localhost:{frontend_port}"
    print(f"📱 Opening frontend in browser: {frontend_url}")
    webbrowser.open(frontend_url)
    
    # Open backend API docs
    backend_url = f"http://localhost:{backend_port}/docs"
    print(f"📘 API documentation available at: {backend_url}")
    webbrowser.open(backend_url)

def main():
    """Main function to parse arguments and start the application."""
    parser = argparse.ArgumentParser(description='AI Chatbot Application')
    parser.add_argument('--backend-port', type=int, default=8000, help='Backend server port')
    parser.add_argument('--frontend-port', type=int, default=3000, help='Frontend server port')
    parser.add_argument('--backend-only', action='store_true', help='Start only the backend server')
    parser.add_argument('--frontend-only', action='store_true', help='Start only the frontend server')
    parser.add_argument('--no-browser', action='store_true', help='Don\'t open browser automatically')
    args = parser.parse_args()

    print("=" * 60)
    print("🤖 AI Chatbot Application")
    print("=" * 60)
    
    if not args.frontend_only:
        if not check_dependencies():
            return
        backend_started = start_backend(args.backend_port)
    else:
        backend_started = True  # Skip backend check if frontend-only
    
    if not args.backend_only:
        frontend_started = start_frontend(args.frontend_port)
    else:
        frontend_started = True  # Skip frontend check if backend-only
    
    if backend_started and frontend_started and not args.no_browser:
        open_browser(args.backend_port, args.frontend_port)
    
    if backend_started or frontend_started:
        print("\n🎉 Application startup successful!")
        print("=" * 60)
        print("Press Ctrl+C to stop the servers")
        try:
            # Keep the main thread alive
            while True:
                import time
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n👋 Shutting down servers...")
            print("=" * 60)

if __name__ == "__main__":
    main()