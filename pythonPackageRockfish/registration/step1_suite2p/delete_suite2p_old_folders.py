import shutil
from pathlib import Path


# Run from the animal/base folder, or edit root_dir below.
# This deletes only folders named exactly suite2p_old inside subfolders of
# imagingSession. Folders named suite2p are left untouched.

root_dir = Path.cwd()


def main():
    imaging_dirs = sorted(p for p in root_dir.rglob("imagingSession") if p.is_dir())

    print(f"Root directory: {root_dir}")
    print(f"Found {len(imaging_dirs)} imagingSession folder(s).")

    deleted_count = 0
    for imaging_dir in imaging_dirs:
        print(f"\nChecking imagingSession: {imaging_dir}")
        session_dirs = sorted(p for p in imaging_dir.iterdir() if p.is_dir())

        for session_dir in session_dirs:
            suite2p_old_dir = session_dir / "suite2p_old"
            suite2p_dir = session_dir / "suite2p"

            if not suite2p_old_dir.is_dir():
                continue

            print(f"  Deleting: {suite2p_old_dir}")
            if suite2p_dir.is_dir():
                print(f"    Keeping suite2p: {suite2p_dir}")

            shutil.rmtree(suite2p_old_dir)
            deleted_count += 1

    print(f"\nDone. Deleted {deleted_count} suite2p_old folder(s).")


if __name__ == "__main__":
    main()
