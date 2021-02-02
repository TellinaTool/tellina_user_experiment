#!/usr/bin/env python3

import sys
import os
import pandas as pd

def main():
    args = sys.argv[1:]

    if(len(args) < 1):
        print("Usage: requires 1 argument")
        print("0: input file")

    input_file = args[0]
    df = pd.read_csv(input_file, sep=',', engine='python')

    for index, row in df.iterrows():
        print(index)
        print(row['Link'], row['Text'])

        if query_yes_no("Keep?"):
            print(f"Keeping answer {index}")
        else:
            print(f"Discarded.")
    
    # dataset['Link'] = dataset['Id'].map(lambda x: base_url + str(x) + '/')

    # # code snippets are either inlined in <p> or contained in <pre>
    # dataset['Code'] = dataset['Body'].apply(lambda cell: BeautifulSoup(cell, 'html.parser').find_all('code'))
    # dataset['Text'] = dataset['Body'].apply(lambda cell: [item.get_text() for item in BeautifulSoup(cell, 'html.parser').find_all('p')])

    # name, ext = os.path.splitext(input_file)
    # output_file = "{name}-clean{ext}".format(name=name, ext=ext)
    # dataset[['Link', 'Text', 'Code']].to_csv(output_file)

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
