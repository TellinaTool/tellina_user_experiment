import requests
from bs4 import BeautifulSoup


page = 1
TOTAL_PAGES = 12 # Obtained looking at the maximum number of pages on their website.
count = 0

with open("bashoneliners.csv", 'x') as file:
    while page <= TOTAL_PAGES:
        print(f"Page {page}")

        URL = "http://www.bashoneliners.com/oneliners/popular/?page=" + str(page)
        dom = requests.get(URL)
        soup = BeautifulSoup(dom.content, 'html.parser')

        data = soup.find_all(class_='oneliner-line')

        for record in data:
            title = record.parent.parent.h3.a.string
            link = record.parent.parent.h3.a['href']
            code = record.string
            count += 1

            csv_record = ", ".join([link, title, code])
            print(csv_record)
            file.write(csv_record + '\n')

        page += 1

print(f"Found {count} questions")