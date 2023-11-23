import os


def list_files_with_extension(folder_path, extension1, extension2):
    try:
        # Get the list of files in the given folder
        items = os.listdir(folder_path)

        # Iterate through the list and print the absolute path of files with the specified extension
        right_reads = []
        left_reads = []
        for item in items:
            item_path = os.path.join(folder_path, item)
            if os.path.isfile(item_path) and item.endswith(extension2):
                right_reads.append(os.path.abspath(item_path))
            elif os.path.isfile(item_path) and item.endswith(extension1):
                left_reads.append(os.path.abspath(item_path))

        # Print the output in the desired format
        with open("../spades_run.yaml", "w") as f:
            f.write(
                """[
      {
        orientation: "fr",
        type: "paired-end",
        right reads: ["""
                + ",\n          ".join(f'"{read}"' for read in right_reads)
                + """],
        left reads: ["""
                + ",\n          ".join(f'"{read}"' for read in left_reads)
                + """]
      }
]"""
            )

    except FileNotFoundError:
        print(f"Folder not found: {folder_path}")


folder_path = "../Illumina_reads/trimmed_reads"
left_extension = "R1.fastq.gz"
right_extension = "R2.fastq.gz"
list_files_with_extension(folder_path, left_extension, right_extension)
