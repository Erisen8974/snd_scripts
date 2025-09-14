import os
import sys
import argparse
import re

def find_lua_file(module_name, search_paths):
    # Convert Lua module name to file path (dots to slashes)
    rel_path = module_name.replace('.', os.sep) + '.lua'
    for path in search_paths:
        candidate = os.path.join(path, rel_path)
        if os.path.isfile(candidate):
            return os.path.abspath(candidate)
    return None

def process_lua_file(file_path, search_paths, included_files, output_lines):
    # Compute relative path from base git directory (SND_scripts)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    while not os.path.isdir(os.path.join(base_dir, '.git')) and os.path.dirname(base_dir) != base_dir:
        base_dir = os.path.dirname(base_dir)
    try:
        rel_file_path = os.path.relpath(file_path, base_dir)
    except Exception:
        rel_file_path = os.path.basename(file_path)
    if file_path in included_files:
        print(f"Skipped import: {rel_file_path}")
        output_lines.append(f"-- Skipped import: {rel_file_path}")
        return  # Prevent duplicate inclusion
    included_files.add(file_path)
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            # Match require with or without parentheses
            match = re.match(r"""\s*require\s*(?:\(\s*['"]([^'"]+)['"]\s*\)|['"]([^'"]+)['"])""", line)
            if match:
                module_name = match.group(1) or match.group(2)
                lua_file = find_lua_file(module_name, search_paths)
                if lua_file:
                    # Compute relative path for import comment
                    try:
                        rel_lua_path = os.path.relpath(lua_file, base_dir)
                    except Exception:
                        rel_lua_path = os.path.basename(lua_file)
                    if lua_file in included_files:
                        print(f"Skipped import: {rel_lua_path}")
                        output_lines.append(f"-- Skipped import: {rel_lua_path}")
                    else:
                        print(f"Imported: {rel_lua_path}")
                        banner = (
                            f"--[[\n"
                            f"{'='*80}\n"
                            f"  BEGIN IMPORT: {rel_lua_path}\n"
                            f"{'='*80}\n"
                            f"]]\n"
                        )
                        end_banner = (
                            f"--[[\n"
                            f"{'='*80}\n"
                            f"  END IMPORT: {rel_lua_path}\n"
                            f"{'='*80}\n"
                            f"]]\n"
                        )
                        output_lines.append(banner)
                        process_lua_file(lua_file, search_paths, included_files, output_lines)
                        output_lines.append(end_banner)
                else:
                    print(f"Warning: Could not find module '{module_name}' required in {file_path}", file=sys.stderr)
            else:
                output_lines.append(line.rstrip('\n'))

def main():
    parser = argparse.ArgumentParser(description="Flatten Lua scripts by resolving require statements.")
    parser.add_argument('base_script', help='Path to base Lua script')
    parser.add_argument('--config_header', help='Path to configuration header file (optional if .meta file exists)')
    parser.add_argument('--footer', help='Path to footer Lua file (optional if tails/<basename>.lua exists)')
    parser.add_argument('--search-paths', nargs='*', default=['.'], help='List of directories to search for required modules')
    parser.add_argument('--output', default='flattened.lua', help='Output file name')
    args = parser.parse_args()

    # Determine config header path
    config_header_path = args.config_header
    if not config_header_path:
        base_script_abs = os.path.abspath(args.base_script)
        base_dir = os.path.dirname(base_script_abs)
        base_name = os.path.splitext(os.path.basename(base_script_abs))[0]
        meta_path = os.path.join(base_dir, 'metadata', base_name + '.meta')
        if os.path.isfile(meta_path):
            config_header_path = meta_path
        else:
            print("Error: No config_header provided and no .meta file found in metadata folder.", file=sys.stderr)
            sys.exit(1)

    # Determine footer path
    footer_path = args.footer
    if not footer_path:
        base_script_abs = os.path.abspath(args.base_script)
        base_dir = os.path.dirname(base_script_abs)
        base_name = os.path.splitext(os.path.basename(base_script_abs))[0]
        tails_path = os.path.join(base_dir, 'tails', base_name + '.lua')
        if os.path.isfile(tails_path):
            footer_path = tails_path
        else:
            footer_path = None  # No footer

    # Read configuration header
    with open(config_header_path, 'r', encoding='utf-8') as f:
        config_header = f.read()

    included_files = set()
    output_lines = []

    # Add configuration header at the top
    output_lines.append('-- Auto generated file, do not edit!')
    output_lines.extend(config_header.splitlines())

    # Process base script and its dependencies
    process_lua_file(os.path.abspath(args.base_script), [os.path.abspath(p) for p in args.search_paths], included_files, output_lines)

    # Add footer if present
    if footer_path:
        with open(footer_path, 'r', encoding='utf-8') as f:
            for line in f:
                output_lines.append(line.rstrip('\n'))

    # Write to output file
    with open(args.output, 'w', encoding='utf-8') as f:
        for line in output_lines:
            f.write(line + '\n')

if __name__ == '__main__':
    main()