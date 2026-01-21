import os
from typing import List

from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

MODEL_NAME = os.getenv(
    "EMBEDDING_MODEL",
    "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
)
DEVICE = os.getenv("EMBEDDING_DEVICE", "cpu")

model = SentenceTransformer(MODEL_NAME, device=DEVICE)

app = FastAPI()


class EmbedRequest(BaseModel):
    texts: List[str]


@app.post("/embed")
def embed(req: EmbedRequest):
    vectors = model.encode(req.texts, normalize_embeddings=True)
    return {"embeddings": [v.tolist() for v in vectors]}


@app.get("/health")
def health():
    return {"ok": True, "model": MODEL_NAME}
