#!/usr/bin/env python3
import sys
import os
import pandas as pd
from bs4 import BeautifulSoup

def main():
    args = sys.argv[1:]

    if(len(args) < 2):
        print("Usage: requires 2 arguments")
        print("0: input file")
        print("1: base_url") #https://stackoverflow.com/questions/

    input_file = args[0]
    base_url = args[1]
    
    dataset = pd.read_csv(input_file, sep=',', engine='python')
    dataset['Link'] = dataset['Id'].map(lambda x: base_url + str(x) + '/')

    # code snippets are either inlined in <p> or contained in <pre>
    dataset['Code'] = dataset['Body'].apply(lambda cell: BeautifulSoup(cell, 'html.parser').find_all('code'))
    dataset['Text'] = dataset['Body'].apply(lambda cell: [item.get_text() for item in BeautifulSoup(cell, 'html.parser').find_all('p')])

    name, ext = os.path.splitext(input_file)
    output_file = "{name}_clean{ext}".format(name=name, ext=ext)
    dataset[['Link', 'Title', 'Text', 'Code']].to_csv(output_file)

if __name__ == "__main__":
    main()
