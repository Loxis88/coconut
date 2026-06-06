"""
OCR module for extracting text from image-based PDFs.

Usage as standalone:
    python ocr_pdf.py path/to/file.pdf

Usage as module:
    from ocr_pdf import extract_text_from_pdf
    text = extract_text_from_pdf("path/to/file.pdf")
"""

import sys
import logging
import numpy as np
import pypdfium2 as pdfium
import easyocr

log = logging.getLogger(__name__)

reader = None


def get_reader():
    global reader
    if reader is None:
        reader = easyocr.Reader(["ru", "en"], gpu=True)
    return reader


def extract_text_from_pdf(pdf_path: str) -> str:
    """Extract text from all pages of a PDF using EasyOCR.

    Args:
        pdf_path: Path to PDF file.

    Returns:
        Extracted text from all pages combined.
    """
    ocr = get_reader()
    pdf = pdfium.PdfDocument(pdf_path)
    total_pages = len(pdf)
    log.info("PDF %s: %d pages", pdf_path, total_pages)
    text_parts = []

    for i in range(total_pages):
        page = pdf[i]
        bitmap = page.render(scale=2)
        img = bitmap.to_pil()
        img_np = np.array(img)
        results = ocr.readtext(img_np, detail=0, paragraph=True)
        page_text = "\n".join(results)
        if page_text.strip():
            text_parts.append(page_text.strip())
            log.info("  Page %d/%d: %d chars extracted", i + 1, total_pages, len(page_text))
        else:
            log.info("  Page %d/%d: empty (no text found)", i + 1, total_pages)

    pdf.close()
    log.info("PDF done: %d pages with text out of %d", len(text_parts), total_pages)
    return "\n\n".join(text_parts)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ocr_pdf.py <path_to_pdf>")
        sys.exit(1)

    path = sys.argv[1]
    text = extract_text_from_pdf(path)
    print(text)
