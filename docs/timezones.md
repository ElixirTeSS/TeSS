# Event times and time zones

## Storage

An event's `start` and `end` are stored as **local (wall clock) time**, with its time zone in `timezone`. The
columns are UTC `datetime`s, so an event at 09:00–17:00 in Buenos Aires is stored as `09:00 UTC` with
`timezone: 'Buenos Aires'`: the stored value is not the actual UTC time.

- `timezone` is optional: blank means unknown, not UTC. Its values are Rails time zone names (e.g. `Buenos Aires`,
  `London`), the keys of `ActiveSupport::TimeZone::MAPPING`.
- `Event#start_utc` / `#end_utc` give the actual UTC time, `#start_local` the time in the event's time zone, and
  `#local_iso8601(time)` ISO 8601 with the offset on that date (`2026-10-22T09:00:00-03:00`), or without an offset
  if the time zone is unknown. These are used by the iCal and Google Calendar exports, JSON-API and Bioschemas.
- Without a time zone, exports give floating local times (`DTSTART:20261105T090000`), which calendars show at the
  same clock time in their own time zone, so on the same day for people near the event.
- Events given only dates (start and end at midnight) get 09:00–17:00 (`Event#set_default_times`), and are marked
  with `time_inferred` until a time of day is given.
- Nothing should depend on the server's time zone: use `Time.zone.now` and `Date.current`, not `Time.now`,
  `DateTime.now` or `Date.today`.

## Inferred time zones

A missing time zone is looked up from the event's coordinates, or a country with a single time zone
(`TimezoneLookup`), when the event is saved, and marked with `timezone_inferred` until it is changed. This is not
done for events with inferred (default) times, as a guessed time zone on top of guessed times would pin them to a
time and day that may not apply. Existing events get one when they are next saved, e.g. when their source is next
ingested.

## Ingestors

- Assign the **local time of the source**, and set `timezone` if the source gives one. Do not assign a time with
  an offset (e.g. `Time` from `.to_time`, or `"2026-10-22T09:00:00+01:00"`): Rails converts it to the actual UTC
  time, which TeSS would then show shifted by the offset.
- For iCalendar `DTSTART`/`DTEND`, use `Ingestor#ical_local_time`, with `timezone` from the `TZID` parameter (`UTC`
  for `...Z` times).
- A date without a time can be assigned as a `Date` (or midnight): the event then gets the default times.
- In tests, check `start_utc` or `local_iso8601(start)` rather than the stored column. `mock_timezone` runs a test in
  another server time zone, which should not change the result.
