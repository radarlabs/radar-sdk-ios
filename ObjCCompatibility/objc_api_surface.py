#!/usr/bin/env python3
"""Keeps RadarSDKObjCAPISurface.m in step with the SDK's generated RadarSDK-Swift.h.

    objc_api_surface.py --check  --header <RadarSDK-Swift.h>
    objc_api_surface.py --update --header <RadarSDK-Swift.h>

The surface file calls every public member of each Swift-implemented class from Objective-C.
`--check` fails when the header has a class or member the file doesn't call, unless the class is
listed in internal-classes.txt. `--update` adds the missing calls. It never rewrites existing
calls, so a renamed or removed member still fails to compile instead of being regenerated away.

Each member gets one function, named for the member (`get_`, `set_`, `call_`, or `class_` for the
class itself), so the check compares names and ignores formatting.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SURFACE_PATH = os.path.join(HERE, "RadarSDKObjCAPISurface.m")
INTERNAL_PATH = os.path.join(HERE, "internal-classes.txt")

MACROS = [
    r"SWIFT_WARN_UNUSED_RESULT",
    r"NS_DESIGNATED_INITIALIZER",
    r"OBJC_DESIGNATED_INITIALIZER",
    r"SWIFT_METHOD_FAMILY\([^)]*\)",
    r"SWIFT_DEPRECATED_MSG\((?:[^()]|\([^)]*\))*\)",
    r"SWIFT_DEPRECATED_OBJC\([^)]*\)",
    r"SWIFT_DEPRECATED",
    r"SWIFT_AVAILABILITY\((?:[^()]|\([^)]*\))*\)",
    r"SWIFT_NOESCAPE",
    r"SWIFT_RETURNS_INDEPENDENT_VALUE",
    r"NS_SWIFT_NAME\([^)]*\)",
]
FUNCTION_NAME = re.compile(r"\b((?:get|set|call|class)_\w+)\(")


def read_header(path):
    text = open(path).read()
    # The header repeats its declarations once per architecture; read only the first copy.
    end = text.find("#elif defined(__x86_64__)")
    return text if end == -1 else text[:end]


def interface_blocks(text):
    """Yields (name, body, declares_class) for each class and Swift extension, merging repeats.

    `declares_class` is false for a Swift extension of an Objective-C class, like `Radar`, whose
    class itself isn't implemented in Swift.
    """
    pattern = re.compile(r"^@interface (\w+)\s*(:[^\n]*|\(SWIFT_EXTENSION\(\w+\)\)[^\n]*)\n(.*?)^@end", re.M | re.S)
    bodies, declares = {}, {}
    for match in pattern.finditer(text):
        name = match.group(1)
        bodies.setdefault(name, []).append(match.group(3))
        declares[name] = declares.get(name, False) or match.group(2).startswith(":")
    for name, parts in bodies.items():
        yield name, "\n".join(parts), declares[name]


def declarations(body):
    body = re.sub(r"^\s*///.*$", "", body, flags=re.M)
    body = re.sub(r"^\s*#.*$", "", body, flags=re.M)
    current = ""
    for line in body.split("\n"):
        if not line.strip():
            continue
        current += " " + line.strip()
        if current.strip().endswith(";"):
            yield current.strip()
            current = ""


def clean(decl):
    for macro in MACROS:
        decl = re.sub(macro, "", decl)
    return re.sub(r"\s+", " ", decl).strip().rstrip(";").strip()


def with_name(c_type, name):
    """Declares `name` with `c_type`, putting the name inside block types."""
    block = re.match(r"^(.*?\(\^)(\s*_Nonnull|\s*_Nullable|\s*_Null_unspecified)?(\).*)$", c_type)
    if block:
        return f"{block.group(1)}{block.group(2) or ''} {name}{block.group(3)}"
    return f"{c_type} {name}"


def property_lines(cls, decl):
    match = re.match(r"@property \(([^)]*)\) (.*)$", decl)
    attrs = [a.strip() for a in match.group(1).split(",")]
    rest = match.group(2)
    block = re.match(r"^(.*\(\^\s*(?:_Nonnull|_Nullable|_Null_unspecified)?\s*)(\w+)(\).*)$", rest)
    if block:
        name, c_type = block.group(2), block.group(1).rstrip() + block.group(3)
    else:
        parts = re.match(r"^(.*?)\s*\b(\w+)$", rest)
        c_type, name = parts.group(1).strip(), parts.group(2)
    is_class = "class" in attrs
    getter = next((a.split("=")[1].strip() for a in attrs if a.startswith("getter=")), None)
    receiver = cls if is_class else "obj"
    suffix = f"{cls}_{'class_' if is_class else ''}{name}"
    obj_param = "void" if is_class else f"{cls} *obj"
    access = f"[{receiver} {getter}]" if getter else f"{receiver}.{name}"
    lines = [f"RADAR_API_SURFACE {with_name(c_type, f'get_{suffix}({obj_param})')} {{ return {access}; }}"]
    if "readonly" not in attrs:
        params = with_name(c_type, "value")
        params = params if is_class else f"{cls} *obj, {params}"
        lines.append(f"RADAR_API_SURFACE void set_{suffix}({params}) {{ {receiver}.{name} = value; }}")
    return lines


def method_line(cls, decl, used_names):
    match = re.match(r"^([-+]) \(([^)]*(?:\([^)]*\)[^)]*)*)\)\s*(.*)$", decl)
    if not match:
        sys.exit(f"Can't parse a declaration in {cls}, so the surface check would miss it: {decl}")
    kind, ret, signature = match.group(1), match.group(2).strip(), match.group(3)
    parts = re.findall(r"(\w+):\(((?:[^()]|\((?:[^()]|\([^()]*\))*\))*)\)\s*(\w+)", signature)
    if parts:
        params = [with_name(p[1].strip(), f"a{i}") for i, p in enumerate(parts)]
        call = " ".join(f"{p[0]}:a{i}" for i, p in enumerate(parts))
        selector = "_".join(p[0] for p in parts)
    else:
        params, call, selector = [], signature.strip(), signature.strip()
    ret = re.sub(r"\b(nonnull|nullable)\s+instancetype\b", lambda m: f"{cls} * _{m.group(1).capitalize()}", ret)
    ret = ret.replace("instancetype", f"{cls} *")
    base = f"call_{cls}_{'class_' if kind == '+' else ''}{re.sub(r'[^A-Za-z0-9_]', '_', selector)}"
    used_names[base] = used_names.get(base, 0) + 1
    name = base if used_names[base] == 1 else f"{base}_{used_names[base]}"
    if kind == "-" and selector.startswith("init"):
        receiver, all_params = f"[{cls} alloc]", params
    elif kind == "+":
        receiver, all_params = cls, params
    else:
        receiver, all_params = "obj", [f"{cls} *obj"] + params
    signature = f"{name}({', '.join(all_params) or 'void'})"
    expr = f"[{receiver} {call}]"
    if ret == "void":
        return f"RADAR_API_SURFACE void {signature} {{ {expr}; }}"
    return f"RADAR_API_SURFACE {with_name(ret, signature)} {{ return {expr}; }}"


def expected_surface(header_path):
    """Returns {class: [lines]} for every class and Swift extension in the header."""
    surface = {}
    for cls, body, declares_class in interface_blocks(read_header(header_path)):
        lines = [f"RADAR_API_SURFACE Class class_{cls}(void) {{ return [{cls} class]; }}"] if declares_class else []
        used_names = {}
        for raw in declarations(body):
            if "SWIFT_UNAVAILABLE" in raw or "NS_UNAVAILABLE" in raw:
                continue
            class_property = re.match(r"^SWIFT_CLASS_PROPERTY\((@property[^;]*;)\)", raw)
            decl = clean(class_property.group(1) if class_property else raw)
            if decl.startswith("@property"):
                lines += property_lines(cls, decl)
            else:
                lines.append(method_line(cls, decl, used_names))
        surface[cls] = lines
    return surface


def internal_classes():
    names = {}
    for line in open(INTERNAL_PATH):
        entry = line.split("#", 1)
        name = entry[0].strip()
        if name:
            if len(entry) < 2 or not entry[1].strip():
                sys.exit(f"{INTERNAL_PATH}: give a reason for {name} after `#`.")
            names[name] = entry[1].strip()
    return names


def surface_sections(text):
    """Returns {class: (start, end)} line ranges of each `#pragma mark - Class` section."""
    lines = text.split("\n")
    marks = [(i, m.group(1)) for i, line in enumerate(lines) if (m := re.match(r"^#pragma mark - (\w+)\s*$", line))]
    sections = {}
    for index, (start, cls) in enumerate(marks):
        end = marks[index + 1][0] if index + 1 < len(marks) else len(lines)
        sections[cls] = (start, end)
    return sections


def missing_calls(expected, internal, text):
    lines = text.split("\n")
    sections = surface_sections(text)
    missing_classes, missing_members = [], {}
    for cls, expected_lines in expected.items():
        if cls in internal:
            continue
        if cls not in sections:
            missing_classes.append(cls)
            continue
        start, end = sections[cls]
        present = set(FUNCTION_NAME.findall("\n".join(lines[start:end])))
        absent = [line for line in expected_lines if FUNCTION_NAME.search(line).group(1) not in present]
        if absent:
            missing_members[cls] = absent
    return missing_classes, missing_members


def update(expected, missing_classes, missing_members, text):
    lines = text.split("\n")
    # Insert from the bottom up so earlier section ranges stay valid.
    for cls, (start, end) in sorted(surface_sections(text).items(), key=lambda item: -item[1][0]):
        if cls not in missing_members:
            continue
        insert_at = end
        while insert_at > start and not lines[insert_at - 1].strip():
            insert_at -= 1
        lines[insert_at:insert_at] = missing_members[cls]
    text = "\n".join(lines).rstrip("\n") + "\n"
    for cls in missing_classes:
        text += f"\n#pragma mark - {cls}\n\n" + "\n".join(expected[cls]) + "\n"
    open(SURFACE_PATH, "w").write(text)
    if shutil.which("clang-format"):
        subprocess.run(["clang-format", "-i", SURFACE_PATH], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--update", action="store_true")
    parser.add_argument("--header", required=True, help="RadarSDK-Swift.h from a built RadarSDK.framework")
    args = parser.parse_args()

    expected = expected_surface(args.header)
    internal = internal_classes()
    stale = sorted(set(internal) - set(expected))
    if stale:
        sys.exit(f"{INTERNAL_PATH} lists classes that aren't in RadarSDK-Swift.h anymore: {', '.join(stale)}. Remove them.")

    text = open(SURFACE_PATH).read()
    missing_classes, missing_members = missing_calls(expected, internal, text)
    if not missing_classes and not missing_members:
        print(f"RadarSDKObjCAPISurface.m covers all {len(expected) - len(internal)} public Swift-implemented classes.")
        return

    if args.update:
        update(expected, missing_classes, missing_members, text)
        print(f"Added {sum(len(v) for v in missing_members.values())} calls and {len(missing_classes)} classes to {SURFACE_PATH}.")
        print("If a new class isn't meant for apps, move it to internal-classes.txt with a reason instead.")
        return

    print("RadarSDKObjCAPISurface.m doesn't call every public member of the Swift-implemented classes.", file=sys.stderr)
    for cls in missing_classes:
        print(f"  New class {cls}: add it, or list it in internal-classes.txt with a reason.", file=sys.stderr)
    for cls, absent in missing_members.items():
        print(f"  {cls} is missing:", file=sys.stderr)
        for line in absent:
            print(f"    {line}", file=sys.stderr)
    print(f"Run `python3 ObjCCompatibility/objc_api_surface.py --update --header {args.header}` to add them.", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
