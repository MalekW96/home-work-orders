# Home Work Orders

A personal maintenance log for the house and the car. Every job is a numbered work order (`WO-2026-0001`, `WO-2026-0002`, ...) opened against an asset, with parts, labour and costs recorded on it.

The app is a single self-contained page, `home-work-orders.html`, published as a Claude artifact. Records live in the artifact's own database, not in this repo.

## What it does

- Assets: car, rooms, appliances, anything you maintain. Optional meter (km, mi or hours).
- Work orders: type, priority, status (Open, In progress, Completed, Cancelled), opened, due and completed dates, reading, who did the work, notes.
- Cost lines per order: parts (with part number and supplier), labour, other.
- Dashboard: open and overdue jobs, spend by asset, cost split.
- Parts & costs: every part used, searchable.
- Exports: work orders and cost lines as CSV, full backup as JSON (Settings).
- PDF report: period and asset choice, optional parts list. Built in the page with jsPDF.

## Numbering

A new work order takes the next number for the current year. The page takes a short lease on `meta/numbering`, reads the highest `seq` for that year, and writes `workorders/WO-<year>-<seq>`. Work orders cannot be deleted, only cancelled, so numbers are never reused.

## Data model

Collections in the artifact database:

| Path | Fields |
|---|---|
| `assets/{id}` | name, category, details, meterUnit (`""`, `km`, `mi`, `h`), notes, archived, createdAt, updatedAt |
| `workorders/{number}` | number, year, seq, title, assetId, type, priority, status, openedOn, dueOn, completedOn, meter, doneBy, description, notes, lines[], followUpOf, createdAt, updatedAt |
| `meta/settings` | currency (ISO code, default `SAR`) |
| `meta/numbering` | lease document used while a number is issued |

Each entry in `lines` is `{kind: part | labour | other, name, partNo, supplier, qty, unitCost}`. Dates are `YYYY-MM-DD` strings. Records created as examples carry `sample: true`.

## Publishing an update

1. Edit `home-work-orders.html`.
2. Republish it to the same artifact so the URL and the stored records are kept. In Claude: "update my Home Work Orders artifact from home-work-orders.html".
3. Keep the declared capabilities: `db`, `user`, `downloads`.

## Notes

- Libraries are loaded from cdnjs at pinned versions: jsPDF 2.5.1 and jspdf-autotable 3.8.2.
- The PDF uses built-in fonts, so text outside the Latin alphabet (for example Arabic) shows as `?` in the report. The app itself displays it fine.
- Dark and light themes follow the viewer's setting.

## Ideas for later

- Reminders that trigger on date or mileage.
- Restore from a JSON backup.
- Photos or receipts attached to a work order.
