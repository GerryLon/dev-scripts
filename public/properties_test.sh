#!/bin/bash

. "./properties.sh"

testFile="demo.properties"

# rm -rf $testFile
# touch $testFile

val=`getProperty $testFile "key2"`
echo "key2: $val"
val=`getProperty $testFile key3`
echo "key3: $val"

val=`getProperty $testFile key4`
echo "key4: $val"
