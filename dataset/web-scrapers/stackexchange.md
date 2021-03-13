
The stack exchange websites (StackOverflow, SuperUser, and Unix&Linux) are obtained using the [Stack Exchange Data Explorer](https://data.stackexchange.com/).
The SQL query used for retrieving the data from a stack exchange website is given below:

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

The query will return a quintuplet of the question's title, id (used to create a link to the question), tags, score, and raw html body. The `INNER JOIN` on `PostTags` and `Tags` enable to filter questions that are tagged with 'bash' and the last `INNER JOIN` on `Posts` enable to filter questions that have an accepted answer for the top 500 questions ordered by score.

## Manual exploration
The web scraping and SQL query are based on available webpages for each site:
* Stack Overflow: https://stackoverflow.com/search?tab=Votes&q=%5bbash%5d%20hasaccepted%3ayes
* Super User: https://superuser.com/search?tab=votes&q=%5bbash%5d%20hasaccepted%3ayes
* Unix & Linux: https://unix.stackexchange.com/questions/tagged/bash?tab=Votes
* CommandLineFu: https://www.commandlinefu.com/commands/browse/sort-by-votes
* Bash One-Liners: http://www.bashoneliners.com/oneliners/popular/
