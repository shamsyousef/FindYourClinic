// =========================================================================
//  Find Your Clinic — Graduation Book builder
//  Run with:   node build.js
//  Output:     Graduation_Book.docx (in this folder)
// =========================================================================
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, PageOrientation, Header, Footer, AlignmentType,
  Paragraph, TextRun, PageNumber, NumberFormat,
} = require("docx");

const { numberingConfig, docStyles, PRIMARY, MUTED } = require("./src/helpers");

const {
  cover, committee, abstractEn, abstractAr,
  acknowledgments, tableOfContents, listOfFigures, listOfAbbreviations,
} = require("./src/frontmatter");

const { chapter1 } = require("./src/chapter1");
const { chapter2 } = require("./src/chapter2");
const { chapter3 } = require("./src/chapter3");
const { chapter4 } = require("./src/chapter4");
const { chapter5 } = require("./src/chapter5");
const { chapter6 } = require("./src/chapter6");
const { chapter7 } = require("./src/chapter7");
const { chapter8 } = require("./src/chapter8");

// Page footer with page number
const buildFooter = () =>
  new Footer({
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({
            children: [PageNumber.CURRENT],
            font: "Calibri",
            size: 20,
            color: MUTED,
          }),
        ],
      }),
    ],
  });

// Page header with the project name on the right
const buildHeader = () =>
  new Header({
    children: [
      new Paragraph({
        alignment: AlignmentType.RIGHT,
        children: [
          new TextRun({
            text: "Find Your Clinic  —  Healthcare Directory Platform",
            font: "Calibri",
            size: 18,
            italics: true,
            color: PRIMARY,
          }),
        ],
      }),
    ],
  });

const allChildren = [
  ...cover(),
  ...committee(),
  ...abstractEn(),
  ...abstractAr(),
  ...acknowledgments(),
  ...tableOfContents(),
  ...listOfFigures(),
  ...listOfAbbreviations(),
  ...chapter1(),
  ...chapter2(),
  ...chapter3(),
  ...chapter4(),
  ...chapter5(),
  ...chapter6(),
  ...chapter7(),
  ...chapter8(),
];

const doc = new Document({
  creator: "Find Your Clinic Team",
  title: "Find Your Clinic — Graduation Book",
  description: "Graduation project documentation for the Find Your Clinic healthcare directory platform.",
  styles: docStyles,
  numbering: numberingConfig,
  sections: [
    {
      properties: {
        page: {
          margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 }, // 1 inch = 1440 twips
          size: { orientation: PageOrientation.PORTRAIT },
          pageNumbers: { start: 1, formatType: NumberFormat.DECIMAL },
        },
      },
      headers: { default: buildHeader() },
      footers: { default: buildFooter() },
      children: allChildren,
    },
  ],
});

(async () => {
  const buffer = await Packer.toBuffer(doc);
  const outPath = path.join(__dirname, "Graduation_Book.docx");
  fs.writeFileSync(outPath, buffer);
  const sizeKB = (buffer.length / 1024).toFixed(1);
  console.log(`✓ Wrote ${outPath} (${sizeKB} KB)`);
})().catch((err) => {
  console.error("✗ Build failed:", err);
  process.exit(1);
});
