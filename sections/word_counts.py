import pathlib
import subprocess


def main(files: list[pathlib.Path]) -> None:
    for file in files:
        cmd = f"detex {file} | wc -w"
        process_output = subprocess.run(
            cmd, shell=True, capture_output=True, text=True
        ).stdout.strip()
        print(f"{file.name} has {process_output} words")


if __name__ == "__main__":
    FILES = list(pathlib.Path().glob("*.tex"))
    main(FILES)
