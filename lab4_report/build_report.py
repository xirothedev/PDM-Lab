"""Build the Lab 4 submission bundle.

    python3 lab4_report/build_report.py

Outputs:
    lab4_report/PDMLab4_sources_ITCSIU25055.zip   the submission bundle
    lab4_report/PDMLab4_ITCSIU25055.docx           editable copy of the report
    lab4_report/report.html                        intermediate, kept for inspection

The bundle contains the report as a PDF plus all the sources it refers to.
The PDF is rendered by Chrome headless from the HTML that pandoc produces,
because there is no LaTeX toolchain on this machine. The CSS in report.css
controls the print layout.
"""

import pathlib
import subprocess
import sys
import tempfile
import zipfile

WS = pathlib.Path(__file__).resolve().parent.parent
R = WS / "lab4_report"
MD = R / "report_source.md"
HTML = R / "report.html"
PDF = R / "PDMLab4_ITCSIU25055_LeThanhTrung.pdf"
DOCX = R / "PDMLab4_ITCSIU25055.docx"
ZIP = R / "PDMLab4_sources_ITCSIU25055.zip"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PANDOC_COMMON = [
    "--from",
    "markdown+yaml_metadata_block+pipe_tables",
    "--number-sections",
]

# Everything that goes into the bundle, relative to the repository root.
# The build tooling (build_report.py, report.css, report.html, scripts/,
# docker-compose.yml) stays in the repository and is not shipped: it is how
# the bundle is produced, not part of the submission.
BUNDLE = [
    "lab4_report/src",
    "lab4_report/evidence",
    "lab4_report/README.md",
    "lab4_report/PDMLab4_ITCSIU25055.docx",
]


def run(cmd):
    print("  $", " ".join(str(c) for c in cmd))
    subprocess.run(cmd, check=True)


def main():
    if not MD.exists():
        sys.exit(f"missing source: {MD}")

    print("building DOCX")
    run(["pandoc", str(MD), *PANDOC_COMMON, "-o", str(DOCX)])

    print("building HTML")
    run(
        [
            "pandoc",
            str(MD),
            *PANDOC_COMMON,
            "--standalone",
            "--css=report.css",
            "--embed-resources",
            "-o",
            str(HTML),
        ]
    )

    print("rendering PDF")
    run(
        [
            CHROME,
            "--headless",
            "--disable-gpu",
            "--no-sandbox",
            f"--print-to-pdf={PDF}",
            "--no-pdf-header-footer",
            "--virtual-time-budget=10000",
            f"file://{HTML}",
        ]
    )

    print("packing the bundle")
    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(PDF, PDF.name)
        for item in BUNDLE:
            path = WS / item
            if path.is_dir():
                for f in sorted(path.rglob("*")):
                    if f.is_file() and "__pycache__" not in f.parts:
                        z.write(f, str(f.relative_to(WS)))
            else:
                z.write(path, item)

    # The report travels inside the bundle only.
    PDF.unlink()

    print(f"  wrote {ZIP.relative_to(WS)} ({ZIP.stat().st_size:,} bytes)")
    print(f"  wrote {DOCX.relative_to(WS)} ({DOCX.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
