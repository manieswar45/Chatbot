from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
from datetime import datetime, timedelta
import os
import motor.motor_asyncio
import jwt
from transformers import pipeline
import time

# Initialize FastAPI app
app = FastAPI(title="AI Chatbot API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
client = motor.motor_asyncio.AsyncIOMotorClient(MONGODB_URI)
db = client.chatbot

# JWT Authentication
SECRET_KEY = os.getenv("JWT_SECRET", "your_secret_key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Load AI model
try:
    model = pipeline("text-generation", model="distilgpt2")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

# Models
class Message(BaseModel):
    message: str

class UserCreate(BaseModel):
    username: str
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class ChatResponse(BaseModel):
    message: str

class ChatHistory(BaseModel):
    id: str
    user_message: str
    bot_response: str
    timestamp: datetime

# Rate limiting
class RateLimiter:
    def __init__(self, requests_per_minute=60):
        self.requests_per_minute = requests_per_minute
        self.requests = {}
        
    async def check(self, client_ip: str) -> bool:
        current_time = time.time()
        if client_ip in self.requests:
            request_times = self.requests[client_ip]
            # Remove requests older than 1 minute
            request_times = [t for t in request_times if current_time - t < 60]
            if len(request_times) >= self.requests_per_minute:
                return False
            request_times.append(current_time)
            self.requests[client_ip] = request_times
        else:
            self.requests[client_ip] = [current_time]
        return True

rate_limiter = RateLimiter()

# Authentication functions
async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
    user = await db.users.find_one({"username": username})
    if user is None:
        raise credentials_exception
    return user

# Middleware
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host
    if not await rate_limiter.check(client_ip):
        raise HTTPException(status_code=429, detail="Too many requests")
    response = await call_next(request)
    return response

# Routes
@app.post("/api/chat", response_model=ChatResponse)
async def chat(message: Message, user=Depends(get_current_user)):
    if not model:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Process with model
        result = model(message.message, max_length=100, do_sample=True, temperature=0.7)
        bot_response = result[0]["generated_text"]
        
        # Save to database
        await db.conversations.insert_one({
            "user_id": str(user["_id"]),
            "user_message": message.message,
            "bot_response": bot_response,
            "timestamp": datetime.now()
        })
        
        return {"message": bot_response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/register")
async def register(user: UserCreate):
    # Check if username exists
    if await db.users.find_one({"username": user.username}):
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # Create user
    hashed_password = user.password  # In production, hash the password!
    user_data = {
        "username": user.username,
        "email": user.email,
        "password": hashed_password,
        "created_at": datetime.now()
    }
    await db.users.insert_one(user_data)
    return {"message": "User created successfully"}

@app.post("/api/login", response_model=Token)
async def login(username: str, password: str):
    user = await db.users.find_one({"username": username})
    if not user or user["password"] != password:  # In production, verify hashed password
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    expires = datetime.utcnow() + access_token_expires
    
    payload = {
        "sub": username,
        "exp": expires
    }
    access_token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/history", response_model=List[ChatHistory])
async def get_history(user=Depends(get_current_user)):
    user_id = str(user["_id"])
    cursor = db.conversations.find({"user_id": user_id}).sort("timestamp", -1).limit(50)
    history = []
    async for doc in cursor:
        history.append({
            "id": str(doc["_id"]),
            "user_message": doc["user_message"],
            "bot_response": doc["bot_response"],
            "timestamp": doc["timestamp"]
        })
    return history

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)