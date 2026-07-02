"""Deep Knowledge Tracing (DKT) model with an LSTM.

Architecture (Piech et al., 2015)
---------------------------------
1. Input  : one-hot encoding of (question_id, correctness) at each
   timestep -> ``2 * n_questions`` features per step.
   Position ``q`` marks "question q was asked".
   Position ``n_questions + q`` marks "question q was answered correctly".
2. LSTM   : 200 hidden units (single layer, batch_first=True).
3. Head   : LayerNorm + Dropout + Linear -> sigmoid.
4. Output : ``(batch, seq, n_questions)`` tensor where ``output[t, q]``
   is the model's estimate of ``P(correct on question q at step t+1)``
   given the history observed up to and including step ``t``.

The output is therefore a **next-step** prediction: to know how the
student will do on the next question, we read ``output[t, q_next]``.

Modifications modernes (vs. papier original) :
- Dropout 0.5 entre LSTM et Dense.
- LayerNorm pour stabiliser l'entraînement.
- Pas de couche LSTM bidirectionnelle (conforme au papier original :
  la prediction future ne doit pas voir le futur de la séquence).
"""

from __future__ import annotations

from typing import Sequence

import torch
import torch.nn as nn


class DKTModel(nn.Module):
    """LSTM-based Deep Knowledge Tracing model.

    Parameters
    ----------
    n_questions:
        Number of distinct questions in the bank.
    hidden_dim:
        Hidden size of the LSTM (200 in the original paper).
    dropout:
        Dropout rate applied between the LSTM and the output head.
    """

    def __init__(
        self,
        n_questions: int,
        hidden_dim: int = 200,
        dropout: float = 0.5,
    ) -> None:
        super().__init__()
        self.n_questions = int(n_questions)
        self.hidden_dim = int(hidden_dim)

        # Dimension d'entree : one-hot de (question, correct) -> 2 * n_questions.
        # Ex : question 5 correcte  -> [0,0,0,0,0,1,0,...,0, 0,0,0,0,0,1,0,...,0]
        #      question 5 incorrecte -> [0,0,0,0,0,1,0,...,0, 0,0,0,0,0,0,0,...,0]
        self.input_dim = 2 * self.n_questions

        self.lstm = nn.LSTM(
            input_size=self.input_dim,
            hidden_size=hidden_dim,
            num_layers=1,
            batch_first=True,
            dropout=0.0,  # Pas de dropout inter-layer avec 1 seule couche.
        )

        self.layer_norm = nn.LayerNorm(hidden_dim)
        self.dropout = nn.Dropout(dropout)

        # Sortie : probabilite de reussite pour chaque question au prochain pas.
        self.output_layer = nn.Linear(hidden_dim, self.n_questions)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass.

        Parameters
        ----------
        x:
            Tensor of shape ``(batch, seq_length, 2 * n_questions)``.

        Returns
        -------
        torch.Tensor
            Tensor of shape ``(batch, seq_length, n_questions)`` where
            each entry is a ``P(correct)`` in ``[0, 1]``.
        """
        lstm_out, _ = self.lstm(x)            # (batch, seq, hidden)
        lstm_out = self.layer_norm(lstm_out)  # normalisation par timestep
        lstm_out = self.dropout(lstm_out)
        output = self.sigmoid(self.output_layer(lstm_out))
        return output                          # (batch, seq, n_questions)

    # ------------------------------------------------------------------
    # Helpers d'inference (single sequence, CPU-friendly)
    # ------------------------------------------------------------------

    def predict_next(
        self,
        sequence: Sequence[tuple[int, int]],
    ) -> torch.Tensor:
        """Predict ``P(correct)`` for every possible next question.

        Parameters
        ----------
        sequence:
            Ordered list of ``(question_idx, correct)`` tuples describing
            what the student has answered so far.

        Returns
        -------
        torch.Tensor
            1-D tensor of length ``n_questions`` containing
            ``P(correct)`` for each possible next question.
        """
        if len(sequence) == 0:
            # Sans historique, on retourne une probabilite a priori uniforme.
            return torch.full((self.n_questions,), 0.5)

        self.eval()
        with torch.no_grad():
            x = self._encode_sequence(sequence).unsqueeze(0)  # (1, T, 2*n_q)
            output = self.forward(x)                          # (1, T, n_q)
            # Dernier timestep = prediction pour le prochain instant.
            last_output = output[0, -1, :]                    # (n_questions,)
            return last_output.detach().cpu()

    def _encode_sequence(
        self,
        sequence: Sequence[tuple[int, int]],
    ) -> torch.Tensor:
        """Encode a variable-length sequence as an LSTM input tensor.

        Parameters
        ----------
        sequence:
            List of ``(question_idx, correct)`` tuples.

        Returns
        -------
        torch.Tensor
            Float tensor of shape ``(seq_length, 2 * n_questions)``.
        """
        seq_length = len(sequence)
        encoded = torch.zeros(seq_length, self.input_dim, dtype=torch.float32)
        for t, (q_idx, correct) in enumerate(sequence):
            encoded[t, q_idx] = 1.0  # one-hot de la question posee
            if correct:
                encoded[t, self.n_questions + q_idx] = 1.0  # one-hot du resultat
        return encoded
