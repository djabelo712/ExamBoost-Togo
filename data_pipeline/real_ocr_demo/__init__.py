"""Pipeline OCR reel sur 5 PDFs d'annales BEPC simulés.

Sous-module autonomme du data_pipeline ExamBoost Togo. Demontre de bout en
bout le flux: PDF (ReportLab) -> image (pdf2image) -> texte (Tesseract fra)
-> JSON structure -> validation. Aucune dependance aux autres modules du
data_pipeline (config.py, utils/) pour rester isolé et réutilisable.
"""
