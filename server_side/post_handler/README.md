# Post Handler

The handler gets forms from `POST` requests, glue each value together with
`,`, and appends the line to `log.csv`.

An example `curl` command can be seen in `example`. To run, change the host and
route to wherever the server is being hosted, then `./example`.
