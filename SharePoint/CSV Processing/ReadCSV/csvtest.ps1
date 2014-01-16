$testcsv = import-csv H:\test.csv
  
 
  
 foreach($test in $testcsv)
  
   {
  
   $field1 = $test."id"
  
   $field2 = $test."name"
  
   
  
   Echo "$field1, $field2"
  
   }