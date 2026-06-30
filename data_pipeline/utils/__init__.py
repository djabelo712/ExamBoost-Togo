"""
Paquet utilitaire du pipeline OCR ExamBoost Togo.

Regroupe les helpers bas niveau (PDF, Tesseract, OpenAI, JSON) afin de garder
les scripts d'orchestration lisibles et testables.
"""

from utils.pdf_utils import (
    convert_pdf_to_images,
    count_pdf_pages,
    save_page_image,
)
from utils.tesseract_utils import (
    run_tesseract,
    detect_math_content,
    normalize_tesseract_text,
)
from utils.openai_utils import (
    openai_vision_ocr,
    openai_structure_questions,
    estimate_vision_cost,
)
from utils.json_utils import (
    QuestionSchemaError,
    build_question_id,
    normalize_enonce,
    validate_question_dict,
    load_questions,
    save_questions,
    merge_questions,
)

__all__ = [
    # pdf_utils
    "convert_pdf_to_images",
    "count_pdf_pages",
    "save_page_image",
    # tesseract_utils
    "run_tesseract",
    "detect_math_content",
    "normalize_tesseract_text",
    # openai_utils
    "openai_vision_ocr",
    "openai_structure_questions",
    "estimate_vision_cost",
    # json_utils
    "QuestionSchemaError",
    "build_question_id",
    "normalize_enonce",
    "validate_question_dict",
    "load_questions",
    "save_questions",
    "merge_questions",
]
