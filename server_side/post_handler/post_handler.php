<?php
if (isset($_POST) && ($_POST)) {
  $filename="../log.csv";
  $line = gmdate("Y-m-d\TH:i:s\Z");
  $line .= ",";
  $line .= implode(",", $_POST);
  $line .= "\n";
  file_put_contents($filename, $line, FILE_APPEND);

  echo "<h2>Submitted</h2>";
}
?>
<html>
  <head>
    <title>A Generic POST -> CSV handler</title>
    <h2>Submit a POST request to log a request.</h2>
  </head>

  <body>
    <form action="post_handler.php" method="POST"/>
  </body>
</html>
