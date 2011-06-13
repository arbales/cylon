Created as `evilbot`.
It evolved.
There could be many forks.
There is no plan.

### Using Cylon

1. Clone this repo.
2. `cd /path/to/cylon`
3. `npm install`
4. `CYLON_USERNAME='cylon' PASSWORD='security' ./start.sh`

Defunkt's `start.sh` just restarts the script whenever an unhanded error occurs.  

#### Using the `ping` command

Using the `ping` command currently requires that you have a Postmark account with a valid sender signature. You also need to set some extra environment variables:

`POSTMARK_API_KEY='1233-4567-1234-9877' POSTMARK_FROM_EMAIL='you@your.com'`