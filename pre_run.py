from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent
CONFIG_DIR = ROOT / "options"
GLOBAL_DATA_PATH = ROOT / "scripts" / "globals" / "globals.gml"

os_targets = ["windows", "linux", "mac"]


def main():
    re_version = re.compile(r'VERSION_STRING\s*=\s*"([^"]+)"')
    with GLOBAL_DATA_PATH.open("r", encoding="utf-8") as f:
        content = f.read()
        match = re_version.search(content)
        if match:
            version_string = match.group(1)
            print(f"================ Update version string : {version_string} ================")
        else:
            print("Error: VERSION_STRING not found in globals.gml")
            sys.exit(1)

    display_name = f"Pixel Composer {version_string}"
    version = version_string

    for target in os_targets:
        config_file = CONFIG_DIR / target / f"options_{target}.yy"
        if not config_file.exists():
            print(f" x Skipping {target}: configuration file not present at {config_file}")
            continue

        re_disp_name = re.compile(f'"option_{target}_display_name":"(.*?)"')
        re_target_version = re.compile(f'"option_{target}_version":"(.*?)"')

        content = config_file.read_text(encoding="utf-8")

        if not re_disp_name.search(content):
            print(f"Error: Display name pattern not found in {config_file}")
        if not re_target_version.search(content):
            print(f"Error: Version pattern not found in {config_file}")

        content = re_disp_name.sub(f'"option_{target}_display_name":"{display_name}"', content)
        content = re_target_version.sub(f'"option_{target}_version":"{version}"', content)

        config_file.write_text(content, encoding="utf-8")
        print(f" > Updated {target} configuration complete.")

    print()


if __name__ == "__main__":
    main()
