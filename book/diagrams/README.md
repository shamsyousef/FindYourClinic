# Chapter 5 Diagrams — Find Your Clinic

This folder contains the system diagrams referenced from Chapter 5 of the graduation book.
Each diagram is written in **Mermaid**, a text-based diagramming language that renders to
SVG in:

- **GitHub** — open the `.md` file in the GitHub web UI and the diagram renders automatically.
- **VS Code** — install the *Markdown Preview Mermaid Support* extension and press
  `Ctrl + Shift + V` to preview.
- **Mermaid Live Editor** — [mermaid.live](https://mermaid.live). Paste the code from any
  file, click **Actions → Download SVG/PNG**, and you get a high-resolution export ready to
  paste into the Word document.

## How to put a diagram into the docx

1. Open the `.md` file you want and copy the content inside the ```` ```mermaid ```` block.
2. Paste it into [mermaid.live](https://mermaid.live).
3. Export as PNG (set scale to 2× or 3× for a crisp image) **or** as SVG (best for printing).
4. In `Graduation_Book.docx`, find the matching dashed placeholder box (e.g. *Figure 1*),
   click inside it, and choose **Insert → Pictures → This Device…**.
5. Delete the placeholder text after the image is in place.

## File list

| # | File | What it shows |
| - | ---- | ------------- |
| 1 | [01-erd-diagram.md](01-erd-diagram.md) | Entity Relationship Diagram of the SQL Server schema |
| 2 | [02-uml-class-diagram.md](02-uml-class-diagram.md) | UML class diagram of the C# domain model |
| 3 | [03-use-case-diagram.md](03-use-case-diagram.md) | Use cases for Patient, Doctor, and Admin |
| 4 | [04-patient-workflow.md](04-patient-workflow.md) | End-to-end patient journey |
| 5 | [05-doctor-workflow.md](05-doctor-workflow.md) | End-to-end doctor journey |
| 6 | [06-admin-workflow.md](06-admin-workflow.md) | Admin verification and moderation flow |
| 7 | [07-booking-payment-sequence.md](07-booking-payment-sequence.md) | Sequence diagram for booking + Paymob payment |

## Tips for rendering

- The ERD is dense — when exporting, set the Mermaid theme to *neutral* or *base* for a clean
  black-and-white look that prints well.
- For the UML class diagram, exporting to SVG keeps text crisp even on A4 paper.
- If a diagram is too wide for the page, set the page orientation of that single page to
  **landscape** in Word: select the page → Layout → Orientation → Landscape (Apply to:
  Selected text).
