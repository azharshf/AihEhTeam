"""
Ingest knowledge base documents into ChromaDB.
Run once: python ingest.py
"""
import os
import chromadb
from chromadb.utils import embedding_functions

KNOWLEDGE_DIR = "knowledge"
CHROMA_DIR = "chroma_db"
COLLECTION_NAME = "lipidwise"
CHUNK_SIZE = 500  # characters per chunk
CHUNK_OVERLAP = 100


def chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """Split text into overlapping chunks by paragraph then by size."""
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    chunks = []
    current = ""

    for para in paragraphs:
        if len(current) + len(para) < chunk_size:
            current += "\n\n" + para if current else para
        else:
            if current:
                chunks.append(current)
            # If single paragraph is too long, split by sentences
            if len(para) > chunk_size:
                words = para.split()
                current = ""
                for word in words:
                    if len(current) + len(word) + 1 < chunk_size:
                        current += " " + word if current else word
                    else:
                        chunks.append(current)
                        # Keep overlap
                        overlap_words = current.split()[-10:]
                        current = " ".join(overlap_words) + " " + word
            else:
                current = para

    if current:
        chunks.append(current)

    return chunks


def ingest():
    # Use ChromaDB's built-in embedding (all-MiniLM-L6-v2, free, no API key)
    ef = embedding_functions.DefaultEmbeddingFunction()

    client = chromadb.PersistentClient(path=CHROMA_DIR)

    # Delete existing collection if exists, then recreate
    try:
        client.delete_collection(COLLECTION_NAME)
    except Exception:
        pass

    collection = client.create_collection(
        name=COLLECTION_NAME,
        embedding_function=ef,
        metadata={"hnsw:space": "cosine"}
    )

    all_docs = []
    all_ids = []
    all_metadata = []

    for filename in sorted(os.listdir(KNOWLEDGE_DIR)):
        if not filename.endswith(".txt"):
            continue

        filepath = os.path.join(KNOWLEDGE_DIR, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()

        chunks = chunk_text(text)
        print(f"  {filename}: {len(chunks)} chunks")

        for i, chunk in enumerate(chunks):
            doc_id = f"{filename}_{i}"
            all_docs.append(chunk)
            all_ids.append(doc_id)
            all_metadata.append({
                "source": filename,
                "chunk_index": i,
            })

    collection.add(
        documents=all_docs,
        ids=all_ids,
        metadatas=all_metadata,
    )

    print(f"\nIngested {len(all_docs)} chunks into ChromaDB collection '{COLLECTION_NAME}'")
    print(f"Stored at: {CHROMA_DIR}/")


if __name__ == "__main__":
    ingest()
