#!/usr/bin/env python3
"""
Build index.md files for directory listings on GitHub Pages.

This creates browsable directory listings since GitHub Pages doesn't
support automatic directory indexing.

Based on: https://github.com/Itsblue/github-pages-deb-repo
Inspired by: https://stackoverflow.com/questions/39048654

Usage:
    python3 createStaticDirectoryListing.py deploy --indexPage deploy/README.md
"""

import os
import argparse
from pathlib import Path

try:
    from mako.template import Template
    HAS_MAKO = True
except ImportError:
    HAS_MAKO = False

DEFAULT_TEMPLATE = {
    "outputFileName": "index.md",
    "icons": {
        "DIR": "📁",
        "FILE": "📄",
        "UP": "⬆️",
        "DEB": "📦",
        "GPG": "🔑",
        "GZ": "🗜️",
    },
    "excludedFiles": ["index.md", "_config.yml", "_layouts", "README.md", ".nojekyll"],
    "template": r"""---
layout: default
title: Index of ${path}
---

# Index of ${path}

%for displayName, fileName, fileType in files:
- ${icons.get(fileType, icons['FILE'])} [${displayName}](${fileName})
%endfor
"""
}

# Fallback template without Mako
SIMPLE_TEMPLATE = """---
layout: default
title: Index of {path}
---

# Index of {path}

{file_list}
"""


def get_file_type(filename: str, is_dir: bool) -> str:
    """Determine file type for icon selection."""
    if is_dir:
        return "DIR"
    
    ext = Path(filename).suffix.lower()
    type_map = {
        '.deb': 'DEB',
        '.gpg': 'GPG',
        '.gz': 'GZ',
        '.xz': 'GZ',
    }
    return type_map.get(ext, 'FILE')


def create_directory_listing(base_directory: str, template: dict, 
                            index_page: str = None, sub_directory: str = ""):
    """Recursively create index.md files for all directories."""
    
    if base_directory.endswith("/"):
        base_directory = base_directory[:-1]

    this_directory = os.path.join(base_directory, sub_directory) if sub_directory else base_directory
    
    if not os.path.isdir(this_directory):
        return

    files = []

    # Add parent directory link if not at root
    if sub_directory:
        files.append(("⬆️ Parent Directory", "../", "UP"))

    # List directory contents
    for filename in sorted(os.listdir(this_directory)):
        if filename in template["excludedFiles"]:
            continue
        if filename.startswith('.'):
            continue

        file_path = os.path.join(this_directory, filename)
        is_dir = os.path.isdir(file_path)
        file_type = get_file_type(filename, is_dir)
        display_name = f"{filename}/" if is_dir else filename

        files.append((display_name, filename, file_type))

        # Recurse into subdirectories
        if is_dir:
            new_sub = os.path.join(sub_directory, filename) if sub_directory else filename
            create_directory_listing(base_directory, template, index_page, new_sub)

    # Build display path
    display_path = "/" if not sub_directory else f"/{sub_directory}"

    # Render template
    if HAS_MAKO:
        file_contents = Template(template["template"]).render(
            files=files, 
            path=display_path, 
            icons=template["icons"]
        )
    else:
        # Fallback without Mako
        file_list = "\n".join([
            f"- {template['icons'].get(ft, '📄')} [{dn}]({fn})" 
            for dn, fn, ft in files
        ])
        file_contents = SIMPLE_TEMPLATE.format(path=display_path, file_list=file_list)

    # Prepend index page content at root
    if not sub_directory and index_page and os.path.exists(index_page):
        with open(index_page, "r") as f:
            file_contents = f.read() + "\n" + file_contents.split("---")[-1]  # Skip frontmatter

    # Write index file
    output_path = os.path.join(this_directory, template["outputFileName"])
    with open(output_path, "w") as f:
        f.write(file_contents)
    
    print(f"📝 Created {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Create static directory listings for GitHub Pages"
    )
    parser.add_argument("directory", help="Base directory to process")
    parser.add_argument(
        "--indexPage", 
        required=False, 
        help="File to prepend to root index page"
    )
    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"❌ Error: {args.directory} is not a directory")
        return 1

    print(f"📂 Processing {args.directory}...")
    create_directory_listing(args.directory, DEFAULT_TEMPLATE, args.indexPage)
    print("✅ Directory listings created")
    return 0


if __name__ == '__main__':
    exit(main())

