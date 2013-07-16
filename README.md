The Oregon State Legislature has an FTP server [1] with information about the session. 

This is a small app that pulls those text files to diff them.

It uses the sucker_punch gem to do the FTP fetching from the main Heroku web process. The rake task only hit the endpoint in the Sinatra app, which queues the job and immediately returns. The scheduler only runs for a few seconds, making it pretty cheap.

This is a major work in progress. All it does right now is download the files.

[1] ftp://landru.leg.state.or.us/pub

---


An example run:

	2013-07-08T19:33:16.732007+00:00 heroku[api]: Starting process with command `bundle exec rake update_ftp` by scheduler@addons.heroku.com
	2013-07-08T19:33:21.738992+00:00 heroku[scheduler.8881]: Starting process with command `bundle exec rake update_ftp`
	2013-07-08T19:33:23.815479+00:00 heroku[scheduler.8881]: State changed from starting to up
	2013-07-08T19:33:24.543526+00:00 app[scheduler.8881]: OK
	2013-07-08T19:33:24.486670+00:00 app[web.1]: 54.224.33.19 - - [08/Jul/2013 19:33:24] "GET /some-semi-secret-key-here-set-by-your-ENV-variable HTTP/1.1" 200 2 0.0050
	2013-07-08T19:33:26.364366+00:00 heroku[scheduler.8881]: Process exited with status 0
	2013-07-08T19:33:26.362555+00:00 heroku[scheduler.8881]: State changed from up to complete
	2013-07-08T19:33:33.920578+00:00 app[web.1]: RefreshJob: perform took 9.430816824
	2013-07-08T19:33:33.921361+00:00 app[web.1]: I'm UpdateJob. I should check for diffs and stuff