// Reusable docx building blocks for the Find Your Clinic graduation book.
const {
  AlignmentType,
  BorderStyle,
  HeadingLevel,
  LevelFormat,
  PageBreak,
  Paragraph,
  ShadingType,
  Table,
  TableCell,
  TableRow,
  TextRun,
  WidthType,
} = require("docx");

const PRIMARY = "1F4E79";   // deep blue
const ACCENT  = "2E75B6";   // mid blue
const MUTED   = "595959";   // dark grey
const LIGHT   = "D9E2F3";   // light blue shading

// --- Text helpers ---------------------------------------------------------

const run = (text, opts = {}) =>
  new TextRun({
    text,
    font: "Calibri",
    size: opts.size ?? 22,            // 11pt
    bold: opts.bold ?? false,
    italics: opts.italics ?? false,
    color: opts.color,
    break: opts.break,
  });

const p = (text, opts = {}) =>
  new Paragraph({
    spacing: { before: 80, after: 120, line: 320 }, // 1.15 line spacing-ish
    alignment: opts.align ?? AlignmentType.JUSTIFIED,
    indent: opts.indent,
    children: Array.isArray(text)
      ? text
      : [run(text, opts)],
  });

const lead = (text) =>
  new Paragraph({
    spacing: { before: 120, after: 160, line: 320 },
    alignment: AlignmentType.JUSTIFIED,
    children: [run(text, { size: 22 })],
  });

// Bullet list item
const bullet = (text, level = 0) =>
  new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { before: 40, after: 40, line: 300 },
    children: Array.isArray(text) ? text : [run(text)],
  });

// Numbered list item
const numbered = (text, level = 0) =>
  new Paragraph({
    numbering: { reference: "numbered", level },
    spacing: { before: 40, after: 40, line: 300 },
    children: Array.isArray(text) ? text : [run(text)],
  });

// --- Heading helpers ------------------------------------------------------

const chapterTitle = (text) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_1,
    pageBreakBefore: true,
    alignment: AlignmentType.LEFT,
    spacing: { before: 240, after: 240 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: PRIMARY, space: 8 } },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size: 40,         // 20pt
        bold: true,
        color: PRIMARY,
      }),
    ],
  });

const h2 = (text) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 280, after: 140 },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size: 30,         // 15pt
        bold: true,
        color: PRIMARY,
      }),
    ],
  });

const h3 = (text) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 200, after: 100 },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size: 26,         // 13pt
        bold: true,
        color: ACCENT,
      }),
    ],
  });

const h4 = (text) =>
  new Paragraph({
    heading: HeadingLevel.HEADING_4,
    spacing: { before: 160, after: 80 },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size: 24,
        bold: true,
        color: MUTED,
      }),
    ],
  });

// --- Special blocks -------------------------------------------------------

const pageBreak = () =>
  new Paragraph({
    children: [new TextRun({ text: "", break: 1 }), new PageBreak()],
  });

// Centered title text on a dedicated cover/title page
const centeredTitle = (text, size = 56, color = PRIMARY) =>
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 200, after: 200 },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size,
        bold: true,
        color,
      }),
    ],
  });

const centeredText = (text, size = 24, opts = {}) =>
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 80, after: 80 },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size,
        bold: opts.bold ?? false,
        italics: opts.italics ?? false,
        color: opts.color,
      }),
    ],
  });

const blank = (count = 1) => {
  const arr = [];
  for (let i = 0; i < count; i++) {
    arr.push(new Paragraph({ spacing: { before: 0, after: 0 }, children: [run(" ")] }));
  }
  return arr;
};

// Image placeholder — a single-cell, full-width table with a caption inside.
// The user replaces the placeholder text with an actual image in Word.
const imagePlaceholder = (figureNumber, caption, heightHint = "≈ 9 cm tall") => {
  const innerLines = [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 600, after: 200 },
      children: [
        new TextRun({
          text: `[ Insert image here — ${heightHint} ]`,
          font: "Calibri",
          size: 22,
          italics: true,
          color: MUTED,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 0, after: 600 },
      children: [
        new TextRun({
          text: "(Replace this box with the actual figure in Word: Insert → Pictures)",
          font: "Calibri",
          size: 18,
          italics: true,
          color: "808080",
        }),
      ],
    }),
  ];

  const placeholder = new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [
      new TableRow({
        children: [
          new TableCell({
            shading: { type: ShadingType.CLEAR, color: "auto", fill: "F2F2F2" },
            borders: {
              top:    { style: BorderStyle.DASHED, size: 6, color: ACCENT },
              bottom: { style: BorderStyle.DASHED, size: 6, color: ACCENT },
              left:   { style: BorderStyle.DASHED, size: 6, color: ACCENT },
              right:  { style: BorderStyle.DASHED, size: 6, color: ACCENT },
            },
            children: innerLines,
          }),
        ],
      }),
    ],
  });

  const cap = new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 120, after: 240 },
    children: [
      new TextRun({
        text: `Figure ${figureNumber}: `,
        font: "Calibri",
        size: 20,
        bold: true,
        color: PRIMARY,
      }),
      new TextRun({
        text: caption,
        font: "Calibri",
        size: 20,
        italics: true,
        color: MUTED,
      }),
    ],
  });

  return [placeholder, cap];
};

// Block quote-style note paragraph
const note = (text) =>
  new Paragraph({
    spacing: { before: 120, after: 120, line: 300 },
    indent: { left: 360 },
    border: { left: { style: BorderStyle.SINGLE, size: 18, color: ACCENT, space: 8 } },
    children: [
      new TextRun({
        text,
        font: "Calibri",
        size: 21,
        italics: true,
        color: MUTED,
      }),
    ],
  });

// Two-column key/value table used for requirement tables, etc.
const kvTable = (rows, headers = ["Item", "Description"]) => {
  const headerRow = new TableRow({
    tableHeader: true,
    children: headers.map(
      (text) =>
        new TableCell({
          shading: { type: ShadingType.CLEAR, color: "auto", fill: PRIMARY },
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({
                  text,
                  font: "Calibri",
                  size: 22,
                  bold: true,
                  color: "FFFFFF",
                }),
              ],
            }),
          ],
        })
    ),
  });
  const dataRows = rows.map(
    (row, idx) =>
      new TableRow({
        children: row.map(
          (cellText) =>
            new TableCell({
              shading: idx % 2 === 0
                ? { type: ShadingType.CLEAR, color: "auto", fill: "FFFFFF" }
                : { type: ShadingType.CLEAR, color: "auto", fill: "F2F6FC" },
              children: [
                new Paragraph({
                  spacing: { before: 60, after: 60 },
                  children: [run(cellText, { size: 21 })],
                }),
              ],
            })
        ),
      })
  );
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [headerRow, ...dataRows],
  });
};

// Numbering reference definitions used by `bullet` and `numbered`
const numberingConfig = {
  config: [
    {
      reference: "bullets",
      levels: [
        { level: 0, format: LevelFormat.BULLET, text: "•",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 540, hanging: 240 } } } },
        { level: 1, format: LevelFormat.BULLET, text: "◦",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 900, hanging: 240 } } } },
        { level: 2, format: LevelFormat.BULLET, text: "▪",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1260, hanging: 240 } } } },
      ],
    },
    {
      reference: "numbered",
      levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "%1.",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 540, hanging: 360 } } } },
        { level: 1, format: LevelFormat.LOWER_LETTER, text: "%2.",
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 900, hanging: 360 } } } },
      ],
    },
  ],
};

// Default document styles
const docStyles = {
  default: {
    document: { run: { font: "Calibri", size: 22 } },
  },
  paragraphStyles: [
    {
      id: "Heading1",
      name: "Heading 1",
      basedOn: "Normal",
      next: "Normal",
      quickFormat: true,
      run: { font: "Calibri", size: 40, bold: true, color: PRIMARY },
      paragraph: { spacing: { before: 240, after: 240 } },
    },
    {
      id: "Heading2",
      name: "Heading 2",
      basedOn: "Normal",
      next: "Normal",
      quickFormat: true,
      run: { font: "Calibri", size: 30, bold: true, color: PRIMARY },
      paragraph: { spacing: { before: 280, after: 140 } },
    },
    {
      id: "Heading3",
      name: "Heading 3",
      basedOn: "Normal",
      next: "Normal",
      quickFormat: true,
      run: { font: "Calibri", size: 26, bold: true, color: ACCENT },
      paragraph: { spacing: { before: 200, after: 100 } },
    },
  ],
};

module.exports = {
  PRIMARY,
  ACCENT,
  MUTED,
  LIGHT,
  run,
  p,
  lead,
  bullet,
  numbered,
  chapterTitle,
  h2,
  h3,
  h4,
  pageBreak,
  centeredTitle,
  centeredText,
  blank,
  imagePlaceholder,
  note,
  kvTable,
  numberingConfig,
  docStyles,
};
