import pathlib
import subprocess


def main(files: list[pathlib.Path]) -> None:
    data = dict()
    for file in files:
        cmd = f"texcount -brief {file}"
        process_output = subprocess.run(
            cmd, shell=True, capture_output=True, text=True
        ).stdout.strip()
        word_count = eval(process_output.split(" ")[0])
        print(f"{file.name} has {word_count} words")
        data[file.stem] = word_count
    final_word_count = (
        data["abstract"]
        + data["discussion"]
        + data["introduction"]
        + data["results"]
        + data["acknowledgements"]
    )
    print(f"Final word count = {final_word_count} words")


if __name__ == "__main__":
    FILES = list(pathlib.Path().glob("*.tex"))
    main(FILES)
