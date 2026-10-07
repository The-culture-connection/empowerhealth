# Provider search live check

Runs real provider searches against the **deployed** Firebase callable functions
`OhioMaximusSearch` and `searchProviders` (project `empower-health-watch`,
region `us-central1`), sending the same payloads the app sends, and checks that
the results respect the ZIP, radius and plan filters for both standard (quick)
and Expanded search.

It needs no dependencies. Use Node 18 or later (it relies on the global `fetch`).

```bash
node scripts/search-check/check-search.mjs --quick   # ~11 calls, about 3 minutes
node scripts/search-check/check-search.mjs           # full matrix, ~61 calls, about 20-25 minutes
```

Options:

| flag | default | meaning |
|---|---|---|
| `--quick` | off | Small smoke subset: 43215 only, radius 3/10, three plans, Expanded, and a midwife-only search |
| `--max-calls N` | 64 (quick: 12) | Hard cap on callable calls. Cases past the cap are reported as SKIP |
| `--delay MS` | 1500 | Pause between callable calls. Calls run one at a time |
| `--tolerance MI` / `--tolerance-pct P` | 2 / 10 | Slack added to the radius for the ZIP-centroid distance test |
| `--no-upstream` | off | Skip the direct reads of the Ohio Medicaid API used to check plans |
| `--zips a,b,c` | 43215,44113,45202,43604,43756 | ZIPs to search (Columbus, Cleveland, Cincinnati, Toledo, McConnelsville in rural Morgan Co.) |
| `--verbose` | off | Print every offending provider |

Exit codes: `0` means no FAIL, `1` means at least one FAIL, and `2` means a fatal error such as failed auth.
Each run writes its full results (payloads, response URLs, every provider with
its computed distance, and every check) to `results/<timestamp>.json`.
The `results/` and `.cache/` folders are gitignored.

## How it calls the app's backend

1. **Auth.** The script signs in anonymously through the Identity Toolkit REST API
   (`accounts:signUp`) using the web API key from `lib/services/firebase_service.dart`.
   This is the same anonymous user the app's guest mode uses. If anonymous sign-in
   is disabled, the script prints that and exits with code 2.
2. **Calls.** Each search is a `POST https://us-central1-empower-health-watch.cloudfunctions.net/<fn>`
   with the body `{"data": {...}}` and the header `Authorization: Bearer <idToken>`.
   This is the callable protocol the `cloud_functions` plugin uses.
3. **Payloads.** Every app search makes two calls, and the script sends the same ones
   (`provider_repository.dart` `searchProviders()`):
   * `OhioMaximusSearch` with `{zip, radius: "<string>", city, healthPlan, providerType, state: "OH"}`.
     `providerType` is a single string when one type is selected and an array otherwise.
   * `searchProviders` with `{zip, city, healthPlan, providerTypeIds, radius: <int>, includeNpi, acceptsPregnantWomen, acceptsNewborns, telehealth}`.
   * The app merges the two result lists, `OhioMaximusSearch` first, and dedupes them by
     `name_city_zip` of the first location. The script reproduces this as "app-merged".
4. **Modes.**
   * **standard** is the quick search (`provider_quick_search_screen.dart`). It always sends
     `includeNpi: true, acceptsPregnantWomen: true, acceptsNewborns: false, telehealth: false`.
   * **expanded** is the Expanded search opened directly (`provider_search_entry_screen.dart`).
     Its defaults are `includeNpi: false, acceptsPregnantWomen: true, acceptsNewborns: false, telehealth: false`.
     When Expanded is opened *from* quick search, `includeNpi` is prefilled as true and the
     payload is the same as standard.
   * In both modes, if no provider type is chosen the app sends `ProviderTypes.mvpTypes`
     (`01,71,11,09,20,72,37,39`). The `OhioMaximusSearch` payload doesn't depend on the mode,
     so the script reuses that response instead of calling it a second time.
   * The city comes from zippopotam.us, the same way the quick search fills it in.

## What is checked

| check | rule | FAIL when |
|---|---|---|
| `radius OMX` / `radius SP` | Every provider row has at least one address within the radius. Distances use ZIP centroids plus the tolerance. Any row that fails is re-checked with street-level geocoding (US Census geocoder) and passes if it is within radius + 1 mi | any provider is outside |
| `first-address` (WARN) | The results card shows `locations.first`. This flags providers that matched through a secondary address while the address on the card is outside the radius | (warning only) |
| `zip-centred` | The nearest result is within the radius. Also reports the median distance | nearest result is outside |
| `npi-gating` / `npi-zip` | NPI rows appear only when `includeNpi=true`, and they show an address in the searched ZIP | NPI rows appear with `includeNpi=false` |
| `plan-param` | The plan sent upstream (`OhioMaximusSearch` echoes `parameters.healthPlan`) matches `normalizeHealthPlanName` | a specific plan is altered |
| `plan-in-response` (SKIP) | Neither function returns plan or network information per provider, so plan membership can't be checked from the app's data | n/a |
| `plan-upstream` | Fetches the raw Ohio Medicaid FHIR URL that `OhioMaximusSearch` built and checks that every `PractitionerRole.organization` is `HealthPlan/<plan>` | a role belongs to another plan |
| `plan-filter-effective` | Different plans return different provider sets | every plan returns the same set |
| `all-plans`, `all-plans coverage`, `not-listed` (WARN) | Compares "All plans" with the union of the plan-specific results | (warning only, known behavior) |
| `monotonic *` | A larger radius returns at least as many unique providers as a smaller one, for the same ZIP, plan and mode | the count goes down |
| `superset *` | Every provider found at the smaller radius is still returned at the larger one | any provider is dropped |
| `upstream-cap` (WARN) | `OhioMaximusSearch` returned 100 unique providers, which is the API's hard limit | (warning only) |
| `type-crowding` | Providers from a single-type search (Nurse Midwife "71") also appear in the universal search for the same ZIP, radius and plan | any are missing |
| `expanded-vs-standard` | Records counts by source for both modes. The non-NPI rows should match, since only `includeNpi` differs. Expanded must contain no NPI rows | covered by `npi-gating` |

## Known backend behaviors (from code review of `functions/index.js`)

* **"All plans" and "Not listed / not sure" both become CareSource.**
  `normalizeHealthPlanName` (~L3244) maps both to `'CareSource'`. An "All plans" search
  therefore returns CareSource's network only.
* **The NPI lookup ignores the radius.** `buildNpiUrl` (~L3037) queries the exact
  `postal_code` and `city`. `parseNpiResult` (~L4454) reads only `addresses`
  (primary practice and mailing) and ignores the NPI `practiceLocations` field. A provider
  who matched on a secondary Columbus practice location can show up with a Michigan
  or Connecticut address.
* **Quick search always sends `includeNpi: true` and `acceptsPregnantWomen: true`.**
  `searchProviders` only forwards `AcceptsPregnantWomen` / `AcceptsNewborns` upstream
  for maternity types (`isMaternityProviderType`). `OhioMaximusSearch` never forwards them.
* **The Ohio Medicaid API (Maximus) returns at most 100 providers per query** and gives
  no `next` link (`_count`, `page` and `pageSize` are ignored). `fetchFhirBundleWithPaging`
  only follows `next`, so any results past 100 are lost. The 100 are not the nearest ones.
  As a result, a larger radius can *drop* closer providers, and a universal search that
  covers all 8 maternity types can return no midwives or doulas at all.
* **The upstream data also returns a few providers that are outside the radius.** One example
  is a Powell address about 13 mi from 43215 that comes back on a 3-mile search. The backend
  passes results through without checking distance.
* **Responses don't include distance or coordinates.** `serializeProvider` drops them, so the
  app's "Nearest" sort and the "x.x miles" label get no data.
* `OhioMaximusSearch` has no `request.auth` check, unlike `searchProviders`.
* Maximus spells UnitedHealthcare as `HealthPlan/United Healthcare` in the results, even
  though the request sends `United HealthCare`. The plan check ignores case and spaces when
  comparing.
* Aetna at 43215 returns 76 `Organization` resources but only 3 `OrganizationAffiliation`s.
  `parseMedicaidResponse` keeps only organizations that have an affiliation, so Aetna yields
  3 providers.
