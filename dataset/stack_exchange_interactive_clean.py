#!/usr/bin/env python3

import sys
import os
import pandas as pd
import re

def main():
    """Interactive session to annotate a clean stackexchange CSV file (e.g., data-clean/stackoverflow*.csv)"""
    args = sys.argv[1:]

    if(len(args) < 1):
        print("Usage: requires 1 argument")
        print("0: input file")

    input_file = args[0]
    df = pd.read_csv(input_file, sep=',', engine='python')

    incompatible_commands = ['awk', 'sed', 'python', 'java', 'git', 'iconv', 
    'ffmpeg', 'jar', 'perl', 'python', 'svn', 'docker']
    kept_posts = [] # contains the list of accepted posts
    kept_target = 30 # the number of posts we want to acquire.

    for index, row in df.iterrows():
 
        code = row["Code"]
        link = row['Link']
        title = row['Title']
        print(f"=========================== (#{index}, url: {link})")
        print(title)
        # print('~~~~~~~~~~~~~~~~~~~~~~~~~~~')
        # print(code) # Todo print Body instead if needed
        print('~~~~~~~~~~~~~~~~~~~~~~~~~~~')

        count = 0
        
        for snippet in code.split("</code>, <code>"):
            snippet = snippet.replace("[<code>", "")
            snippet = snippet.replace("</code>]", "")
            snippet = snippet.replace("#!/bin/bash", "")

            snippet = snippet.strip()
            
            snippet = snippet.replace("&lt;", "<")
            snippet = snippet.replace("&gt;", ">")
            snippet = snippet.replace("&amp;", "&")

            if " " not in snippet:
                continue

            # if '\n' in snippet or '\r' in snippet:
            #     continue
            # Sometimes, multiline snippets include also the result of the command.

            if any(ext in snippet for ext in incompatible_commands):
                continue

            legal_start = re.search(r"^\$? ?[a-zA-Z0-9\-]+ ", snippet)
            if_matches = re.search(r"if[\s\S]*?then[\s\S]*?fi", snippet)
            while_matches = re.search(r"if[\s\S]*?then[\s\S]*?fi", snippet)
            for_matches = re.search(r"for[\s\S]*?in[\s\S]*?[\s\S]*?do[\s\S]*?done", snippet)
            
            
            # if, for, do, while, done
            
            # if not legal_start:
            #     print("Not a valid command start")
            # elif if_matches:
            #     print(f"Found an if statement: {if_matches}")
            # elif while_matches:
            #     print(f"Found a while statement: {while_matches}")
            # elif for_matches:
            #     print(f"Found a for statement: {for_matches}")
            # else:
            #     print("Good to go!")

            if if_matches or while_matches or for_matches or not legal_start:
                continue

            print(f"-> {snippet}")
            count += 1

        if count:
            if query_yes_no("Keep?"):
                kept_posts.append(link)
                print(f"Keeping answer {index} ({len(kept_posts)}/{kept_target})")
            else:
                print(f"Discarded.")
        else:
            print(f"No valid snippet for {link}")

        print()

        if kept_target == len(kept_posts):
            if query_yes_no(f"You reached the post target ({kept_target}). Do you want to save and exit (Answering 'No' will rairse the target by 10 posts)?"):
                # Save posts to file
                output_file = 'se_interactive_session_results.txt'
                with open(output_file, 'w') as f:
                    for item in kept_posts:
                        print(item)
                        f.write(f"{str(item)}\n")
                print(f"Results saved in {output_file}")
                break
            else:
                kept_target += 10
                print(f"Post target raised to {kept_target}")

def clean_alt_list(list_):
    list_ = list_.replace(', ', '","')
    list_ = list_.replace('[', '["')
    list_ = list_.replace(']', '"]')
    return list_

def query_yes_no(question, default="yes"):
    """Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    https://stackoverflow.com/questions/3041986/
    """
    valid = {"yes": True, "y": True, "ye": True,
             "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' "
                             "(or 'y' or 'n').\n")

if __name__ == "__main__":
    main()
