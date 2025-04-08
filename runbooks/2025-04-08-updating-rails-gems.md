Here are the steps to update a rails gem used by a web app in a docker container:

1. Start the container and ensure the web app is running
2. Acquire a container command line prompt
3. On your local machine, edit Gemfile to add or update the version of whatever gem
4. On the container command line prompt run:

```
> bundle install
```

5. Enusure the web app is still running

You are done