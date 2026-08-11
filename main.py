from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import os
import urllib.request
import urllib.parse
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="LokSetu AI Universal Multilingual API",
    description="Universal API supporting ANY language translation and question answering",
    version="2.0"
)

# Allow frontend & external clients to communicate with backend
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


class ChatRequest(BaseModel):
    message: str
    language: Optional[str] = "English"
    category: Optional[str] = "General"
    api_key: Optional[str] = None


class TranslationRequest(BaseModel):
    text: str
    target_language: str
    source_language: Optional[str] = "Auto"


def query_wikipedia(query: str, lang: str = "en") -> Optional[str]:
    """Fetches concise Wikipedia article summary with proper User-Agent header"""
    try:
        lang_code = "en"
        lower_lang = lang.lower()
        if "hindi" in lower_lang or "हिंदी" in lower_lang: lang_code = "hi"
        elif "bengali" in lower_lang or "বাংলা" in lower_lang: lang_code = "bn"
        elif "assamese" in lower_lang or "অসমীয়া" in lower_lang: lang_code = "as"

        # Search summary
        clean_q = urllib.parse.quote(query.strip())
        url = f"https://{lang_code}.wikipedia.org/api/rest_v1/page/summary/{clean_q}"
        req = urllib.request.Request(url, headers={
            'User-Agent': 'LokSetuAI/2.0 (https://github.com/Ariyen12/Loksetu-Ai)',
            'Accept': 'application/json'
        })
        with urllib.request.urlopen(req, timeout=3) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode('utf-8'))
                extract = data.get('extract')
                if extract:
                    sentences = extract.split('. ')
                    return '. '.join(sentences[:2]) + '.'
    except Exception:
        pass
    return None


def query_gemini_ai(prompt: str, language: str, api_key: Optional[str] = None) -> Optional[str]:
    """Queries Google Gemini API for intelligent open-domain answers"""
    key = api_key or os.getenv("GEMINI_API_KEY")
    if not key:
        return None
    try:
        from google import genai
        client = genai.Client(api_key=key)
        system_prompt = (
            f"You are LokSetu AI. Answer the user question accurately in {language} in 1 to 3 polite sentences. "
            "Do NOT include markdown formatting or boilerplate intros."
        )
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=f"{system_prompt}\n\nUser Question: {prompt}",
        )
        if response and response.text:
            return response.text.strip()
    except Exception:
        pass
    return None


# Home / Health check
@app.get("/")
def home():
    return {
        "status": "online",
        "message": "LokSetu AI Universal Multilingual API is active",
        "version": "2.0",
        "capabilities": [
            "Universal Language Translation",
            "Open-Domain Question Answering",
            "Northeast Indian Languages Support",
            "Gemini AI Integration"
        ],
        "total_languages": len(languages)
    }


# Health check for cloud deployments
@app.get("/health")
def health():
    return {"status": "healthy"}


# Get all languages
@app.get("/languages")
def get_languages():
    return languages


# Universal Question Answering Endpoint (GET)
@app.get("/ask")
def ask_question(
    q: str = Query(..., description="User question in any language"),
    language: str = Query("English", description="Target response language"),
    api_key: Optional[str] = Query(None, description="Optional Google Gemini API Key")
):
    trimmed = q.strip()
    if not trimmed:
        raise HTTPException(status_code=400, detail="Query string cannot be empty")

    # 1. Try Gemini AI
    ai_answer = query_gemini_ai(trimmed, language, api_key)
    if ai_answer:
        return {
            "query": trimmed,
            "language": language,
            "answer": ai_answer,
            "source": "Google Gemini AI"
        }

    # 2. Try Wikipedia Knowledge
    wiki_answer = query_wikipedia(trimmed, language)
    if wiki_answer:
        return {
            "query": trimmed,
            "language": language,
            "answer": f"{wiki_answer} 🙏✨",
            "source": "Wikipedia Knowledge Engine"
        }

    # 3. Contextual Universal Multilingual Engine
    lower = trimmed.lower()
    if "sky" in lower or "aasmaan" in lower or "akax" in lower:
        ans = "The sky appears blue because of Rayleigh scattering. Earth's atmosphere scatters shorter blue light wavelengths from the Sun more than longer red light wavelengths. 🙏✨"
    elif "rain" in lower or "baarish" in lower or "cloud" in lower:
        ans = "Rain occurs when water vapor in clouds condenses into heavier water droplets that fall due to gravity. 🌧️🙏"
    elif "sun" in lower or "suraj" in lower:
        ans = "The Sun is a yellow dwarf star at the center of our solar system that provides light and heat to Earth. ☀️✨"
    elif "moon" in lower or "chand" in lower:
        ans = "The Moon is Earth's natural satellite that orbits Earth every 27.3 days. 🌙✨"
    elif "crop" in lower or "kheti" in lower or "fasal" in lower or "pest" in lower:
        ans = f"Regarding '{trimmed}': For best crop yield and pest protection, spray Neem Oil (5ml/L) or consult Krishi Vigyan Kendra. Call Kisan Helpline at 1800-180-1551. 🌾🙏"
    elif "health" in lower or "doctor" in lower or "bimar" in lower or "fever" in lower:
        ans = f"Regarding healthcare for '{trimmed}': Consult doctors online for free via eSanjeevani (esanjeevaniopd.in). For emergencies dial 108. 🏥🌸"
    elif "scheme" in lower or "yojana" in lower or "pm" in lower:
        ans = f"Regarding government welfare for '{trimmed}': Top schemes include Ayushman Bharat (₹5 Lakh health cover) and PM-Kisan (₹6,000/year). Apply at your local CSC. 📜✨"
    else:
        ans = f"Regarding '{trimmed}': LokSetu AI provides comprehensive guidance for science, agriculture, healthcare, education, and government welfare schemes. 🙏✨"

    return {
        "query": trimmed,
        "language": language,
        "answer": ans,
        "source": "LokSetu AI Engine"
    }



# Universal Chat Endpoint (POST)
@app.post("/chat")
def chat(req: ChatRequest):
    return ask_question(q=req.message, language=req.language or "English", api_key=req.api_key)


# Universal Translation Endpoint (GET & POST)
@app.get("/translate")
def translate(
    language: str,
    english: str,
    api_key: Optional[str] = None
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

    # 2. Dynamic AI Translation via Gemini
    ai_translation = query_gemini_ai(f"Translate into {language}: '{english}'", language, api_key)
    if ai_translation:
        return {
            "language": language,
            "english": english,
            "translation": ai_translation,
            "source": "Google Gemini AI"
        }

    # 3. Fallback Wikipedia / Knowledge Translation
    wiki = query_wikipedia(english, language)
    if wiki:
        return {
            "language": language,
            "english": english,
            "translation": wiki,
            "source": "Wikipedia Engine"
        }

    return {
        "language": language,
        "english": english,
        "translation": f"[{language}] {english}",
        "source": "LokSetu AI Fallback"
    }


@app.post("/translate")
def translate_post(req: TranslationRequest):
    return translate(language=req.target_language, english=req.text)


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host=host, port=port)

