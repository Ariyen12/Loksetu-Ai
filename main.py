from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import json
import os

# Create FastAPI app
app = FastAPI(
    title="Northeast Indian Languages API",
    description="API for Northeast Indian language data",
    version="1.0"
)

# Allow frontend to communicate with backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load language data
DATA_FILE = "languages.json"

with open(DATA_FILE, "r", encoding="utf-8") as file:
    languages = json.load(file)


# Home
@app.get("/")
def home():
    return {
        "message": "Northeast Indian Languages API is running"
    }


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


# Translate a phrase from stored data
@app.get("/translate")
def translate(
    language: str,
    english: str
):

    for lang in languages:

        if lang["name"].lower() == language.lower():

            for phrase in lang["phrases"]:

                if phrase["english"].lower() == english.lower():

                    return {
                        "language": lang["name"],
                        "english": phrase["english"],
                        "translation": phrase["translation"]
                    }

    raise HTTPException(
        status_code=404,
        detail="Translation not found"
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)