# CLAUDE.md

The task is to develop an iOS app that adds a Armenian keyboard with a word suggestion bar.

## Notes

- When unsure about something do websearch
- Ask questions to clarify unknowns. Strive not to make assumptions

## ML training and data

Model training, corpus building and the Western Armenian lexicon pipeline live in a separate
private `armenian-nlp` repo, not here. This repo only ships the built artifacts
(`armenian_ngram.json`, `western_ngram.json`, `western_words.tsv`).

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



## Western Armenian mode (in progress, started 2026-09-20)

Goal: a Western Armenian (classical orthography) variant of both predictors. Toggle lives in the
container app's settings or as a second keyboard — never as an on-keyboard control. User learning
(on-device frequency bumps for typed/accepted words) is planned for both dialects.

### Data (kept in the `armenian-nlp` repo under `data/western/`)

| Source | Use | License |
|---|---|---|
| Nayiri Armenian Lexicon v3 (2026-04-25, nayiri.com) | 7.5K lexemes / 1.6M inflected forms, 709 inflection tags; completion vocabulary + periphrastic verb bigrams | CC BY 4.0 (credit "Nayiri Armenian Lexicon © Serouj Ourishian") |
| UD_Western_Armenian-ArmTDP treebank | 100K tokens; form/lemma frequencies, sentences for n-gram | CC BY-SA 4.0 |
| Western Armenian Wikipedia dump (hywwiki) | 3.7M cleaned words; n-gram corpus | CC BY-SA 4.0 |
| hyw-en parallel corpus (AriNubar) | cleaned to `corpus/parallel_nc_clean.txt` but NOT in the default build | CC BY-NC-SA 4.0 — non-commercial, keep out of shipped models |

### Build scripts (in the `armenian-nlp` repo)

```bash
D=data/western   # run from the armenian-nlp checkout
# 1. completion dictionary: western_words.tsv (120K forms, "form<TAB>score 1..255", code-point sorted)
#    + western_bigrams.tsv (Nayiri periphrastic pairs)
python3 build_western_lexicon.py --nayiri $D/nayiri-armenian-lexicon-2026-04-25-v3.json \
  --conllu $D/hyw_armtdp-ud-*.conllu --outdir $D/out
# 2. corpus: wiki dump -> raw paragraphs -> cleaned segments
python3 extract_hywwiki.py $D/corpus/hywwiki-latest-pages-articles.xml.bz2 $D/corpus/hywwiki_raw.txt
python3 clean_western_corpus.py --input $D/corpus/hywwiki_raw.txt --output $D/corpus/hywwiki_clean.txt
python3 clean_western_corpus.py --input $D/corpus/armtdp_sentences.txt --output $D/corpus/armtdp_clean.txt
# 3. n-gram (same JSON shape as armenian_ngram.json): 3.3MB, 4K 4-gram / 35K 3-gram / 30K 2-gram
python3 build_western_ngram.py --input $D/corpus/hywwiki_clean.txt $D/corpus/armtdp_clean.txt \
  --output $D/out/western_ngram.json --lexicon-bigrams $D/out/western_bigrams.tsv --min-count 3 --min-count-4 5
```

Scoring in `build_western_lexicon.py`: `(2·log1p(form_count) + log1p(lemma_count)) × slot_weight`,
where slot_weight is a hand table over Nayiri's inflection tags (nominative/present = 1.0,
possessive-suffixed oblique plurals ≈ 0.1). All lemma citation forms are force-kept.

### Notes for the app side (step 4, not started)

- Forms like `կ՚ըսէ` are single entries with U+055A apostrophe; normalize `'` and `’` to U+055A on input.
- The corpus is formal register (encyclopedia/press). Conversational contexts are thin; user learning matters more here than for Eastern.
- The current `Trie` (class node + dictionary per char) cannot hold 120K forms in a keyboard extension; use a sorted-array binary search or a serialized compact trie loaded from the bundle.
