#[@UOPublicRecords](https://twitter.com/uopublicrecords)

The University of Oregon publishes [requests for public records](http://publicrecords.uoregon.edu/requests) on its website.

This app pulls these pages, computes an MD5 hash of the text content of the page, and makes a copy of the page on S3. Using a hash allows a 'cache miss' when anything on the page, including the status of the request, changes. 

It runs on Heroku for basically free. A ```rake``` task hits an endpoint that kicks off a ```sucker_punch``` job that does the scraping.

Questions? I know this is quick and dirty. [@ivarvong](https://twitter.com/ivarvong)