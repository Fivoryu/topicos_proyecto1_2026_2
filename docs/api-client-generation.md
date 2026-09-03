# API client generation and contract freeze

The **frozen contract** is `contracts/openapi.json`. FastAPI exports it and the pinned OpenAPI Generator CLI produces the TypeScript and Dart-Dio clients. Generated files are never hand-edited.

## Pinned toolchain

| Piece | Pin / rule | Operational source |
| --- | --- | --- |
| OpenAPI Generator CLI | `7.14.0` | repository-root `openapitools.json` (the drift script runs from repo root) |
| Secondary metadata | `7.14.0` | `web/openapitools.json` and `mobile/pubspec.yaml` are aligned to the operational root pin |
| TypeScript generator | `typescript-fetch` | `backend/scripts/check_contract_drift.py` |
| Dart generator | `dart-dio`, `serializationLibrary=json_serializable` | same drift script |
| Browser transport | credentials/cookies through handwritten adapter | `web/src/app/api-client.ts` |

## Reproducible commands

Start from the **repository root**. The generator package is installed with the web dev dependencies, so run the two generation commands from `web/` where their relative input/output paths are unambiguous:

```bash
# 1. Export the FastAPI contract (repository root)
python -m backend.scripts.export_openapi

# 2. Enter the web package, which owns the pinned generator dependency
cd web

# 3. Regenerate the TypeScript client
npm exec -- openapi-generator-cli generate \
  -i ../contracts/openapi.json -g typescript-fetch \
  -o src/generated/api --skip-validate-spec \
  --additional-properties=supportsES6=true

# 4. Regenerate the Dart-Dio client
npm exec -- openapi-generator-cli generate \
  -i ../contracts/openapi.json -g dart-dio \
  -o ../mobile/lib/generated/api --skip-validate-spec \
  --additional-properties=serializationLibrary=json_serializable

cd ..

# 5. Build Dart serialization parts
cd mobile/lib/generated/api
dart pub get
dart run build_runner build --delete-conflicting-outputs
cd ../../../..

# 6. Verify the committed snapshot and both client trees
python -m backend.scripts.check_contract_drift --cwd .
```

For normal verification, prefer the final drift-check command: it exports and regenerates into temporary directories using the same root `7.14.0` pin, then compares the results without overwriting committed generated files.

The drift script exports/regenerates into temporary directories, normalizes the generated Dart SDK floor exactly as defined by the script, builds serialization parts, and compares bytes against committed output. A green drift check proves reproducibility from the handwritten API source and pinned workflow.

## No-hand-edit rule

Never manually edit:

- `web/src/generated/api/**`
- `mobile/lib/generated/api/**`

TODO markers inside generated output are generator artifacts, not automatically product scope.

If the API really changes:

1. Change handwritten FastAPI route/schema source and backend tests/specs first.
2. Export `contracts/openapi.json` and review the contract diff.
3. Regenerate affected clients through the commands above.
4. Update consumer tests for the changed wire shape.
5. Run `python -m backend.scripts.check_contract_drift --cwd .`.
6. Record the contract change in the owning OpenSpec change.

Presentation-only, seed-only, README, or environment-documentation changes do **not** justify generated-client churn.
