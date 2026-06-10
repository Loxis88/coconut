"""
OCR module using Mistral OCR API for extracting text from PDFs.

Usage as standalone:
    python ocr_mistral.py path/to/file.pdf

Usage as module:
    from ocr_mistral import extract_text_from_pdf
    text = extract_text_from_pdf("path/to/file.pdf")
"""

import os
import hashlib
import sys
import logging
from mistralai.client import Mistral

from config import MISTRAL_API_KEY

log = logging.getLogger(__name__)
OCR_CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ocr_cache")


def extract_text_from_pdf(pdf_path: str) -> str:
    """Extract text from PDF using Mistral OCR API. Results are cached.

    Args:
        pdf_path: Path to PDF file.

    Returns:
        Extracted text from all pages combined.
    """
    import base64

    os.makedirs(OCR_CACHE_DIR, exist_ok=True)

    # Cache key based on file content hash
    with open(pdf_path, "rb") as f:
        file_bytes = f.read()
    file_hash = hashlib.md5(file_bytes).hexdigest()
    cache_path = os.path.join(OCR_CACHE_DIR, f"{file_hash}.txt")

    if os.path.exists(cache_path):
        log.info("OCR cache hit: %s", cache_path)
        with open(cache_path, "r", encoding="utf-8") as f:
            return f.read()

    pdf_b64 = base64.b64encode(file_bytes).decode()

    with Mistral(api_key=MISTRAL_API_KEY) as mistral:
        res = mistral.ocr.process(
            model="mistral-ocr-latest",
            document={
                "type": "document_url",
                "document_url": f"data:application/pdf;base64,{pdf_b64}",
            },
        )

    total_pages = len(res.pages)
    log.info("Mistral OCR: %s — %d pages", pdf_path, total_pages)
    text_parts = []
    for page in res.pages:
        if page.markdown.strip():
            log.info("  Page %d/%d: %d chars", page.index + 1, total_pages, len(page.markdown))
            text_parts.append(page.markdown.strip())
        else:
            log.info("  Page %d/%d: empty", page.index + 1, total_pages)

    result = "\n\n".join(text_parts)
    log.info("Mistral OCR done: %d/%d pages with text, total %d chars",
             len(text_parts), total_pages, len(result))

    # Save to cache
    with open(cache_path, "w", encoding="utf-8") as f:
        f.write(result)

    return result


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

    if len(sys.argv) < 2:
        print("Usage: python ocr_mistral.py <path_to_pdf>")
        sys.exit(1)

    path = sys.argv[1]
    text = extract_text_from_pdf(path)
    print(text)
