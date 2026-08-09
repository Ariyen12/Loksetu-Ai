from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import json
import os
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="Northeast Indian Languages & LokSetu AI API",
    description="API for Northeast Indian language data and AI assistant",
    version="1.1"
)

# Allow frontend to communicate with backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Robust path resolution for language data
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, "languages.json")

languages = []
if os.path.exists(DATA_FILE):
    with open(DATA_FILE, "r", encoding="utf-8") as file:
        languages = json.load(file)


# Home / Health check
@app.get("/")
def home():
    return {
        "status": "online",
        "message": "Northeast Indian Languages & LokSetu AI API is running",
        "version": "1.1",
        "total_languages": len(languages)
    }


# Health endpoint for cloud deployments
@app.get("/health")
def health():
    return {"status": "healthy"}


# Get all languages
@app.get("/languages")
def get_languages():
    return languages


# Get one language
@app.get("/languages/{language_name}")
def get_language(language_name: str):
    for language in languages:
        if language["name"].lower() == language_name.lower():
            return language

    raise HTTPException(
        status_code=404,
        detail="Language not found"
    )


# Get basic phrases
@app.get("/languages/{language_name}/phrases")
def get_phrases(language_name: str):
    for language in languages:
        if language["name"].lower() == language_name.lower():
            return {
                "language": language["name"],
                "phrases": language["phrases"]
            }

    raise HTTPException(
        status_code=404,
        detail="Language not found"
    )


# Translate a phrase from stored data with optional dynamic AI fallback
@app.get("/translate")
def translate(
    language: str,
    english: str,
    use_ai_fallback: bool = True
):
    # 1. Search local dictionary
    for lang in languages:
        if lang["name"].lower() == language.lower():
            for phrase in lang["phrases"]:
                if phrase["english"].lower() == english.lower():
                    return {
                        "language": lang["name"],
                        "english": phrase["english"],
                        "translation": phrase["translation"],
                        "source": "dictionary"
                    }

    # 2. Dynamic AI fallback if Gemini API Key is available
    gemini_key = os.getenv("GEMINI_API_KEY")
    if use_ai_fallback and gemini_key:
        try:
            from google import genai
            client = genai.Client(api_key=gemini_key)
            prompt = f"Translate the following English phrase accurately into {language}: '{english}'. Return ONLY the direct translation, nothing else."
            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
            )
            if response and response.text:
                return {
                    "language": language,
                    "english": english,
                    "translation": response.text.strip(),
                    "source": "gemini_ai"
                }
        except Exception as e:
            pass

    raise HTTPException(
        status_code=404,
        detail="Translation not found"
    )


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host=host, port=port)
