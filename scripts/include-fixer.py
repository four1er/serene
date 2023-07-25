#! /usr/bin/env python

import sys
import re
import fileinput
from pathlib import Path


target_header_pattern = re.compile(r"\#include [<\"](.+)[\">](.*)$", re.M)


if __name__ == "__main__":
    # In the `.pre-commit-config.yaml` configuration we have set:
    # files: ".*.(h|cpp)"
    # for this file. So it will only receive cpp and h files. No need to
    # fiter.
    files = sys.argv[1:]

    src_dir = Path(__file__).parent.parent / "serene" / "src"
    headers_files = (src_dir).rglob("*.h")

    headers = []
    for h in headers_files:
        headers.append(str(h.relative_to(src_dir)))

    # Loop over every line in every input file and write lines
    # one by one and modify any file that needs to be rewritten
    for line in fileinput.input(files=files, inplace=True):
        m = re.match(target_header_pattern, line)
        if m:
            header = m.group(1)
            rest = m.group(2)
            if header in headers or header.startswith("serene/"):
                print(f"#include \"{header}\"{rest}")
            else:
                print(f"#include <{header}>{rest}")
        else:
            print(line, end='')

    # # For debugging purposes I leave this here.
    # for f in files:
    #     with open(f, "r") as fd:
    #         lines = fd.readlines()
    #         for line in lines:
    #             m = re.match(target_header_pattern, line)
    #             if m:
    #                 header = m.group(1)
    #                 print("header: ", header)
    #                 rest = m.group(2)
    #                 if header in headers or header == "serene/config.h":
    #                     print(f"#include \"{header}\"{rest}")
    #                 else:
    #                     print(f"#include <{header}>{rest}")
    #             else:
    #                 print(line, end='')
    # raise TypeError()
