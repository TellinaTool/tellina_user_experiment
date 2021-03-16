import requests
from bs4 import BeautifulSoup

TOTAL_COMMANDS = 14042 # Obtained automatically by running the parser until nothing is returned.
TOP_COMMANDS = 500 # We don't need all the commands on the website to sample from, only the 500 most popular.
command = 0

with open("commandlinefu.csv", 'x') as file:
    while command < TOTAL_COMMANDS and command < TOP_COMMANDS:
        print(f"Page {command // 25}")

        # This website indexes pages by command instead of page. Each pages contains 25 commands.
        # For example, command = 0 will return commands 0 to 24. command = 25 will return commands 25 to 29.
        URL = "https://www.commandlinefu.com/commands/browse/sort-by-votes/" + str(command) 
        dom = requests.get(URL)
        soup = BeautifulSoup(dom.content, 'html.parser')

        data = soup.find_all(class_='one-liner')
        for record in data:
            title = record.a.string
            link = record.a['href']
            code = record.find(class_='command').get_text()
            command += 1

            csv_record = ", ".join([link, title, code])
            print(csv_record)
            file.write(csv_record + '\n')

        print(command)

print(f"Collected {command} commands")