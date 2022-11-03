# Post-to-fedi

Simple system to extract posts from a JSON feed and post it to a fediverse instance.

`read-feed.pl` gets new entries and adds them to a database with one hour's postponement.

`post-to-fedi.pl` checks if any entries in the DB are older than the current time, and posts them. 

## Database schema

```
CREATE TABLE IF NOT EXISTS "entries" (url text primary key,
posted integer not null default 0,
age integer not null, -- Unix timestamp
content text not null);
```
