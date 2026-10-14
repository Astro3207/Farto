# Free-monster replacement phases

StockingMimic reserves the last Gregarious or Monster Habitats copy while draining
the habitat chain, runs the existing backup-camera phase, then uses remaining
Macrometeorite charges followed by Powerful Glove replacement charges. The last
original copy is finished through the existing pearl-farming route afterward.

The shared `copyTarget` in `iotm.ash` must be a free-fight monster. This feature
does not change that selection or seed a new target. A source must match that
monster and have exactly one fight remaining across Habitats and Gregarious.
Earlier daily Gregarious charges are consumed normally before reserving a source.
If no suitable source remains, these phases skip without spending replacements.

Replacement encounters take place in Noob Cave: replace a crate into the reserved
target, then continue the existing CCS/familiar strategy. No Portscan is used.
Native autoattack is disabled so it cannot kill the crate before replacement.
The Glove is forced only for its replacement phase. State and autoattack are
restored in `finally`, including on an abort.

An unexpected encounter, missing source, exhausted skill, unchanged resource
counter, or wrong replacement result stops automation. Wrong enemies remain in
combat for inspection instead of being killed as an ordinary paid fight. The
driver additionally checks that finished encounters did not spend a turn.

Offline validation:

```
java --class-path /path/to/KoLmafia.jar tests/ValidateReplacements.java /path/to/Farto
```

The tests mock all game state/actions. They cover charge boundaries, missing
resources, configured target changes, successful replacements, unexpected enemies,
stalled counters, wrong replacement results, and placement after both backup phases.
The full scripts were also checked with the installed KoLmafia ASH parser.
Live chain behavior remains to be verified; this is a draft PR.
