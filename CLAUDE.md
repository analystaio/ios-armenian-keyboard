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
- **venv note**: Must use Python 3.13 explicitly (system Python 3.14 breaks torch):
  ```bash
  ~/.pyenv/versions/3.13.11/bin/python3 -m venv .venv
  .venv/bin/pip install -r requirements.txt
  ```

## Word Prediction

### Architecture

The keyboard uses two prediction modes:
1. **Prefix completion** (while typing): Trie lookup from `ArmenianDictionary.swift` (1500 words)
2. **Next-word prediction** (after space): 4-gram n-gram model with backoff, LSTM as fallback

### N-gram Model (primary predictor)

- **File**: `ArmenianKeyboardExtension/armenian_ngram.json` (2.3MB)
- **Type**: 4-gram with backoff → 3-gram → 2-gram → unigram
- **Built by**: `ml_training/build_ngram.py`
- **Stats**: 15K 4-gram, 27K 3-gram, 12K 2-gram entries, top-3 predictions per context
- **Min count**: 2 (n-grams appearing only once are filtered out)
- **iOS integration**: `NGramPredictor.swift` loads JSON from bundle, `KeyboardViewController.swift` calls it in Scenario 2

**Ligature normalization**: The Armenian ев ligature (U+0587) is decomposed to delays ե (U+0565) + վ (U+057E) during tokenization, because the keyboard outputs the two letters separately. This is handled in both `build_ngram.py` and `NGramPredictor.swift`.

#### Rebuilding the n-gram model

```bash
python3 ml_training/build_ngram.py \
  --input /tmp/nazeni_cleaned_full.txt /tmp/mher_cleaned.txt /tmp/amalya_cleaned.txt \
  --output ArmenianKeyboardExtension/armenian_ngram.json \
  --top-k 3 --min-count 2
```

### Industry Standard (for reference)

Popular keyboards (Gboard, SwiftKey, Apple QuickType) use:
- **Base**: n-gram model (4-gram/5-gram with Kneser-Ney smoothing) — fast, small, works well
- **Neural layer**: lightweight LSTM or Transformer for personalization
- Gboard core = 5-gram with 1.25M entries, ~1.4MB quantized
- For Armenian, an n-gram model may outperform the current LSTM given data limitations

## Training Data

### N-gram corpus (YouTube captions — native Armenian)

Collected from Armenian YouTube interview/podcast channels. ~1.13M words, 188K sentences from 129 videos across 3 channels.

| Channel | Videos | Content |
|---------|--------|---------|
| Nazeni Hovhannisyan | ~50 | Interviews, talk show |
| Mher Baghdasaryan | ~40 | Interviews, podcasts |
| Amalya Hovhannisyan | ~39 | Interviews, conversations |

#### Data collection pipeline

1. **Scrape captions**: `ml_training/scrape_yt_channel.py` downloads Armenian auto-subtitles via yt-dlp
   ```bash
   # Downloads VTT files to ~/yt_captions/<channel>/
   python3 ml_training/scrape_yt_channel.py
   ```

2. **Clean captions**: `ml_training/clean_yt_captions.py` processes raw VTT files
   - Parses rolling cues (takes last line of each cue block to dedup)
   - Strips inline VTT tags, HTML entities, `[annotations]`
   - Filters non-Armenian lines (rejects lines with Latin characters)
   - Minimum 3 words per line
   - Optional `--remove-names` flag uses Stanza NER (`hy` model) to remove PERSON entities
   ```bash
   python3 ml_training/clean_yt_captions.py \
     --input ~/yt_captions/nazeni/*.vtt \
     --output /tmp/nazeni_cleaned.txt \
     --remove-names
   ```

3. **Build n-gram**: `ml_training/build_ngram.py` (see "Rebuilding" above)

#### Cleaned corpus files (on local Mac)

- `/tmp/nazeni_cleaned_full.txt`
- `/tmp/mher_cleaned.txt`
- `/tmp/amalya_cleaned.txt`

### Data Sources to Explore

**Armenian Wikipedia** (large, free, native text):
- Download XML dump from `dumps.wikimedia.org/hywiki/`
- Formal register but large volume (~40–60MB)

**Full OpenSubtitles Armenian corpus**:
- Only 24 files downloaded so far — thousands more available
- `opus.nlpl.eu` has the full Armenian OpenSubtitles corpus

**More YouTube channels**: ~700–1000 unique sentences per 1hr video, ~5K–8K words


