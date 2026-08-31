# API client generation and contract freeze

The **frozen contract** is `contracts/openapi.json`. It is the single source of
truth for every client: FastAPI exports it (`backend/scripts/export_openapi.py`),
and the pinned OpenAPI generator CLI produces the TypeScript and Dart-Dio
clients from it.

## Pinned toolchain

| Piece | Pin | Location |
| --- | --- | --- |
| OpenAPI Generator CLI | `7.19.0` | `web/openapitools.json` (`generator-cli.version`) and `mobile/pubspec.yaml` (`openapi_generator.cli_version`) |
| TypeScript generator | `typescript-fetch` | `backend/scripts/check_contract_drift.py` (`_WEB_GENERATOR`) |
| Dart generator | `dart-dio` with `serializationLibrary=json_serializable` | same file (`_MOBILE_GENERATOR` + property) |
| Web transport wiring | `credentials: "include"` | `web/src/app/api-client.ts` (adapter level; generated files are never edited) |

## Commands

```bash
# 1. Export the contract (must be run from the repository root)
python -m backend.scripts.export_openapi

# 2. Regenerate both clients (also run by the drift check)
npm --prefix web exec -- openapi-generator-cli generate \
  -i contracts/openapi.json -g typescript-fetch \
  -o web/src/generated/api --skip-validate-spec \
  --additional-properties=supportsES6=true
npm --prefix web exec -- openapi-generator-cli generate \
  -i contracts/openapi.json -g dart-dio \
  -o mobile/lib/generated/api --skip-validate-spec \
  --additional-properties=serializationLibrary=json_serializable

# 3. Build the Dart serialization parts (json_serializable)
cd mobile/lib/generated/api
dart pub get
dart run build_runner build --delete-conflicting-outputs
cd ../../..
# Transient artifacts (.dart_tool, .build, pubspec.lock) are not committed.

# 4. Verify drift (export + regenerate into temp dirs + diff)
python -m backend.scripts.check_contract_drift --cwd .
```

Steps 1–4 are exactly what `backend/scripts/check_contract_drift.py` performs
against temporary directories, so a green drift check proves the committed
contract and both generated trees are reproducible from source.

## No-hand-edit rule

Every file under `web/src/generated/api/` and `mobile/lib/generated/api/` is
generated output. **Never hand-edit them**: the drift check compares bytes and
any manual change fails regeneration. Two deterministic, script-owned
exceptions are applied by `generate_clients` itself (both sides of the
comparison, so drift stays clean):

- the Dart package's SDK floor is pinned to `>=3.10.0 <4.0.0` (the template
  emits `>=3.5.0`, which the Dart CFE rejects for path-dep part files under the
  host SDK);
- transport wiring (cookies, CSRF header) lives in adapter files outside the
  generated trees (`web/src/app/api-client.ts`, mobile data adapters).

## Contract-change workflow

1. Change the FastAPI source (routes/schemas) and the backend tests.
2. Re-export the contract and review the diff in `contracts/openapi.json`.
3. Regenerate + rebuild both clients (commands above) and update consumer
   tests that assert wire shapes.
4. Run `python -m backend.scripts.check_contract_drift --cwd .` — it must be
   green before the change is complete.
5. Record the change in the OpenSpec change's `apply-progress.md`; the contract
   freeze (gate `T-CF`) re-verifies steps 2–4.

## Frozen shapes (gate T-CF, freeze recorded 2026-08-28)

- Cookie security described (`cc_session` apiKey-in-cookie) plus the
  `X-CSRF-Token` header requirement on unsafe group/auth operations.
- Monetary fields are integer cents on the wire (`*_cents`); no floats.
- Participant rename is name-only (`RenameParticipantRequest = {name: string}`).
- Stable error envelope: `ErrorResponse` / `FieldError` (FastAPI default
  validation schemas are stripped from the export; the envelope is the sole
  error shape).
- Responses carry the server-derived role (`SessionIdentityResponse`); no
  client role field exists anywhere in the contract.
