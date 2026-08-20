#!/usr/bin/env bash
# Lite path: pure Python, in-process Qdrant, SQLite Feast online store.
# No Docker, no GPU, no external services. ~60s on a clean machine.

set -euo pipefail

echo "[lite] Day 19 lightweight setup"
echo "[lite] Stack: fastembed + qdrant-client[memory] + rank-bm25 + feast(sqlite) + FastAPI"
echo

# ── 1. Python ───────────────────────────────────────────────────────────
command -v python3 >/dev/null 2>&1 || { echo "[lite] python3 not found. Install Python 3.10+."; exit 1; }
PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "[lite] system python3 is $PY_VER (the venv may differ — reported below)"

# ── 2. venv ─────────────────────────────────────────────────────────────
if [ ! -d ".venv" ]; then
  if command -v uv >/dev/null 2>&1; then
    echo "[lite] Creating venv with uv (faster)"
    uv venv .venv
  else
    echo "[lite] Creating venv with python -m venv"
    python3 -m venv .venv
  fi
fi
# Activate venv on Linux/WSL or Windows/Git Bash
if [ -f ".venv/bin/activate" ]; then
  source .venv/bin/activate
elif [ -f ".venv/Scripts/activate" ]; then
  source .venv/Scripts/activate
else
  echo "[lite] Cannot find venv activation script"
  exit 1
fi

# ── 3. Install deps ─────────────────────────────────────────────────────
# `uv venv` may pick a different interpreter than the system `python3`, so the
# dill decision must be made from the VENV's Python (already active here), not
# from the version printed above.
if [ -f ".venv/Scripts/python.exe" ]; then
  VENV_PY=".venv/Scripts/python.exe"
  VENV_PIP=".venv/Scripts/pip.exe"
else
  VENV_PY=".venv/bin/python"
  VENV_PIP=".venv/bin/pip"
fi

VENV_PY_VER=$("$VENV_PY" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
NEED_DILL_OVERRIDE=$("$VENV_PY" -c 'import sys; print(1 if sys.version_info >= (3,14) else 0)')

echo "[lite] venv Python $VENV_PY_VER"

if [ "$NEED_DILL_OVERRIDE" = "1" ]; then
  echo "[lite] Python >= 3.14 -> applying dill>=0.4 override (feast's pin is too old; see requirements.txt)"
fi

if command -v uv >/dev/null 2>&1; then
  if [ "$NEED_DILL_OVERRIDE" = "1" ]; then
    uv pip install --python "$VENV_PY" --overrides overrides-py314.txt -r requirements.txt
  else
    uv pip install --python "$VENV_PY" -r requirements.txt
  fi
else
  "$VENV_PY" -m pip install -q -U pip
  "$VENV_PY" -m pip install -q -r requirements.txt

  if [ "$NEED_DILL_OVERRIDE" = "1" ]; then
    "$VENV_PY" -m pip install -q --upgrade 'dill>=0.4,<1.0'
  fi
fi



# ── 4. Convert Jupytext sources to .ipynb ───────────────────────────────
# `_setup.py` is a helper module, not a notebook -- converting it produces
# a _setup.ipynb that fails on execute. Only convert numbered notebooks.
"$VENV_PY" -m jupytext --to notebook --update notebooks/[0-9]*.py 2>/dev/null || "$VENV_PY" -m jupytext --to notebook notebooks/[0-9]*.py

# ── 4b. Register a venv-specific Jupyter kernel ─────────────────────────
# The default "python3" kernelspec (registered by whichever Python installed
# ipykernel last -- often a system/Anaconda install, not this venv) launches
# via a bare `python` looked up on PATH at kernel-start time. That silently
# picks up the wrong interpreter (missing this project's deps) whenever PATH
# ordering differs from expectation -- e.g. under `make`, which spawns its
# recipe shell with its own environment. Registering under a distinct name
# with an absolute interpreter path removes that ambiguity entirely.
"$VENV_PY" -m ipykernel install --user --name=day19-lite --display-name="Day19 lite (.venv)" >/dev/null

# ── 5. .env scaffold ────────────────────────────────────────────────────
[ -f .env ] || cp .env.example .env

# ── 6. Seed corpus + golden set ─────────────────────────────────────────
"$VENV_PY" scripts/seed_corpus.py

# Data for the advanced missions (NB6 compound queries, NB8 spend parquet).
# gen_agent_queries embeds the corpus once to build brute-force ground truth,
# so this adds ~20 s -- worth it: the alternative is students hand-labelling.
echo "  · seeding advanced-mission data (NB6 + NB8)…"
"$VENV_PY" scripts/gen_agent_queries.py
"$VENV_PY" scripts/gen_spend.py

# ── 7. Smoke test ───────────────────────────────────────────────────────
"$VENV_PY" scripts/verify_lite.py

cat <<EOF

[lite] Done. Activate the venv and start working:

    source .venv/bin/activate
    make api       # start FastAPI on :8000
    make lab       # open Jupyter on :8888
    make benchmark # Precision@10 + latency table

Tip: read VIBE-CODING.md before starting NB1 -- it tells you what to delegate
to your AI assistant and what to think through yourself.
EOF
