#!/bin/bash

# Navigate to the backend directory
echo "Setting up backend..."
cd backend

# Activate the virtual environment
source venv/bin/activate

# Start the FastAPI server
if [ -f "app_fastapi.py" ]; then
    echo "Running FastAPI backend..."
    uvicorn app_fastapi:app --host 0.0.0.0 --port 8000 --reload &
else
    echo "Running Node.js backend..."
    npm run dev &
fi

# Navigate to the frontend directory
echo "Setting up frontend..."
cd ../frontend

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "npm not found. Please install Node.js."
    exit 1
fi

npm start &

echo "Project is running. Backend on http://localhost:8000 and Frontend on http://localhost:3000"