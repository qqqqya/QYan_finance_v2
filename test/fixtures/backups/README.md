# Frozen backup compatibility fixtures

Do not regenerate these when the exporter changes. Every format change must add a
new immutable fixture and a tested migration, preserving all earlier fixtures.

- v1-stage4-all-types.json: exact stage 4 all-entity QA backup bytes, created before
  stage 5; includes three languages, cents, UUIDs, ordering, histories and settings.
- v0.0-all-types.json: representative unversioned project structure derived from
  that backup by removing only schemaVersion and checksum; not claimed to be an
  observed export from a separate old tool. This is the user's v0.0 contract.
- v1-pre-checksum-sample.json: exact historical protocol sample from commit
  608cc3f, before stage 4 added integrity checks. It is a schema example, not a
  production financial export.

The tests compare every original data field after migration, SQLite restoration
and re-export. No test data is seeded into normal app startup.

- v2-theme-all-types.json: new v2 representative fixture, derived once from the frozen v1 all-types fixture by adding themeColor=purple, schemaVersion=2 and appVersion=0.5.1+6, then recalculating the checksum. Old fixtures remain byte-for-byte intact. Legacy restoration adds only the new blue preference; original facts and settings still compare exactly.
