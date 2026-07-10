# PT-0001-002 — Understand

Date: 2026-01-15

Build CRUD for contact lists: a user creates a named list, renames it, adds and
removes existing contacts, and deletes the list (soft-delete — it disappears
from the UI but rows remain).

A list belongs to one user. A contact can be in many lists. Deleting a list does
not delete its contacts.
