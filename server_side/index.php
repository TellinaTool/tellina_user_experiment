<!DOCTYPE html>
<html>
<head>
  <title>Tellina User Experiment Log</title>
  <style>
  table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
  }

  th, td {
    padding: 5px
  }
  </style>
</head>

<body>
<p>
<a href="log.csv">Download CSV</a>
</p>

<?php
echo "<html><body><table>\n\n";
$f = fopen("log.csv", "r");
$header = True;

while (($line = fgetcsv($f)) !== false) {
  echo "<tr>";
  if ($header) {
    foreach ($line as $cell) {
      echo "<th>" . htmlspecialchars($cell) . "</th>";
    }
    $header = False;
  } else {
    foreach ($line as $cell) {
      echo "<td>" . htmlspecialchars($cell) . "</td>";
    }
  }
  echo "</tr>\n";
}
fclose($f);
echo "\n</table></body></html>";
?>
</body>
</html>
