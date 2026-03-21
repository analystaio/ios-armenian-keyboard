# CLAUDE.md

The task is to develop an iOS app that adds a Armenian keyboard with a word suggestion bar.

## Notes

- When unsure about something do websearch and also ask codex `codex --config model_reasoning_effort="high" exec "<your question>"`
- Ask questions to clarify unknowns. Strive not to make assumptions

## Arch Linux Training Machine

The user has an Arch Linux machine with an NVIDIA RTX 3060 (12GB VRAM) for training ML models.

### Connection Details

- **Hostname**: `archpc.lan` (or `192.168.1.112`)
- **Username**: `varant`
- **SSH**: `ssh varant@archpc.lan`

### ML Training Environment

- **Working directory**: `/home/varant/ml_training/`
- **Virtual environment**: `/home/varant/ml_training/.venv/`
- **PyTorch version**: 2.5.1+cu121 (CUDA enabled)

### Directory Structure on Arch Machine

```
/home/varant/ml_training/
├── .venv/                    # Python virtual environment
├── data/
│   ├── combined_v2_train.txt # Training data (29MB, 229K lines)
│   ├── combined_v2_test.txt  # Test data (864KB, 11K lines)
│   └── ...
├── models/                   # Saved model checkpoints
├── hyperparam_tuning.py      # Hyperparameter search script
├── train_conversational.py   # Main training script
└── tuning.log               # Training output log
```

### Running Training Jobs

```bash
# Copy scripts to Arch machine
scp ml_training/hyperparam_tuning.py varant@archpc.lan:~/ml_training/

# Start training in background (persists after SSH disconnect)
ssh varant@archpc.lan "cd ~/ml_training && source .venv/bin/activate && nohup python hyperparam_tuning.py > tuning.log 2>&1 &"

# Check if training is running
ssh varant@archpc.lan "ps aux | grep python | grep -v grep"

# Monitor training progress
ssh varant@archpc.lan "tail -50 ~/ml_training/tuning.log"

# Check GPU utilization
ssh varant@archpc.lan "nvidia-smi"

# View hyperparameter tuning results
ssh varant@archpc.lan "cat ~/ml_training/models/tuning_results.json"
```

### Retrieving Trained Models

```bash
# Copy best model back to Mac
scp varant@archpc.lan:~/ml_training/models/tuning_best_*.pth ml_training/models/
scp varant@archpc.lan:~/ml_training/models/tuning_tokenizer_*.pkl ml_training/models/
scp varant@archpc.lan:~/ml_training/models/tuning_results.json ml_training/models/
```

### Converting to CoreML (on Mac)

After retrieving the best model, convert to CoreML for iOS:

```bash
cd ml_training
source .venv/bin/activate
python convert_conversational_to_coreml.py
```

Then copy `models/ArmenianPredictor.mlpackage` and `models/vocabulary.json` to the Xcode project.

### venv note

The venv must be created with Python 3.13 explicitly — the system Python is 3.14 which breaks torch:

```bash
~/.pyenv/versions/3.13.11/bin/python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## ML Model

### Current Model

- **Architecture**: LSTM (embedding 128 → LSTM 256 hidden, 2 layers → softmax)
- **Vocabulary**: 5,000 words
- **Sequence length**: 5 tokens
- **Accuracy**: top-1 ~37%, top-3 ~52%
- **CoreML model**: `ArmenianKeyboardExtension/models/ArmenianPredictor.mlpackage`
- **iOS integration**: `MLPredictor.swift` — used for next-word prediction after space; Trie used for prefix completion while typing

### Industry Standard (for reference)

Popular keyboards (Gboard, SwiftKey, Apple QuickType) use:
- **Base**: n-gram model (4-gram/5-gram with Kneser-Ney smoothing) — fast, small, works well
- **Neural layer**: lightweight LSTM or Transformer for personalization
- Gboard core = 5-gram with 1.25M entries, ~1.4MB quantized
- For Armenian, an n-gram model may outperform the current LSTM given data limitations

### Training Data

Current combined dataset: `combined_v2_train.txt` — 229K lines, ~2.3M tokens, 28MB

| Source | Size | Quality | Notes |
|--------|------|---------|-------|
| HAG corpus | 90K lines, 6.5MB | Machine-translated | Sentences translated to Armenian |
| OpenSubtitles | 24 files, ~288K words | Possibly machine-translated | Subtitle dialogue |
| Synthetic v2 | ~4,980 files | Synthetic | Generated sentences |

**Data quality issue**: Most data is machine-translated from English, teaching the model English word order in Armenian. This limits prediction quality.

### Data Sources to Explore

**YouTube auto-captions** (best option for native conversational Armenian):
- Use `yt-dlp --write-auto-sub --sub-lang hy --sub-format vtt --skip-download`
- Armenian channels (1lurer, CivilNet Armenian content, Azatutyun) have hours of native speech
- ~700–1000 unique sentences per 1hr video, ~5K–8K words
- Need ~150–200 videos for 1M tokens
- Filter out English-language segments with Armenian character check
- Strip VTT timestamps/tags, dedup rolling subtitle lines

**Armenian Wikipedia** (large, free, native text):
- Download XML dump from `dumps.wikimedia.org/hywiki/`
- Formal register but large volume (~40–60MB)

**Full OpenSubtitles Armenian corpus**:
- Only 24 files downloaded so far — thousands more available
- `opus.nlpl.eu` has the full Armenian OpenSubtitles corpus


