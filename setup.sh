#!/bin/bash
# Setup script for AI Chatbot Application
# This script creates a virtual environment, installs dependencies,
# and starts the application.

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}🤖 AI Chatbot Application - Setup Script${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check if Python 3 is installed
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}❌ Python 3 is not installed. Please install Python 3 and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python 3 is installed.${NC}"

# Check if pip is installed
if ! command -v pip3 &>/dev/null; then
    echo -e "${RED}❌ pip is not installed. Please install pip and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ pip is installed.${NC}"

# Check if Node.js and npm are installed (for frontend)
if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    echo -e "${YELLOW}⚠️ Node.js or npm is not installed. Frontend setup will be skipped.${NC}"
    echo -e "${YELLOW}⚠️ To run the complete application, please install Node.js and npm.${NC}"
    SKIP_FRONTEND=true
else
    echo -e "${GREEN}✅ Node.js and npm are installed.${NC}"
    SKIP_FRONTEND=false
fi

# Create project directory structure if it doesn't exist
echo -e "${CYAN}📁 Creating project directory structure...${NC}"
mkdir -p backend
mkdir -p frontend/src/components
mkdir -p frontend/public

# Create virtual environment
echo -e "${CYAN}🔧 Creating Python virtual environment...${NC}"
python3 -m venv venv
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Failed to create virtual environment.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Virtual environment created successfully.${NC}"

# Activate virtual environment
echo -e "${CYAN}🔧 Activating virtual environment...${NC}"
source venv/bin/activate
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to activate virtual environment.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Virtual environment activated.${NC}"

# Install backend dependencies
echo -e "${CYAN}📦 Installing Python backend dependencies...${NC}"
pip install fastapi uvicorn motor pyjwt python-multipart transformers torch python-dotenv requests
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install Python dependencies.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python backend dependencies installed successfully.${NC}"

# Check for backend files and create them if they don't exist
if [ ! -f "backend/app_fastapi.py" ]; then
    echo -e "${YELLOW}⚠️ Backend app_fastapi.py not found. Creating skeleton file...${NC}"
    cat > backend/app_fastapi.py << 'EOF'
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="AI Chatbot API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Message(BaseModel):
    message: str

class ChatResponse(BaseModel):
    message: str

@app.get("/")
async def root():
    return {"message": "AI Chatbot API is running"}

@app.post("/api/chat", response_model=ChatResponse)
async def chat(message: Message):
    # Simple echo response for initial setup
    return {"message": f"Echo: {message.message}"}

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
EOF
    echo -e "${GREEN}✅ Created skeleton backend file.${NC}"
fi

# Set up frontend if Node.js and npm are installed
if [ "$SKIP_FRONTEND" = false ]; then
    echo -e "${CYAN}📦 Setting up React frontend...${NC}"
    
    # Initialize package.json if it doesn't exist
    if [ ! -f "frontend/package.json" ]; then
        echo -e "${YELLOW}⚠️ Frontend package.json not found. Creating new React app...${NC}"
        
        # Temporarily move to parent directory to create React app
        cd frontend
        
        # Initialize a new React app with necessary dependencies
        npm init -y
        npm install react react-dom react-scripts @chakra-ui/react @emotion/react @emotion/styled framer-motion axios react-icons react-markdown react-router-dom socket.io-client
        
        # Create basic structure
        mkdir -p src/components public
        
        # Create index.html
        cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="AI Chatbot Application" />
    <title>AI Chatbot</title>
</head>
<body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
</body>
</html>
EOF

        # Create index.js
        cat > src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

        # Create App.js
        cat > src/App.js << 'EOF'
import React from 'react';
import { ChakraProvider, Box, Text, VStack, Container } from '@chakra-ui/react';

function App() {
  return (
    <ChakraProvider>
      <Container maxW="container.md" py={10}>
        <VStack spacing={8}>
          <Box p={5} shadow="md" borderWidth="1px" borderRadius="md">
            <Text fontSize="2xl" fontWeight="bold">
              AI Chatbot
            </Text>
            <Text mt={4}>
              Welcome to the AI Chatbot Application! This is a placeholder UI.
              Replace with your ChatInterface component.
            </Text>
          </Box>
        </VStack>
      </Container>
    </ChakraProvider>
  );
}

export default App;
EOF

        # Add start script to package.json
        npx json -I -f package.json -e "this.scripts = { ...this.scripts, 'start': 'react-scripts start', 'build': 'react-scripts build' }"
        
        # Create .gitignore
        cat > .gitignore << 'EOF'
# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# production
/build

# misc
.DS_Store
.env.local
.env.development.local
.env.test.local
.env.production.local

npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

        # Go back to the project root directory
        cd ..
        
        echo -e "${GREEN}✅ React frontend initialized successfully.${NC}"
    else
        # If package.json exists, just install dependencies
        cd frontend
        echo -e "${CYAN}📦 Installing frontend dependencies...${NC}"
        npm install
        cd ..
        echo -e "${GREEN}✅ Frontend dependencies installed.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Skipping frontend setup.${NC}"
fi

# Create .env file for environment variables
if [ ! -f ".env" ]; then
    echo -e "${CYAN}📝 Creating .env file for environment variables...${NC}"
    cat > .env << 'EOF'
# Backend Configuration
PORT=8000
MONGODB_URI=mongodb://localhost:27017/chatbot
JWT_SECRET=your_secret_key_change_this_in_production

# Frontend Configuration
REACT_APP_API_URL=http://localhost:8000
EOF
    echo -e "${GREEN}✅ .env file created.${NC}"
fi

# Create a .gitignore file
if [ ! -f ".gitignore" ]; then
    echo -e "${CYAN}📝 Creating .gitignore file...${NC}"
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/
env/
.env

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
.pnpm-debug.log

# Build files
/build
/dist
/frontend/build

# Misc
.DS_Store
.idea/
.vscode/
*.swp
*.swo
EOF
    echo -e "${GREEN}✅ .gitignore file created.${NC}"
fi

# Create run.sh script for easier startup
echo -e "${CYAN}📝 Creating run.sh script for easier startup...${NC}"
cat > run.sh << 'EOF'
#!/bin/bash
# Run script for AI Chatbot Application

# Activate virtual environment
source venv/bin/activate

# Run the main.py script
python main.py "$@"
EOF
chmod +x run.sh
echo -e "${GREEN}✅ run.sh script created.${NC}"

# Make setup.sh and main.py executable
chmod +x main.py
chmod +x setup.sh

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "${YELLOW}To run the application:${NC}"
echo -e "${CYAN}1. Activate the virtual environment:${NC} ${MAGENTA}source venv/bin/activate${NC}"
echo -e "${CYAN}2. Start the application:${NC} ${MAGENTA}./run.sh${NC}"
echo -e "${CYAN}   - To run only the backend:${NC} ${MAGENTA}./run.sh --backend-only${NC}"
echo -e "${CYAN}   - To run only the frontend:${NC} ${MAGENTA}./run.sh --frontend-only${NC}"
echo -e "${CYAN}   - To set custom ports:${NC} ${MAGENTA}./run.sh --backend-port 8080 --frontend-port 3001${NC}"
echo -e "${BLUE}======================================================${NC}"

# Ask if the user wants to run the application now
read -p "Would you like to run the application now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}🚀 Starting the application...${NC}"
    # Make sure virtual environment is activated
    source venv/bin/activate
    # Run the main.py script
    python main.py
else
    echo -e "${CYAN}You can run the application later using:${NC} ${MAGENTA}./run.sh${NC}"
fi