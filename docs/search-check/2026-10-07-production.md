# Provider search live check: production 2026-10-07

**Result: PASS.** 299 checks passed, 0 failed, 2 warnings, across 61 real searches.

| | |
|---|---|
| Target | https://us-central1-empower-health-watch.cloudfunctions.net |
| Started / finished | 2026-10-07T23:51:52.112Z / 2026-10-08T00:03:18.321Z |
| Searches (function calls) | 61 |
| ZIP codes | 43215, 44113, 45202, 43604, 43756 |
| Radius tolerance | 2 mi + 10% (ZIP-centroid geocoding is approximate) |
| Results file | 2026-10-07T23-51-52-112Z.json |

## Summary

| Status | Count |
|---|---|
| PASS | 299 |
| FAIL | 0 |
| WARN | 2 |
| INFO | 118 |

INFO lines are measurements (counts, coverage), not pass/fail checks.

## Speed

| Function | Calls | Median | 90th percentile | Slowest |
|---|---|---|---|---|
| OhioMaximusSearch | 28 | 12.7 s | 24.5 s | 25.3 s |
| searchProviders | 33 | 6.1 s | 7.7 s | 21.0 s |

The app runs both calls for one search. A first search of an area is slow because each provider type is queried at the state directory; results are cached for 12 hours, so repeat searches are much faster.

## Results by search

Distances are measured independently by the check script, not taken from the server: street address when it was checked, otherwise the centre of the provider's ZIP code (so providers in the searched ZIP show 0.0 mi). "Farthest" is the farthest provider returned; it must be within the radius plus tolerance.

| Search | Radius | Providers (app list) | Medicaid | National (NPI) | Nearest | Farthest | Checks |
|---|---|---|---|---|---|---|---|
| 43215 Columbus | 3 mi | 405 | 254 | 151 | 0.0 mi | 3.7 mi | 8 pass |
| 43215 Columbus | 10 mi | 491 | 311 | 180 | 0.0 mi | 9.2 mi | 8 pass |
| 43215 Columbus | 25 mi | 533 | 353 | 180 | 0.0 mi | 25.8 mi | 8 pass |
| 43215 Columbus | 50 mi | 552 | 372 | 180 | 0.0 mi | 48.1 mi | 8 pass |
| 44113 Cleveland | 3 mi | 359 | 231 | 128 | 0.0 mi | 4.0 mi | 8 pass |
| 44113 Cleveland | 10 mi | 535 | 358 | 177 | 0.0 mi | 9.3 mi | 8 pass |
| 44113 Cleveland | 25 mi | 556 | 379 | 177 | 0.0 mi | 24.9 mi | 8 pass |
| 44113 Cleveland | 50 mi | 573 | 396 | 177 | 0.0 mi | 50.0 mi | 8 pass |
| 45202 Cincinnati | 3 mi | 391 | 225 | 166 | 0.0 mi | 4.5 mi | 8 pass |
| 45202 Cincinnati | 10 mi | 462 | 288 | 174 | 0.0 mi | 9.6 mi | 8 pass |
| 45202 Cincinnati | 25 mi | 493 | 319 | 174 | 0.0 mi | 23.6 mi | 8 pass |
| 45202 Cincinnati | 50 mi | 527 | 353 | 174 | 0.0 mi | 50.3 mi | 8 pass |
| 43604 Toledo | 3 mi | 264 | 176 | 88 | 0.0 mi | 4.8 mi | 8 pass |
| 43604 Toledo | 10 mi | 459 | 298 | 161 | 0.0 mi | 9.9 mi | 8 pass |
| 43604 Toledo | 25 mi | 468 | 305 | 163 | 0.0 mi | 20.4 mi | 8 pass |
| 43604 Toledo | 50 mi | 518 | 340 | 178 | 0.0 mi | 53.8 mi | 8 pass |
| 43756 Mc Connelsville | 3 mi | 32 | 24 | 8 | 0.0 mi | 0.0 mi | 8 pass |
| 43756 Mc Connelsville | 10 mi | 38 | 26 | 12 | 0.0 mi | 4.3 mi | 8 pass |
| 43756 Mc Connelsville | 25 mi | 317 | 204 | 113 | 0.0 mi | 28.1 mi | 8 pass, 1 warn |
| 43756 Mc Connelsville | 50 mi | 424 | 270 | 154 | 0.0 mi | 51.4 mi | 8 pass |
| 43215 Columbus · expanded | 10 mi | 311 | 311 | 0 | 0.0 mi | 9.2 mi | 7 pass |
| 44113 Cleveland · expanded | 10 mi | 358 | 358 | 0 | 0.0 mi | 9.3 mi | 7 pass |
| 45202 Cincinnati · expanded | 10 mi | 288 | 288 | 0 | 0.0 mi | 9.6 mi | 7 pass |
| 43604 Toledo · expanded | 10 mi | 298 | 298 | 0 | 0.0 mi | 9.9 mi | 7 pass |
| 43756 Mc Connelsville · expanded | 10 mi | 26 | 26 | 0 | 0.0 mi | 4.3 mi | 7 pass |
| 43215 Columbus · type 71 | 10 mi | 74 | 44 | 30 | 0.0 mi | 9.2 mi | 8 pass |
| 43215 Columbus · Buckeye | 10 mi | 449 | 269 | 180 | 0.0 mi | 9.1 mi | 8 pass |
| 43215 Columbus · CareSource | 10 mi | 480 | 300 | 180 | 0.0 mi | 9.2 mi | 8 pass, 1 warn |
| 43215 Columbus · Molina | 10 mi | 455 | 275 | 180 | 0.0 mi | 9.9 mi | 8 pass |
| 43215 Columbus · UnitedHealthcare | 10 mi | 454 | 274 | 180 | 0.0 mi | 9.9 mi | 8 pass |
| 43215 Columbus · Anthem | 10 mi | 459 | 279 | 180 | 0.0 mi | 9.2 mi | 8 pass |
| 43215 Columbus · Aetna | 10 mi | 183 | 3 | 180 | 0.0 mi | 9.1 mi | 8 pass |
| 43215 Columbus · Not listed / not sure | 10 mi | 491 | 311 | 180 | 0.0 mi | 9.2 mi | 8 pass |

## Plans (Columbus 43215, 10 mi)

| Plan chosen | Providers | Plans seen on results |
|---|---|---|
| All plans | 491 | CareSource (280), AmeriHealth Caritas (241), Anthem (178), Humana (164), UnitedHealthcare (142), Buckeye (109), Molina (106) |
| Buckeye | 449 | Buckeye (269) |
| CareSource | 480 | CareSource (300) |
| Molina | 455 | Molina (275) |
| UnitedHealthcare | 454 | UnitedHealthcare (274) |
| Anthem | 459 | Anthem (279) |
| Aetna | 183 | Aetna (3) |
| Not listed / not sure | 491 | CareSource (280), AmeriHealth Caritas (241), Anthem (178), Humana (164), UnitedHealthcare (142), Buckeye (109), Molina (106) |

## Example results (nearest 10)

Spot-check these against the app: run the same search in Find Your Care and compare.

### 43215 Columbus r=10 plan="All plans" standard

| Provider | Source | Distance | Plans |
|---|---|---|---|
| Ala Marie Shuman | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource |
| ALEXANDER ROSPERT | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, Buckeye, CareSource, Humana, UnitedHealthcare |
| ALEXANDRA Greathouse | Medicaid | 0.0 mi | AmeriHealth Caritas, CareSource, Humana, Molina |
| ALEXANDRA LAROSE | Medicaid | 0.0 mi | CareSource, Humana, Molina |
| ALEXIS DAVIS | Medicaid | 0.0 mi | AmeriHealth Caritas, Buckeye, CareSource, Humana |
| ALISON COURTRIGHT | Medicaid | 0.0 mi | AmeriHealth Caritas, CareSource, Humana |
| ALISSA JACKSON | Medicaid | 0.0 mi | Anthem, Buckeye, CareSource, Humana, UnitedHealthcare |
| Allison Diller | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource, UnitedHealthcare |
| Allison Hull | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource, UnitedHealthcare |
| ALLYSON WOERNDLE | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource, Humana, Molina, UnitedHealthcare |

### 43215 Columbus r=10 plan="All plans" standard types=71

| Provider | Source | Distance | Plans |
|---|---|---|---|
| ANNA CONNAIR | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource, Humana, Molina |
| ALICE ANN ROBERTSON, CNM, FNP-C | National (NPI) | 0.0 mi |  |
| ANNA MARIE CONNAIR, MS, BSN, CNM, RN | National (NPI) | 0.0 mi |  |
| BARBARA MARIE BROWN, CNM, WHNP-BC | National (NPI) | 0.0 mi |  |
| DESIREE J.E. OSBY, CNM | National (NPI) | 0.0 mi |  |
| KALEIGH BRIANNE PETERS, CNP | National (NPI) | 0.0 mi |  |
| MARY ANN CHAMBERS, BSN | National (NPI) | 0.0 mi |  |
| MARY ELLENOR DWYER, APRN-CNM | National (NPI) | 0.0 mi |  |
| MICA AYANA ALEXANDER, CNM | National (NPI) | 0.0 mi |  |
| NANCY CAROL HANINGER, CNM | National (NPI) | 0.0 mi |  |

### 43756 Mc Connelsville r=25 plan="All plans" standard

| Provider | Source | Distance | Plans |
|---|---|---|---|
| AMELIA Moats | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, Buckeye, CareSource, Humana, UnitedHealthcare |
| ANGELA GRAY | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, Buckeye, CareSource, Humana, Molina |
| Courtney St. Clair | Medicaid | 0.0 mi | AmeriHealth Caritas, CareSource, UnitedHealthcare |
| GREENE MBA | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource, Molina, UnitedHealthcare |
| HALEY ELLIS | Medicaid | 0.0 mi | AmeriHealth Caritas, CareSource, UnitedHealthcare |
| HEIDI FLOYD | Medicaid | 0.0 mi | CareSource, Humana |
| JAN QUACKENBUSH | Medicaid | 0.0 mi | CareSource, Humana, UnitedHealthcare |
| JANELLE MCCONNELL | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, CareSource, UnitedHealthcare |
| JULIANNE WILLIAMSON | Medicaid | 0.0 mi | AmeriHealth Caritas, Anthem, Buckeye, CareSource, Humana, Molina |
| KENDRA DUNCAN | Medicaid | 0.0 mi | AmeriHealth Caritas, CareSource |

## Failures

None.

## Warnings


- **43756 Mc Connelsville r=25 plan="All plans" standard**: partial OhioMaximusSearch: server returned partial results (upstream deadline/timeout): {"11":{"rungsQueried":[3,25],"upstreamCapped":false,"partial":false,"found":0,"returned":0,"cutoffMiles":null},"20":{"rungsQueried":[3,5,10,15,25],"upstreamCapped":true,"partial":false,"found":97,"ret
- **43215 Columbus r=10 plan="CareSource" standard**: partial OhioMaximusSearch: server returned partial results (upstream deadline/timeout): {"11":{"rungsQueried":[3,10],"upstreamCapped":false,"partial":false,"found":0,"returned":0,"cutoffMiles":null},"20":{"rungsQueried":[3],"upstreamCapped":true,"partial":false,"found":100,"returned":60,

## What each check means

| Check | Meaning |
|---|---|
| counts | Provider counts per function. |
| radius OMX | Every provider from OhioMaximusSearch has a location within the radius (independent geocode, small tolerance). |
| radius SP | Same radius check for searchProviders (Medicaid + national NPI list + directory). |
| omx dedupe | One row per provider (no duplicates per address). |
| upstream-cap | Whether the state directory hit its 100-per-query cap (handled by the radius ladder). |
| distance-field OMX | Each provider includes a distance from the searched ZIP. |
| distance-field SP | Same, for searchProviders. |
| zip-centred | The nearest result is close to the searched ZIP. |
| npi-zip | National (NPI) providers are near the searched ZIP, not out of state. |
| plan-param | The plan the user picked is the plan sent to the state directory. |
| plan-in-response | Providers list which plans they accept. |
| upstream types | Provider types returned by the state directory. |
| plan-upstream | Upstream plan data matches the plan searched. |
| partial OhioMaximusSearch | The server stopped at its 25 s deadline and returned partial results. |
| monotonic OMX | A bigger radius never returns fewer providers. |
| superset OMX | A bigger radius still includes everyone from a smaller radius. |
| monotonic SP medicaid | Same, for searchProviders Medicaid results. |
| superset SP medicaid | Same, for searchProviders Medicaid results. |
| monotonic app-merged | Same, for the merged list the app shows. |
| superset app-merged | Same, for the merged list the app shows. |
| plan counts | Provider counts per plan option. |
| all-plans | "All plans" is not just CareSource. |
| all-plans networks | "All plans" returns providers from many plans. |
| all-plans coverage | How much of the individual plan results "All plans" covers. |
| not-listed | "Not listed / not sure" behaves like "All plans". |
| plan-filter-effective | Different plans return different providers (the filter works). |
| type-crowding | Providers found by a single-type search (e.g. midwives) also appear in the all-types search. |
| expanded-vs-standard | Differences between standard and Expanded search. |
| expanded non-NPI parity | Standard and Expanded return the same Medicaid/directory providers (only the national list differs). |

## Every check

| Search | Check | Status | Detail |
|---|---|---|---|
| 43215 Columbus r=3 plan="All plans" standard | counts | INFO | OMX=254 SP=405 {"medicaid":254,"npi":151} app-merged=404 |
| 43215 Columbus r=3 plan="All plans" standard | radius OMX | PASS | 254/254 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 43215 Columbus r=3 plan="All plans" standard | radius SP | PASS | 405/405 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 43215 Columbus r=3 plan="All plans" standard | omx dedupe | PASS | 254 rows -> 254 unique providers (app key name+first location) |
| 43215 Columbus r=3 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=3 plan="All plans" standard | distance-field OMX | PASS | 254/254 rows have distanceMiles |
| 43215 Columbus r=3 plan="All plans" standard | distance-field SP | PASS | 405/405 rows have distanceMiles |
| 43215 Columbus r=3 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 5.3mi) |
| 43215 Columbus r=3 plan="All plans" standard | npi-zip | INFO | 151 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=3 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=3 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":193,"Anthem":147,"CareSource":232,"Buckeye":89,"Humana":144,"UnitedHealthcare":121,"Molina":82}; 20 rows without plan data (organizations) |
| 43215 Columbus r=3 plan="All plans" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=3 plan="All plans" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":80,"OrganizationAffiliation":6} (first of 8 upstream URLs) |
| 43215 Columbus r=10 plan="All plans" standard | counts | INFO | OMX=311 SP=491 {"medicaid":311,"npi":180} app-merged=490 |
| 43215 Columbus r=10 plan="All plans" standard | radius OMX | PASS | 311/311 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="All plans" standard | radius SP | PASS | 491/491 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="All plans" standard | omx dedupe | PASS | 311 rows -> 311 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@5mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="All plans" standard | distance-field OMX | PASS | 311/311 rows have distanceMiles |
| 43215 Columbus r=10 plan="All plans" standard | distance-field SP | PASS | 491/491 rows have distanceMiles |
| 43215 Columbus r=10 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="All plans" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=10 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":241,"Anthem":178,"CareSource":280,"Buckeye":109,"Humana":164,"UnitedHealthcare":142,"Molina":106}; 28 rows without plan data (organizations) |
| 43215 Columbus r=10 plan="All plans" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="All plans" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":80,"OrganizationAffiliation":6} (first of 13 upstream URLs) |
| 43215 Columbus r=25 plan="All plans" standard | counts | INFO | OMX=353 SP=533 {"medicaid":353,"npi":180} app-merged=532 |
| 43215 Columbus r=25 plan="All plans" standard | radius OMX | PASS | 353/353 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 43215 Columbus r=25 plan="All plans" standard | radius SP | PASS | 533/533 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 43215 Columbus r=25 plan="All plans" standard | omx dedupe | PASS | 353 rows -> 353 unique providers (app key name+first location) |
| 43215 Columbus r=25 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@5mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=25 plan="All plans" standard | distance-field OMX | PASS | 353/353 rows have distanceMiles |
| 43215 Columbus r=25 plan="All plans" standard | distance-field SP | PASS | 533/533 rows have distanceMiles |
| 43215 Columbus r=25 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 29.5mi) |
| 43215 Columbus r=25 plan="All plans" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=25 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=25 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":262,"Anthem":189,"CareSource":307,"Buckeye":115,"Humana":171,"UnitedHealthcare":158,"Molina":114}; 58 rows without plan data (organizations) |
| 43215 Columbus r=25 plan="All plans" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=25 plan="All plans" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":80,"OrganizationAffiliation":6} (first of 13 upstream URLs) |
| 43215 Columbus r=50 plan="All plans" standard | counts | INFO | OMX=372 SP=552 {"medicaid":372,"npi":180} app-merged=551 |
| 43215 Columbus r=50 plan="All plans" standard | radius OMX | PASS | 372/372 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 43215 Columbus r=50 plan="All plans" standard | radius SP | PASS | 552/552 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 43215 Columbus r=50 plan="All plans" standard | omx dedupe | PASS | 372 rows -> 372 unique providers (app key name+first location) |
| 43215 Columbus r=50 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@5mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=50 plan="All plans" standard | distance-field OMX | PASS | 372/372 rows have distanceMiles |
| 43215 Columbus r=50 plan="All plans" standard | distance-field SP | PASS | 552/552 rows have distanceMiles |
| 43215 Columbus r=50 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 57.0mi) |
| 43215 Columbus r=50 plan="All plans" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=50 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=50 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":264,"Anthem":191,"CareSource":309,"Buckeye":116,"Humana":173,"UnitedHealthcare":158,"Molina":115}; 92 rows without plan data (organizations) |
| 43215 Columbus r=50 plan="All plans" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=50 plan="All plans" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":80,"OrganizationAffiliation":6} (first of 13 upstream URLs) |
| 44113 Cleveland r=3 plan="All plans" standard | counts | INFO | OMX=231 SP=359 {"medicaid":231,"npi":128} app-merged=359 |
| 44113 Cleveland r=3 plan="All plans" standard | radius OMX | PASS | 231/231 rows within 3mi (ZIP-centroid +2.3mi slack, 1 confirmed by street address) |
| 44113 Cleveland r=3 plan="All plans" standard | radius SP | PASS | 359/359 rows within 3mi (ZIP-centroid +2.3mi slack, 1 confirmed by street address) |
| 44113 Cleveland r=3 plan="All plans" standard | omx dedupe | PASS | 231 rows -> 231 unique providers (app key name+first location) |
| 44113 Cleveland r=3 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 44113 Cleveland r=3 plan="All plans" standard | distance-field OMX | PASS | 231/231 rows have distanceMiles |
| 44113 Cleveland r=3 plan="All plans" standard | distance-field SP | PASS | 359/359 rows have distanceMiles |
| 44113 Cleveland r=3 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=2.0mi (limit 5.3mi) |
| 44113 Cleveland r=3 plan="All plans" standard | npi-zip | INFO | 128 NPI rows, 69 with the nearest practice location in 44113 (others are elsewhere inside the radius) |
| 44113 Cleveland r=3 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 44113 Cleveland r=3 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":199,"Anthem":135,"CareSource":199,"Humana":135,"UnitedHealthcare":138,"Buckeye":70,"Molina":86}; 10 rows without plan data (organizations) |
| 44113 Cleveland r=10 plan="All plans" standard | counts | INFO | OMX=358 SP=535 {"medicaid":358,"npi":177} app-merged=535 |
| 44113 Cleveland r=10 plan="All plans" standard | radius OMX | PASS | 358/358 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 44113 Cleveland r=10 plan="All plans" standard | radius SP | PASS | 535/535 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 44113 Cleveland r=10 plan="All plans" standard | omx dedupe | PASS | 358 rows -> 358 unique providers (app key name+first location) |
| 44113 Cleveland r=10 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 44113 Cleveland r=10 plan="All plans" standard | distance-field OMX | PASS | 358/358 rows have distanceMiles |
| 44113 Cleveland r=10 plan="All plans" standard | distance-field SP | PASS | 535/535 rows have distanceMiles |
| 44113 Cleveland r=10 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=2.2mi (limit 13.0mi) |
| 44113 Cleveland r=10 plan="All plans" standard | npi-zip | INFO | 177 NPI rows, 69 with the nearest practice location in 44113 (others are elsewhere inside the radius) |
| 44113 Cleveland r=10 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 44113 Cleveland r=10 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":238,"Anthem":172,"CareSource":289,"Humana":164,"UnitedHealthcare":176,"Buckeye":110,"Molina":110}; 60 rows without plan data (organizations) |
| 44113 Cleveland r=25 plan="All plans" standard | counts | INFO | OMX=379 SP=556 {"medicaid":379,"npi":177} app-merged=556 |
| 44113 Cleveland r=25 plan="All plans" standard | radius OMX | PASS | 379/379 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 44113 Cleveland r=25 plan="All plans" standard | radius SP | PASS | 556/556 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 44113 Cleveland r=25 plan="All plans" standard | omx dedupe | PASS | 379 rows -> 379 unique providers (app key name+first location) |
| 44113 Cleveland r=25 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 44113 Cleveland r=25 plan="All plans" standard | distance-field OMX | PASS | 379/379 rows have distanceMiles |
| 44113 Cleveland r=25 plan="All plans" standard | distance-field SP | PASS | 556/556 rows have distanceMiles |
| 44113 Cleveland r=25 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=2.5mi (limit 29.5mi) |
| 44113 Cleveland r=25 plan="All plans" standard | npi-zip | INFO | 177 NPI rows, 69 with the nearest practice location in 44113 (others are elsewhere inside the radius) |
| 44113 Cleveland r=25 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 44113 Cleveland r=25 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":241,"Anthem":172,"CareSource":294,"Humana":163,"UnitedHealthcare":180,"Buckeye":113,"Molina":112}; 90 rows without plan data (organizations) |
| 44113 Cleveland r=50 plan="All plans" standard | counts | INFO | OMX=396 SP=573 {"medicaid":396,"npi":177} app-merged=573 |
| 44113 Cleveland r=50 plan="All plans" standard | radius OMX | PASS | 396/396 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 44113 Cleveland r=50 plan="All plans" standard | radius SP | PASS | 573/573 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 44113 Cleveland r=50 plan="All plans" standard | omx dedupe | PASS | 396 rows -> 396 unique providers (app key name+first location) |
| 44113 Cleveland r=50 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 71@50mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 44113 Cleveland r=50 plan="All plans" standard | distance-field OMX | PASS | 396/396 rows have distanceMiles |
| 44113 Cleveland r=50 plan="All plans" standard | distance-field SP | PASS | 573/573 rows have distanceMiles |
| 44113 Cleveland r=50 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=2.5mi (limit 57.0mi) |
| 44113 Cleveland r=50 plan="All plans" standard | npi-zip | INFO | 177 NPI rows, 69 with the nearest practice location in 44113 (others are elsewhere inside the radius) |
| 44113 Cleveland r=50 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 44113 Cleveland r=50 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":244,"Anthem":172,"CareSource":298,"Humana":163,"UnitedHealthcare":183,"Buckeye":117,"Molina":114}; 116 rows without plan data (organizations) |
| 45202 Cincinnati r=3 plan="All plans" standard | counts | INFO | OMX=224 SP=391 {"user_submission":1,"npi":166,"medicaid":224} app-merged=388 |
| 45202 Cincinnati r=3 plan="All plans" standard | radius OMX | PASS | 224/224 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 45202 Cincinnati r=3 plan="All plans" standard | radius SP | PASS | 391/391 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 45202 Cincinnati r=3 plan="All plans" standard | omx dedupe | PASS | 224 rows -> 224 unique providers (app key name+first location) |
| 45202 Cincinnati r=3 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 45202 Cincinnati r=3 plan="All plans" standard | distance-field OMX | PASS | 224/224 rows have distanceMiles |
| 45202 Cincinnati r=3 plan="All plans" standard | distance-field SP | PASS | 391/391 rows have distanceMiles |
| 45202 Cincinnati r=3 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 5.3mi) |
| 45202 Cincinnati r=3 plan="All plans" standard | npi-zip | INFO | 166 NPI rows, 66 with the nearest practice location in 45202 (others are elsewhere inside the radius) |
| 45202 Cincinnati r=3 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 45202 Cincinnati r=3 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":187,"CareSource":202,"UnitedHealthcare":138,"Anthem":159,"Humana":139,"Molina":78,"Buckeye":94}; 10 rows without plan data (organizations) |
| 45202 Cincinnati r=10 plan="All plans" standard | counts | INFO | OMX=287 SP=462 {"user_submission":1,"npi":174,"medicaid":287} app-merged=459 |
| 45202 Cincinnati r=10 plan="All plans" standard | radius OMX | PASS | 287/287 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 45202 Cincinnati r=10 plan="All plans" standard | radius SP | PASS | 462/462 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 45202 Cincinnati r=10 plan="All plans" standard | omx dedupe | PASS | 287 rows -> 287 unique providers (app key name+first location) |
| 45202 Cincinnati r=10 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 45202 Cincinnati r=10 plan="All plans" standard | distance-field OMX | PASS | 287/287 rows have distanceMiles |
| 45202 Cincinnati r=10 plan="All plans" standard | distance-field SP | PASS | 462/462 rows have distanceMiles |
| 45202 Cincinnati r=10 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 13.0mi) |
| 45202 Cincinnati r=10 plan="All plans" standard | npi-zip | INFO | 174 NPI rows, 66 with the nearest practice location in 45202 (others are elsewhere inside the radius) |
| 45202 Cincinnati r=10 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 45202 Cincinnati r=10 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":218,"CareSource":251,"UnitedHealthcare":165,"Anthem":190,"Humana":149,"Molina":86,"Buckeye":121}; 24 rows without plan data (organizations) |
| 45202 Cincinnati r=25 plan="All plans" standard | counts | INFO | OMX=318 SP=493 {"user_submission":1,"npi":174,"medicaid":318} app-merged=490 |
| 45202 Cincinnati r=25 plan="All plans" standard | radius OMX | PASS | 318/318 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 45202 Cincinnati r=25 plan="All plans" standard | radius SP | PASS | 493/493 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 45202 Cincinnati r=25 plan="All plans" standard | omx dedupe | PASS | 318 rows -> 318 unique providers (app key name+first location) |
| 45202 Cincinnati r=25 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 45202 Cincinnati r=25 plan="All plans" standard | distance-field OMX | PASS | 318/318 rows have distanceMiles |
| 45202 Cincinnati r=25 plan="All plans" standard | distance-field SP | PASS | 493/493 rows have distanceMiles |
| 45202 Cincinnati r=25 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 29.5mi) |
| 45202 Cincinnati r=25 plan="All plans" standard | npi-zip | INFO | 174 NPI rows, 66 with the nearest practice location in 45202 (others are elsewhere inside the radius) |
| 45202 Cincinnati r=25 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 45202 Cincinnati r=25 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":235,"CareSource":268,"UnitedHealthcare":174,"Anthem":203,"Humana":157,"Molina":94,"Buckeye":129}; 50 rows without plan data (organizations) |
| 45202 Cincinnati r=50 plan="All plans" standard | counts | INFO | OMX=352 SP=527 {"user_submission":1,"npi":174,"medicaid":352} app-merged=524 |
| 45202 Cincinnati r=50 plan="All plans" standard | radius OMX | PASS | 352/352 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 45202 Cincinnati r=50 plan="All plans" standard | radius SP | PASS | 527/527 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 45202 Cincinnati r=50 plan="All plans" standard | omx dedupe | PASS | 352 rows -> 352 unique providers (app key name+first location) |
| 45202 Cincinnati r=50 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 45202 Cincinnati r=50 plan="All plans" standard | distance-field OMX | PASS | 352/352 rows have distanceMiles |
| 45202 Cincinnati r=50 plan="All plans" standard | distance-field SP | PASS | 527/527 rows have distanceMiles |
| 45202 Cincinnati r=50 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 57.0mi) |
| 45202 Cincinnati r=50 plan="All plans" standard | npi-zip | INFO | 174 NPI rows, 66 with the nearest practice location in 45202 (others are elsewhere inside the radius) |
| 45202 Cincinnati r=50 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 45202 Cincinnati r=50 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":251,"CareSource":284,"UnitedHealthcare":182,"Anthem":217,"Humana":166,"Molina":99,"Buckeye":138}; 84 rows without plan data (organizations) |
| 43604 Toledo r=3 plan="All plans" standard | counts | INFO | OMX=176 SP=264 {"medicaid":176,"npi":88} app-merged=264 |
| 43604 Toledo r=3 plan="All plans" standard | radius OMX | PASS | 176/176 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 43604 Toledo r=3 plan="All plans" standard | radius SP | PASS | 264/264 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 43604 Toledo r=3 plan="All plans" standard | omx dedupe | PASS | 176 rows -> 176 unique providers (app key name+first location) |
| 43604 Toledo r=3 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43604 Toledo r=3 plan="All plans" standard | distance-field OMX | PASS | 176/176 rows have distanceMiles |
| 43604 Toledo r=3 plan="All plans" standard | distance-field SP | PASS | 264/264 rows have distanceMiles |
| 43604 Toledo r=3 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.2mi (limit 5.3mi) |
| 43604 Toledo r=3 plan="All plans" standard | npi-zip | INFO | 88 NPI rows, 47 with the nearest practice location in 43604 (others are elsewhere inside the radius) |
| 43604 Toledo r=3 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43604 Toledo r=3 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"CareSource":163,"Humana":115,"UnitedHealthcare":97,"AmeriHealth Caritas":142,"Anthem":120,"Molina":50,"Buckeye":66}; 10 rows without plan data (organizations) |
| 43604 Toledo r=10 plan="All plans" standard | counts | INFO | OMX=298 SP=459 {"medicaid":298,"npi":161} app-merged=459 |
| 43604 Toledo r=10 plan="All plans" standard | radius OMX | PASS | 298/298 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43604 Toledo r=10 plan="All plans" standard | radius SP | PASS | 459/459 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43604 Toledo r=10 plan="All plans" standard | omx dedupe | PASS | 298 rows -> 298 unique providers (app key name+first location) |
| 43604 Toledo r=10 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43604 Toledo r=10 plan="All plans" standard | distance-field OMX | PASS | 298/298 rows have distanceMiles |
| 43604 Toledo r=10 plan="All plans" standard | distance-field SP | PASS | 459/459 rows have distanceMiles |
| 43604 Toledo r=10 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 13.0mi) |
| 43604 Toledo r=10 plan="All plans" standard | npi-zip | INFO | 161 NPI rows, 47 with the nearest practice location in 43604 (others are elsewhere inside the radius) |
| 43604 Toledo r=10 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43604 Toledo r=10 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"CareSource":252,"Humana":139,"UnitedHealthcare":157,"AmeriHealth Caritas":200,"Anthem":196,"Molina":77,"Buckeye":131}; 36 rows without plan data (organizations) |
| 43604 Toledo r=25 plan="All plans" standard | counts | INFO | OMX=305 SP=468 {"medicaid":305,"npi":163} app-merged=468 |
| 43604 Toledo r=25 plan="All plans" standard | radius OMX | PASS | 305/305 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 43604 Toledo r=25 plan="All plans" standard | radius SP | PASS | 468/468 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 43604 Toledo r=25 plan="All plans" standard | omx dedupe | PASS | 305 rows -> 305 unique providers (app key name+first location) |
| 43604 Toledo r=25 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@25mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43604 Toledo r=25 plan="All plans" standard | distance-field OMX | PASS | 305/305 rows have distanceMiles |
| 43604 Toledo r=25 plan="All plans" standard | distance-field SP | PASS | 468/468 rows have distanceMiles |
| 43604 Toledo r=25 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 29.5mi) |
| 43604 Toledo r=25 plan="All plans" standard | npi-zip | INFO | 163 NPI rows, 47 with the nearest practice location in 43604 (others are elsewhere inside the radius) |
| 43604 Toledo r=25 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43604 Toledo r=25 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"CareSource":256,"Humana":140,"UnitedHealthcare":158,"AmeriHealth Caritas":205,"Anthem":201,"Molina":80,"Buckeye":134}; 44 rows without plan data (organizations) |
| 43604 Toledo r=50 plan="All plans" standard | counts | INFO | OMX=340 SP=518 {"medicaid":340,"npi":178} app-merged=518 |
| 43604 Toledo r=50 plan="All plans" standard | radius OMX | PASS | 340/340 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 43604 Toledo r=50 plan="All plans" standard | radius SP | PASS | 518/518 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 43604 Toledo r=50 plan="All plans" standard | omx dedupe | PASS | 340 rows -> 340 unique providers (app key name+first location) |
| 43604 Toledo r=50 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@25mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43604 Toledo r=50 plan="All plans" standard | distance-field OMX | PASS | 340/340 rows have distanceMiles |
| 43604 Toledo r=50 plan="All plans" standard | distance-field SP | PASS | 518/518 rows have distanceMiles |
| 43604 Toledo r=50 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=3.1mi (limit 57.0mi) |
| 43604 Toledo r=50 plan="All plans" standard | npi-zip | INFO | 178 NPI rows, 47 with the nearest practice location in 43604 (others are elsewhere inside the radius) |
| 43604 Toledo r=50 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43604 Toledo r=50 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"CareSource":267,"Humana":145,"UnitedHealthcare":162,"AmeriHealth Caritas":211,"Anthem":211,"Molina":85,"Buckeye":143}; 92 rows without plan data (organizations) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | counts | INFO | OMX=24 SP=32 {"medicaid":24,"npi":8} app-merged=32 |
| 43756 Mc Connelsville r=3 plan="All plans" standard | radius OMX | PASS | 24/24 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | radius SP | PASS | 32/32 rows within 3mi (ZIP-centroid +2.3mi slack) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | omx dedupe | PASS | 24 rows -> 24 unique providers (app key name+first location) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | upstream-cap | INFO | no type hit the Ohio Medicaid API 100-provider cap |
| 43756 Mc Connelsville r=3 plan="All plans" standard | distance-field OMX | PASS | 24/24 rows have distanceMiles |
| 43756 Mc Connelsville r=3 plan="All plans" standard | distance-field SP | PASS | 32/32 rows have distanceMiles |
| 43756 Mc Connelsville r=3 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 5.3mi) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | npi-zip | INFO | 8 NPI rows, 8 with the nearest practice location in 43756 (others are elsewhere inside the radius) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43756 Mc Connelsville r=3 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":17,"Anthem":11,"Buckeye":8,"CareSource":20,"Humana":10,"UnitedHealthcare":11,"Molina":3}; 4 rows without plan data (organizations) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | counts | INFO | OMX=26 SP=38 {"medicaid":26,"npi":12} app-merged=38 |
| 43756 Mc Connelsville r=10 plan="All plans" standard | radius OMX | PASS | 26/26 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | radius SP | PASS | 38/38 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | omx dedupe | PASS | 26 rows -> 26 unique providers (app key name+first location) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | upstream-cap | INFO | no type hit the Ohio Medicaid API 100-provider cap |
| 43756 Mc Connelsville r=10 plan="All plans" standard | distance-field OMX | PASS | 26/26 rows have distanceMiles |
| 43756 Mc Connelsville r=10 plan="All plans" standard | distance-field SP | PASS | 38/38 rows have distanceMiles |
| 43756 Mc Connelsville r=10 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | npi-zip | INFO | 12 NPI rows, 8 with the nearest practice location in 43756 (others are elsewhere inside the radius) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43756 Mc Connelsville r=10 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":18,"Anthem":12,"Buckeye":9,"CareSource":21,"Humana":10,"UnitedHealthcare":11,"Molina":4}; 6 rows without plan data (organizations) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | partial OhioMaximusSearch | WARN | server returned partial results (upstream deadline/timeout): {"11":{"rungsQueried":[3,25],"upstreamCapped":false,"partial":false,"found":0,"returned":0,"cutoffMiles":null},"20":{"rungsQueried":[3,5,10,15,25],"upstreamCap |
| 43756 Mc Connelsville r=25 plan="All plans" standard | counts | INFO | OMX=204 SP=317 {"medicaid":204,"npi":113} app-merged=321 |
| 43756 Mc Connelsville r=25 plan="All plans" standard | radius OMX | PASS | 204/204 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | radius SP | PASS | 317/317 rows within 25mi (ZIP-centroid +4.5mi slack) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | omx dedupe | PASS | 204 rows -> 204 unique providers (app key name+first location) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@25mi, 37@25mi, 72@25mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43756 Mc Connelsville r=25 plan="All plans" standard | distance-field OMX | PASS | 204/204 rows have distanceMiles |
| 43756 Mc Connelsville r=25 plan="All plans" standard | distance-field SP | PASS | 317/317 rows have distanceMiles |
| 43756 Mc Connelsville r=25 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=19.9mi (limit 29.5mi) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | npi-zip | INFO | 113 NPI rows, 8 with the nearest practice location in 43756 (others are elsewhere inside the radius) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43756 Mc Connelsville r=25 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":175,"Anthem":127,"Buckeye":87,"CareSource":187,"Humana":123,"UnitedHealthcare":103,"Molina":75}; 14 rows without plan data (organizations) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | counts | INFO | OMX=270 SP=424 {"medicaid":270,"npi":154} app-merged=422 |
| 43756 Mc Connelsville r=50 plan="All plans" standard | radius OMX | PASS | 270/270 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | radius SP | PASS | 424/424 rows within 50mi (ZIP-centroid +7.0mi slack) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | omx dedupe | PASS | 270 rows -> 270 unique providers (app key name+first location) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@25mi, 37@25mi, 39@50mi, 72@25mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43756 Mc Connelsville r=50 plan="All plans" standard | distance-field OMX | PASS | 270/270 rows have distanceMiles |
| 43756 Mc Connelsville r=50 plan="All plans" standard | distance-field SP | PASS | 424/424 rows have distanceMiles |
| 43756 Mc Connelsville r=50 plan="All plans" standard | zip-centred | PASS | nearest=0.0mi median=19.9mi (limit 57.0mi) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | npi-zip | INFO | 154 NPI rows, 8 with the nearest practice location in 43756 (others are elsewhere inside the radius) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43756 Mc Connelsville r=50 plan="All plans" standard | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":214,"Anthem":160,"Buckeye":115,"CareSource":238,"Humana":141,"UnitedHealthcare":122,"Molina":99}; 38 rows without plan data (organizations) |
| 43215 Columbus r=10 plan="All plans" expanded | counts | INFO | OMX=311 SP=311 {"medicaid":311} app-merged=311 |
| 43215 Columbus r=10 plan="All plans" expanded | radius OMX | PASS | 311/311 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="All plans" expanded | radius SP | PASS | 311/311 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="All plans" expanded | distance-field OMX | PASS | 311/311 rows have distanceMiles |
| 43215 Columbus r=10 plan="All plans" expanded | distance-field SP | PASS | 311/311 rows have distanceMiles |
| 43215 Columbus r=10 plan="All plans" expanded | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="All plans" expanded | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=10 plan="All plans" expanded | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":241,"Anthem":178,"CareSource":280,"Buckeye":109,"Humana":164,"UnitedHealthcare":142,"Molina":106}; 28 rows without plan data (organizations) |
| 44113 Cleveland r=10 plan="All plans" expanded | counts | INFO | OMX=358 SP=358 {"medicaid":358} app-merged=358 |
| 44113 Cleveland r=10 plan="All plans" expanded | radius OMX | PASS | 358/358 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 44113 Cleveland r=10 plan="All plans" expanded | radius SP | PASS | 358/358 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 44113 Cleveland r=10 plan="All plans" expanded | distance-field OMX | PASS | 358/358 rows have distanceMiles |
| 44113 Cleveland r=10 plan="All plans" expanded | distance-field SP | PASS | 358/358 rows have distanceMiles |
| 44113 Cleveland r=10 plan="All plans" expanded | zip-centred | PASS | nearest=0.0mi median=2.5mi (limit 13.0mi) |
| 44113 Cleveland r=10 plan="All plans" expanded | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 44113 Cleveland r=10 plan="All plans" expanded | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":238,"Anthem":172,"CareSource":289,"Humana":164,"UnitedHealthcare":176,"Buckeye":110,"Molina":110}; 60 rows without plan data (organizations) |
| 45202 Cincinnati r=10 plan="All plans" expanded | counts | INFO | OMX=287 SP=288 {"user_submission":1,"medicaid":287} app-merged=288 |
| 45202 Cincinnati r=10 plan="All plans" expanded | radius OMX | PASS | 287/287 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 45202 Cincinnati r=10 plan="All plans" expanded | radius SP | PASS | 288/288 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 45202 Cincinnati r=10 plan="All plans" expanded | distance-field OMX | PASS | 287/287 rows have distanceMiles |
| 45202 Cincinnati r=10 plan="All plans" expanded | distance-field SP | PASS | 288/288 rows have distanceMiles |
| 45202 Cincinnati r=10 plan="All plans" expanded | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 13.0mi) |
| 45202 Cincinnati r=10 plan="All plans" expanded | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 45202 Cincinnati r=10 plan="All plans" expanded | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":218,"CareSource":251,"UnitedHealthcare":165,"Anthem":190,"Humana":149,"Molina":86,"Buckeye":121}; 24 rows without plan data (organizations) |
| 43604 Toledo r=10 plan="All plans" expanded | counts | INFO | OMX=298 SP=298 {"medicaid":298} app-merged=298 |
| 43604 Toledo r=10 plan="All plans" expanded | radius OMX | PASS | 298/298 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43604 Toledo r=10 plan="All plans" expanded | radius SP | PASS | 298/298 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43604 Toledo r=10 plan="All plans" expanded | distance-field OMX | PASS | 298/298 rows have distanceMiles |
| 43604 Toledo r=10 plan="All plans" expanded | distance-field SP | PASS | 298/298 rows have distanceMiles |
| 43604 Toledo r=10 plan="All plans" expanded | zip-centred | PASS | nearest=0.0mi median=1.5mi (limit 13.0mi) |
| 43604 Toledo r=10 plan="All plans" expanded | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43604 Toledo r=10 plan="All plans" expanded | plan-in-response | PASS | "All plans": providers from 7 plans {"CareSource":252,"Humana":139,"UnitedHealthcare":157,"AmeriHealth Caritas":200,"Anthem":196,"Molina":77,"Buckeye":131}; 36 rows without plan data (organizations) |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | counts | INFO | OMX=26 SP=26 {"medicaid":26} app-merged=26 |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | radius OMX | PASS | 26/26 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | radius SP | PASS | 26/26 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | distance-field OMX | PASS | 26/26 rows have distanceMiles |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | distance-field SP | PASS | 26/26 rows have distanceMiles |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43756 Mc Connelsville r=10 plan="All plans" expanded | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":18,"Anthem":12,"Buckeye":9,"CareSource":21,"Humana":10,"UnitedHealthcare":11,"Molina":4}; 6 rows without plan data (organizations) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | counts | INFO | OMX=44 SP=74 {"medicaid":44,"npi":30} app-merged=74 |
| 43215 Columbus r=10 plan="All plans" standard types=71 | radius OMX | PASS | 44/44 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | radius SP | PASS | 74/74 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | omx dedupe | PASS | 44 rows -> 44 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | upstream-cap | INFO | no type hit the Ohio Medicaid API 100-provider cap |
| 43215 Columbus r=10 plan="All plans" standard types=71 | distance-field OMX | PASS | 44/44 rows have distanceMiles |
| 43215 Columbus r=10 plan="All plans" standard types=71 | distance-field SP | PASS | 74/74 rows have distanceMiles |
| 43215 Columbus r=10 plan="All plans" standard types=71 | zip-centred | PASS | nearest=0.0mi median=6.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | npi-zip | INFO | 30 NPI rows, 11 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | plan-param | PASS | "All plans" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=10 plan="All plans" standard types=71 | plan-in-response | PASS | "All plans": providers from 7 plans {"AmeriHealth Caritas":40,"Anthem":32,"CareSource":40,"Humana":22,"Molina":23,"UnitedHealthcare":17,"Buckeye":15}; 2 rows without plan data (organizations) |
| 43215 Columbus r=10 plan="Buckeye" standard | counts | INFO | OMX=269 SP=449 {"medicaid":269,"npi":180} app-merged=448 |
| 43215 Columbus r=10 plan="Buckeye" standard | radius OMX | PASS | 269/269 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Buckeye" standard | radius SP | PASS | 449/449 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Buckeye" standard | omx dedupe | PASS | 269 rows -> 269 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="Buckeye" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="Buckeye" standard | distance-field OMX | PASS | 269/269 rows have distanceMiles |
| 43215 Columbus r=10 plan="Buckeye" standard | distance-field SP | PASS | 449/449 rows have distanceMiles |
| 43215 Columbus r=10 plan="Buckeye" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="Buckeye" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="Buckeye" standard | plan-param | PASS | "Buckeye" -> upstream healthplan="Buckeye" (expected "Buckeye") |
| 43215 Columbus r=10 plan="Buckeye" standard | plan-in-response | PASS | 538/538 Medicaid rows list "Buckeye" in healthPlans |
| 43215 Columbus r=10 plan="Buckeye" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="Buckeye" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":80,"OrganizationAffiliation":6} (first of 14 upstream URLs) |
| 43215 Columbus r=10 plan="CareSource" standard | partial OhioMaximusSearch | WARN | server returned partial results (upstream deadline/timeout): {"11":{"rungsQueried":[3,10],"upstreamCapped":false,"partial":false,"found":0,"returned":0,"cutoffMiles":null},"20":{"rungsQueried":[3],"upstreamCapped":true," |
| 43215 Columbus r=10 plan="CareSource" standard | counts | INFO | OMX=300 SP=480 {"medicaid":300,"npi":180} app-merged=479 |
| 43215 Columbus r=10 plan="CareSource" standard | radius OMX | PASS | 300/300 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="CareSource" standard | radius SP | PASS | 480/480 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="CareSource" standard | omx dedupe | PASS | 300 rows -> 300 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="CareSource" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="CareSource" standard | distance-field OMX | PASS | 300/300 rows have distanceMiles |
| 43215 Columbus r=10 plan="CareSource" standard | distance-field SP | PASS | 480/480 rows have distanceMiles |
| 43215 Columbus r=10 plan="CareSource" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="CareSource" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="CareSource" standard | plan-param | PASS | "CareSource" -> upstream healthplan="CareSource" (expected "CareSource") |
| 43215 Columbus r=10 plan="CareSource" standard | plan-in-response | PASS | 600/600 Medicaid rows list "CareSource" in healthPlans |
| 43215 Columbus r=10 plan="CareSource" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="CareSource" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":79,"OrganizationAffiliation":6} (first of 13 upstream URLs) |
| 43215 Columbus r=10 plan="Molina" standard | counts | INFO | OMX=275 SP=455 {"medicaid":275,"npi":180} app-merged=454 |
| 43215 Columbus r=10 plan="Molina" standard | radius OMX | PASS | 275/275 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Molina" standard | radius SP | PASS | 455/455 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Molina" standard | omx dedupe | PASS | 275 rows -> 275 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="Molina" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@5mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="Molina" standard | distance-field OMX | PASS | 275/275 rows have distanceMiles |
| 43215 Columbus r=10 plan="Molina" standard | distance-field SP | PASS | 455/455 rows have distanceMiles |
| 43215 Columbus r=10 plan="Molina" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="Molina" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="Molina" standard | plan-param | PASS | "Molina" -> upstream healthplan="Molina" (expected "Molina") |
| 43215 Columbus r=10 plan="Molina" standard | plan-in-response | PASS | 550/550 Medicaid rows list "Molina" in healthPlans |
| 43215 Columbus r=10 plan="Molina" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="Molina" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":79,"OrganizationAffiliation":6} (first of 14 upstream URLs) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | counts | INFO | OMX=274 SP=454 {"medicaid":274,"npi":180} app-merged=453 |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | radius OMX | PASS | 274/274 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | radius SP | PASS | 454/454 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | omx dedupe | PASS | 274 rows -> 274 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | distance-field OMX | PASS | 274/274 rows have distanceMiles |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | distance-field SP | PASS | 454/454 rows have distanceMiles |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | plan-param | PASS | "UnitedHealthcare" -> upstream healthplan="United HealthCare" (expected "United HealthCare") |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | plan-in-response | PASS | 548/548 Medicaid rows list "UnitedHealthcare" in healthPlans |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="UnitedHealthcare" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":79,"OrganizationAffiliation":6} (first of 13 upstream URLs) |
| 43215 Columbus r=10 plan="Anthem" standard | counts | INFO | OMX=279 SP=459 {"medicaid":279,"npi":180} app-merged=458 |
| 43215 Columbus r=10 plan="Anthem" standard | radius OMX | PASS | 279/279 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Anthem" standard | radius SP | PASS | 459/459 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Anthem" standard | omx dedupe | PASS | 279 rows -> 279 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="Anthem" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@10mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="Anthem" standard | distance-field OMX | PASS | 279/279 rows have distanceMiles |
| 43215 Columbus r=10 plan="Anthem" standard | distance-field SP | PASS | 459/459 rows have distanceMiles |
| 43215 Columbus r=10 plan="Anthem" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="Anthem" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="Anthem" standard | plan-param | PASS | "Anthem" -> upstream healthplan="Anthem" (expected "Anthem") |
| 43215 Columbus r=10 plan="Anthem" standard | plan-in-response | PASS | 558/558 Medicaid rows list "Anthem" in healthPlans |
| 43215 Columbus r=10 plan="Anthem" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="Anthem" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":77,"OrganizationAffiliation":4} (first of 14 upstream URLs) |
| 43215 Columbus r=10 plan="Aetna" standard | counts | INFO | OMX=3 SP=183 {"medicaid":3,"npi":180} app-merged=182 |
| 43215 Columbus r=10 plan="Aetna" standard | radius OMX | PASS | 3/3 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Aetna" standard | radius SP | PASS | 183/183 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Aetna" standard | omx dedupe | PASS | 3 rows -> 3 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="Aetna" standard | upstream-cap | INFO | no type hit the Ohio Medicaid API 100-provider cap |
| 43215 Columbus r=10 plan="Aetna" standard | distance-field OMX | PASS | 3/3 rows have distanceMiles |
| 43215 Columbus r=10 plan="Aetna" standard | distance-field SP | PASS | 183/183 rows have distanceMiles |
| 43215 Columbus r=10 plan="Aetna" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="Aetna" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="Aetna" standard | plan-param | PASS | "Aetna" -> upstream healthplan="Aetna" (expected "Aetna") |
| 43215 Columbus r=10 plan="Aetna" standard | plan-in-response | PASS | 6/6 Medicaid rows list "Aetna" in healthPlans |
| 43215 Columbus r=10 plan="Aetna" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="Aetna" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":75,"OrganizationAffiliation":3} (first of 16 upstream URLs) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | counts | INFO | OMX=311 SP=491 {"medicaid":311,"npi":180} app-merged=490 |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | radius OMX | PASS | 311/311 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | radius SP | PASS | 491/491 rows within 10mi (ZIP-centroid +3.0mi slack) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | omx dedupe | PASS | 311 rows -> 311 unique providers (app key name+first location) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | upstream-cap | INFO | Ohio Medicaid API hit its 100-provider cap for type(s) 20@3mi, 37@3mi, 39@5mi, 72@3mi; the server stopped at that radius rung (nearest-first ladder) and returns the nearest 60 per type |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | distance-field OMX | PASS | 311/311 rows have distanceMiles |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | distance-field SP | PASS | 491/491 rows have distanceMiles |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | zip-centred | PASS | nearest=0.0mi median=0.0mi (limit 13.0mi) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | npi-zip | INFO | 180 NPI rows, 111 with the nearest practice location in 43215 (others are elsewhere inside the radius) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | plan-param | PASS | "Not listed / not sure" -> upstream healthplan="All Plans" (expected "All Plans", every Ohio Medicaid plan) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | plan-in-response | PASS | "Not listed / not sure": providers from 7 plans {"AmeriHealth Caritas":241,"Anthem":178,"CareSource":280,"Buckeye":109,"Humana":164,"UnitedHealthcare":142,"Molina":106}; 28 rows without plan data (organizations) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | upstream types | INFO | provider types among the returned roles: {} (searched 01,71,11,09,20,72,37,39) |
| 43215 Columbus r=10 plan="Not listed / not sure" standard | plan-upstream | INFO | no PractitionerRole rows to check; Maximus PractitionerRole.organization: {}; resources {"Organization":80,"OrganizationAffiliation":6} (first of 13 upstream URLs) |
| 43215 plan="All plans" standard | monotonic OMX | PASS | 3mi:254 10mi:311 25mi:353 50mi:372 |
| 43215 plan="All plans" standard | superset OMX | PASS | every provider from a smaller radius is still returned at the larger radius |
| 43215 plan="All plans" standard | monotonic SP medicaid | PASS | 3mi:254 10mi:311 25mi:353 50mi:372 |
| 43215 plan="All plans" standard | superset SP medicaid | PASS | every provider from a smaller radius is still returned at the larger radius |
| 43215 plan="All plans" standard | monotonic app-merged | PASS | 3mi:404 10mi:490 25mi:532 50mi:551 |
| 43215 plan="All plans" standard | superset app-merged | PASS | every provider from a smaller radius is still returned at the larger radius (except 3->10mi: 1 beyond the 0mi nearest-first cutoff; 25->50mi: 1 beyond the 0mi nearest-first cutoff) |
| 44113 plan="All plans" standard | monotonic OMX | PASS | 3mi:231 10mi:358 25mi:379 50mi:396 |
| 44113 plan="All plans" standard | superset OMX | PASS | every provider from a smaller radius is still returned at the larger radius (except 10->25mi: 1 beyond the 2mi nearest-first cutoff) |
| 44113 plan="All plans" standard | monotonic SP medicaid | PASS | 3mi:231 10mi:358 25mi:379 50mi:396 |
| 44113 plan="All plans" standard | superset SP medicaid | PASS | every provider from a smaller radius is still returned at the larger radius (except 10->25mi: 1 beyond the 2mi nearest-first cutoff) |
| 44113 plan="All plans" standard | monotonic app-merged | PASS | 3mi:359 10mi:535 25mi:556 50mi:573 |
| 44113 plan="All plans" standard | superset app-merged | PASS | every provider from a smaller radius is still returned at the larger radius (except 10->25mi: 1 beyond the 0mi nearest-first cutoff; 25->50mi: 1 beyond the 0mi nearest-first cutoff) |
| 45202 plan="All plans" standard | monotonic OMX | PASS | 3mi:224 10mi:287 25mi:318 50mi:352 |
| 45202 plan="All plans" standard | superset OMX | PASS | every provider from a smaller radius is still returned at the larger radius |
| 45202 plan="All plans" standard | monotonic SP medicaid | PASS | 3mi:224 10mi:287 25mi:318 50mi:352 |
| 45202 plan="All plans" standard | superset SP medicaid | PASS | every provider from a smaller radius is still returned at the larger radius |
| 45202 plan="All plans" standard | monotonic app-merged | PASS | 3mi:388 10mi:459 25mi:490 50mi:524 |
| 45202 plan="All plans" standard | superset app-merged | PASS | every provider from a smaller radius is still returned at the larger radius |
| 43604 plan="All plans" standard | monotonic OMX | PASS | 3mi:176 10mi:298 25mi:305 50mi:340 |
| 43604 plan="All plans" standard | superset OMX | PASS | every provider from a smaller radius is still returned at the larger radius (except 10->25mi: 2 beyond the 1.7mi nearest-first cutoff) |
| 43604 plan="All plans" standard | monotonic SP medicaid | PASS | 3mi:176 10mi:298 25mi:305 50mi:340 |
| 43604 plan="All plans" standard | superset SP medicaid | PASS | every provider from a smaller radius is still returned at the larger radius (except 10->25mi: 2 beyond the 1.7mi nearest-first cutoff) |
| 43604 plan="All plans" standard | monotonic app-merged | PASS | 3mi:264 10mi:459 25mi:468 50mi:518 |
| 43604 plan="All plans" standard | superset app-merged | PASS | every provider from a smaller radius is still returned at the larger radius (except 10->25mi: 2 beyond the 0mi nearest-first cutoff) |
| 43756 plan="All plans" standard | monotonic OMX | PASS | 3mi:24 10mi:26 25mi:204 50mi:270 |
| 43756 plan="All plans" standard | superset OMX | PASS | every provider from a smaller radius is still returned at the larger radius (except 25->50mi: 6 beyond the 21.6mi nearest-first cutoff) |
| 43756 plan="All plans" standard | monotonic SP medicaid | PASS | 3mi:24 10mi:26 25mi:204 50mi:270 |
| 43756 plan="All plans" standard | superset SP medicaid | PASS | every provider from a smaller radius is still returned at the larger radius |
| 43756 plan="All plans" standard | monotonic app-merged | PASS | 3mi:32 10mi:38 25mi:321 50mi:422 |
| 43756 plan="All plans" standard | superset app-merged | PASS | every provider from a smaller radius is still returned at the larger radius (except 25->50mi: 7 beyond the 21.6mi nearest-first cutoff) |
| 43215 r=10 standard | plan counts | INFO | All plans=311, Buckeye=269, CareSource=300, Molina=275, UnitedHealthcare=274, Anthem=279, Aetna=3, Not listed / not sure=311 |
| 43215 r=10 standard | all-plans | PASS | "All plans" (311) differs from CareSource (300) |
| 43215 r=10 standard | all-plans networks | PASS | "All plans" rows are listed under 7 plans: AmeriHealth Caritas, Anthem, CareSource, Buckeye, Humana, UnitedHealthcare, Molina |
| 43215 r=10 standard | all-plans coverage | INFO | 299/653 providers from the individual plan searches also appear under "All plans" (upstream 100-per-query cap is shared across plans in an "All Plans" query) |
| 43215 r=10 standard | not-listed | PASS | "Not listed / not sure" searches every plan, same as "All plans" |
| 43215 r=10 standard | plan-filter-effective | PASS | different plans return different provider sets |
| 43215 r=10 plan="All plans" types=71 | type-crowding | PASS | all 44/44 type-71 providers also appear in the universal search |
| 43215 r=10 plan="All plans" | expanded-vs-standard | INFO | standard SP {"medicaid":311,"npi":180} app=490 \| expanded SP {"medicaid":311} app=311 \| non-NPI only-in-standard=0 only-in-expanded=0 |
| 43215 r=10 plan="All plans" | expanded non-NPI parity | PASS | Medicaid/directory rows identical; difference is only the NPI rows (includeNpi) |
| 44113 r=10 plan="All plans" | expanded-vs-standard | INFO | standard SP {"medicaid":358,"npi":177} app=535 \| expanded SP {"medicaid":358} app=358 \| non-NPI only-in-standard=0 only-in-expanded=0 |
| 44113 r=10 plan="All plans" | expanded non-NPI parity | PASS | Medicaid/directory rows identical; difference is only the NPI rows (includeNpi) |
| 45202 r=10 plan="All plans" | expanded-vs-standard | INFO | standard SP {"user_submission":1,"npi":174,"medicaid":287} app=459 \| expanded SP {"user_submission":1,"medicaid":287} app=288 \| non-NPI only-in-standard=0 only-in-expanded=0 |
| 45202 r=10 plan="All plans" | expanded non-NPI parity | PASS | Medicaid/directory rows identical; difference is only the NPI rows (includeNpi) |
| 43604 r=10 plan="All plans" | expanded-vs-standard | INFO | standard SP {"medicaid":298,"npi":161} app=459 \| expanded SP {"medicaid":298} app=298 \| non-NPI only-in-standard=0 only-in-expanded=0 |
| 43604 r=10 plan="All plans" | expanded non-NPI parity | PASS | Medicaid/directory rows identical; difference is only the NPI rows (includeNpi) |
| 43756 r=10 plan="All plans" | expanded-vs-standard | INFO | standard SP {"medicaid":26,"npi":12} app=38 \| expanded SP {"medicaid":26} app=26 \| non-NPI only-in-standard=0 only-in-expanded=0 |
| 43756 r=10 plan="All plans" | expanded non-NPI parity | PASS | Medicaid/directory rows identical; difference is only the NPI rows (includeNpi) |

---

Generated by scripts/search-check/report.mjs from 2026-10-07T23-51-52-112Z.json. Re-run the check with `node scripts/search-check/check-search.mjs`, then `node scripts/search-check/report.mjs`.
