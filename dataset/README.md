# User Study Dataset
This folder contains the various scripts and datasets to produce or replicate the taskset used by the user study.
[`pipenv`](https://docs.pipenv.org/) is used to manage package dependency and virtual environment for the Python scripts. They are declared in the file `Pipfile`.

# Sources
The tasks are sourced from StackOverflow, SuperUser, Unix&Linux, CommandLineFu, and Bash One-Liners. 
For each source, we retrieve the most popular questions or one-liners up to 500 items. 
We retrieve the data from the StackExchange websites (i.e., StackOverflow, SuperUser, Unix&Linux) using the [Stack Exchange Data Explorer](https://data.stackexchange.com/). For CommandLineFu and Bash One-Liners, we use the web scraping scripts developed in `web-scrapers/`.

## SQL Query
The SQL query used for retrieving the data from the stack exchange website is given below. 

```sql
SELECT TOP 500 q.Title, q.Id, q.Tags, q.Score, a.Body
FROM Posts q
INNER JOIN PostTags pt ON q.Id = pt.PostId
INNER JOIN Tags t ON pt.TagId = t.Id
INNER JOIN Posts a ON a.Id = q.AcceptedAnswerId 
WHERE t.TagName LIKE 'bash' 
AND q.AcceptedAnswerId is not NULL
ORDER BY q.Score DESC
```

The query will return a quintuplet of the question's title, id (used to create a link to the question), tags, score, and raw html body. The `INNER JOIN` on `PostTags` and `Tags` enable to filter questions that are tagged with 'bash' and the last `INNER JOIN` on Posts enable to filter questions that have an accepted answer for the top 500 questions ordered by score.

## Manual exploration
The web scraping and SQL query are based on available webpages for each site:
* Stack Overflow: https://stackoverflow.com/search?tab=Votes&q=%5bbash%5d%20hasaccepted%3ayes
* Super User: https://superuser.com/search?tab=votes&q=%5bbash%5d%20hasaccepted%3ayes
* Unix & Linux: https://unix.stackexchange.com/questions/tagged/bash?tab=Votes
* CommandLineFu: https://www.commandlinefu.com/commands/browse/sort-by-votes
* Bash One-Liners: http://www.bashoneliners.com/oneliners/popular/
