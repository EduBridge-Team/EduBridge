# Palestinian Sign Language (PSL) dataset integration

EduBridge includes a metadata-only import of the public `fidaakh/STEM_data` dataset for Palestinian Sign Language.

## Current scope

- 77 metadata labels imported into the API.
- 41 math labels and 36 science labels in the supplied public CSV.
- Source: https://huggingface.co/datasets/fidaakh/STEM_data
- Declared dataset license: Apache-2.0.
- Original MP4/JPG media is **not** stored in this repository.
- `media_url` and `thumbnail_url` intentionally remain nullable until the original media is obtained with confirmed usage rights.

## Safety and data quality

Entry external label `49` is intentionally marked `needs_review` because the published bilingual source label is `Veins@شريان`: “Veins” maps to “أوردة”, while “شريان” maps to “Artery”. It is excluded from normal user API responses until the source video is reviewed.

The API does not silently substitute either translation.

## API

Authenticated and identity-verified users can use:

- `GET /api/sign-language`
- `GET /api/sign-language/categories`
- `GET /api/sign-language/signs?category=math&q=مثلث`
- `GET /api/sign-language/signs/{id}`

Admins may append `include_review=1` to inspect entries awaiting review.

## Next step

When the original media becomes available, populate `media_url` / `thumbnail_url` without changing the API contract. This keeps the Flutter and web clients stable while the media source is pending.
