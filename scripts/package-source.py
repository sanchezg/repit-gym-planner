# Copyright (C) 2026 gsanz.dev
# Licensed under GNU GPL version 3 only, with the additional notice-preservation
# term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

"""Bundle the corresponding project source with each compiled application."""

import argparse
import os
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRECTORIES = ("Repit", "Tests", "UITests", "scripts", "Repit.xcodeproj", "screenshots")


def collect_sources() -> list[Path]:
    root = ROOT
    files = [root / name for name in (
        "LICENSE", "ATTRIBUTION.md", "LICENSING.md", "README.md", ".gitignore",
    )]
    excluded_parts = {"xcuserdata", "__pycache__", ".git"}
    for directory in SOURCE_DIRECTORIES:
        source_directory = root / directory
        if not source_directory.is_dir():
            raise SystemExit(f"Missing corresponding source directory: {directory}")
        for current, directory_names, file_names in os.walk(source_directory):
            directory_names[:] = sorted(name for name in directory_names if name not in excluded_parts)
            files.extend(Path(current) / name for name in file_names if name != ".DS_Store")
    if any(not file.is_file() for file in files):
        raise SystemExit("The corresponding source is incomplete; missing project or license files.")
    return sorted(set(files))


def write_input_list() -> None:
    input_list = ROOT / "scripts/source-inputs.xcfilelist"
    paths = {ROOT, input_list, *collect_sources()}
    for path in list(paths):
        paths.update(parent for parent in path.parents if parent.is_relative_to(ROOT))
    lines = ["$(SRCROOT)/" + path.relative_to(ROOT).as_posix() for path in sorted(paths)]
    input_list.write_text("\n".join(lines) + "\n")
    print(f"Declared {len(paths)} sandbox inputs for source packaging")


def package_source(output: Path) -> None:
    root = ROOT
    files = collect_sources()
    output = output.resolve()
    if output in files or any(output.is_relative_to(root / directory) for directory in SOURCE_DIRECTORIES):
        raise SystemExit("Write the source archive outside packaged source directories to avoid recursive archives.")
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
        for file in sorted(set(files)):
            entry = ZipInfo("Repit/" + file.relative_to(root).as_posix(), date_time=(2026, 10, 15, 0, 0, 0))
            entry.compress_type = ZIP_DEFLATED
            permissions = 0o100755 if file.stat().st_mode & 0o111 else 0o100644
            entry.external_attr = permissions << 16
            archive.writestr(entry, file.read_bytes())
    print(f"Bundled {len(set(files))} corresponding source files")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--output", type=Path)
    action.add_argument("--write-input-list", action="store_true")
    args = parser.parse_args()
    if args.write_input_list:
        write_input_list()
    else:
        package_source(args.output)
