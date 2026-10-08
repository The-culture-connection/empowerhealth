# Provider search live check

Runs real provider searches against the Firebase callable functions
`OhioMaximusSearch` and `searchProviders` (project `empower-health-watch`,
region `us-central1`), either the **deployed** functions or the **Functions emulator**,
sending the same payloads the app sends, and checks that the results respect the ZIP,
radius and plan filters for both standard (quick) and Expanded search.

It needs no dependencies. Use Node 18 or later (it relies on the global `fetch`).

```bash
node scripts/search-check/check-search.mjs --quick   # ~11 calls, a few minutes
node scripts/search-check/check-search.mjs           # full matrix, ~61 calls, about 15-30 minutes

# against the local Functions emulator (see "Running against the emulator")
node scripts/search-check/check-search.mjs --quick --base http://127.0.0.1:5001/empower-health-watch/us-central1
```

Options:

| flag | default | meaning |
|---|---|---|
| `--quick` | off | Small smoke subset: 43215 only, radius 3/10, three plans, Expanded, and a midwife-only search |
| `--base URL` | deployed functions | Callable base URL. Use `http://127.0.0.1:5001/empower-health-watch/us-central1` for the emulator. Also read from `SEARCH_CHECK_BASE` |
| `--max-calls N` | 64 (quick: 12) | Hard cap on callable calls. Cases past the cap are reported as SKIP |
| `--delay MS` | 1500 | Pause between callable calls. Calls run one at a time |
| `--tolerance MI` / `--tolerance-pct P` | 2 / 10 | Slack added to the radius for the ZIP-centroid distance test |
| `--no-upstream` | off | Skip the direct reads of the Ohio Medicaid API used to check plans |
| `--zips a,b,c` | 43215,44113,45202,43604,43756 | ZIPs to search (Columbus, Cleveland, Cincinnati, Toledo, McConnelsville in rural Morgan Co.) |
| `--verbose` | off | Print every offending provider |

Exit codes: `0` means no FAIL, `1` means at least one FAIL, and `2` means a fatal error such as failed auth.
Each run writes its full results (payloads, response URLs, coverage and timings returned by
the server, every provider with its computed distance, every check, and a latency summary)
to `results/<timestamp>.json`. The `results/` and `.cache/` folders are gitignored.

## Running against the emulator

The emulator runs the local `functions/` code and calls the real Ohio Medicaid and NPI APIs.

1. `functions/.secret.local` must define the secrets the code declares. Provider search
   doesn't use any, so a dummy is fine: `OPENAI_API_KEY=dummy`. The file is gitignored.
2. Start the Functions and Firestore emulators from the repo root (the Firestore emulator
   holds the search cache, the directory and the block list, so nothing is written to
   production). Java is needed for Firestore; Android Studio's JBR works:
   ```bash
   JAVA_HOME="/c/Program Files/Android/Android Studio/jbr" PATH="$JAVA_HOME/bin:$PATH" \
     firebase emulators:start --only functions,firestore --project empower-health-watch
   ```
3. Run the check with `--base http://127.0.0.1:5001/empower-health-watch/us-central1`.
   The anonymous ID token from the real project works: the Functions emulator decodes the
   token without verifying its signature.
4. To measure cold (uncached) latency, clear the emulator's Firestore first:
   `curl -X DELETE "http://127.0.0.1:8080/emulator/v1/projects/empower-health-watch/databases/(default)/documents"`.

## How it calls the app's backend

1. **Auth.** The script signs in anonymously through the Identity Toolkit REST API
   (`accounts:signUp`) using the web API key from `lib/services/firebase_service.dart`.
   This is the same anonymous user the app's guest mode uses. If anonymous sign-in
   is disabled, the script prints that and exits with code 2.
2. **Calls.** Each search is a `POST <base>/<fn>` with the body `{"data": {...}}` and the
   header `Authorization: Bearer <idToken>`. This is the callable protocol the
   `cloud_functions` plugin uses.
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

The script computes its own distances (zippopotam.us ZIP centroids, US Census street
geocoder as a fallback), independently of the distances the server returns.
`ZIP_CENTROID_FIXES` in the script corrects known zippopotam.us errors for single-building
ZIPs (44195, Cleveland Clinic, is placed in Lake Erie 14 mi from downtown); without it,
Cleveland Clinic providers that are 4 mi away would be reported as outside a 10 mi radius.

| check | rule | FAIL when |
|---|---|---|
| `radius OMX` / `radius SP` | Every provider row has at least one address within the radius. Distances use ZIP centroids plus the tolerance. Any row that fails is re-checked with street-level geocoding (US Census geocoder) and passes if it is within radius + 1 mi | any provider is outside |
| `first-address` (WARN) | The results card shows `locations.first`. This flags providers whose first address is outside the radius although another address is inside | (warning only) |
| `distance-field OMX/SP` | Every row has `distanceMiles`, equal to `locations[0].distance` | a row has no distance |
| `omx dedupe` | `OhioMaximusSearch` returns one row per provider | duplicate rows |
| `zip-centred` | The nearest result is within the radius. Also reports the median distance | nearest result is outside |
| `npi-gating` / `npi-zip` | NPI rows appear only when `includeNpi=true`. `npi-zip` (INFO) counts NPI rows whose nearest practice location is in the searched ZIP | NPI rows appear with `includeNpi=false` |
| `plan-param` | The plan sent upstream (`parameters.healthPlan`) matches `normalizeHealthPlanName`; "All plans" and "Not listed / not sure" send `All Plans` | wrong plan sent |
| `plan-in-response` | Medicaid rows list the searched plan in `healthPlans` (organizations in an "All plans" search have no plan data upstream and are counted separately) | a row is listed under other plans only |
| `plan-upstream` | Fetches the first raw Ohio Medicaid FHIR URL the server used and checks every `PractitionerRole.organization` is `HealthPlan/<plan>` (several plans for "All plans") | a role belongs to another plan |
| `plan-filter-effective` | Different plans return different provider sets | every plan returns the same set |
| `all-plans`, `all-plans networks` | "All plans" differs from CareSource and its rows come from several plans | "All plans" is one plan's network |
| `all-plans coverage` (INFO) | Share of the individual plan results that also appear under "All plans". Below 100% by design: an `All Plans` query shares the API's 100-provider cap across every plan | n/a |
| `not-listed` | "Not listed / not sure" returns the same set as "All plans" | (WARN when different) |
| `monotonic *` | A larger radius returns at least as many unique providers as a smaller one, for the same ZIP, plan and mode | the count goes down |
| `superset *` | Every provider found at the smaller radius is still returned at the larger one, unless it is at or beyond the larger search's `coverage.completeWithinMiles` (the list is capped nearest-first per type) | a closer provider is dropped |
| `type-crowding` | Providers from a single-type search (Nurse Midwife "71") also appear in the universal search for the same ZIP, radius and plan, unless beyond that type's cutoff distance | any closer one is missing |
| `upstream-cap` (INFO) | Which provider types hit the Ohio Medicaid API's 100-provider cap, and at which radius rung | n/a |
| `latency *` (WARN) | A call took longer than the app's client timeout (30 s for `OhioMaximusSearch`, 60 s for `searchProviders`); the app would drop that response | (warning only) |
| `partial *` (WARN) | The server hit its upstream deadline and returned what it had (`coverage.partial`). `monotonic`/`superset`/`type-crowding` problems in partial runs are reported as WARN, not FAIL | (warning only) |
| `expanded-vs-standard` | Records counts by source for both modes. The non-NPI rows should match, since only `includeNpi` differs. Expanded must contain no NPI rows | covered by `npi-gating` |

## Backend behavior (functions/providerSearchEngine.js)

* **Ohio Medicaid (Maximus) API: 100 providers per query, no paging, not nearest-first.**
  Each provider type is queried separately, on a radius ladder that matches the app's radius
  options (3, 5, 10, 15, 25, 50 mi), smallest first, stopping at the first rung that hits the
  cap. A larger search repeats the smaller search's rung queries, so it never drops a closer
  provider. Results are cut to the nearest 60 per provider type, so one type can't crowd out
  another; `coverage.completeWithinMiles` says how far the list is complete.
* **"All plans" / "Not listed / not sure"** use the API's own `healthplan=All Plans` value
  (every Ohio Medicaid plan, including Humana and AmeriHealth Caritas). Each row's
  `healthPlans` lists its plans (from `PractitionerRole.organization`).
* **Distance.** Offline ZIP and city centroids (US Census 2023 Gazetteer, public domain,
  `functions/data/zip-centroids.json`, built by `scripts/geo/build-zip-centroids.mjs`).
  Locations farther than radius + 0.5 mi + 5% are dropped; the nearest is listed first and
  its distance is returned as `distanceMiles` and `locations[].distance`.
* **NPI Registry.** Queried by `taxonomy_description` (the old `taxonomy_code` parameter is not
  an NPI API parameter and was ignored) for the 6 nearest ZIPs plus every 3-digit ZIP prefix
  inside the radius. Practice locations (`practiceLocations`) are included; rows with no
  location inside the radius are dropped; capped at the nearest 30 per taxonomy.
* **Caching.** Upstream Maximus responses are cached in memory and in Firestore
  (`provider_search_cache`, 12 hours), so the two callables share one fetch and repeat
  searches are fast. Cold searches are bound by the Maximus API (single queries take
  2-20 s).
* `AcceptsPregnantWomen` / `AcceptsNewborns` are no longer sent to the Maximus API: it returns
  identical results with and without them (checked for types 01, 71, 72).
* Aetna at 43215 returns only 3 hospitals: the API's Aetna network (OhioRISE) has no
  practitioners there. The 76 `Organization` entries are duplicates (one per address) of
  those 3 hospitals; they are now merged into one row with all addresses.
