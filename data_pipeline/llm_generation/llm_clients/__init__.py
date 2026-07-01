"""Wrappers homogenes pour les 3 LLM utilises par le pipeline.

Chaque client expose une API unique:
    client = XxxClient()
    questions = await client.generate_questions(prompt_template, count)

Tous les clients:
    - retournent List[Dict] (liste de questions au format ExamBoost)
    - gerent les retry avec backoff exponentiel
    - respectent un rate limit conservateur
    - loggent leur usage + couts estimes
"""

from __future__ import annotations

__all__ = ["ClaudeClient", "OpenAIClient", "MistralClient"]
