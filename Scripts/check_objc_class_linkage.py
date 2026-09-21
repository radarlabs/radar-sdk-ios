#!/usr/bin/env python3
"""Check that public Objective-C classes are implemented and exported by RadarSDK."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path


HEADER_BUILD_RE = re.compile(
    r"/\* ([^*]+\.h) in Headers \*/ = \{[^\n]*fileRef = ([A-F0-9]+) /\*"
    r"[^\n]*ATTRIBUTES = \(Public,"
)
FILE_REFERENCE_RE = re.compile(
    r"^\s*([A-F0-9]+) /\* [^*]+ \*/ = \{isa = PBXFileReference;(?P<body>[^}]*)\};$",
    re.MULTILINE,
)
INTERFACE_RE = re.compile(r"^\s*@interface\s+([A-Za-z_]\w*)\s*:", re.MULTILINE)


def public_headers(root: Path) -> list[Path]:
    project = root / "RadarSDK.xcodeproj" / "project.pbxproj"
    project_text = project.read_text()
    entries = HEADER_BUILD_RE.findall(project_text)
    if not entries:
        raise RuntimeError(f"No Public headers found in {project}")

    paths_by_ref = {}
    for match in FILE_REFERENCE_RE.finditer(project_text):
        path_match = re.search(r"path = ([^;]+);", match.group("body"))
        if path_match:
            paths_by_ref[match.group(1)] = path_match.group(1).strip('"')

    headers = []
    for name, file_ref in sorted(set(entries)):
        relative_path = paths_by_ref.get(file_ref, name)
        candidates = [
            root / "RadarSDK" / relative_path,
            root / "RadarSDK" / "Include" / relative_path,
            root / relative_path,
        ]
        path = next((candidate for candidate in candidates if candidate.is_file()), None)
        if path is None:
            raise RuntimeError(f"Public header {name} could not be located from {project}")
        headers.append(path)
    return headers


def public_classes(headers: list[Path]) -> dict[str, Path]:
    classes: dict[str, Path] = {}
    for header in headers:
        for class_name in INTERFACE_RE.findall(header.read_text()):
            classes.setdefault(class_name, header)
    return classes


def check_source(root: Path) -> None:
    classes = public_classes(public_headers(root))
    swift_text = "\n".join(
        path.read_text() for path in sorted((root / "RadarSDK").glob("*.swift"))
    )

    violations: list[str] = []
    for class_name, header in classes.items():
        pattern = re.compile(
            rf"@objc\s*\(\s*{re.escape(class_name)}\s*\)"
            rf"\s*(?:(?:public|internal|private|fileprivate|open|final)\s+)*class\b"
        )
        if pattern.search(swift_text):
            violations.append(
                f"{class_name} ({header.name}) is declared as a standalone "
                f"@objc({class_name}) Swift class; use @objc @implementation extension"
            )

    if violations:
        raise RuntimeError("Source linkage check failed:\n- " + "\n- ".join(violations))

    print(f"Source linkage check passed ({len(classes)} public Objective-C classes inspected).")


def framework_classes(framework: Path) -> dict[str, Path]:
    headers_dir = framework / "Headers"
    if not headers_dir.is_dir():
        raise RuntimeError(f"Framework headers directory not found: {headers_dir}")

    classes: dict[str, Path] = {}
    for header in sorted(headers_dir.glob("*.h")):
        for class_name in INTERFACE_RE.findall(header.read_text()):
            classes.setdefault(class_name, header)
    return classes


def run_fixture(root: Path, framework: Path) -> None:
    fixture = root / "Scripts" / "objc_linkage_fixture.m"
    sdk_path = subprocess.check_output(
        ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True
    ).strip()
    with tempfile.TemporaryDirectory(prefix="radar-objc-linkage-") as temp_dir:
        output = Path(temp_dir) / "objc_linkage_fixture"
        command = [
            "xcrun",
            "clang",
            "-fobjc-arc",
            "-target",
            "arm64-apple-ios15.0-simulator",
            "-isysroot",
            sdk_path,
            "-F",
            str(framework.parent),
            "-I",
            str(framework / "Headers"),
            str(fixture),
            "-framework",
            "Foundation",
            "-framework",
            "RadarSDK",
            "-o",
            str(output),
        ]
        subprocess.run(command, check=True)
    print("Release Objective-C linkage fixture passed (RadarTripOptions linked).")


def check_binary(root: Path, framework: Path) -> None:
    framework = framework.resolve()
    binary = framework / framework.stem
    if not binary.is_file():
        raise RuntimeError(f"Framework binary not found: {binary}")

    symbols = subprocess.check_output(["nm", "-gU", str(binary)], text=True)
    exported = {line.split()[-1] for line in symbols.splitlines() if line.split()}
    missing = [
        class_name
        for class_name in framework_classes(framework)
        if f"_OBJC_CLASS_$_{class_name}" not in exported
    ]
    if missing:
        raise RuntimeError(
            "Release binary linkage check failed; missing exported Objective-C class symbols:\n- "
            + "\n- ".join(missing)
        )

    print(f"Release binary linkage check passed ({len(framework_classes(framework))} classes inspected).")
    run_fixture(root, framework)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--source-only", action="store_true")
    parser.add_argument("--framework", type=Path)
    args = parser.parse_args()

    try:
        check_source(args.root)
        if not args.source_only:
            if args.framework is None:
                raise RuntimeError("--framework is required unless --source-only is used")
            check_binary(args.root, args.framework)
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
