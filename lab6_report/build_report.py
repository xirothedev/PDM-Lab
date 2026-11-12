import pathlib
import subprocess
import sys
import zipfile

WS = pathlib.Path(__file__).resolve().parent.parent
R = WS / "lab6_report"
MD = R / "report_source.md"
HTML = R / "report.html"
PDF = R / "PDMLab6_ITCSIU25055_LeThanhTrung.pdf"
DOCX = R / "PDMLab6_ITCSIU25055.docx"
ZIP = R / "PDMLab6_sources_ITCSIU25055.zip"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PANDOC_COMMON = [
    "--from",
    "markdown+yaml_metadata_block+pipe_tables",
    "--number-sections",
]

BUNDLE = [
    "lab6_report/project",
    "lab6_report/src",
    "lab6_report/evidence",
    "lab6_report/README.md",
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
                    if (
                        f.is_file()
                        and "__pycache__" not in f.parts
                        and "target" not in f.parts
                    ):
                        z.write(f, str(f.relative_to(WS)))
            else:
                z.write(path, item)

    PDF.unlink()

    print(f"  wrote {ZIP.relative_to(WS)} ({ZIP.stat().st_size:,} bytes)")
    print(f"  wrote {DOCX.relative_to(WS)} ({DOCX.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
