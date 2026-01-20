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
    # Track imported files for .sources output
    if hasattr(process_lua_file, 'sources'):
        process_lua_file.sources.append(rel_file_path)
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
    parser.add_argument('--search-paths', nargs='*', default=['.'], help='List of directories to search for required modules')
    parser.add_argument('--output', default='flattened.lua', help='Output file name')
    args = parser.parse_args()


    included_files = set()
    output_lines = []

    # Add configuration header at the top
    output_lines.append('-- Auto generated file, do not edit!')

    # Prepare to track sources
    process_lua_file.sources = []

    # Process base script and its dependencies
    process_lua_file(os.path.abspath(args.base_script), [os.path.abspath(p) for p in args.search_paths], included_files, output_lines)

    # Write to output file
    with open(args.output, 'w', encoding='utf-8') as f:
        for line in output_lines:
            f.write(line + '\n')

    # Write sources file
    sources_filename = args.output + '.sources'
    with open(sources_filename, 'w', encoding='utf-8') as f:
        for src in process_lua_file.sources:
            f.write(src + '\n')

if __name__ == '__main__':
    main()