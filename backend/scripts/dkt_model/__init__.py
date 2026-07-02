"""DKT (Deep Knowledge Tracing) package for ExamBoost Togo.

Implementation of Deep Knowledge Tracing with an LSTM, following
Piech et al. (2015) "Deep Knowledge Tracing" (NeurIPS).

This package provides a modern neural alternative to the classical
Bayesian Knowledge Tracing (BKT) used elsewhere in the project
(``lib/models/user.dart`` and ``backend/services/bkt_service.py``).

Modules
-------
generate_sequences
    Build a synthetic dataset of student trajectories (IRT 3PL + learning).
dkt_model
    PyTorch LSTM model definition.
train_dkt
    Training loop with early stopping.
evaluate_dkt
    Evaluation against BKT (AUC, accuracy, log-loss, F1) + ROC curves.
convert_to_onnx
    Export the trained model to ONNX for on-device Flutter inference.

Typical workflow
----------------
    python generate_sequences.py
    python train_dkt.py
    python evaluate_dkt.py
    python convert_to_onnx.py
"""

__version__ = "1.0.0"
